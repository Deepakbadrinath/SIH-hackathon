import { Injectable, Logger } from '@nestjs/common';
import { InMemoryDbService } from '../../database/in-memory-db.service';
import { UserRole } from '../../common/enums/user-role.enum';
import { AuthenticatedUser } from '../../common/guards/jwt-auth.guard';
import {
  BatchSyncRequestDto,
  BatchSyncResponseDto,
  OperationResult,
} from './sync.dto';

@Injectable()
export class SyncService {
  private readonly logger = new Logger(SyncService.name);

  // In-memory processed operations cache for idempotency check (backed by DB in prod)
  private readonly processedOperations = new Set<string>();

  constructor(private readonly dbService: InMemoryDbService) {}

  async processBatchSync(
    dto: BatchSyncRequestDto,
    user?: AuthenticatedUser,
  ): Promise<BatchSyncResponseDto> {
    const results: OperationResult[] = [];
    const now = new Date().toISOString();

    for (const op of dto.operations) {
      // 1. Check idempotency: If operationId was already executed, return CONFLICT_IGNORED without duplicate write
      if (this.processedOperations.has(op.operationId)) {
        this.logger.log(`Idempotent duplicate ignored for operationId: ${op.operationId}`);
        results.push({
          operationId: op.operationId,
          status: 'CONFLICT_IGNORED',
          serverSyncTimestamp: now,
          message: 'Operation was already processed previously.',
        });
        continue;
      }

      // 2. Server-Side Ownership & Relationship Enforcement
      if (user) {
        const targetPatientId =
          op.payload?.patientId ||
          op.payload?.patient_id ||
          (user.role === UserRole.PATIENT ? user.userId : null);

        if (user.role === UserRole.PATIENT && targetPatientId && targetPatientId !== user.userId) {
          this.logger.warn(
            `Security Violation: Patient ${user.userId} attempted to sync data for Patient ${targetPatientId}`,
          );
          results.push({
            operationId: op.operationId,
            status: 'ERROR',
            serverSyncTimestamp: now,
            message: 'Unauthorized: Patient cannot synchronize data for another patient.',
          });
          continue;
        }

        if (user.role === UserRole.CAREGIVER && targetPatientId) {
          const hasRel = await this.dbService.findActiveRelationship(user.userId, targetPatientId);
          if (!hasRel) {
            this.logger.warn(
              `Security Violation: Caregiver ${user.userId} attempted unlinked sync for Patient ${targetPatientId}`,
            );
            results.push({
              operationId: op.operationId,
              status: 'ERROR',
              serverSyncTimestamp: now,
              message: 'Unauthorized: Caregiver does not have an active relationship with this patient.',
            });
            continue;
          }
        }
      }

      try {
        // 3. Dispatch to entity-specific handlers
        switch (op.entityType) {
          case 'GAME_SESSION':
          case 'GAME_RESULT':
          case 'PERFORMANCE_METRICS':
          case 'MEDICATION_LOG':
            this.logger.log(
              `Processing ${op.operationType} for ${op.entityType} [ID: ${op.entityId}]`,
            );
            // Append-only write simulation
            this.processedOperations.add(op.operationId);
            results.push({
              operationId: op.operationId,
              status: 'SUCCESS',
              serverSyncTimestamp: now,
            });
            break;

          default:
            this.logger.warn(`Unknown entity type: ${op.entityType}`);
            results.push({
              operationId: op.operationId,
              status: 'ERROR',
              serverSyncTimestamp: now,
              message: `Unsupported entity type: ${op.entityType}`,
            });
        }
      } catch (err: any) {
        this.logger.error(`Error processing operation ${op.operationId}: ${err.message}`);
        results.push({
          operationId: op.operationId,
          status: 'ERROR',
          serverSyncTimestamp: now,
          message: 'An internal error occurred while processing this operation.',
        });
      }
    }

    return {
      batchId: dto.batchId,
      processedAt: now,
      results,
    };
  }
}
