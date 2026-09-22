import 'package:flutter/foundation.dart';
import '../../../../domain/models/caregiver.dart';
import '../../../../domain/models/caregiver_dashboard_models.dart';
import '../../../../domain/models/patient.dart';
import '../../../../domain/repositories/caregiver_dashboard_repository.dart';
import '../../../../domain/repositories/caregiver_repository.dart';
import '../../../../domain/repositories/game_repository.dart';
import '../../../../domain/repositories/medication_repository.dart';
import '../../../../domain/services/caregiver_authorization_service.dart';

class CaregiverController extends ChangeNotifier {
  final CaregiverRepository _caregiverRepo;
  final GameRepository _gameRepo;
  final MedicationRepository _medicationRepo;
  final CaregiverDashboardRepository? _dashboardRepo;
  final CaregiverAuthorizationService? _authService;

  String _activeCaregiverId = 'caregiver_demo_1';
  List<ConnectedPatient> _connectedPatients = [];
  String? _selectedPatientId;
  DateRangeFilter _selectedDateFilter = DateRangeFilter.last7Days;
  CaregiverDashboardData? _dashboardData;
  bool _isUnauthorized = false;
  String? _errorMessage;
  bool _isLoading = false;
  int _pendingSyncOperations = 0;

  CaregiverController({
    required CaregiverRepository caregiverRepo,
    required GameRepository gameRepo,
    required MedicationRepository medicationRepo,
    CaregiverDashboardRepository? dashboardRepo,
    CaregiverAuthorizationService? authService,
    String defaultCaregiverId = 'caregiver_demo_1',
  })  : _caregiverRepo = caregiverRepo,
        _gameRepo = gameRepo,
        _medicationRepo = medicationRepo,
        _dashboardRepo = dashboardRepo,
        _authService = authService,
        _activeCaregiverId = defaultCaregiverId;

  // Getters
  CaregiverRepository get caregiverRepo => _caregiverRepo;
  GameRepository get gameRepo => _gameRepo;
  MedicationRepository get medicationRepo => _medicationRepo;
  CaregiverDashboardRepository? get dashboardRepo => _dashboardRepo;
  CaregiverAuthorizationService? get authService => _authService;

  String get activeCaregiverId => _activeCaregiverId;
  List<ConnectedPatient> get connectedPatients => _connectedPatients;
  String? get selectedPatientId => _selectedPatientId;
  DateRangeFilter get selectedDateFilter => _selectedDateFilter;
  CaregiverDashboardData? get dashboardData => _dashboardData;
  bool get isUnauthorized => _isUnauthorized;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  int get pendingSyncOperations => _pendingSyncOperations;

  ConnectedPatient? get selectedPatient {
    if (_selectedPatientId == null) return null;
    final idx = _connectedPatients.indexWhere((p) => p.id == _selectedPatientId);
    return idx >= 0 ? _connectedPatients[idx] : null;
  }

  // Backwards-compatible legacy getters
  double get averageAccuracy => _dashboardData?.performanceSummary.averageAccuracy ?? 86.4;
  double get averageResponseTimeSeconds => _dashboardData?.performanceSummary.averageResponseTimeSeconds ?? 2.3;
  double get medicationAdherenceRate => _dashboardData?.medicationSummary.adherencePercentage ?? 94.2;

  /// Loads authorized connected patients and queries initial dashboard data for caregiver.
  Future<void> initializeDashboard({
    String? caregiverId,
    String? preferredPatientId,
    DateRangeFilter? dateFilter,
  }) async {
    if (caregiverId != null && caregiverId.isNotEmpty) {
      _activeCaregiverId = caregiverId;
    }
    if (dateFilter != null) {
      _selectedDateFilter = dateFilter;
    }

    _isLoading = true;
    _isUnauthorized = false;
    _errorMessage = null;
    notifyListeners();

    try {
      final repo = _dashboardRepo;
      if (repo != null) {
        _connectedPatients = await repo.getConnectedPatients(_activeCaregiverId);
      }

      if (_connectedPatients.isNotEmpty) {
        if (preferredPatientId != null && _connectedPatients.any((p) => p.id == preferredPatientId)) {
          _selectedPatientId = preferredPatientId;
        } else if (_selectedPatientId == null || !_connectedPatients.any((p) => p.id == _selectedPatientId)) {
          _selectedPatientId = _connectedPatients.first.id;
        }

        await _fetchPatientData();
      } else {
        // No connected patients found
        _selectedPatientId = null;
        _dashboardData = null;
      }
    } catch (e) {
      _errorMessage = e.toString();
      if (kDebugMode) print('Error initializing caregiver dashboard: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Selects a different patient and loads their metrics with backend authorization check.
  Future<void> selectPatient(String patientId) async {
    _selectedPatientId = patientId;
    _isLoading = true;
    _isUnauthorized = false;
    _errorMessage = null;
    notifyListeners();

    try {
      await _fetchPatientData();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Changes the active date window and re-aggregates performance data.
  Future<void> setDateFilter(DateRangeFilter filter) async {
    if (_selectedDateFilter == filter) return;
    _selectedDateFilter = filter;
    _isLoading = true;
    notifyListeners();

    try {
      await _fetchPatientData();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Internal fetch method that delegates to repository with zero-trust authorization.
  Future<void> _fetchPatientData() async {
    final patientId = _selectedPatientId;
    if (patientId == null) return;

    final repo = _dashboardRepo;
    if (repo == null) {
      // If repository not injected (e.g. legacy test harness), refresh via basic repos
      await refreshDashboard(patientId);
      return;
    }

    try {
      _isUnauthorized = false;
      _dashboardData = await repo.getDashboardData(
        requestingCaregiverId: _activeCaregiverId,
        patientId: patientId,
        dateFilter: _selectedDateFilter,
      );
    } on CaregiverUnauthorizedException catch (e) {
      _isUnauthorized = true;
      _dashboardData = null;
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Failed to load dashboard data: $e';
    }
  }

  /// Backwards-compatible refresh method.
  Future<void> refreshDashboard([String? patientId]) async {
    final pid = patientId ?? _selectedPatientId ?? 'patient_demo_1';
    _isLoading = true;
    notifyListeners();

    try {
      final repo = _dashboardRepo;
      if (repo != null && _selectedPatientId != null) {
        await _fetchPatientData();
      } else {
        final acc = await _gameRepo.getAverageAccuracyTrend(pid);
        final rtMs = await _gameRepo.getAverageResponseTimeTrend(pid);
        final adh = await _medicationRepo.getAdherenceRate(pid);

        _dashboardData = CaregiverDashboardData(
          patient: ConnectedPatient(
            patient: _connectedPatients.isNotEmpty
                ? _connectedPatients.first.patient
                : ConnectedPatient(
                    patient: _connectedPatients.isNotEmpty ? _connectedPatients.first.patient : _createDemoPatient(pid),
                    accessRole: CaregiverAccessRole.primary,
                    isActive: true,
                  ).patient,
            accessRole: CaregiverAccessRole.primary,
            isActive: true,
          ),
          dateFilter: _selectedDateFilter,
          performanceSummary: CognitiveGamePerformanceSummary(
            totalGamesCompleted: 12,
            averageAccuracy: acc,
            averageResponseTimeSeconds: double.parse((rtMs / 1000.0).toStringAsFixed(1)),
            currentDifficultyLevel: 2,
            accuracyTrend: [],
            responseTimeTrend: [],
            difficultyProgression: [],
            gamesBreakdown: {},
          ),
          medicationSummary: MedicationAdherenceSummary(
            adherencePercentage: adh,
            totalScheduledDoses: 14,
            takenDoses: 13,
            skippedDoses: 0,
            missedDoses: 1,
          ),
          recentSessions: [],
          generatedAt: DateTime.now(),
        );
      }
    } catch (e) {
      if (kDebugMode) print('Error refreshing caregiver dashboard: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updatePendingSyncCount(int count) {
    _pendingSyncOperations = count;
    notifyListeners();
  }

  Patient _createDemoPatient(String pid) {
    final now = DateTime.now();
    return Patient(
      id: pid,
      userId: 'user_$pid',
      displayName: 'Deka Da',
      birthYear: 1950,
      emergencyContactPhone: '+91 98765 43210',
      regionalDialect: 'as_IN',
      createdAt: now,
      updatedAt: now,
    );
  }
}
