import 'dart:async';
import 'package:flutter_test/flutter_test.dart';

import 'package:smriti_setu/core/network/network_info.dart';
import 'package:smriti_setu/core/security/secure_storage_service.dart';
import 'package:smriti_setu/domain/models/system_models.dart';
import 'package:smriti_setu/domain/repositories/sync_repository.dart';
import 'package:smriti_setu/domain/services/sync_manager.dart';
import 'package:smriti_setu/features/offline_sync/data/services/sync_manager_impl.dart';

/// In-memory mock of SyncRepository for robust isolated unit testing.
class MockSyncRepository implements SyncRepository {
  final List<SyncItem> items = [];
  final Map<String, bool> localEntitySyncedMap = {};

  @override
  Future<void> enqueueOperation(SyncItem item) async {
    final idx = items.indexWhere((i) => i.operationId == item.operationId);
    if (idx >= 0) {
      items[idx] = item;
    } else {
      items.add(item);
    }
  }

  @override
  Future<List<SyncItem>> getPendingOperations({int limit = 25}) async {
    return items
        .where((i) => i.syncStatus == SyncStatus.pending || i.syncStatus == SyncStatus.failed)
        .take(limit)
        .toList();
  }

  @override
  Future<void> updateOperationStatus({
    required String operationId,
    required SyncStatus status,
    String? lastError,
    bool incrementRetry = false,
  }) async {
    final idx = items.indexWhere((i) => i.operationId == operationId);
    if (idx >= 0) {
      final old = items[idx];
      items[idx] = old.copyWith(
        syncStatus: status,
        lastError: lastError,
        retryCount: incrementRetry ? old.retryCount + 1 : old.retryCount,
      );
    }
  }

  @override
  Future<void> markOperationCompleted(String operationId, String entityId, String entityType) async {
    final idx = items.indexWhere((i) => i.operationId == operationId);
    if (idx >= 0) {
      items[idx] = items[idx].copyWith(syncStatus: SyncStatus.completed);
    }
    localEntitySyncedMap[entityId] = true;
  }

  @override
  Future<int> getPendingOperationsCount() async {
    return items.where((i) => i.syncStatus != SyncStatus.completed).length;
  }

  @override
  Future<void> clearCompletedOperations() async {
    items.removeWhere((i) => i.syncStatus == SyncStatus.completed);
  }

  @override
  Future<int> resetInProgressOperations() async {
    int count = 0;
    for (int i = 0; i < items.length; i++) {
      if (items[i].syncStatus == SyncStatus.inProgress) {
        items[i] = items[i].copyWith(
          syncStatus: SyncStatus.pending,
          lastError: 'Recovered from unexpected process termination (app restart/crash)',
        );
        count++;
      }
    }
    return count;
  }

  @override
  Future<void> markPermanentlyFailed(String operationId, String reason) async {
    final idx = items.indexWhere((i) => i.operationId == operationId);
    if (idx >= 0) {
      items[idx] = items[idx].copyWith(
        syncStatus: SyncStatus.failed,
        lastError: reason,
      );
    }
  }
}

/// Controllable mock of INetworkInfo with stream updates.
class MockNetworkInfo implements INetworkInfo {
  bool _connected = true;
  final StreamController<bool> _controller = StreamController<bool>.broadcast();

  @override
  Future<bool> get isConnected async => _connected;

  Stream<bool> get onConnectivityChanged => _controller.stream;

  void setConnected(bool value) {
    _connected = value;
    _controller.add(value);
  }

  void dispose() {
    _controller.close();
  }
}

/// Mock HTTP client for inspecting and simulating network responses.
class MockHttpClientWrapper extends HttpClientWrapper {
  int requestCount = 0;
  Map<String, dynamic>? nextResponse;
  Exception? throwError;
  List<Map<String, dynamic>> recordedRequests = [];

  MockHttpClientWrapper() : super(tokenVault: _MockTokenVault());

  @override
  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    requestCount++;
    recordedRequests.add(body);

    if (throwError != null) {
      throw throwError!;
    }

    if (nextResponse != null) {
      return nextResponse!;
    }

    // Default success response for all operations in batch
    final ops = body['operations'] as List? ?? [];
    return {
      'batchId': body['batchId'],
      'processedAt': DateTime.now().toIso8601String(),
      'results': ops.map((o) => {
        'operationId': o['operationId'],
        'status': 'SUCCESS',
        'serverSyncTimestamp': DateTime.now().toIso8601String(),
      }).toList(),
    };
  }
}

class _MockTokenVault implements TokenVault {
  @override
  Future<String?> getAccessToken() async => 'mock_jwt_token_sih';
  @override
  Future<String?> getRefreshToken() async => 'mock_refresh_token';
  @override
  Future<String?> getUserId() async => 'user_test_1';
  @override
  Future<String?> getUserRole() async => 'PATIENT';
  @override
  Future<void> saveAuthTokens({
    required String accessToken,
    required String refreshToken,
    required String userId,
    required String userRole,
  }) async {}
  @override
  Future<void> clearAuth() async {}
}

void main() {
  late MockSyncRepository repository;
  late MockNetworkInfo networkInfo;
  late MockHttpClientWrapper httpClient;
  late SyncManagerImpl syncManager;

  setUp(() {
    repository = MockSyncRepository();
    networkInfo = MockNetworkInfo();
    httpClient = MockHttpClientWrapper();

    syncManager = SyncManagerImpl(
      repository: repository,
      networkInfo: networkInfo,
      httpClient: httpClient,
      policy: const SyncPolicy(
        maxRetries: 5,
        initialBackoffSeconds: 2,
        maxBackoffSeconds: 300,
        batchSize: 25,
      ),
      connectivityStream: networkInfo.onConnectivityChanged,
    );
  });

  tearDown(() {
    syncManager.dispose();
    networkInfo.dispose();
  });

  group('Phase 15: Robust Offline Sync Tests', () {
    test('1. Offline Mode: local write queues operation, remains pending without network call', () async {
      networkInfo.setConnected(false);
      await syncManager.initialize();

      // Perform local write for a game session
      final item = await syncManager.enqueueOperation(
        entityId: 'session_game_101',
        entityType: 'GAME_SESSION',
        operationType: SyncOperationType.insert,
        payload: {
          'gameType': 'PATTERN_COMPLETION',
          'score': 95,
          'accuracyPercentage': 92.5,
        },
      );

      expect(item.operationId, startsWith('op_'));
      expect(repository.items.length, equals(1));
      expect(repository.items.first.syncStatus, equals(SyncStatus.pending));
      expect(repository.items.first.retryCount, equals(0));
      expect(repository.localEntitySyncedMap['session_game_101'], isNull);

      // Attempt explicit sync while offline
      final result = await syncManager.synchronizePendingBatch();
      expect(result.totalProcessed, equals(0));
      expect(httpClient.requestCount, equals(0), reason: 'Must NOT attempt network call while offline');
      expect(syncManager.currentState, equals(SyncManagerState.offline));
    });

    test('2. Online Mode: pending operations are uploaded and marked completed with local is_synced=1', () async {
      networkInfo.setConnected(true);
      await syncManager.initialize();

      await syncManager.enqueueOperation(
        entityId: 'session_game_102',
        entityType: 'GAME_SESSION',
        operationType: SyncOperationType.insert,
        payload: {'gameType': 'ACTIVITY_SEQUENCE', 'score': 100},
      );

      final result = await syncManager.synchronizePendingBatch();

      expect(result.totalProcessed, equals(1));
      expect(result.succeededCount, equals(1));
      expect(result.failedCount, equals(0));
      expect(httpClient.requestCount, greaterThanOrEqualTo(1));

      // Verify local status updated
      expect(repository.items.first.syncStatus, equals(SyncStatus.completed));
      expect(repository.localEntitySyncedMap['session_game_102'], isTrue);
    });

    test('3. Network Failure: network drop mid-sync sets status to failed and increments retry count', () async {
      networkInfo.setConnected(true);
      await syncManager.initialize();

      await syncManager.enqueueOperation(
        entityId: 'med_log_201',
        entityType: 'MEDICATION_LOG',
        operationType: SyncOperationType.insert,
        payload: {'status': 'TAKEN', 'dosage': '5mg'},
      );

      // Simulate network socket drop / timeout
      httpClient.throwError = Exception('Connection refused / network unreachable');

      final result = await syncManager.synchronizePendingBatch(force: true);

      expect(result.failedCount, equals(1));
      expect(result.succeededCount, equals(0));
      expect(syncManager.currentState, equals(SyncManagerState.error));

      // Verify item updated with failure and incremented retry count
      final item = repository.items.first;
      expect(item.syncStatus, equals(SyncStatus.failed));
      expect(item.retryCount, equals(1));
      expect(item.lastError, contains('Connection refused'));
      expect(repository.localEntitySyncedMap['med_log_201'], isNull);
    });

    test('4. Exponential Retry & Maximum Retry Policy: backoff delays and ceases retrying at maxRetries', () async {
      networkInfo.setConnected(true);
      await syncManager.initialize();

      // Enqueue item with timestamp in the future to simulate active backoff
      final now = DateTime.now();
      final item = SyncItem(
        operationId: 'op_backoff_test',
        entityId: 'session_backoff_1',
        entityType: 'GAME_SESSION',
        operationType: SyncOperationType.insert,
        payloadJson: '{"test": 1}',
        timestamp: now,
        retryCount: 2, // 2 retries -> 2 * 2^2 = 8 seconds delay
        syncStatus: SyncStatus.failed,
      );
      await repository.enqueueOperation(item);

      // Verify exponential backoff calculation
      const policy = SyncPolicy(initialBackoffSeconds: 2, maxBackoffSeconds: 300);
      expect(policy.calculateBackoff(1), equals(const Duration(seconds: 4)));
      expect(policy.calculateBackoff(2), equals(const Duration(seconds: 8)));
      expect(policy.calculateBackoff(3), equals(const Duration(seconds: 16)));
      expect(policy.calculateBackoff(4), equals(const Duration(seconds: 32)));
      expect(policy.calculateBackoff(5), equals(const Duration(seconds: 64)));

      // Call synchronize without force: item is within backoff window, so it is skipped
      httpClient.requestCount = 0;
      final skippedResult = await syncManager.synchronizePendingBatch(force: false);
      expect(skippedResult.totalProcessed, equals(0));
      expect(httpClient.requestCount, equals(0), reason: 'Must skip items still within exponential backoff window');

      // Now simulate item that has reached maxRetries (5 retries)
      final exhaustedItem = item.copyWith(
        operationId: 'op_exhausted',
        retryCount: 5,
        timestamp: now.subtract(const Duration(hours: 1)),
      );
      await repository.enqueueOperation(exhaustedItem);

      final maxResult = await syncManager.synchronizePendingBatch(force: true);
      expect(maxResult.permanentlyFailedCount, equals(1));

      // Ensure item is marked permanently failed and excluded from upload batch
      final updatedExhausted = repository.items.firstWhere((i) => i.operationId == 'op_exhausted');
      expect(updatedExhausted.lastError, contains('Exceeded maximum retry limit'));
    });

    test('5. Duplicate Operation / Idempotency: duplicate request returns CONFLICT_IGNORED without duplicate session', () async {
      networkInfo.setConnected(true);
      await syncManager.initialize();

      const fixedOpId = 'op_idempotent_session_999';
      await syncManager.enqueueOperation(
        operationId: fixedOpId,
        entityId: 'game_session_fixed_999',
        entityType: 'GAME_SESSION',
        operationType: SyncOperationType.insert,
        payload: {'game': 'PatternRecall', 'trials': 10},
      );

      // Server simulates idempotent duplicate response (CONFLICT_IGNORED)
      httpClient.nextResponse = {
        'batchId': 'batch_123',
        'processedAt': DateTime.now().toIso8601String(),
        'results': [
          {
            'operationId': fixedOpId,
            'status': 'CONFLICT_IGNORED',
            'serverSyncTimestamp': DateTime.now().toIso8601String(),
            'message': 'Operation was already processed previously.',
          }
        ],
      };

      final result = await syncManager.synchronizePendingBatch(force: true);

      expect(result.conflictIgnoredCount, equals(1));
      expect(result.failedCount, equals(0));
      expect(result.totalCompleted, equals(1));

      // Verify operation marked completed locally
      final op = repository.items.firstWhere((i) => i.operationId == fixedOpId);
      expect(op.syncStatus, equals(SyncStatus.completed));
      expect(repository.localEntitySyncedMap['game_session_fixed_999'], isTrue);
    });

    test('6. App Killed / Device Restart: stranded IN_PROGRESS operations reset to PENDING on boot', () async {
      // Simulate app was killed mid-upload: operation stuck in IN_PROGRESS
      final strandedItem1 = SyncItem(
        operationId: 'op_stranded_1',
        entityId: 'session_stranded_1',
        entityType: 'GAME_SESSION',
        operationType: SyncOperationType.insert,
        payloadJson: '{"game": "FaceMatch"}',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        syncStatus: SyncStatus.inProgress,
      );
      final strandedItem2 = SyncItem(
        operationId: 'op_stranded_2',
        entityId: 'med_stranded_2',
        entityType: 'MEDICATION_LOG',
        operationType: SyncOperationType.insert,
        payloadJson: '{"status": "TAKEN"}',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        syncStatus: SyncStatus.inProgress,
      );

      await repository.enqueueOperation(strandedItem1);
      await repository.enqueueOperation(strandedItem2);

      // Verify stranded state
      expect(repository.items.where((i) => i.syncStatus == SyncStatus.inProgress).length, equals(2));

      // Simulate device reboot / app restart
      networkInfo.setConnected(false); // keep offline so auto-sync doesn't fire immediately
      final recoveredCount = await syncManager.recoverUnfinishedOperations();

      expect(recoveredCount, equals(2));
      expect(repository.items.where((i) => i.syncStatus == SyncStatus.inProgress).length, equals(0));
      expect(repository.items.where((i) => i.syncStatus == SyncStatus.pending).length, equals(2));
      expect(repository.items.first.lastError, contains('Recovered from unexpected process termination'));
    });

    test('7. Partial Synchronization: handles mixed batch (SUCCESS, CONFLICT_IGNORED, ERROR) cleanly', () async {
      networkInfo.setConnected(true);
      await syncManager.initialize();

      final op1 = await syncManager.enqueueOperation(
        operationId: 'op_batch_1',
        entityId: 'entity_1',
        entityType: 'GAME_SESSION',
        operationType: SyncOperationType.insert,
        payload: {'item': 1},
      );
      final op2 = await syncManager.enqueueOperation(
        operationId: 'op_batch_2',
        entityId: 'entity_2',
        entityType: 'GAME_SESSION',
        operationType: SyncOperationType.insert,
        payload: {'item': 2},
      );
      final op3 = await syncManager.enqueueOperation(
        operationId: 'op_batch_3',
        entityId: 'entity_3',
        entityType: 'MEDICATION_LOG',
        operationType: SyncOperationType.insert,
        payload: {'item': 3},
      );

      // Mock server returning partial result:
      // op1: SUCCESS
      // op2: CONFLICT_IGNORED (duplicate)
      // op3: ERROR (validation failure)
      httpClient.nextResponse = {
        'batchId': 'batch_mixed',
        'processedAt': DateTime.now().toIso8601String(),
        'results': [
          {'operationId': op1.operationId, 'status': 'SUCCESS'},
          {'operationId': op2.operationId, 'status': 'CONFLICT_IGNORED'},
          {'operationId': op3.operationId, 'status': 'ERROR', 'message': 'Invalid dosage format'},
        ],
      };

      final result = await syncManager.synchronizePendingBatch(force: true);

      expect(result.totalProcessed, equals(3));
      expect(result.succeededCount, equals(1));
      expect(result.conflictIgnoredCount, equals(1));
      expect(result.failedCount, equals(1));
      expect(result.totalCompleted, equals(2));

      // Verify op1 and op2 are completed and entities marked synced
      expect(repository.items.firstWhere((i) => i.operationId == op1.operationId).syncStatus, equals(SyncStatus.completed));
      expect(repository.localEntitySyncedMap['entity_1'], isTrue);

      expect(repository.items.firstWhere((i) => i.operationId == op2.operationId).syncStatus, equals(SyncStatus.completed));
      expect(repository.localEntitySyncedMap['entity_2'], isTrue);

      // Verify op3 failed and is scheduled for retry
      final failedOp = repository.items.firstWhere((i) => i.operationId == op3.operationId);
      expect(failedOp.syncStatus, equals(SyncStatus.failed));
      expect(failedOp.retryCount, equals(1));
      expect(failedOp.lastError, equals('Invalid dosage format'));
      expect(repository.localEntitySyncedMap['entity_3'], isNull);
    });

    test('8. Timeout Handling: simulated request timeout increments retry count and sets error', () async {
      networkInfo.setConnected(true);
      await syncManager.initialize();

      await syncManager.enqueueOperation(
        entityId: 'timeout_session_1',
        entityType: 'GAME_SESSION',
        operationType: SyncOperationType.insert,
        payload: {'timeoutTest': true},
      );

      // Simulate timeout exception from HTTP client
      httpClient.throwError = TimeoutException('HTTP request timed out after 15000ms');

      final result = await syncManager.synchronizePendingBatch(force: true);

      expect(result.failedCount, equals(1));
      expect(result.succeededCount, equals(0));

      final item = repository.items.first;
      expect(item.syncStatus, equals(SyncStatus.failed));
      expect(item.retryCount, equals(1));
      expect(item.lastError, contains('timed out'));
    });

    test('9. Connectivity Transition: offline to online transition triggers automatic upload', () async {
      networkInfo.setConnected(false);
      await syncManager.initialize();

      await syncManager.enqueueOperation(
        entityId: 'auto_sync_session_1',
        entityType: 'GAME_SESSION',
        operationType: SyncOperationType.insert,
        payload: {'autoSync': true},
      );

      expect(httpClient.requestCount, equals(0));
      expect(repository.items.first.syncStatus, equals(SyncStatus.pending));

      // Network transitions to online
      networkInfo.setConnected(true);

      // Wait a microtask / pump for listener to trigger
      await Future.delayed(const Duration(milliseconds: 50));

      expect(httpClient.requestCount, greaterThanOrEqualTo(1));
      expect(repository.items.first.syncStatus, equals(SyncStatus.completed));
    });
  });
}
