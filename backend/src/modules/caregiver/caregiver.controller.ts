import {
  Controller,
  ForbiddenException,
  Get,
  Param,
  Req,
  UseGuards,
} from '@nestjs/common';
import { Request } from 'express';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { UserRole } from '../../common/enums/user-role.enum';
import { CaregiverService } from './caregiver.service';

@Controller('api/v1/caregivers')
@UseGuards(JwtAuthGuard, RolesGuard)
export class CaregiverController {
  constructor(private readonly caregiverService: CaregiverService) {}

  @Get(':id/patients')
  @Roles(UserRole.ADMIN, UserRole.CAREGIVER)
  async getConnectedPatients(@Param('id') id: string, @Req() req: Request) {
    const user = (req as any).user;

    // Server-enforced ownership: caregiver can only query their own patient list unless ADMIN
    if (user.role === UserRole.CAREGIVER && user.userId !== id) {
      throw new ForbiddenException(
        "Access denied: You cannot view another caregiver's connected patients.",
      );
    }

    return this.caregiverService.getConnectedPatients(id);
  }
}
