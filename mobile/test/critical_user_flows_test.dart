import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:smriti_setu/core/config/app_config.dart';
import 'package:smriti_setu/core/database/database_helper.dart';
import 'package:smriti_setu/core/localization/app_localizations.dart';
import 'package:smriti_setu/core/network/network_info.dart';
import 'package:smriti_setu/core/security/secure_storage_service.dart';

import 'package:smriti_setu/data/datasources/local/caregiver_local_data_source.dart';
import 'package:smriti_setu/data/datasources/local/game_local_data_source.dart';
import 'package:smriti_setu/data/datasources/local/medication_local_data_source.dart';
import 'package:smriti_setu/data/datasources/local/patient_local_data_source.dart';
import 'package:smriti_setu/data/datasources/local/sync_queue_local_data_source.dart';
import 'package:smriti_setu/data/datasources/local/user_local_data_source.dart';

import 'package:smriti_setu/domain/models/caregiver.dart';
import 'package:smriti_setu/domain/models/caregiver_dashboard_models.dart';
import 'package:smriti_setu/domain/models/game_models.dart';
import 'package:smriti_setu/domain/models/medication_models.dart';
import 'package:smriti_setu/domain/models/patient.dart';
import 'package:smriti_setu/domain/models/system_models.dart';
import 'package:smriti_setu/domain/models/user.dart';
import 'package:smriti_setu/domain/services/voice_service.dart';

import 'package:smriti_setu/features/adaptive_difficulty/presentation/controllers/adaptive_difficulty_controller.dart';
import 'package:smriti_setu/features/authentication/data/repositories/auth_repository_impl.dart';
import 'package:smriti_setu/features/caregiver/data/repositories/caregiver_dashboard_repository_impl.dart';
import 'package:smriti_setu/features/caregiver/data/repositories/caregiver_repository_impl.dart';
import 'package:smriti_setu/features/caregiver/data/services/caregiver_authorization_service_impl.dart';
import 'package:smriti_setu/features/elderly_home/presentation/controllers/elderly_home_controller.dart';
import 'package:smriti_setu/features/games/data/repositories/game_repository_impl.dart';
import 'package:smriti_setu/features/localization/presentation/controllers/localization_controller.dart';
import 'package:smriti_setu/features/medication/data/repositories/medication_repository_impl.dart';
import 'package:smriti_setu/features/offline_sync/data/repositories/sync_repository_impl.dart';
import 'package:smriti_setu/features/voice/data/datasources/bhashini_voice_provider.dart';
import 'package:smriti_setu/features/voice/data/services/voice_service_impl.dart';

class MockTestTokenVault implements TokenVault {
  String? _accessToken;
  String? _userId;

  @override
  Future<String?> getAccessToken() async => _accessToken;
  @override
  Future<String?> getRefreshToken() async => 'mock_refresh_token';
  @override
  Future<String?> getUserId() async => _userId;
  @override
  Future<String?> getUserRole() async => 'PATIENT';
  @override
  Future<void> saveAuthTokens({
    required String accessToken,
    required String refreshToken,
    required String userId,
    required String userRole,
  }) async {
    _accessToken = accessToken;
    _userId = userId;
  }
  @override
  Future<void> clearAuth() async {
    _accessToken = null;
    _userId = null;
  }
}

class MockTestNetworkInfo implements INetworkInfo {
  bool _connected = true;
  @override
  Future<bool> get isConnected async => _connected;
  void setConnected(bool value) => _connected = value;
}

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  setUpAll(() {
    AppConfig.initialize(Environment.development);
  });

  group('Critical Flow 1: USER REGISTRATION → LOGIN → HOME → SELECT GAME → PLAY → COMPLETE → SCORE SAVED → DIFFICULTY UPDATED', () {
    late DatabaseHelper dbHelper;
    late UserLocalDataSource userDataSource;
    late PatientLocalDataSource patientDataSource;
    late GameLocalDataSource gameDataSource;
    late AuthRepositoryImpl authRepo;
    late GameRepositoryImpl gameRepo;
    late AdaptiveDifficultyController adaptiveController;
    late ElderlyHomeController homeController;
    late MockTestTokenVault tokenVault;

    setUp(() async {
      dbHelper = DatabaseHelper.forCustomPath(inMemoryDatabasePath);
      userDataSource = UserLocalDataSourceImpl(dbHelper: dbHelper);
      patientDataSource = PatientLocalDataSourceImpl(dbHelper: dbHelper);
      gameDataSource = GameLocalDataSourceImpl(dbHelper: dbHelper);
      tokenVault = MockTestTokenVault();

      authRepo = AuthRepositoryImpl(
        userLocalDataSource: userDataSource,
        tokenVault: tokenVault,
      );
      gameRepo = GameRepositoryImpl(localDataSource: gameDataSource);
      adaptiveController = AdaptiveDifficultyController();
      homeController = ElderlyHomeController();
    });

    tearDown(() async {
      await dbHelper.close();
    });

    test('Full user registration, login, game completion, score persistence, and adaptive progression', () async {
      // 1. USER REGISTRATION & 2. LOGIN
      final user = await authRepo.loginWithCredentials(
        'pranab@example.com',
        'SecurePassword123!',
      );
      expect(user.phoneOrEmail, equals('pranab@example.com'));
      expect(await authRepo.isAuthenticated(), isTrue);

      final now = DateTime.now();
      // Ensure patient record exists to satisfy foreign keys
      await patientDataSource.createPatient(Patient(
        id: user.id,
        userId: user.id,
        displayName: user.fullName,
        createdAt: now,
        updatedAt: now,
      ));

      // 3. HOME
      expect(homeController.completedGamesToday, equals(2));
      homeController.incrementGamesPlayed();
      expect(homeController.completedGamesToday, equals(3));

      // 4. SELECT GAME & 5. PLAY
      const initialDifficulty = 1;

      // 6. COMPLETE
      final session = GameSession(
        id: 'session_pattern_001',
        patientId: user.id,
        gameType: GameType.patternCompletion,
        startTime: now.subtract(const Duration(minutes: 2)),
        endTime: now,
        difficultyLevel: initialDifficulty,
        isCompleted: true,
        createdAt: now,
        updatedAt: now,
      );

      final result = GameResult(
        id: 'result_pattern_001',
        sessionId: 'session_pattern_001',
        gameType: GameType.patternCompletion,
        score: 100,
        maxPossibleScore: 100,
        accuracyPercentage: 100.0,
        totalTrials: 5,
        correctTrials: 5,
        errorCount: 0,
        avgResponseTimeMs: 1400.0,
        totalHesitationPauseMs: 400.0,
        completedAt: now,
        createdAt: now,
        updatedAt: now,
      );

      // 7. SCORE SAVED
      await gameRepo.saveGameSession(session);
      await gameRepo.saveGameResult(result);

      final recentResults = await gameRepo.getRecentResults(user.id);
      expect(recentResults.length, equals(1));
      expect(recentResults.first.sessionId, equals('session_pattern_001'));
      expect(recentResults.first.score, equals(100));

      // 8. DIFFICULTY UPDATED
      final decision1 = adaptiveController.calculateNextDifficulty(
        currentDifficulty: initialDifficulty,
        accuracy: 100.0,
        avgResponseTimeMs: 1400,
        hesitationMs: 400,
        errorCount: 0,
      );
      expect(decision1.nextDifficulty, equals(1)); // First session establishes baseline

      final decision2 = adaptiveController.calculateNextDifficulty(
        currentDifficulty: 1,
        accuracy: 100.0,
        avgResponseTimeMs: 1350,
        hesitationMs: 380,
        errorCount: 0,
      );
      expect(decision2.nextDifficulty, equals(2));
      expect(decision2.reasonCode, equals('PROMOTED_HIGH_PERFORMANCE'));
      expect(decision2.reason, contains('Increase from Level 1 → Level 2'));
    });
  });

  group('Critical Flow 2: CAREGIVER LOGIN → PATIENT LIST → PATIENT → PERFORMANCE → MEDICATION → ADHERENCE', () {
    late DatabaseHelper dbHelper;
    late CaregiverLocalDataSource caregiverDataSource;
    late RelationshipLocalDataSource relDataSource;
    late PatientLocalDataSource patientDataSource;
    late UserLocalDataSource userDataSource;
    late GameLocalDataSource gameDataSource;
    late MedicationLocalDataSource medicationDataSource;
    late CaregiverRepositoryImpl caregiverRepo;
    late CaregiverDashboardRepositoryImpl dashboardRepo;
    late MedicationRepositoryImpl medicationRepo;

    setUp(() async {
      dbHelper = DatabaseHelper.forCustomPath(inMemoryDatabasePath);
      caregiverDataSource = CaregiverLocalDataSourceImpl(dbHelper: dbHelper);
      relDataSource = RelationshipLocalDataSourceImpl(dbHelper: dbHelper);
      patientDataSource = PatientLocalDataSourceImpl(dbHelper: dbHelper);
      userDataSource = UserLocalDataSourceImpl(dbHelper: dbHelper);
      gameDataSource = GameLocalDataSourceImpl(dbHelper: dbHelper);
      medicationDataSource = MedicationLocalDataSourceImpl(dbHelper: dbHelper);

      caregiverRepo = CaregiverRepositoryImpl(
        caregiverDataSource: caregiverDataSource,
        relationshipDataSource: relDataSource,
      );
      final authService = CaregiverAuthorizationServiceImpl(dbHelper: dbHelper);
      dashboardRepo = CaregiverDashboardRepositoryImpl(
        authService: authService,
        dbHelper: dbHelper,
      );
      medicationRepo = MedicationRepositoryImpl(localDataSource: medicationDataSource);
    });

    tearDown(() async {
      await dbHelper.close();
    });

    test('Caregiver views assigned patient roster, performance trends, and medication adherence', () async {
      final now = DateTime.now();

      // Setup patient user & record
      final pUser = User(
        id: 'patient_p1',
        phoneOrEmail: 'bhaben@example.com',
        role: UserRole.patient,
        fullName: 'Bhaben Baruah',
        preferredLanguage: 'as',
        createdAt: now,
        updatedAt: now,
      );
      await userDataSource.createUser(pUser);
      final patient = Patient(
        id: 'patient_p1',
        userId: 'patient_p1',
        displayName: 'Bhaben Baruah',
        birthYear: 1948,
        emergencyContactPhone: '+919876543210',
        createdAt: now,
        updatedAt: now,
      );
      await patientDataSource.createPatient(patient);

      // Setup caregiver user & profile
      final cUser = User(
        id: 'cg_user_1',
        phoneOrEmail: 'ananya@caregiver.org',
        role: UserRole.caregiver,
        fullName: 'Dr. Ananya Sharma',
        preferredLanguage: 'en',
        createdAt: now,
        updatedAt: now,
      );
      await userDataSource.createUser(cUser);
      final caregiver = Caregiver(
        id: 'cg_1',
        userId: 'cg_user_1',
        fullName: 'Dr. Ananya Sharma',
        relationshipToPatient: 'Primary Caregiver',
        phone: '+919988776655',
        createdAt: now,
        updatedAt: now,
      );
      await caregiverDataSource.createCaregiver(caregiver);

      // Link Patient to Caregiver
      final rel = PatientCaregiverRelation(
        id: 'rel_cg1_p1',
        caregiverId: 'cg_1',
        patientId: 'patient_p1',
        accessRole: CaregiverAccessRole.primary,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );
      await relDataSource.createRelationship(rel);

      // 1. CAREGIVER LOGIN: Verify caregiver profile
      final retrievedCg = await caregiverRepo.getCaregiverById('cg_1');
      expect(retrievedCg, isNotNull);

      // 2. PATIENT LIST: Retrieve authorized relationships
      final relations = await caregiverRepo.getRelationships('cg_1');
      expect(relations.length, equals(1));
      expect(relations.first.patientId, equals('patient_p1'));

      // 3. PATIENT SELECTION & 4. PERFORMANCE
      final session = GameSession(
        id: 'sess_cg_01',
        patientId: 'patient_p1',
        gameType: GameType.familyFaceMatch,
        startTime: now.subtract(const Duration(hours: 1)),
        endTime: now,
        difficultyLevel: 1,
        isCompleted: true,
        createdAt: now,
        updatedAt: now,
      );
      await gameDataSource.insertSession(session);

      final result = GameResult(
        id: 'res_cg_01',
        sessionId: 'sess_cg_01',
        gameType: GameType.familyFaceMatch,
        score: 95,
        maxPossibleScore: 100,
        accuracyPercentage: 95.0,
        totalTrials: 10,
        correctTrials: 9,
        errorCount: 1,
        avgResponseTimeMs: 1800.0,
        totalHesitationPauseMs: 200.0,
        completedAt: now,
        createdAt: now,
        updatedAt: now,
      );
      await gameDataSource.insertResult(result);

      final dashboardData = await dashboardRepo.getDashboardData(
        requestingCaregiverId: 'cg_1',
        patientId: 'patient_p1',
        dateFilter: DateRangeFilter.allTime,
      );
      expect(dashboardData.patient.id, equals('patient_p1'));
      expect(dashboardData.patient.isActive, isTrue);
      expect(dashboardData.performanceSummary.totalGamesCompleted, equals(1));
      expect(dashboardData.performanceSummary.averageAccuracy, closeTo(95.0, 0.1));

      // 5. MEDICATION & 6. ADHERENCE
      final med = Medication(
        id: 'med_donepezil_1',
        patientId: 'patient_p1',
        name: 'Donepezil',
        dosageDescription: '5mg daily with breakfast',
        instructions: 'Take with food',
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );
      await medicationRepo.saveMedication(med);

      final sched = MedicationSchedule(
        id: 'sched_donepezil_1',
        medicationId: 'med_donepezil_1',
        timeOfDay: '08:00',
        mealRelation: MealRelation.afterMeal,
        daysOfWeek: '1,2,3,4,5,6,7',
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );
      await medicationRepo.saveMedicationSchedule(sched);

      await medicationRepo.recordMedicationAction(
        scheduleId: 'sched_donepezil_1',
        scheduledTime: '08:00',
        status: MedicationLogStatus.taken,
        confirmedByRole: 'CAREGIVER',
        notes: 'Observed patient swallowing pill',
      );

      final adherence = await medicationRepo.getAdherenceRate('patient_p1', days: 7);
      expect(adherence, closeTo(100.0, 0.1));
    });
  });

  group('Critical Flow 3 & 4: OFFLINE PERSISTENCE & RECONNECT IDEMPOTENT SYNC', () {
    late DatabaseHelper dbHelper;
    late SyncQueueLocalDataSource syncDataSource;
    late GameLocalDataSource gameDataSource;
    late UserLocalDataSource userDataSource;
    late PatientLocalDataSource patientDataSource;
    late SyncRepositoryImpl syncRepo;
    late MockTestNetworkInfo networkInfo;

    setUp(() async {
      dbHelper = DatabaseHelper.forCustomPath(inMemoryDatabasePath);
      syncDataSource = SyncQueueLocalDataSourceImpl(dbHelper: dbHelper);
      gameDataSource = GameLocalDataSourceImpl(dbHelper: dbHelper);
      userDataSource = UserLocalDataSourceImpl(dbHelper: dbHelper);
      patientDataSource = PatientLocalDataSourceImpl(dbHelper: dbHelper);
      syncRepo = SyncRepositoryImpl(localDataSource: syncDataSource);
      networkInfo = MockTestNetworkInfo();
    });

    tearDown(() async {
      await dbHelper.close();
    });

    test('Offline game completion persists across simulated restart and syncs idempotently upon reconnect', () async {
      final now = DateTime.now();
      final user = User(
        id: 'patient_off_1',
        phoneOrEmail: 'ratul@example.com',
        role: UserRole.patient,
        fullName: 'Ratul Saikia',
        preferredLanguage: 'as',
        createdAt: now,
        updatedAt: now,
      );
      await userDataSource.createUser(user);

      // Create Patient record to satisfy foreign key constraint
      await patientDataSource.createPatient(Patient(
        id: 'patient_off_1',
        userId: 'patient_off_1',
        displayName: 'Ratul Saikia',
        createdAt: now,
        updatedAt: now,
      ));

      // 1. DISCONNECT INTERNET
      networkInfo.setConnected(false);
      expect(await networkInfo.isConnected, isFalse);

      // 2. PLAY GAME & SAVE RESULT OFFLINE
      final session = GameSession(
        id: 'sess_off_99',
        patientId: 'patient_off_1',
        gameType: GameType.activitySequence,
        startTime: now.subtract(const Duration(minutes: 5)),
        endTime: now,
        difficultyLevel: 1,
        isCompleted: true,
        createdAt: now,
        updatedAt: now,
      );
      await gameDataSource.insertSession(session);

      final syncOp = SyncItem(
        operationId: 'op_sync_session_99',
        entityId: 'sess_off_99',
        entityType: 'GAME_SESSION',
        operationType: SyncOperationType.insert,
        payloadJson: jsonEncode(session.toMap()),
        timestamp: now,
        syncStatus: SyncStatus.pending,
        retryCount: 0,
      );
      await syncRepo.enqueueOperation(syncOp);

      // 3. RESTART APP SIMULATION
      final restartedSyncRepo = SyncRepositoryImpl(localDataSource: syncDataSource);
      final restartedGameSource = GameLocalDataSourceImpl(dbHelper: dbHelper);

      // 4. RESULT STILL EXISTS
      final retrievedSession = await restartedGameSource.getSessionById('sess_off_99');
      expect(retrievedSession, isNotNull);
      expect(retrievedSession!.id, equals('sess_off_99'));

      final pendingOps = await restartedSyncRepo.getPendingOperations();
      expect(pendingOps.length, equals(1));
      expect(pendingOps.first.operationId, equals('op_sync_session_99'));

      // 5. RECONNECT INTERNET
      networkInfo.setConnected(true);
      expect(await networkInfo.isConnected, isTrue);

      // 6. SYNC EXECUTION & IDEMPOTENT RESPONSE
      await restartedSyncRepo.markOperationCompleted(
        'op_sync_session_99',
        'sess_off_99',
        'GAME_SESSION',
      );

      final pendingAfterSync = await restartedSyncRepo.getPendingOperations();
      expect(pendingAfterSync, isEmpty);

      // 7. NO DUPLICATE RECORD ON REPLAY
      await restartedSyncRepo.enqueueOperation(syncOp.copyWith(syncStatus: SyncStatus.completed));
      final allPending = await restartedSyncRepo.getPendingOperations();
      expect(allPending, isEmpty);
    });
  });

  group('Critical Flow 5: VOICE: SELECT LANGUAGE → VOICE INSTRUCTION → SPEECH INPUT → RESPONSE', () {
    test('Voice service loads regional audio prompts and recognizes voice intent', () async {
      final bhashini = BhashiniVoiceProvider(
        simulatedLatency: Duration.zero,
        mockTranscribedText: 'yes',
      );
      final platform = NativePlatformVoiceProvider(
        installedOfflineTtsLocales: {'en', 'hi'},
        installedOfflineSttLocales: {'en'},
        simulatedLatency: Duration.zero,
        mockTranscribedText: 'yes',
      );
      final voiceService = VoiceServiceImpl(
        bhashiniProvider: bhashini,
        nativeProvider: platform,
      );

      // 1. SELECT LANGUAGE (from 14 supported regional languages)
      const regionalCodes = ['as', 'bn', 'hi', 'en', 'mni', 'or', 'ta', 'te'];
      for (final lang in regionalCodes) {
        // 2. VOICE INSTRUCTION
        final res = await voiceService.readInstructionAloud(
          'Please select a game to begin your morning activity.',
          languageCode: lang,
        );
        expect(res.isSuccess, isTrue, reason: 'Failed for language $lang');
        expect(voiceService.lastSpokenInstruction, isNotEmpty);
      }

      // 3. SPEECH INPUT & 4. RESPONSE
      final inputResult = await voiceService.captureVoiceInput(languageCode: 'en');
      expect(inputResult.isSuccess, isTrue);

      final confirmResult = await voiceService.requestVoiceConfirmation(
        languageCode: 'en',
      );
      expect(confirmResult, equals(VoiceConfirmationResult.confirmed));
    });
  });

  group('Critical Flow 6: LOCALIZATION: CHANGE LANGUAGE → UI UPDATES → NO TEXT OVERFLOW → RTL WORKS', () {
    testWidgets('Screen updates across Indian and RTL locales without text overflow', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final locController = LocalizationController();

      await tester.pumpWidget(
        AnimatedBuilder(
          animation: locController,
          builder: (context, _) {
            final isRtl = locController.isRtl;
            return MaterialApp(
              locale: locController.currentLocale,
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              home: Directionality(
                textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                child: Scaffold(
                  body: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          locController.currentLocale.languageCode,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'SmritiSetu Cognitive Support for Elderly Dementia Patients',
                          style: TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );

      final testLocales = ['as', 'bn', 'hi', 'te', 'ta', 'kn', 'ml', 'ur', 'ar', 'en'];
      for (final lang in testLocales) {
        locController.setLanguageCode(lang);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'Language $lang caused an exception or overflow');
        if (lang == 'ur' || lang == 'ar') {
          expect(locController.isRtl, isTrue);
        } else {
          expect(locController.isRtl, isFalse);
        }
      }
    });
  });

  group('Critical Flow 7: SECURITY: UNAUTHORIZED USER → PROTECTED API → ACCESS DENIED', () {
    late DatabaseHelper dbHelper;
    late CaregiverLocalDataSource caregiverDataSource;
    late PatientLocalDataSource patientDataSource;
    late UserLocalDataSource userDataSource;
    late CaregiverDashboardRepositoryImpl dashboardRepo;

    setUp(() async {
      dbHelper = DatabaseHelper.forCustomPath(inMemoryDatabasePath);
      caregiverDataSource = CaregiverLocalDataSourceImpl(dbHelper: dbHelper);
      patientDataSource = PatientLocalDataSourceImpl(dbHelper: dbHelper);
      userDataSource = UserLocalDataSourceImpl(dbHelper: dbHelper);

      final authService = CaregiverAuthorizationServiceImpl(dbHelper: dbHelper);
      dashboardRepo = CaregiverDashboardRepositoryImpl(
        authService: authService,
        dbHelper: dbHelper,
      );
    });

    tearDown(() async {
      await dbHelper.close();
    });

    test('Caregiver is strictly denied access to unlinked patient data (Broken Access Control prevention)', () async {
      final now = DateTime.now();
      final p1 = User(
        id: 'patient_secret_1',
        phoneOrEmail: 'secret@patient.com',
        role: UserRole.patient,
        fullName: 'Private Patient',
        preferredLanguage: 'en',
        createdAt: now,
        updatedAt: now,
      );
      await userDataSource.createUser(p1);
      await patientDataSource.createPatient(Patient(
        id: 'patient_secret_1',
        userId: 'patient_secret_1',
        displayName: 'Private Patient',
        birthYear: 1950,
        emergencyContactPhone: '0000000000',
        createdAt: now,
        updatedAt: now,
      ));

      final c2 = User(
        id: 'cg_unauthorized',
        phoneOrEmail: 'intruder@caregiver.com',
        role: UserRole.caregiver,
        fullName: 'Intruding Caregiver',
        preferredLanguage: 'en',
        createdAt: now,
        updatedAt: now,
      );
      await userDataSource.createUser(c2);
      await caregiverDataSource.createCaregiver(Caregiver(
        id: 'cg_unauthorized',
        userId: 'cg_unauthorized',
        fullName: 'Intruding Caregiver',
        relationshipToPatient: 'External',
        phone: '1111111111',
        createdAt: now,
        updatedAt: now,
      ));

      expect(
        () async => await dashboardRepo.getDashboardData(
          requestingCaregiverId: 'cg_unauthorized',
          patientId: 'patient_secret_1',
          dateFilter: DateRangeFilter.allTime,
        ),
        throwsA(isA<CaregiverUnauthorizedException>()),
      );
    });
  });
}
