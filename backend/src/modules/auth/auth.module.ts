import { Global, Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { OwnershipGuard } from '../../common/guards/ownership.guard';

@Global()
@Module({
  imports: [
    JwtModule.registerAsync({
      useFactory: () => {
        const secret = process.env.JWT_SECRET;
        const isProduction = process.env.NODE_ENV === 'production';
        if (isProduction && (!secret || secret.length < 32)) {
          throw new Error(
            'CRITICAL SECURITY CONFIGURATION ERROR: JWT_SECRET must be at least 32 characters long in production environment.',
          );
        }
        return {
          secret: secret || 'smriti-setu-secure-backend-master-secret-key-sih-26003',
          signOptions: { expiresIn: '15m' },
        };
      },
    }),
  ],
  controllers: [AuthController],
  providers: [AuthService, JwtAuthGuard, RolesGuard, OwnershipGuard],
  exports: [AuthService, JwtModule, JwtAuthGuard, RolesGuard, OwnershipGuard],
})
export class AuthModule {}
