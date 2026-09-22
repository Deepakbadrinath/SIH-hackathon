import {
  IsArray,
  IsEnum,
  IsNotEmpty,
  IsObject,
  IsString,
  ValidateNested,
} from 'class-validator';
import { Type } from 'class-transformer';

export enum SyncOperationType {
  INSERT = 'INSERT',
  UPDATE = 'UPDATE',
  DELETE = 'DELETE',
}

export class SyncOperationDto {
  @IsString()
  @IsNotEmpty()
  operationId: string; // UUIDv4 idempotency key

  @IsString()
  @IsNotEmpty()
  entityId: string;

  @IsString()
  @IsNotEmpty()
  entityType: string; // 'GAME_SESSION', 'GAME_RESULT', 'MEDICATION_LOG', etc.

  @IsEnum(SyncOperationType, { message: 'Invalid sync operation type' })
  operationType: SyncOperationType;

  @IsObject()
  payload: Record<string, any>;

  @IsString()
  @IsNotEmpty()
  timestamp: string;
}

export class BatchSyncRequestDto {
  @IsString()
  @IsNotEmpty()
  batchId: string;

  @IsString()
  @IsNotEmpty()
  clientTimestamp: string;

  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => SyncOperationDto)
  operations: SyncOperationDto[];
}

export interface OperationResult {
  operationId: string;
  status: 'SUCCESS' | 'CONFLICT_IGNORED' | 'ERROR';
  serverSyncTimestamp: string;
  message?: string;
}

export class BatchSyncResponseDto {
  batchId: string;
  processedAt: string;
  results: OperationResult[];
}
