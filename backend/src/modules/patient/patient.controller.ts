import {
  Controller,
  Get,
  Param,
  UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { OwnershipGuard } from '../../common/guards/ownership.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { UserRole } from '../../common/enums/user-role.enum';
import { PatientService } from './patient.service';

@Controller('api/v1/patients')
@UseGuards(JwtAuthGuard, RolesGuard, OwnershipGuard)
export class PatientController {
  constructor(private readonly patientService: PatientService) {}

  @Get(':id/dashboard')
  @Roles(UserRole.ADMIN, UserRole.CAREGIVER, UserRole.PATIENT)
  async getDashboard(@Param('id') id: string) {
    return this.patientService.getPatientDashboard(id);
  }

  @Get(':id/medications')
  @Roles(UserRole.ADMIN, UserRole.CAREGIVER, UserRole.PATIENT)
  async getMedications(@Param('id') id: string) {
    return this.patientService.getPatientMedications(id);
  }
}
