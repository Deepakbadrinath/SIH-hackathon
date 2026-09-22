import { Injectable } from '@nestjs/common';
import { InMemoryDbService } from '../../database/in-memory-db.service';

@Injectable()
export class AdminService {
  constructor(private readonly dbService: InMemoryDbService) {}

  async getAllUsers() {
    return this.dbService.getAllUsers();
  }
}
