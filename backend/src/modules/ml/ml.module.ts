import { Module } from '@nestjs/common';
import { DatabaseModule } from '../../database/database.module';
import { MlController } from './ml.controller';
import { MlService } from './ml.service';

@Module({
  imports: [DatabaseModule],
  controllers: [MlController],
  providers: [MlService],
  exports: [MlService],
})
export class MlModule {}
