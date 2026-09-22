import '../models/system_models.dart';

abstract class SyncRepository {
  Future<void> enqueueOperation(SyncItem item);
  Future<List<SyncItem>> getPendingOperations({int limit = 25});
  Future<void> updateOperationStatus({
    required String operationId,
    required SyncStatus status,
    String? lastError,
    bool incrementRetry = false,
  });
  Future<void> markOperationCompleted(String operationId, String entityId, String entityType);
  Future<int> getPendingOperationsCount();
  Future<void> clearCompletedOperations();
  Future<int> resetInProgressOperations();
  Future<void> markPermanentlyFailed(String operationId, String reason);
}

abstract class AuditRepository {
  Future<void> recordEvent({
    required String actorId,
    required String actorRole,
    required String action,
    required String resourceType,
    required String resourceId,
    String? detailsJson,
  });
  Future<List<AuditLog>> getRecentLogs({int limit = 50});
}
