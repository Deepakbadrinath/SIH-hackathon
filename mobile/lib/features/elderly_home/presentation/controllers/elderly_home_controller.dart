import 'package:flutter/foundation.dart';

class ElderlyHomeController extends ChangeNotifier {
  String _patientName = 'Deka Da (দাদা)';
  String _emergencyPhone = '+91 98765 43210';
  int _pendingMedicationsCount = 1;
  int _completedGamesToday = 2;

  String get patientName => _patientName;
  String get emergencyPhone => _emergencyPhone;
  int get pendingMedicationsCount => _pendingMedicationsCount;
  int get completedGamesToday => _completedGamesToday;

  void updatePatientProfile({required String name, required String emergencyPhone}) {
    _patientName = name;
    _emergencyPhone = emergencyPhone;
    notifyListeners();
  }

  void markMedicationTaken() {
    if (_pendingMedicationsCount > 0) {
      _pendingMedicationsCount--;
      notifyListeners();
    }
  }

  void incrementGamesPlayed() {
    _completedGamesToday++;
    notifyListeners();
  }
}
