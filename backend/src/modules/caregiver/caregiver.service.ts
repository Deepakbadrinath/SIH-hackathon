import { Injectable } from '@nestjs/common';
import { InMemoryDbService } from '../../database/in-memory-db.service';

@Injectable()
export class CaregiverService {
  constructor(private readonly dbService: InMemoryDbService) {}

  async getConnectedPatients(caregiverId: string) {
    const relationships = await this.dbService.getCaregiverPatients(caregiverId);

    const patients = await Promise.all(
      relationships.map(async (rel) => {
        const patientUser = await this.dbService.findUserById(rel.patientId);
        const record = await this.dbService.getPatientRecord(rel.patientId);

        return {
          relationshipId: rel.id,
          patientId: rel.patientId,
          fullName: patientUser?.fullName || record?.fullName || 'Unknown',
          relationshipType: rel.relationshipType,
          isActive: rel.isActive,
          performanceSummary: record?.performanceSummary || null,
        };
      }),
    );

    return {
      caregiverId,
      totalConnected: patients.length,
      patients,
    };
  }
}
