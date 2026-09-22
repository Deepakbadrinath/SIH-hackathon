import 'dart:async';
import '../models/system_models.dart';

enum SyncManagerState {
  idle,
  syncing,
  offline,
  error,
  success,
}

class SyncPolicy {
  final int maxRetries;
  final int initialBackoffSeconds;
  final int maxBackoffSeconds;
  final int batchSize;
  final Duration requestTimeout;
  final Duration periodicSyncInterval;

  const SyncPolicy({
    this.maxRetries = 5,
    this.initialBackoffSeconds = 2,
    this.maxBackoffSeconds = 300,
    this.batchSize = 25,
    this.requestTimeout = const Duration(seconds: 15),
    this.periodicSyncInterval = const Duration(minutes: 5),
  });

  /// Calculates deterministic exponential backoff duration based on retry count.
  /// Formula: min(maxBackoffSeconds, initialBackoffSeconds * 2^retryCount)
  Duration calculateBackoff(int retryCount) {
    if (retryCount <= 0) return Duration.zero;
    final exponent = retryCount > 10 ? 10 : retryCount; // cap exponent to prevent overflow
    final seconds = initialBackoffSeconds * (1 << exponent);
    final clampedSeconds = seconds > maxBackoffSeconds ? maxBackoffSeconds : seconds;
    return Duration(seconds: clampedSeconds);
  }
}

class SyncBatchResult {
  final int totalProcessed;
  final int succeededCount;
  final int conflictIgnoredCount;
  final int failedCount;
  final int permanentlyFailedCount;
  final List<String> errors;

  const SyncBatchResult({
    required this.totalProcessed,
    required this.succeededCount,
    required this.conflictIgnoredCount,
    required this.failedCount,
    required this.permanentlyFailedCount,
    this.errors = const [],
  });

  bool get isFullSuccess => failedCount == 0 && permanentlyFailedCount == 0 && totalProcessed > 0;
  bool get hasFailures => failedCount > 0 || permanentlyFailedCount > 0;
  int get totalCompleted => succeededCount + conflictIgnoredCount;

  static const empty = SyncBatchResult(
    totalProcessed: 0,
    succeededCount: 0,
    conflictIgnoredCount: 0,
    failedCount: 0,
    permanentlyFailedCount: 0,
  );
}

abstract class SyncManager {
  /// Initializes the sync engine, recovers uncompleted operations from process crashes,
  /// and attaches network connectivity listeners.
  Future<void> initialize();

  /// Enqueues a local write into the persistent SyncQueue with an idempotent operationId.
  Future<SyncItem> enqueueOperation({
    required String entityId,
    required String entityType,
    required SyncOperationType operationType,
    required Map<String, dynamic> payload,
    String? operationId,
  });

  /// Uploads eligible pending and retryable operations to the server in a batch.
  /// If [force] is true, ignores exponential backoff delays.
  Future<SyncBatchResult> synchronizePendingBatch({bool force = false});

  /// Recovers any operations left in `IN_PROGRESS` state due to process termination or device reboot,
  /// resetting them back to `PENDING`.
  Future<int> recoverUnfinishedOperations();

  /// Emits the current high-level sync state.
  Stream<SyncManagerState> get stateStream;

  /// Returns the current state of the sync manager.
  SyncManagerState get currentState;

  /// Returns true if an upload synchronization cycle is currently executing.
  bool get isSyncing;

  /// Returns total count of operations currently pending synchronization.
  Future<int> getPendingCount();

  /// Cleans up timers, subscriptions, and controllers.
  void dispose();
}
