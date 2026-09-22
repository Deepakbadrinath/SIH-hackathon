import { Injectable, OnModuleInit } from '@nestjs/common';
import { UserRole } from '../common/enums/user-role.enum';
import { PasswordHasherService } from '../common/services/password-hasher.service';

export interface UserEntity {
  id: string;
  email: string;
  passwordHash: string;
  role: UserRole;
  fullName: string;
  isActive: boolean;
  createdAt: string;
}

export interface CaregiverPatientRelationshipEntity {
  id: string;
  caregiverId: string;
  patientId: string;
  relationshipType: string;
  isActive: boolean;
  createdAt: string;
}

export interface RefreshTokenEntity {
  id: string;
  userId: string;
  tokenHash: string;
  expiresAt: string;
  isRevoked: boolean;
  createdAt: string;
}

export interface PasswordResetEntity {
  id: string;
  userId: string;
  tokenHash: string;
  expiresAt: string;
  isUsed: boolean;
  createdAt: string;
}

export interface PatientDashboardRecord {
  patientId: string;
  fullName: string;
  age: number;
  location: string;
  performanceSummary: {
    averageAccuracy: number;
    averageResponseTimeSeconds: number;
    totalGamesCompleted: number;
    currentDifficultyLevel: number;
  };
  medications: Array<{
    id: string;
    medicineName: string;
    dosage: string;
    scheduleTime: string;
    status: 'taken' | 'skipped' | 'missed' | 'pending';
  }>;
}

@Injectable()
export class InMemoryDbService implements OnModuleInit {
  private users: Map<string, UserEntity> = new Map();
  private relationships: Map<string, CaregiverPatientRelationshipEntity> = new Map();
  private refreshTokens: Map<string, RefreshTokenEntity> = new Map();
  private passwordResets: Map<string, PasswordResetEntity> = new Map();
  private patientRecords: Map<string, PatientDashboardRecord> = new Map();

  constructor(private readonly passwordHasher: PasswordHasherService) {}

  async onModuleInit() {
    await this.seedInitialData();
  }

  // ---- Users ----
  async findUserByEmail(email: string): Promise<UserEntity | null> {
    const normalized = email.trim().toLowerCase();
    for (const user of this.users.values()) {
      if (user.email.toLowerCase() === normalized) {
        return user;
      }
    }
    return null;
  }

  async findUserById(id: string): Promise<UserEntity | null> {
    return this.users.get(id) || null;
  }

  async createUser(user: UserEntity): Promise<UserEntity> {
    this.users.set(user.id, user);
    return user;
  }

  async updateUserPassword(userId: string, newPasswordHash: string): Promise<boolean> {
    const user = this.users.get(userId);
    if (!user) return false;
    user.passwordHash = newPasswordHash;
    this.users.set(userId, user);
    return true;
  }

  async getAllUsers(): Promise<Omit<UserEntity, 'passwordHash'>[]> {
    return Array.from(this.users.values()).map(({ passwordHash, ...safeUser }) => safeUser);
  }

  // ---- Relationships ----
  async findActiveRelationship(caregiverId: string, patientId: string): Promise<CaregiverPatientRelationshipEntity | null> {
    for (const rel of this.relationships.values()) {
      if (rel.caregiverId === caregiverId && rel.patientId === patientId && rel.isActive) {
        return rel;
      }
    }
    return null;
  }

  async getCaregiverPatients(caregiverId: string): Promise<CaregiverPatientRelationshipEntity[]> {
    return Array.from(this.relationships.values()).filter(
      (rel) => rel.caregiverId === caregiverId && rel.isActive,
    );
  }

  async createRelationship(rel: CaregiverPatientRelationshipEntity): Promise<void> {
    this.relationships.set(rel.id, rel);
  }

  // ---- Refresh Tokens ----
  async saveRefreshToken(token: RefreshTokenEntity): Promise<void> {
    this.refreshTokens.set(token.id, token);
  }

  async findRefreshToken(tokenHash: string): Promise<RefreshTokenEntity | null> {
    for (const token of this.refreshTokens.values()) {
      if (token.tokenHash === tokenHash) {
        return token;
      }
    }
    return null;
  }

  async revokeRefreshToken(tokenHash: string): Promise<boolean> {
    const token = await this.findRefreshToken(tokenHash);
    if (token) {
      token.isRevoked = true;
      this.refreshTokens.set(token.id, token);
      return true;
    }
    return false;
  }

  async revokeAllUserTokens(userId: string): Promise<void> {
    for (const token of this.refreshTokens.values()) {
      if (token.userId === userId) {
        token.isRevoked = true;
        this.refreshTokens.set(token.id, token);
      }
    }
  }

  // ---- Password Reset Requests ----
  async savePasswordReset(reset: PasswordResetEntity): Promise<void> {
    this.passwordResets.set(reset.id, reset);
  }

  async findPasswordReset(tokenHash: string): Promise<PasswordResetEntity | null> {
    for (const reset of this.passwordResets.values()) {
      if (reset.tokenHash === tokenHash) {
        return reset;
      }
    }
    return null;
  }

  async markPasswordResetUsed(id: string): Promise<void> {
    const reset = this.passwordResets.get(id);
    if (reset) {
      reset.isUsed = true;
      this.passwordResets.set(id, reset);
    }
  }

  // ---- Patient Records ----
  async getPatientRecord(patientId: string): Promise<PatientDashboardRecord | null> {
    return this.patientRecords.get(patientId) || null;
  }

  async savePatientRecord(record: PatientDashboardRecord): Promise<void> {
    this.patientRecords.set(record.patientId, record);
  }

  // ---- Seeding ----
  async seedInitialData() {
    this.users.clear();
    this.relationships.clear();
    this.refreshTokens.clear();
    this.passwordResets.clear();
    this.patientRecords.clear();

    const adminHash = await this.passwordHasher.hashPassword('Admin@12345!');
    const caregiverHash = await this.passwordHasher.hashPassword('Caregiver@12345!');
    const patientHash = await this.passwordHasher.hashPassword('Patient@12345!');

    // Seed Admin
    this.users.set('user_admin', {
      id: 'user_admin',
      email: 'admin@smritisetu.org',
      passwordHash: adminHash,
      role: UserRole.ADMIN,
      fullName: 'System Administrator',
      isActive: true,
      createdAt: new Date().toISOString(),
    });

    // Seed Caregiver 1 (authorized for patient_1 and patient_2)
    this.users.set('caregiver_1', {
      id: 'caregiver_1',
      email: 'caregiver1@smritisetu.org',
      passwordHash: caregiverHash,
      role: UserRole.CAREGIVER,
      fullName: 'Anita Sharma',
      isActive: true,
      createdAt: new Date().toISOString(),
    });

    // Seed Caregiver 2 (unauthorized, no assigned patients)
    this.users.set('caregiver_2', {
      id: 'caregiver_2',
      email: 'caregiver2@smritisetu.org',
      passwordHash: caregiverHash,
      role: UserRole.CAREGIVER,
      fullName: 'Ranjit Roy',
      isActive: true,
      createdAt: new Date().toISOString(),
    });

    // Seed Patient 1
    this.users.set('patient_1', {
      id: 'patient_1',
      email: 'patient1@smritisetu.org',
      passwordHash: patientHash,
      role: UserRole.PATIENT,
      fullName: 'Deka Da',
      isActive: true,
      createdAt: new Date().toISOString(),
    });

    // Seed Patient 2
    this.users.set('patient_2', {
      id: 'patient_2',
      email: 'patient2@smritisetu.org',
      passwordHash: patientHash,
      role: UserRole.PATIENT,
      fullName: 'Baruah Baideo',
      isActive: true,
      createdAt: new Date().toISOString(),
    });

    // Seed Secret Patient
    this.users.set('patient_secret', {
      id: 'patient_secret',
      email: 'secret_patient@smritisetu.org',
      passwordHash: patientHash,
      role: UserRole.PATIENT,
      fullName: 'Secret Patient VIP',
      isActive: true,
      createdAt: new Date().toISOString(),
    });

    // Relationships:
    // Caregiver 1 is connected to Patient 1 and Patient 2
    this.relationships.set('rel_1', {
      id: 'rel_1',
      caregiverId: 'caregiver_1',
      patientId: 'patient_1',
      relationshipType: 'Primary Caregiver',
      isActive: true,
      createdAt: new Date().toISOString(),
    });
    this.relationships.set('rel_2', {
      id: 'rel_2',
      caregiverId: 'caregiver_1',
      patientId: 'patient_2',
      relationshipType: 'Family Guardian',
      isActive: true,
      createdAt: new Date().toISOString(),
    });

    // Seed Patient Records
    this.patientRecords.set('patient_1', {
      patientId: 'patient_1',
      fullName: 'Deka Da',
      age: 74,
      location: 'Guwahati, Assam',
      performanceSummary: {
        averageAccuracy: 88.5,
        averageResponseTimeSeconds: 2.1,
        totalGamesCompleted: 14,
        currentDifficultyLevel: 2,
      },
      medications: [
        {
          id: 'med_1',
          medicineName: 'Donepezil',
          dosage: '5mg - after dinner',
          scheduleTime: '20:30',
          status: 'taken',
        },
        {
          id: 'med_2',
          medicineName: 'Multivitamin B-Complex',
          dosage: '1 tablet - morning',
          scheduleTime: '08:30',
          status: 'taken',
        },
      ],
    });

    this.patientRecords.set('patient_2', {
      patientId: 'patient_2',
      fullName: 'Baruah Baideo',
      age: 69,
      location: 'Jorhat, Assam',
      performanceSummary: {
        averageAccuracy: 92.0,
        averageResponseTimeSeconds: 1.8,
        totalGamesCompleted: 18,
        currentDifficultyLevel: 3,
      },
      medications: [
        {
          id: 'med_3',
          medicineName: 'Memantine',
          dosage: '10mg - morning',
          scheduleTime: '09:00',
          status: 'taken',
        },
      ],
    });

    this.patientRecords.set('patient_secret', {
      patientId: 'patient_secret',
      fullName: 'Secret Patient VIP',
      age: 80,
      location: 'Confidential Ward',
      performanceSummary: {
        averageAccuracy: 75.0,
        averageResponseTimeSeconds: 3.5,
        totalGamesCompleted: 5,
        currentDifficultyLevel: 1,
      },
      medications: [],
    });
  }
}
