import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../../domain/repositories/sync_repository.dart';
import '../../../../domain/services/sync_manager.dart';

class SyncController extends ChangeNotifier {
  final SyncManager? _syncManager;
  final SyncRepository _syncRepository;
  int _pendingCount = 0;
  bool _isSyncing = false;
  DateTime? _lastSyncTimestamp;
  StreamSubscription<SyncManagerState>? _managerSubscription;

  SyncController({
    SyncManager? syncManager,
    required SyncRepository syncRepository,
  })  : _syncManager = syncManager,
        _syncRepository = syncRepository {
    if (_syncManager != null) {
      _managerSubscription = _syncManager!.stateStream.listen((state) {
        _isSyncing = state == SyncManagerState.syncing;
        if (state == SyncManagerState.success) {
          _lastSyncTimestamp = DateTime.now();
        }
        refreshPendingCount();
      });
    }
  }

  int get pendingCount => _pendingCount;
  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncTimestamp => _lastSyncTimestamp;
  bool get isAllSynced => _pendingCount == 0;
  SyncManager? get syncManager => _syncManager;

  Future<void> refreshPendingCount() async {
    _pendingCount = await _syncRepository.getPendingOperationsCount();
    notifyListeners();
  }

  Future<void> triggerManualSync() async {
    _isSyncing = true;
    notifyListeners();

    try {
      if (_syncManager != null) {
        await _syncManager!.synchronizePendingBatch(force: true);
      }
      _lastSyncTimestamp = DateTime.now();
      _pendingCount = await _syncRepository.getPendingOperationsCount();
    } catch (e) {
      if (kDebugMode) print('Manual sync trigger error: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _managerSubscription?.cancel();
    super.dispose();
  }
}
