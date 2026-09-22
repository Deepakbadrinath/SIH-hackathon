import { Global, Module } from '@nestjs/common';
import { InMemoryDbService } from './in-memory-db.service';
import { PasswordHasherService } from '../common/services/password-hasher.service';

@Global()
@Module({
  providers: [PasswordHasherService, InMemoryDbService],
  exports: [PasswordHasherService, InMemoryDbService],
})
export class DatabaseModule {}
