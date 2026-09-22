import {
  BadRequestException,
  ConflictException,
  Injectable,
  Logger,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import * as crypto from 'crypto';
import { InMemoryDbService, UserEntity } from '../../database/in-memory-db.service';
import { PasswordHasherService } from '../../common/services/password-hasher.service';
import {
  LoginDto,
  PasswordResetConfirmDto,
  PasswordResetRequestDto,
  RefreshTokenDto,
  RegisterDto,
} from './auth.dto';

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);

  constructor(
    private readonly dbService: InMemoryDbService,
    private readonly passwordHasher: PasswordHasherService,
    private readonly jwtService: JwtService,
  ) {}

  /**
   * Registers a new caregiver or patient user.
   */
  async register(dto: RegisterDto) {
    const existing = await this.dbService.findUserByEmail(dto.email);
    if (existing) {
      throw new ConflictException('An account with this email address already exists');
    }

    const passwordHash = await this.passwordHasher.hashPassword(dto.password);
    const userId = `user_${crypto.randomUUID()}`;

    const newUser: UserEntity = {
      id: userId,
      email: dto.email.trim().toLowerCase(),
      passwordHash,
      role: dto.role,
      fullName: dto.fullName.trim(),
      isActive: true,
      createdAt: new Date().toISOString(),
    };

    await this.dbService.createUser(newUser);

    this.logger.log(`Registered new user: ${newUser.email} [Role: ${newUser.role}]`);

    return {
      id: newUser.id,
      email: newUser.email,
      fullName: newUser.fullName,
      role: newUser.role,
      createdAt: newUser.createdAt,
    };
  }

  /**
   * Authenticates credentials and issues short-lived JWT + rotating refresh token.
   */
  async login(dto: LoginDto) {
    const user = await this.dbService.findUserByEmail(dto.email);
    
    // Constant time behavior: if user not found, perform dummy hash check to prevent timing leaks
    if (!user || !user.isActive) {
      await this.passwordHasher.verifyPassword('dummy_password_timing_pad', '00000000000000000000000000000000:00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000');
      throw new UnauthorizedException('Invalid email or password');
    }

    const isValid = await this.passwordHasher.verifyPassword(dto.password, user.passwordHash);
    if (!isValid) {
      throw new UnauthorizedException('Invalid email or password');
    }

    return this.generateTokens(user);
  }

  /**
   * Validates refresh token, revokes it (token rotation), and issues new pair.
   */
  async refreshToken(dto: RefreshTokenDto) {
    const tokenHash = this.hashToken(dto.refreshToken);
    const record = await this.dbService.findRefreshToken(tokenHash);

    if (!record || record.isRevoked) {
      throw new UnauthorizedException('Invalid or revoked refresh token');
    }

    const isExpired = new Date(record.expiresAt).getTime() < Date.now();
    if (isExpired) {
      throw new UnauthorizedException('Refresh token has expired. Please log in again.');
    }

    // Revoke old refresh token (Single-use Token Rotation)
    await this.dbService.revokeRefreshToken(tokenHash);

    const user = await this.dbService.findUserById(record.userId);
    if (!user || !user.isActive) {
      throw new UnauthorizedException('User account is inactive or not found');
    }

    return this.generateTokens(user);
  }

  /**
   * Revokes refresh tokens and logs out user session.
   */
  async logout(userId: string, refreshToken?: string) {
    if (refreshToken) {
      const tokenHash = this.hashToken(refreshToken);
      await this.dbService.revokeRefreshToken(tokenHash);
    } else {
      await this.dbService.revokeAllUserTokens(userId);
    }
    return { success: true, message: 'Logged out successfully' };
  }

  /**
   * Initiates password reset with zero-enumeration generic response.
   */
  async requestPasswordReset(dto: PasswordResetRequestDto) {
    const user = await this.dbService.findUserByEmail(dto.email);

    if (user && user.isActive) {
      const rawToken = crypto.randomBytes(32).toString('hex');
      const tokenHash = this.hashToken(rawToken);
      const expiresAt = new Date(Date.now() + 15 * 60 * 1000).toISOString(); // 15 mins

      await this.dbService.savePasswordReset({
        id: crypto.randomUUID(),
        userId: user.id,
        tokenHash,
        expiresAt,
        isUsed: false,
        createdAt: new Date().toISOString(),
      });

      // Audit log event with hashed identifier only; NEVER log raw tokens or plaintext PII
      const auditHash = crypto.createHash('sha256').update(user.id).digest('hex').substring(0, 12);
      this.logger.log(`Password reset token generated for auditRef: ${auditHash}`);
    }

    // Always return safe generic confirmation regardless of email existence (prevent enumeration)
    return {
      success: true,
      message: 'If an active account exists for this email address, password reset instructions have been sent.',
    };
  }

  /**
   * Confirms password reset, updates hash, and invalidates all existing sessions.
   */
  async confirmPasswordReset(dto: PasswordResetConfirmDto) {
    const tokenHash = this.hashToken(dto.token);
    const resetRecord = await this.dbService.findPasswordReset(tokenHash);

    if (!resetRecord || resetRecord.isUsed) {
      throw new BadRequestException('Invalid or expired password reset token');
    }

    const isExpired = new Date(resetRecord.expiresAt).getTime() < Date.now();
    if (isExpired) {
      throw new BadRequestException('Password reset token has expired');
    }

    // Mark token as consumed
    await this.dbService.markPasswordResetUsed(resetRecord.id);

    // Hash new password and update user
    const newPasswordHash = await this.passwordHasher.hashPassword(dto.newPassword);
    await this.dbService.updateUserPassword(resetRecord.userId, newPasswordHash);

    // Invalidate all existing refresh tokens for security
    await this.dbService.revokeAllUserTokens(resetRecord.userId);

    this.logger.log(`Password reset completed for userId: ${resetRecord.userId}`);

    return {
      success: true,
      message: 'Password has been successfully reset. Please log in with your new password.',
    };
  }

  private async generateTokens(user: UserEntity) {
    const payload = {
      sub: user.id,
      email: user.email,
      role: user.role,
    };

    // Short-lived access token (15 minutes)
    const accessToken = await this.jwtService.signAsync(payload, {
      expiresIn: '15m',
    });

    // High-entropy random refresh token (7 days)
    const rawRefreshToken = crypto.randomBytes(40).toString('hex');
    const tokenHash = this.hashToken(rawRefreshToken);
    const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString();

    await this.dbService.saveRefreshToken({
      id: crypto.randomUUID(),
      userId: user.id,
      tokenHash,
      expiresAt,
      isRevoked: false,
      createdAt: new Date().toISOString(),
    });

    return {
      accessToken,
      refreshToken: rawRefreshToken,
      tokenType: 'Bearer',
      expiresIn: 900, // 15 minutes in seconds
      user: {
        id: user.id,
        email: user.email,
        fullName: user.fullName,
        role: user.role,
      },
    };
  }

  private hashToken(token: string): string {
    return crypto.createHash('sha256').update(token).digest('hex');
  }
}
