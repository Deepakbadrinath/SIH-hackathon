import { Injectable, NotFoundException } from '@nestjs/common';
import { InMemoryDbService } from '../../database/in-memory-db.service';

@Injectable()
export class PatientService {
  constructor(private readonly dbService: InMemoryDbService) {}

  async getPatientDashboard(patientId: string) {
    const record = await this.dbService.getPatientRecord(patientId);
    if (!record) {
      throw new NotFoundException(`Patient record with id '${patientId}' was not found`);
    }

    return {
      patientId: record.patientId,
      fullName: record.fullName,
      age: record.age,
      location: record.location,
      // Strictly non-clinical terminology
      performanceSummary: record.performanceSummary,
      medications: record.medications,
    };
  }

  async getPatientMedications(patientId: string) {
    const record = await this.dbService.getPatientRecord(patientId);
    if (!record) {
      throw new NotFoundException(`Patient record with id '${patientId}' was not found`);
    }

    return {
      patientId: record.patientId,
      medications: record.medications,
    };
  }
}
