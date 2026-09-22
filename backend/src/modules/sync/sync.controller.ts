import {
  Body,
  Controller,
  HttpCode,
  HttpStatus,
  Post,
  Req,
  UseGuards,
} from '@nestjs/common';
import { Throttle } from '@nestjs/throttler';
import { BatchSyncRequestDto, BatchSyncResponseDto } from './sync.dto';
import { SyncService } from './sync.service';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { UserRole } from '../../common/enums/user-role.enum';

@Controller('api/v1/sync')
@UseGuards(JwtAuthGuard, RolesGuard)
export class SyncController {
  constructor(private readonly syncService: SyncService) {}

  @Post('batch')
  @HttpCode(HttpStatus.OK)
  @Roles(UserRole.ADMIN, UserRole.CAREGIVER, UserRole.PATIENT)
  @Throttle({ default: { limit: 30, ttl: 60000 } })
  async batchSync(
    @Body() requestDto: BatchSyncRequestDto,
    @Req() req: any,
  ): Promise<BatchSyncResponseDto> {
    return this.syncService.processBatchSync(requestDto, req.user);
  }
}
