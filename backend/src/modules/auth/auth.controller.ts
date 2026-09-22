import {
  Body,
  Controller,
  Get,
  HttpCode,
  HttpStatus,
  Post,
  Req,
  UseGuards,
} from '@nestjs/common';
import { Throttle } from '@nestjs/throttler';
import { Request } from 'express';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { AuthService } from './auth.service';
import {
  LoginDto,
  PasswordResetConfirmDto,
  PasswordResetRequestDto,
  RefreshTokenDto,
  RegisterDto,
} from './auth.dto';

@Controller('api/v1/auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('register')
  @HttpCode(HttpStatus.CREATED)
  @Throttle({ default: { limit: 10, ttl: 60000 } })
  async register(@Body() dto: RegisterDto) {
    return this.authService.register(dto);
  }

  @Post('login')
  @HttpCode(HttpStatus.OK)
  // Strict Rate Limiting: 5 attempts per minute to mitigate brute-force and credential stuffing
  @Throttle({ default: { limit: 5, ttl: 60000 } })
  async login(@Body() dto: LoginDto) {
    return this.authService.login(dto);
  }

  @Post('refresh')
  @HttpCode(HttpStatus.OK)
  @Throttle({ default: { limit: 20, ttl: 60000 } })
  async refreshToken(@Body() dto: RefreshTokenDto) {
    return this.authService.refreshToken(dto);
  }

  @Post('logout')
  @HttpCode(HttpStatus.OK)
  @UseGuards(JwtAuthGuard)
  @Throttle({ default: { limit: 20, ttl: 60000 } })
  async logout(@Req() req: Request, @Body() body?: { refreshToken?: string }) {
    const user = (req as any).user;
    return this.authService.logout(user.userId, body?.refreshToken);
  }

  @Post('password-reset/request')
  @HttpCode(HttpStatus.OK)
  @Throttle({ default: { limit: 5, ttl: 60000 } })
  async requestPasswordReset(@Body() dto: PasswordResetRequestDto) {
    return this.authService.requestPasswordReset(dto);
  }

  @Post('password-reset/confirm')
  @HttpCode(HttpStatus.OK)
  @Throttle({ default: { limit: 5, ttl: 60000 } })
  async confirmPasswordReset(@Body() dto: PasswordResetConfirmDto) {
    return this.authService.confirmPasswordReset(dto);
  }

  @Get('me')
  @UseGuards(JwtAuthGuard)
  async getProfile(@Req() req: Request) {
    return (req as any).user;
  }
}
