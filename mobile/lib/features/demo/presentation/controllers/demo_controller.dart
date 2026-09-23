import 'package:flutter/foundation.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/demo/demo_data_manager.dart';
import '../../../../core/network/network_info.dart';

class DemoController extends ChangeNotifier {
  final NetworkInfo _networkInfo;
  final DatabaseHelper _dbHelper;

  final bool _isDemoModeActive = true;
  bool _isOfflineSimulated = false;
  bool _isExpanded = false;
  String _statusMessage = 'SIH Demo Mode Active (Synthetic Data)';

  DemoController({
    required NetworkInfo networkInfo,
    required DatabaseHelper dbHelper,
    bool initialExpanded = false,
  })  : _networkInfo = networkInfo,
        _dbHelper = dbHelper,
        _isExpanded = initialExpanded || (kIsWeb && Uri.base.queryParameters['demo_panel'] == 'open');

  bool get isDemoModeActive => _isDemoModeActive;
  bool get isOfflineSimulated => _isOfflineSimulated;
  bool get isExpanded => _isExpanded;
  String get statusMessage => _statusMessage;
  NetworkInfo get networkInfo => _networkInfo;

  void toggleExpanded() {
    _isExpanded = !_isExpanded;
    notifyListeners();
  }

  void setExpanded(bool value) {
    _isExpanded = value;
    notifyListeners();
  }

  /// Toggles simulated offline mode without requiring physical Wi-Fi disconnect.
  Future<void> toggleSimulatedOffline() async {
    _isOfflineSimulated = !_isOfflineSimulated;
    if (_isOfflineSimulated) {
      _networkInfo.setMockConnectionStatus(false);
      _statusMessage = 'Offline Mode Active: Local SQLite Persistence & Sync Queue';
    } else {
      _networkInfo.setMockConnectionStatus(true);
      _statusMessage = 'Online Reconnected: Ready to Synchronize';
    }
    notifyListeners();
  }

  /// Sets offline status explicitly.
  void setSimulatedOffline(bool offline) {
    _isOfflineSimulated = offline;
    _networkInfo.setMockConnectionStatus(!offline);
    _statusMessage = offline
        ? 'Offline Mode Active: Local SQLite Persistence & Sync Queue'
        : 'Online Reconnected: Ready to Synchronize';
    notifyListeners();
  }

  /// Resets demo state and re-seeds baseline synthetic data.
  Future<void> resetDemoData() async {
    _isOfflineSimulated = false;
    _networkInfo.setMockConnectionStatus(null); // restore auto
    await DemoDataManager.seedDemoData(dbHelper: _dbHelper, resetExisting: true);
    _statusMessage = 'Baseline Demo Data Restored (100% Repeatable)';
    notifyListeners();
  }
}
