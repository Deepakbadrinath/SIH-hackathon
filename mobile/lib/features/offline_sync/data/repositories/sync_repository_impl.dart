import '../../../../data/datasources/local/sync_queue_local_data_source.dart';
import '../../../../domain/models/system_models.dart';
import '../../../../domain/repositories/sync_repository.dart';

class SyncRepositoryImpl implements SyncRepository {
  final SyncQueueLocalDataSource _localDataSource;

  SyncRepositoryImpl({required SyncQueueLocalDataSource localDataSource})
      : _localDataSource = localDataSource;

  @override
  Future<void> enqueueOperation(SyncItem item) async {
    await _localDataSource.enqueue(item);
  }

  @override
  Future<List<SyncItem>> getPendingOperations({int limit = 25}) async {
    return await _localDataSource.getPending(limit: limit);
  }

  @override
  Future<void> updateOperationStatus({
    required String operationId,
    required SyncStatus status,
    String? lastError,
    bool incrementRetry = false,
  }) async {
    await _localDataSource.updateStatus(
      operationId: operationId,
      status: status,
      lastError: lastError,
      incrementRetry: incrementRetry,
    );
  }

  @override
  Future<void> markOperationCompleted(String operationId, String entityId, String entityType) async {
    await _localDataSource.markCompleted(operationId, entityId, entityType);
  }

  @override
  Future<int> getPendingOperationsCount() async {
    return await _localDataSource.getPendingCount();
  }

  @override
  Future<void> clearCompletedOperations() async {
    await _localDataSource.deleteCompleted();
  }

  @override
  Future<int> resetInProgressOperations() async {
    return await _localDataSource.resetInProgressOperations();
  }

  @override
  Future<void> markPermanentlyFailed(String operationId, String reason) async {
    await _localDataSource.markPermanentlyFailed(operationId, reason);
  }
}
