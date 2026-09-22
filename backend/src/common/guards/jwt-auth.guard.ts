import {
  CanActivate,
  ExecutionContext,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { Request } from 'express';
import { InMemoryDbService } from '../../database/in-memory-db.service';

export interface AuthenticatedUser {
  userId: string;
  email: string;
  role: string;
}

@Injectable()
export class JwtAuthGuard implements CanActivate {
  constructor(
    private readonly jwtService: JwtService,
    private readonly dbService: InMemoryDbService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest<Request>();
    const authHeader = request.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      throw new UnauthorizedException('Authentication token missing or invalid');
    }

    const token = authHeader.substring(7).trim();
    if (!token) {
      throw new UnauthorizedException('Authentication token missing');
    }

    try {
      const payload = await this.jwtService.verifyAsync(token);
      
      // Verify the user exists and is active in the server database
      const user = await this.dbService.findUserById(payload.sub);
      if (!user || !user.isActive) {
        throw new UnauthorizedException('User account is inactive or not found');
      }

      // Attach authenticated user identity to request
      (request as any).user = {
        userId: user.id,
        email: user.email,
        role: user.role,
      };

      return true;
    } catch (err: any) {
      if (err.name === 'TokenExpiredError') {
        throw new UnauthorizedException('Authentication token has expired');
      }
      throw new UnauthorizedException('Authentication token is invalid');
    }
  }
}
