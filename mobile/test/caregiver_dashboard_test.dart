import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:smriti_setu/core/config/app_config.dart';
import 'package:smriti_setu/core/localization/app_localizations.dart';
import 'package:smriti_setu/core/theme/accessible_theme.dart';
import 'package:smriti_setu/domain/models/caregiver.dart';
import 'package:smriti_setu/domain/models/caregiver_dashboard_models.dart';
import 'package:smriti_setu/domain/models/game_models.dart';
import 'package:smriti_setu/domain/models/medication_models.dart';
import 'package:smriti_setu/domain/models/patient.dart';
import 'package:smriti_setu/domain/repositories/caregiver_dashboard_repository.dart';
import 'package:smriti_setu/domain/repositories/caregiver_repository.dart';
import 'package:smriti_setu/domain/repositories/game_repository.dart';
import 'package:smriti_setu/domain/repositories/medication_repository.dart';
import 'package:smriti_setu/domain/services/caregiver_authorization_service.dart';
import 'package:smriti_setu/features/caregiver/presentation/controllers/caregiver_controller.dart';
import 'package:smriti_setu/presentation/common_widgets/disclaimer_banner.dart';
import 'package:smriti_setu/presentation/screens/caregiver/caregiver_dashboard_screen.dart';
import 'package:smriti_setu/presentation/screens/caregiver/widgets/simple_accessible_charts.dart';

/// In-memory mock implementation of CaregiverAuthorizationService for isolated unit testing.
class MockCaregiverAuthorizationService implements CaregiverAuthorizationService {
  final List<PatientCaregiverRelation> _relations = [];

  void addRelation(PatientCaregiverRelation rel) {
    _relations.add(rel);
  }

  void clear() {
    _relations.clear();
  }

  @override
  Future<bool> isAuthorized({required String caregiverId, required String patientId}) async {
    if (caregiverId.isEmpty || patientId.isEmpty) return false;
    return _relations.any(
      (r) => r.caregiverId == caregiverId && r.patientId == patientId && r.isActive,
    );
  }

  @override
  Future<void> validateAccess({required String caregiverId, required String patientId}) async {
    final ok = await isAuthorized(caregiverId: caregiverId, patientId: patientId);
    if (!ok) {
      throw CaregiverUnauthorizedException(
        'Caregiver "$caregiverId" is not authorized to access patient "$patientId".',
        caregiverId: caregiverId,
        patientId: patientId,
      );
    }
  }

  @override
  Future<List<String>> getAuthorizedPatientIds(String caregiverId) async {
    return _relations
        .where((r) => r.caregiverId == caregiverId && r.isActive)
        .map((r) => r.patientId)
        .toList();
  }

  @override
  Future<List<PatientCaregiverRelation>> getAuthorizedRelationships(String caregiverId) async {
    return _relations.where((r) => r.caregiverId == caregiverId && r.isActive).toList();
  }
}

/// In-memory mock implementation of CaregiverDashboardRepository enforcing zero-trust checks.
class MockCaregiverDashboardRepository implements CaregiverDashboardRepository {
  final CaregiverAuthorizationService authService;
  final Map<String, Patient> patients = {};
  final List<GameSession> sessions = [];
  final List<GameResult> results = [];
  final List<MedicationLog> medLogs = [];

  MockCaregiverDashboardRepository({required this.authService});

  void seedTestData() {
    final now = DateTime.now();

    // Patient 1 (Authorized to caregiver_1)
    final p1 = Patient(
      id: 'patient_1',
      userId: 'user_p1',
      displayName: 'Deka Da',
      birthYear: 1950,
      emergencyContactPhone: '+91 98765 43210',
      regionalDialect: 'as_IN',
      createdAt: now,
      updatedAt: now,
    );

    // Patient 2 (Authorized to caregiver_1)
    final p2 = Patient(
      id: 'patient_2',
      userId: 'user_p2',
      displayName: 'Baruah Baideo',
      birthYear: 1954,
      emergencyContactPhone: '+91 98765 11223',
      regionalDialect: 'as_IN',
      createdAt: now,
      updatedAt: now,
    );

    // Patient 3 (UNAUTHORIZED to caregiver_1; belongs to caregiver_other)
    final p3 = Patient(
      id: 'patient_secret_3',
      userId: 'user_p3',
      displayName: 'Secret Patient',
      birthYear: 1948,
      emergencyContactPhone: '+91 99999 88888',
      regionalDialect: 'en_IN',
      createdAt: now,
      updatedAt: now,
    );

    patients[p1.id] = p1;
    patients[p2.id] = p2;
    patients[p3.id] = p3;

    // Seed recent game activity for patient_1
    final s1 = GameSession(
      id: 'sess_1',
      patientId: 'patient_1',
      gameType: GameType.familyFaceMatch,
      startTime: now.subtract(const Duration(days: 2)),
      difficultyLevel: 2,
      isCompleted: true,
      createdAt: now,
      updatedAt: now,
    );
    final r1 = GameResult(
      id: 'res_1',
      sessionId: 'sess_1',
      gameType: GameType.familyFaceMatch,
      score: 95,
      maxPossibleScore: 100,
      accuracyPercentage: 95.0,
      totalTrials: 10,
      correctTrials: 9,
      errorCount: 1,
      avgResponseTimeMs: 2100.0,
      totalHesitationPauseMs: 500.0,
      completedAt: now.subtract(const Duration(days: 2)),
      createdAt: now,
      updatedAt: now,
    );

    final s2 = GameSession(
      id: 'sess_2',
      patientId: 'patient_1',
      gameType: GameType.patternCompletion,
      startTime: now.subtract(const Duration(days: 1)),
      difficultyLevel: 2,
      isCompleted: true,
      createdAt: now,
      updatedAt: now,
    );
    final r2 = GameResult(
      id: 'res_2',
      sessionId: 'sess_2',
      gameType: GameType.patternCompletion,
      score: 85,
      maxPossibleScore: 100,
      accuracyPercentage: 85.0,
      totalTrials: 10,
      correctTrials: 8,
      errorCount: 2,
      avgResponseTimeMs: 2500.0,
      totalHesitationPauseMs: 600.0,
      completedAt: now.subtract(const Duration(days: 1)),
      createdAt: now,
      updatedAt: now,
    );

    // Old session from 20 days ago (for date filter testing)
    final sOld = GameSession(
      id: 'sess_old',
      patientId: 'patient_1',
      gameType: GameType.activitySequence,
      startTime: now.subtract(const Duration(days: 20)),
      difficultyLevel: 1,
      isCompleted: true,
      createdAt: now,
      updatedAt: now,
    );
    final rOld = GameResult(
      id: 'res_old',
      sessionId: 'sess_old',
      gameType: GameType.activitySequence,
      score: 70,
      maxPossibleScore: 100,
      accuracyPercentage: 70.0,
      totalTrials: 10,
      correctTrials: 7,
      errorCount: 3,
      avgResponseTimeMs: 3800.0,
      totalHesitationPauseMs: 1200.0,
      completedAt: now.subtract(const Duration(days: 20)),
      createdAt: now,
      updatedAt: now,
    );

    sessions.addAll([s1, s2, sOld]);
    results.addAll([r1, r2, rOld]);

    // Seed medication logs
    medLogs.add(MedicationLog(
      id: 'log_1',
      scheduleId: 'sched_1',
      scheduledTime: '08:00',
      status: MedicationLogStatus.taken,
      actionTimestamp: now.subtract(const Duration(days: 1)),
      confirmedByRole: 'PATIENT',
      createdAt: now,
      updatedAt: now,
    ));
    medLogs.add(MedicationLog(
      id: 'log_2',
      scheduleId: 'sched_2',
      scheduledTime: '13:30',
      status: MedicationLogStatus.missed,
      actionTimestamp: now.subtract(const Duration(days: 1)),
      confirmedByRole: 'CAREGIVER',
      createdAt: now,
      updatedAt: now,
    ));
  }

  @override
  Future<List<ConnectedPatient>> getConnectedPatients(String caregiverId) async {
    final relations = await authService.getAuthorizedRelationships(caregiverId);
    final List<ConnectedPatient> list = [];
    for (final rel in relations) {
      final p = patients[rel.patientId];
      if (p != null) {
        list.add(ConnectedPatient(
          patient: p,
          accessRole: rel.accessRole,
          isActive: rel.isActive,
        ));
      }
    }
    return list;
  }

  @override
  Future<CaregiverDashboardData> getDashboardData({
    required String requestingCaregiverId,
    required String patientId,
    required DateRangeFilter dateFilter,
  }) async {
    // 1. Zero-Trust Authorization check
    await authService.validateAccess(
      caregiverId: requestingCaregiverId,
      patientId: patientId,
    );

    final patient = patients[patientId];
    if (patient == null) {
      throw StateError('Patient $patientId not found');
    }

    final cutoff = dateFilter.cutoffDate;

    // Filter sessions
    final filteredSessions = sessions.where((s) {
      if (s.patientId != patientId) return false;
      if (cutoff != null && s.startTime.isBefore(cutoff)) return false;
      return true;
    }).toList();

    filteredSessions.sort((a, b) => a.startTime.compareTo(b.startTime));

    int totalGamesCompleted = 0;
    double totalAccuracy = 0.0;
    double totalRtMs = 0.0;
    int accuracyCount = 0;
    int currentDifficulty = 1;

    final List<TrendDataPoint<double>> accuracyTrend = [];
    final List<TrendDataPoint<double>> responseTimeTrend = [];
    final List<TrendDataPoint<int>> difficultyProgression = [];
    final Map<GameType, int> gamesBreakdown = {};
    final List<RecentGameSessionSummary> recent = [];

    for (final s in filteredSessions) {
      final matching = results.where((res) => res.sessionId == s.id);
      if (s.isCompleted) {
        totalGamesCompleted++;
        gamesBreakdown[s.gameType] = (gamesBreakdown[s.gameType] ?? 0) + 1;
      }
      currentDifficulty = s.difficultyLevel;

      if (matching.isNotEmpty) {
        final r = matching.first;
        totalAccuracy += r.accuracyPercentage;
        totalRtMs += r.avgResponseTimeMs;
        accuracyCount++;

        accuracyTrend.add(TrendDataPoint<double>(
          timestamp: s.startTime,
          value: r.accuracyPercentage,
          label: '${s.startTime.day}/${s.startTime.month}',
        ));

        final rtSec = double.parse((r.avgResponseTimeMs / 1000.0).toStringAsFixed(1));
        responseTimeTrend.add(TrendDataPoint<double>(
          timestamp: s.startTime,
          value: rtSec,
          label: '${s.startTime.day}/${s.startTime.month}',
        ));

        recent.add(RecentGameSessionSummary(
          sessionId: s.id,
          gameType: s.gameType,
          gameName: s.gameType.name,
          playedAt: s.startTime,
          difficultyLevel: s.difficultyLevel,
          isCompleted: s.isCompleted,
          accuracyPercentage: r.accuracyPercentage,
          avgResponseTimeSeconds: rtSec,
          score: r.score,
        ));
      }

      difficultyProgression.add(TrendDataPoint<int>(
        timestamp: s.startTime,
        value: s.difficultyLevel,
        label: '${s.startTime.day}/${s.startTime.month}',
      ));
    }

    final avgAcc = accuracyCount > 0 ? double.parse((totalAccuracy / accuracyCount).toStringAsFixed(1)) : 86.4;
    final avgRt = accuracyCount > 0 ? double.parse(((totalRtMs / accuracyCount) / 1000.0).toStringAsFixed(1)) : 2.3;

    final perf = CognitiveGamePerformanceSummary(
      totalGamesCompleted: totalGamesCompleted,
      averageAccuracy: avgAcc,
      averageResponseTimeSeconds: avgRt,
      currentDifficultyLevel: currentDifficulty,
      accuracyTrend: accuracyTrend,
      responseTimeTrend: responseTimeTrend,
      difficultyProgression: difficultyProgression,
      gamesBreakdown: gamesBreakdown,
    );

    // Medication summary
    final med = MedicationAdherenceSummary(
      adherencePercentage: 50.0,
      totalScheduledDoses: 2,
      takenDoses: 1,
      skippedDoses: 0,
      missedDoses: 1,
    );

    return CaregiverDashboardData(
      patient: ConnectedPatient(
        patient: patient,
        accessRole: CaregiverAccessRole.primary,
        isActive: true,
      ),
      dateFilter: dateFilter,
      performanceSummary: perf,
      medicationSummary: med,
      recentSessions: recent,
      generatedAt: DateTime.now(),
    );
  }
}

/// Fallback dummy repos
class DummyCaregiverRepository implements CaregiverRepository {
  @override
  Future<void> createRelationship(PatientCaregiverRelation relation) async {}
  @override
  Future<Caregiver?> getCaregiverById(String id) async => null;
  @override
  Future<Caregiver?> getCaregiverByUserId(String userId) async => null;
  @override
  Future<List<PatientCaregiverRelation>> getRelationships(String caregiverId) async => [];
  @override
  Future<void> saveCaregiver(Caregiver caregiver) async {}
}

class DummyGameRepository implements GameRepository {
  @override
  Future<double> getAverageAccuracyTrend(String patientId, {int days = 7}) async => 86.4;
  @override
  Future<double> getAverageResponseTimeTrend(String patientId, {int days = 7}) async => 2300.0;
  @override
  Future<List<DifficultyHistory>> getDifficultyHistory(String patientId, GameType gameType, {int limit = 10}) async => [];
  @override
  Future<int> getLatestDifficultyLevel(String patientId, GameType gameType) async => 2;
  @override
  Future<List<GameResult>> getRecentResults(String patientId, {int limit = 10}) async => [];
  @override
  Future<void> saveDifficultyHistory(DifficultyHistory history) async {}
  @override
  Future<void> saveGameResult(GameResult result) async {}
  @override
  Future<void> saveGameSession(GameSession session) async {}
  @override
  Future<void> savePerformanceMetrics(List<PerformanceMetrics> metrics) async {}
}

class DummyMedicationRepository implements MedicationRepository {
  @override
  Future<double> getAdherenceRate(String patientId, {int days = 7}) async => 94.2;
  @override
  Future<List<Medication>> getMedicationsForPatient(String patientId) async => [];
  @override
  Future<Medication?> getMedicationById(String id) async => null;
  @override
  Future<void> saveMedication(Medication medication) async {}
  @override
  Future<void> updateMedication(Medication medication) async {}
  @override
  Future<void> deleteMedication(String id) async {}
  @override
  Future<List<MedicationSchedule>> getSchedulesForMedication(String medicationId) async => [];
  @override
  Future<List<MedicationSchedule>> getAllActiveSchedulesForPatient(String patientId) async => [];
  @override
  Future<void> saveMedicationSchedule(MedicationSchedule schedule) async {}
  @override
  Future<void> updateMedicationSchedule(MedicationSchedule schedule) async {}
  @override
  Future<void> deleteMedicationSchedule(String id) async {}
  @override
  Future<List<MedicationLog>> getLogsForSchedule(String scheduleId, {int limit = 20}) async => [];
  @override
  Future<List<MedicationLog>> getMedicationHistory(String patientId, {int limit = 50}) async => [];
  @override
  Future<void> recordMedicationAction({
    required String scheduleId,
    required String scheduledTime,
    required MedicationLogStatus status,
    required String confirmedByRole,
    String? notes,
  }) async {}
  @override
  Future<List<MedicationReminderItem>> getTodayReminders(String patientId, {DateTime? forDate}) async => [];
  @override
  Future<List<MedicationReminderItem>> getUpcomingReminders(String patientId, {int daysAhead = 7, DateTime? fromDate}) async => [];
  @override
  Future<List<MedicationReminderItem>> getCompletedReminders(String patientId, {DateTime? forDate}) async => [];
  @override
  Future<List<MedicationReminderItem>> getMissedReminders(String patientId, {DateTime? forDate}) async => [];
  @override
  Future<int> getMissedDosesCount(String patientId, {int days = 7}) async => 0;
}

class _TestLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _TestLocalizationsDelegate();
  @override
  bool isSupported(Locale locale) => true;
  @override
  Future<AppLocalizations> load(Locale locale) async => AppLocalizations(locale);
  @override
  bool shouldReload(_TestLocalizationsDelegate old) => false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    AppConfig.initialize(Environment.development);
  });

  group('Phase 13: Zero-Trust Backend Authorization Checks', () {
    late MockCaregiverAuthorizationService authService;
    late MockCaregiverDashboardRepository dashboardRepo;

    setUp(() {
      authService = MockCaregiverAuthorizationService();
      dashboardRepo = MockCaregiverDashboardRepository(authService: authService);
      dashboardRepo.seedTestData();

      // Authorize caregiver_1 to patient_1 and patient_2
      final now = DateTime.now();
      authService.addRelation(PatientCaregiverRelation(
        id: 'rel_1',
        caregiverId: 'caregiver_1',
        patientId: 'patient_1',
        accessRole: CaregiverAccessRole.primary,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ));
      authService.addRelation(PatientCaregiverRelation(
        id: 'rel_2',
        caregiverId: 'caregiver_1',
        patientId: 'patient_2',
        accessRole: CaregiverAccessRole.secondary,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ));
      // Add an INACTIVE relation
      authService.addRelation(PatientCaregiverRelation(
        id: 'rel_revoked',
        caregiverId: 'caregiver_1',
        patientId: 'patient_revoked',
        accessRole: CaregiverAccessRole.viewer,
        isActive: false, // Inactive / revoked
        createdAt: now,
        updatedAt: now,
      ));
    });

    test('Authorized caregiver can successfully retrieve dashboard data', () async {
      final data = await dashboardRepo.getDashboardData(
        requestingCaregiverId: 'caregiver_1',
        patientId: 'patient_1',
        dateFilter: DateRangeFilter.last7Days,
      );

      expect(data.patient.id, equals('patient_1'));
      expect(data.patient.displayName, equals('Deka Da'));
      expect(data.performanceSummary.totalGamesCompleted, equals(2));
      expect(data.performanceSummary.averageAccuracy, equals(90.0)); // (95 + 85) / 2
    });

    test('Unauthorized caregiver is strictly rejected with CaregiverUnauthorizedException', () async {
      // Rogue caregiver attempting to access patient_1 without authorization
      expect(
        () async => await dashboardRepo.getDashboardData(
          requestingCaregiverId: 'caregiver_rogue',
          patientId: 'patient_1',
          dateFilter: DateRangeFilter.last7Days,
        ),
        throwsA(isA<CaregiverUnauthorizedException>()),
      );
    });

    test('Caregiver accessing secret patient without relationship is rejected with CaregiverUnauthorizedException', () async {
      // caregiver_1 is not authorized for patient_secret_3
      expect(
        () async => await dashboardRepo.getDashboardData(
          requestingCaregiverId: 'caregiver_1',
          patientId: 'patient_secret_3',
          dateFilter: DateRangeFilter.last7Days,
        ),
        throwsA(isA<CaregiverUnauthorizedException>()),
      );
    });

    test('Revoked/inactive relationship is strictly rejected with CaregiverUnauthorizedException', () async {
      expect(
        () async => await dashboardRepo.getDashboardData(
          requestingCaregiverId: 'caregiver_1',
          patientId: 'patient_revoked',
          dateFilter: DateRangeFilter.last7Days,
        ),
        throwsA(isA<CaregiverUnauthorizedException>()),
      );
    });

    test('getConnectedPatients only returns authorized active patients', () async {
      final connected = await dashboardRepo.getConnectedPatients('caregiver_1');
      expect(connected.length, equals(2));
      expect(connected.any((p) => p.id == 'patient_1'), isTrue);
      expect(connected.any((p) => p.id == 'patient_2'), isTrue);
      expect(connected.any((p) => p.id == 'patient_secret_3'), isFalse);
      expect(connected.any((p) => p.id == 'patient_revoked'), isFalse);
    });
  });

  group('Phase 13: Date & Patient Filtering Metrics', () {
    late MockCaregiverAuthorizationService authService;
    late MockCaregiverDashboardRepository dashboardRepo;
    late CaregiverController controller;

    setUp(() {
      authService = MockCaregiverAuthorizationService();
      dashboardRepo = MockCaregiverDashboardRepository(authService: authService);
      dashboardRepo.seedTestData();

      final now = DateTime.now();
      authService.addRelation(PatientCaregiverRelation(
        id: 'rel_1',
        caregiverId: 'caregiver_1',
        patientId: 'patient_1',
        accessRole: CaregiverAccessRole.primary,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ));
      authService.addRelation(PatientCaregiverRelation(
        id: 'rel_2',
        caregiverId: 'caregiver_1',
        patientId: 'patient_2',
        accessRole: CaregiverAccessRole.secondary,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ));

      controller = CaregiverController(
        caregiverRepo: DummyCaregiverRepository(),
        gameRepo: DummyGameRepository(),
        medicationRepo: DummyMedicationRepository(),
        dashboardRepo: dashboardRepo,
        authService: authService,
        defaultCaregiverId: 'caregiver_1',
      );
    });

    test('Date filter restricts data to specified time window', () async {
      // Last 7 days: should only see the 2 recent sessions (not the 20-day old one)
      await controller.initializeDashboard(dateFilter: DateRangeFilter.last7Days);
      expect(controller.dashboardData!.performanceSummary.totalGamesCompleted, equals(2));

      // All time: includes the 20-day old session as well
      await controller.setDateFilter(DateRangeFilter.allTime);
      expect(controller.dashboardData!.performanceSummary.totalGamesCompleted, equals(3));
      expect(controller.dashboardData!.recentSessions.length, equals(3));
    });

    test('Patient filter switches active patient data', () async {
      await controller.initializeDashboard();
      expect(controller.selectedPatientId, equals('patient_1'));

      // Switch to patient_2
      await controller.selectPatient('patient_2');
      expect(controller.selectedPatientId, equals('patient_2'));
      expect(controller.dashboardData!.patient.displayName, equals('Baruah Baideo'));
    });

    test('Selecting unauthorized patient sets isUnauthorized state and clears data', () async {
      await controller.initializeDashboard();
      expect(controller.isUnauthorized, isFalse);

      // Attempt to select unauthorized patient
      await controller.selectPatient('patient_secret_3');
      expect(controller.isUnauthorized, isTrue);
      expect(controller.dashboardData, isNull);
    });
  });

  group('Phase 13: Strict Non-Clinical Terminology Assertion', () {
    test('Prohibited medical terms are strictly absent from models, charts, and screen', () {
      const prohibitedPhrases = [
        'dementia diagnosis',
        'dementia score',
        'patient cured',
      ];

      // Verify that none of these prohibited words appear in domain models or charts
      final samplePerf = CognitiveGamePerformanceSummary.empty();
      final sampleMed = MedicationAdherenceSummary.empty();

      for (final phrase in prohibitedPhrases) {
        expect(samplePerf.toString().toLowerCase().contains(phrase), isFalse);
        expect(sampleMed.toString().toLowerCase().contains(phrase), isFalse);
      }
    });
  });

  group('Phase 13: UI Widgets & User Interactions', () {
    late MockCaregiverAuthorizationService authService;
    late MockCaregiverDashboardRepository dashboardRepo;
    late CaregiverController controller;

    setUp(() {
      authService = MockCaregiverAuthorizationService();
      dashboardRepo = MockCaregiverDashboardRepository(authService: authService);
      dashboardRepo.seedTestData();

      final now = DateTime.now();
      authService.addRelation(PatientCaregiverRelation(
        id: 'rel_1',
        caregiverId: 'caregiver_1',
        patientId: 'patient_1',
        accessRole: CaregiverAccessRole.primary,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ));
      authService.addRelation(PatientCaregiverRelation(
        id: 'rel_2',
        caregiverId: 'caregiver_1',
        patientId: 'patient_2',
        accessRole: CaregiverAccessRole.secondary,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ));

      controller = CaregiverController(
        caregiverRepo: DummyCaregiverRepository(),
        gameRepo: DummyGameRepository(),
        medicationRepo: DummyMedicationRepository(),
        dashboardRepo: dashboardRepo,
        authService: authService,
        defaultCaregiverId: 'caregiver_1',
      );
    });

    Widget createTestApp(Widget child) {
      return ChangeNotifierProvider<CaregiverController>.value(
        value: controller,
        child: MaterialApp(
          theme: AccessibleTheme.getLightTheme(),
          localizationsDelegates: const [_TestLocalizationsDelegate()],
          supportedLocales: const [Locale('en')],
          home: child,
        ),
      );
    }

    testWidgets('Renders connected patients, date filter chips, metrics, charts, and non-clinical sections', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestApp(const CaregiverDashboardScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(CaregiverDashboardScreen), findsOneWidget);
      expect(find.byType(DisclaimerBanner), findsOneWidget);

      // Verify connected patient selector
      expect(find.text('Connected Patients'), findsOneWidget);
      expect(find.text('Deka Da'), findsWidgets);

      // Verify date filter chips
      expect(find.text('Last 7 Days'), findsOneWidget);
      expect(find.text('Last 14 Days'), findsOneWidget);
      expect(find.text('Last 30 Days'), findsOneWidget);
      expect(find.text('All Time'), findsOneWidget);

      // Verify required non-clinical section titles
      expect(find.text('Game Performance'), findsOneWidget);
      expect(find.text('Performance Trend'), findsOneWidget);
      expect(find.text('Recent Cognitive Activity'), findsOneWidget);
      expect(find.text('Medication Adherence'), findsWidgets);

      // Verify accessible simple charts
      expect(find.byType(AccuracyTrendChart), findsOneWidget);
      expect(find.byType(ResponseTimeTrendChart), findsOneWidget);
      expect(find.byType(DifficultyProgressionChart), findsOneWidget);

      // Verify strict absence of forbidden terms
      expect(find.textContaining('Dementia diagnosis', findRichText: true), findsNothing);
      expect(find.textContaining('Dementia score', findRichText: true), findsNothing);
      expect(find.textContaining('Patient cured', findRichText: true), findsNothing);
    });

    testWidgets('Tapping Date Filter chip updates performance trends', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestApp(const CaregiverDashboardScreen()));
      await tester.pumpAndSettle();

      // Tap 'All Time' chip
      await tester.tap(find.text('All Time'));
      await tester.pumpAndSettle();

      expect(controller.selectedDateFilter, equals(DateRangeFilter.allTime));
      expect(find.text('3'), findsWidgets); // 3 games completed in All Time
    });

    testWidgets('Tapping second connected patient switches active patient', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestApp(const CaregiverDashboardScreen()));
      await tester.pumpAndSettle();

      // Tap 'Baruah Baideo'
      await tester.tap(find.text('Baruah Baideo'));
      await tester.pumpAndSettle();

      expect(controller.selectedPatientId, equals('patient_2'));
      expect(find.textContaining('Baruah Baideo'), findsWidgets);
    });

    testWidgets('Unauthorized patient selection displays Access Denied screen', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestApp(const CaregiverDashboardScreen()));
      await tester.pumpAndSettle();

      // Simulate rogue patient selection
      await controller.selectPatient('patient_secret_3');
      await tester.pumpAndSettle();

      expect(find.text('Access Denied'), findsOneWidget);
      expect(find.textContaining('not authorized'), findsOneWidget);
      expect(find.byType(AccuracyTrendChart), findsNothing);
    });
  });
}
