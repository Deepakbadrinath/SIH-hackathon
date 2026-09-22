enum SyncOperationType { insert, update, delete }

extension SyncOperationTypeExtension on SyncOperationType {
  String toDbString() {
    switch (this) {
      case SyncOperationType.insert:
        return 'INSERT';
      case SyncOperationType.update:
        return 'UPDATE';
      case SyncOperationType.delete:
        return 'DELETE';
    }
  }

  static SyncOperationType fromDbString(String str) {
    switch (str.toUpperCase()) {
      case 'UPDATE':
        return SyncOperationType.update;
      case 'DELETE':
        return SyncOperationType.delete;
      case 'INSERT':
      default:
        return SyncOperationType.insert;
    }
  }
}

enum SyncStatus { pending, inProgress, failed, completed }

extension SyncStatusExtension on SyncStatus {
  String toDbString() {
    switch (this) {
      case SyncStatus.pending:
        return 'PENDING';
      case SyncStatus.inProgress:
        return 'IN_PROGRESS';
      case SyncStatus.failed:
        return 'FAILED';
      case SyncStatus.completed:
        return 'COMPLETED';
    }
  }

  static SyncStatus fromDbString(String str) {
    switch (str.toUpperCase()) {
      case 'IN_PROGRESS':
        return SyncStatus.inProgress;
      case 'FAILED':
        return SyncStatus.failed;
      case 'COMPLETED':
        return SyncStatus.completed;
      case 'PENDING':
      default:
        return SyncStatus.pending;
    }
  }
}

class SyncItem {
  final String operationId; // UUIDv4 Idempotency key
  final String entityId;
  final String entityType; // e.g., 'GAME_SESSION', 'MEDICATION_LOG'
  final SyncOperationType operationType;
  final String payloadJson;
  final DateTime timestamp;
  final int retryCount;
  final SyncStatus syncStatus;
  final String? lastError;

  const SyncItem({
    required this.operationId,
    required this.entityId,
    required this.entityType,
    required this.operationType,
    required this.payloadJson,
    required this.timestamp,
    this.retryCount = 0,
    this.syncStatus = SyncStatus.pending,
    this.lastError,
  });

  Map<String, dynamic> toMap() {
    return {
      'operation_id': operationId,
      'entity_id': entityId,
      'entity_type': entityType,
      'operation_type': operationType.toDbString(),
      'payload_json': payloadJson,
      'timestamp': timestamp.toIso8601String(),
      'retry_count': retryCount,
      'sync_status': syncStatus.toDbString(),
      'last_error': lastError,
    };
  }

  factory SyncItem.fromMap(Map<String, dynamic> map) {
    return SyncItem(
      operationId: map['operation_id'] as String,
      entityId: map['entity_id'] as String,
      entityType: map['entity_type'] as String,
      operationType: SyncOperationTypeExtension.fromDbString(map['operation_type'] as String),
      payloadJson: map['payload_json'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      retryCount: (map['retry_count'] as int?) ?? 0,
      syncStatus: SyncStatusExtension.fromDbString(map['sync_status'] as String),
      lastError: map['last_error'] as String?,
    );
  }

  SyncItem copyWith({
    String? operationId,
    String? entityId,
    String? entityType,
    SyncOperationType? operationType,
    String? payloadJson,
    DateTime? timestamp,
    int? retryCount,
    SyncStatus? syncStatus,
    String? lastError,
  }) {
    return SyncItem(
      operationId: operationId ?? this.operationId,
      entityId: entityId ?? this.entityId,
      entityType: entityType ?? this.entityType,
      operationType: operationType ?? this.operationType,
      payloadJson: payloadJson ?? this.payloadJson,
      timestamp: timestamp ?? this.timestamp,
      retryCount: retryCount ?? this.retryCount,
      syncStatus: syncStatus ?? this.syncStatus,
      lastError: lastError ?? this.lastError,
    );
  }
}

class AuditLog {
  final String id;
  final String actorId;
  final String actorRole;
  final String action;
  final String resourceType;
  final String resourceId;
  final String? detailsJson;
  final DateTime timestamp;
  final bool isSynced;

  const AuditLog({
    required this.id,
    required this.actorId,
    required this.actorRole,
    required this.action,
    required this.resourceType,
    required this.resourceId,
    this.detailsJson,
    required this.timestamp,
    this.isSynced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'actor_id': actorId,
      'actor_role': actorRole,
      'action': action,
      'resource_type': resourceType,
      'resource_id': resourceId,
      'details_json': detailsJson,
      'timestamp': timestamp.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
    };
  }

  factory AuditLog.fromMap(Map<String, dynamic> map) {
    return AuditLog(
      id: map['id'] as String,
      actorId: map['actor_id'] as String,
      actorRole: map['actor_role'] as String,
      action: map['action'] as String,
      resourceType: map['resource_type'] as String,
      resourceId: map['resource_id'] as String,
      detailsJson: map['details_json'] as String?,
      timestamp: DateTime.parse(map['timestamp'] as String),
      isSynced: (map['is_synced'] as int?) == 1,
    );
  }
}

class AppSetting {
  final String key;
  final String value;
  final DateTime updatedAt;

  const AppSetting({
    required this.key,
    required this.value,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'setting_key': key,
      'setting_value': value,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory AppSetting.fromMap(Map<String, dynamic> map) {
    return AppSetting(
      key: map['setting_key'] as String,
      value: map['setting_value'] as String,
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}
