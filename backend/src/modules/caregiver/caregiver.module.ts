import { Module } from '@nestjs/common';
import { CaregiverController } from './caregiver.controller';
import { CaregiverService } from './caregiver.service';

@Module({
  controllers: [CaregiverController],
  providers: [CaregiverService],
  exports: [CaregiverService],
})
export class CaregiverModule {}
