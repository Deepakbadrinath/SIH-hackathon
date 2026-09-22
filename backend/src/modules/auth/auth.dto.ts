import {
  IsEmail,
  IsEnum,
  IsNotEmpty,
  IsString,
  Matches,
  MaxLength,
  MinLength,
} from 'class-validator';
import { UserRole } from '../../common/enums/user-role.enum';

export class RegisterDto {
  @IsEmail({}, { message: 'Invalid email address format' })
  @MaxLength(256, { message: 'Email address cannot exceed 256 characters' })
  @IsNotEmpty()
  email: string;

  @IsString()
  @MinLength(8, { message: 'Password must be at least 8 characters long' })
  @MaxLength(128, { message: 'Password cannot exceed 128 characters' })
  @Matches(
    /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$/,
    {
      message:
        'Password must contain at least one uppercase letter, one lowercase letter, one number, and one special character (@$!%*?&)',
    },
  )
  password: string;

  @IsString()
  @MaxLength(100, { message: 'Full name cannot exceed 100 characters' })
  @IsNotEmpty({ message: 'Full name is required' })
  fullName: string;

  @IsEnum([UserRole.CAREGIVER, UserRole.PATIENT], {
    message: 'Registration is permitted for CAREGIVER or PATIENT roles only',
  })
  role: UserRole;
}

export class LoginDto {
  @IsEmail({}, { message: 'Invalid email address format' })
  @MaxLength(256, { message: 'Email address cannot exceed 256 characters' })
  @IsNotEmpty()
  email: string;

  @IsString()
  @MaxLength(128, { message: 'Password cannot exceed 128 characters' })
  @IsNotEmpty({ message: 'Password is required' })
  password: string;
}

export class RefreshTokenDto {
  @IsString()
  @MaxLength(1024, { message: 'Refresh token cannot exceed 1024 characters' })
  @IsNotEmpty({ message: 'Refresh token is required' })
  refreshToken: string;
}

export class PasswordResetRequestDto {
  @IsEmail({}, { message: 'Invalid email address format' })
  @MaxLength(256, { message: 'Email address cannot exceed 256 characters' })
  @IsNotEmpty()
  email: string;
}

export class PasswordResetConfirmDto {
  @IsString()
  @MaxLength(256, { message: 'Reset token cannot exceed 256 characters' })
  @IsNotEmpty({ message: 'Reset token is required' })
  token: string;

  @IsString()
  @MinLength(8, { message: 'New password must be at least 8 characters long' })
  @MaxLength(128, { message: 'New password cannot exceed 128 characters' })
  @Matches(
    /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$/,
    {
      message:
        'Password must contain at least one uppercase letter, one lowercase letter, one number, and one special character (@$!%*?&)',
    },
  )
  newPassword: string;
}
