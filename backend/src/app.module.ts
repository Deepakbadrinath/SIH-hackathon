import { Module } from '@nestjs/common';
import { APP_GUARD } from '@nestjs/core';
import { ThrottlerGuard, ThrottlerModule } from '@nestjs/throttler';
import { DatabaseModule } from './database/database.module';
import { AuthModule } from './modules/auth/auth.module';
import { PatientModule } from './modules/patient/patient.module';
import { CaregiverModule } from './modules/caregiver/caregiver.module';
import { AdminModule } from './modules/admin/admin.module';
import { SyncModule } from './modules/sync/sync.module';
import { MlModule } from './modules/ml/ml.module';

import { AppController } from './app.controller';

@Module({
  controllers: [AppController],
  imports: [
    // Global Rate Limiting: 100 requests per 60 seconds by default
    ThrottlerModule.forRoot([
      {
        name: 'default',
        ttl: 60000,
        limit: 100,
      },
    ]),
    DatabaseModule,
    AuthModule,
    PatientModule,
    CaregiverModule,
    AdminModule,
    SyncModule,
    MlModule,
  ],
  providers: [
    {
      provide: APP_GUARD,
      useClass: ThrottlerGuard,
    },
  ],
})
export class AppModule {}
