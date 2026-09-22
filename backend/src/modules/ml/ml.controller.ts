import {
  Body,
  Controller,
  ForbiddenException,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  Post,
  Req,
  UseGuards,
} from '@nestjs/common';
import { Throttle } from '@nestjs/throttler';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { UserRole } from '../../common/enums/user-role.enum';
import { InMemoryDbService } from '../../database/in-memory-db.service';
import {
  PerformanceTrendResponseDto,
  PredictCompletionDto,
  PredictCompletionResponseDto,
  RecommendGameDto,
  RecommendGameResponseDto,
} from './ml.dto';
import { MlService } from './ml.service';

@Controller('api/v1/ml')
@UseGuards(JwtAuthGuard, RolesGuard)
export class MlController {
  constructor(
    private readonly mlService: MlService,
    private readonly dbService: InMemoryDbService,
  ) {}

  @Post('recommend-game')
  @HttpCode(HttpStatus.OK)
  @Roles(UserRole.ADMIN, UserRole.CAREGIVER, UserRole.PATIENT)
  @Throttle({ default: { limit: 60, ttl: 60000 } })
  async recommendGame(
    @Body() dto: RecommendGameDto,
    @Req() req: any,
  ): Promise<RecommendGameResponseDto> {
    const user = req.user;

    // Enforce patient ownership or caregiver relationship
    if (user.role === UserRole.PATIENT && dto.patientId !== user.userId) {
      throw new ForbiddenException('Access denied: Patients can only request recommendations for themselves.');
    }

    if (user.role === UserRole.CAREGIVER) {
      const hasRel = await this.dbService.findActiveRelationship(user.userId, dto.patientId);
      if (!hasRel) {
        throw new ForbiddenException('Access denied: Caregiver not authorized for this patient.');
      }
    }

    return this.mlService.recommendGame(dto);
  }

  @Post('predict-completion')
  @HttpCode(HttpStatus.OK)
  @Roles(UserRole.ADMIN, UserRole.CAREGIVER, UserRole.PATIENT)
  @Throttle({ default: { limit: 60, ttl: 60000 } })
  async predictCompletion(
    @Body() dto: PredictCompletionDto,
    @Req() req: any,
  ): Promise<PredictCompletionResponseDto> {
    const user = req.user;

    if (user.role === UserRole.PATIENT && dto.patientId !== user.userId) {
      throw new ForbiddenException('Access denied: Patients can only evaluate completion risks for themselves.');
    }

    if (user.role === UserRole.CAREGIVER) {
      const hasRel = await this.dbService.findActiveRelationship(user.userId, dto.patientId);
      if (!hasRel) {
        throw new ForbiddenException('Access denied: Caregiver not authorized for this patient.');
      }
    }

    return this.mlService.predictCompletion(dto);
  }

  @Get('trend/:patientId')
  @HttpCode(HttpStatus.OK)
  @Roles(UserRole.ADMIN, UserRole.CAREGIVER, UserRole.PATIENT)
  @Throttle({ default: { limit: 30, ttl: 60000 } })
  async getPerformanceTrend(
    @Param('patientId') patientId: string,
    @Req() req: any,
  ): Promise<PerformanceTrendResponseDto> {
    const user = req.user;

    if (user.role === UserRole.PATIENT && patientId !== user.userId) {
      throw new ForbiddenException('Access denied: Patients can only query their own trends.');
    }

    if (user.role === UserRole.CAREGIVER) {
      const hasRel = await this.dbService.findActiveRelationship(user.userId, patientId);
      if (!hasRel) {
        throw new ForbiddenException('Access denied: Caregiver not authorized for this patient.');
      }
    }

    return this.mlService.getPerformanceTrend(patientId);
  }

  @Get('model-card')
  @HttpCode(HttpStatus.OK)
  @Roles(UserRole.ADMIN, UserRole.CAREGIVER, UserRole.PATIENT)
  @Throttle({ default: { limit: 20, ttl: 60000 } })
  async getModelCard(): Promise<any> {
    return this.mlService.getModelCard();
  }
}
