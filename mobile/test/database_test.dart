import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:smriti_setu/core/database/database_constants.dart';
import 'package:smriti_setu/core/database/database_helper.dart';
import 'package:smriti_setu/core/database/migrations/migration_runner.dart';
import 'package:smriti_setu/core/database/migrations/migration_v1_to_v2.dart';
import 'package:smriti_setu/data/datasources/local/caregiver_local_data_source.dart';
import 'package:smriti_setu/data/datasources/local/game_local_data_source.dart';
import 'package:smriti_setu/data/datasources/local/medication_local_data_source.dart';
import 'package:smriti_setu/data/datasources/local/patient_local_data_source.dart';
import 'package:smriti_setu/data/datasources/local/sync_queue_local_data_source.dart';
import 'package:smriti_setu/data/datasources/local/user_local_data_source.dart';
import 'package:smriti_setu/data/datasources/local/audit_and_settings_local_data_source.dart';
import 'package:smriti_setu/domain/models/caregiver.dart';
import 'package:smriti_setu/domain/models/game_models.dart';
import 'package:smriti_setu/domain/models/medication_models.dart';
import 'package:smriti_setu/domain/models/patient.dart';
import 'package:smriti_setu/domain/models/system_models.dart';
import 'package:smriti_setu/domain/models/user.dart';

void main() {
  // Initialize FFI for running real in-memory SQLite on desktop test runner
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('Phase 2 SQLite Offline-First Database Tests', () {
    late DatabaseHelper dbHelper;
    late UserLocalDataSource userSource;
    late PatientLocalDataSource patientSource;
    late CaregiverLocalDataSource caregiverSource;
    late RelationshipLocalDataSource relationshipSource;
    late GameLocalDataSource gameSource;
    late MedicationLocalDataSource medicationSource;
    late SyncQueueLocalDataSource syncSource;
    late AuditLocalDataSource auditSource;
    late SettingsLocalDataSource settingsSource;

    setUp(() async {
      // Use in-memory SQLite database for clean, isolated test runs
      dbHelper = DatabaseHelper.forCustomPath(inMemoryDatabasePath);
      userSource = UserLocalDataSourceImpl(dbHelper: dbHelper);
      patientSource = PatientLocalDataSourceImpl(dbHelper: dbHelper);
      caregiverSource = CaregiverLocalDataSourceImpl(dbHelper: dbHelper);
      relationshipSource = RelationshipLocalDataSourceImpl(dbHelper: dbHelper);
      gameSource = GameLocalDataSourceImpl(dbHelper: dbHelper);
      medicationSource = MedicationLocalDataSourceImpl(dbHelper: dbHelper);
      syncSource = SyncQueueLocalDataSourceImpl(dbHelper: dbHelper);
      auditSource = AuditLocalDataSourceImpl(dbHelper: dbHelper);
      settingsSource = SettingsLocalDataSourceImpl(dbHelper: dbHelper);
    });

    tearDown(() async {
      await dbHelper.close();
    });

    // -------------------------------------------------------------
    // 1. CRUD Operations Test
    // -------------------------------------------------------------
    test('User, Patient, and Caregiver CRUD operations succeed', () async {
      final now = DateTime.now();

      // Create User
      final user = User(
        id: 'u_test_1',
        phoneOrEmail: 'deka@assam.in',
        role: UserRole.patient,
        fullName: 'Deka Da',
        preferredLanguage: 'as',
        createdAt: now,
        updatedAt: now,
      );
      await userSource.createUser(user);

      // Read User
      final fetchedUser = await userSource.getUserById('u_test_1');
      expect(fetchedUser, isNotNull);
      expect(fetchedUser!.fullName, equals('Deka Da'));
      expect(fetchedUser.preferredLanguage, equals('as'));

      // Update User
      final updatedUser = user.copyWith(fullName: 'Deka Da (Brahmaputra)');
      await userSource.updateUser(updatedUser);
      final readUpdated = await userSource.getUserById('u_test_1');
      expect(readUpdated!.fullName, equals('Deka Da (Brahmaputra)'));

      // Create Patient
      final patient = Patient(
        id: 'p_test_1',
        userId: 'u_test_1',
        displayName: 'Deka Da',
        birthYear: 1950,
        emergencyContactPhone: '+91 98765 00000',
        regionalDialect: 'as_IN',
        createdAt: now,
        updatedAt: now,
      );
      await patientSource.createPatient(patient);

      // Read Patient
      final fetchedPatient = await patientSource.getPatientById('p_test_1');
      expect(fetchedPatient, isNotNull);
      expect(fetchedPatient!.regionalDialect, equals('as_IN'));
      expect(fetchedPatient.birthYear, equals(1950));

      // Create Caregiver User & Profile
      final cUser = User(
        id: 'u_care_1',
        phoneOrEmail: 'ananya@care.in',
        role: UserRole.caregiver,
        fullName: 'Ananya Sharma',
        createdAt: now,
        updatedAt: now,
      );
      await userSource.createUser(cUser);

      final caregiver = Caregiver(
        id: 'c_test_1',
        userId: 'u_care_1',
        fullName: 'Ananya Sharma',
        relationshipToPatient: 'Daughter',
        phone: '+91 98765 11111',
        createdAt: now,
        updatedAt: now,
      );
      await caregiverSource.createCaregiver(caregiver);

      // Create Relationship
      final relation = PatientCaregiverRelation(
        id: 'rel_test_1',
        patientId: 'p_test_1',
        caregiverId: 'c_test_1',
        accessRole: CaregiverAccessRole.primary,
        createdAt: now,
        updatedAt: now,
      );
      await relationshipSource.createRelationship(relation);

      final rels = await relationshipSource.getRelationshipsForCaregiver('c_test_1');
      expect(rels.length, equals(1));
      expect(rels.first.patientId, equals('p_test_1'));

      // Delete Patient & User
      await patientSource.deletePatient('p_test_1');
      expect(await patientSource.getPatientById('p_test_1'), isNull);

      await userSource.deleteUser('u_test_1');
      expect(await userSource.getUserById('u_test_1'), isNull);
    });

    test('Game Sessions, Results, and Metrics CRUD operations succeed', () async {
      final now = DateTime.now();

      // Seed parent User & Patient
      await userSource.createUser(User(
        id: 'u_game_user',
        phoneOrEmail: 'gamer@assam.in',
        role: UserRole.patient,
        fullName: 'Test Patient',
        createdAt: now,
        updatedAt: now,
      ));
      await patientSource.createPatient(Patient(
        id: 'p_game_patient',
        userId: 'u_game_user',
        displayName: 'Game Patient',
        createdAt: now,
        updatedAt: now,
      ));

      // Insert Game Session
      final session = GameSession(
        id: 'ses_100',
        patientId: 'p_game_patient',
        gameType: GameType.familyFaceMatch,
        startTime: now,
        difficultyLevel: 2,
        createdAt: now,
        updatedAt: now,
      );
      await gameSource.insertSession(session);

      final fetchedSession = await gameSource.getSessionById('ses_100');
      expect(fetchedSession, isNotNull);
      expect(fetchedSession!.gameType, equals(GameType.familyFaceMatch));
      expect(fetchedSession.difficultyLevel, equals(2));

      // Insert Game Result
      final result = GameResult(
        id: 'res_100',
        sessionId: 'ses_100',
        gameType: GameType.familyFaceMatch,
        score: 95,
        maxPossibleScore: 100,
        accuracyPercentage: 95.0,
        totalTrials: 5,
        correctTrials: 5,
        errorCount: 0,
        avgResponseTimeMs: 1450.0,
        totalHesitationPauseMs: 400.0,
        completedAt: now,
        createdAt: now,
        updatedAt: now,
      );
      await gameSource.insertResult(result);

      final fetchedResult = await gameSource.getResultBySessionId('ses_100');
      expect(fetchedResult, isNotNull);
      expect(fetchedResult!.score, equals(95));
      expect(fetchedResult.accuracyPercentage, equals(95.0));

      // Insert Performance Metrics (Per trial telemetry)
      final metrics = [
        PerformanceMetrics(
          id: 'pm_1',
          sessionId: 'ses_100',
          trialNumber: 1,
          stimulusId: 'photo_son_1',
          userResponse: 'son',
          isCorrect: true,
          responseTimeMs: 1200,
          hesitationDurationMs: 300,
          recordedAt: now,
        ),
        PerformanceMetrics(
          id: 'pm_2',
          sessionId: 'ses_100',
          trialNumber: 2,
          stimulusId: 'photo_daughter_1',
          userResponse: 'daughter',
          isCorrect: true,
          responseTimeMs: 1700,
          hesitationDurationMs: 500,
          recordedAt: now,
        ),
      ];
      await gameSource.insertPerformanceMetrics(metrics);

      final fetchedMetrics = await gameSource.getMetricsForSession('ses_100');
      expect(fetchedMetrics.length, equals(2));
      expect(fetchedMetrics.first.stimulusId, equals('photo_son_1'));

      // Delete Session
      await gameSource.deleteSession('ses_100');
      expect(await gameSource.getSessionById('ses_100'), isNull);
    });

    test('Medication, Schedules, and Logs CRUD operations succeed', () async {
      final now = DateTime.now();

      // Seed parent User & Patient
      await userSource.createUser(User(
        id: 'u_med_user',
        phoneOrEmail: 'med@assam.in',
        role: UserRole.patient,
        fullName: 'Med Patient',
        createdAt: now,
        updatedAt: now,
      ));
      await patientSource.createPatient(Patient(
        id: 'p_med_patient',
        userId: 'u_med_user',
        displayName: 'Med Patient',
        createdAt: now,
        updatedAt: now,
      ));

      // 1. Insert Medication
      final med = Medication(
        id: 'med_1',
        patientId: 'p_med_patient',
        name: 'Donepezil',
        dosageDescription: '5mg once daily',
        instructions: 'After dinner with warm water',
        createdAt: now,
        updatedAt: now,
      );
      await medicationSource.insertMedication(med);

      final meds = await medicationSource.getMedicationsForPatient('p_med_patient');
      expect(meds.length, equals(1));
      expect(meds.first.name, equals('Donepezil'));

      // 2. Insert Schedule
      final schedule = MedicationSchedule(
        id: 'sch_1',
        medicationId: 'med_1',
        timeOfDay: '20:30',
        mealRelation: MealRelation.afterMeal,
        createdAt: now,
        updatedAt: now,
      );
      await medicationSource.insertSchedule(schedule);

      final schedules = await medicationSource.getSchedulesForMedication('med_1');
      expect(schedules.length, equals(1));
      expect(schedules.first.timeOfDay, equals('20:30'));

      // 3. Insert Log
      final log = MedicationLog(
        id: 'log_1',
        scheduleId: 'sch_1',
        scheduledTime: '20:30',
        status: MedicationLogStatus.taken,
        actionTimestamp: now,
        confirmedByRole: 'PATIENT',
        createdAt: now,
        updatedAt: now,
      );
      await medicationSource.insertLog(log);

      final logs = await medicationSource.getLogsForSchedule('sch_1');
      expect(logs.length, equals(1));
      expect(logs.first.status, equals(MedicationLogStatus.taken));

      // 4. Update Log status
      final updatedLog = MedicationLog(
        id: 'log_1',
        scheduleId: 'sch_1',
        scheduledTime: '20:30',
        status: MedicationLogStatus.snoozed,
        actionTimestamp: now,
        confirmedByRole: 'PATIENT',
        notes: 'Requested 15-minute delay',
        createdAt: now,
        updatedAt: DateTime.now(),
      );
      await medicationSource.updateLog(updatedLog);

      final readLog = await medicationSource.getLogsForSchedule('sch_1');
      expect(readLog.first.status, equals(MedicationLogStatus.snoozed));
      expect(readLog.first.notes, equals('Requested 15-minute delay'));

      // 5. Delete Schedule & Medication
      await medicationSource.deleteSchedule('sch_1');
      expect(await medicationSource.getSchedulesForMedication('med_1'), isEmpty);

      await medicationSource.deleteMedication('med_1');
      expect(await medicationSource.getMedicationById('med_1'), isNull);
    });

    test('SyncQueue, AuditLogs, and AppSettings CRUD operations succeed', () async {
      final now = DateTime.now();

      // SyncQueue: Enqueue item
      final syncItem = SyncItem(
        operationId: 'op_uuid_123',
        entityId: 'ses_100',
        entityType: 'GAME_SESSION',
        operationType: SyncOperationType.insert,
        payloadJson: '{"id":"ses_100"}',
        timestamp: now,
        retryCount: 0,
        syncStatus: SyncStatus.pending,
      );
      await syncSource.enqueue(syncItem);

      expect(await syncSource.getPendingCount(), equals(1));
      final pending = await syncSource.getPending();
      expect(pending.length, equals(1));
      expect(pending.first.operationId, equals('op_uuid_123'));

      // Update sync status to inProgress
      await syncSource.updateStatus(
        operationId: 'op_uuid_123',
        status: SyncStatus.inProgress,
      );

      // Mark completed
      await syncSource.markCompleted('op_uuid_123', 'ses_100', 'GAME_SESSION');
      expect(await syncSource.getPendingCount(), equals(0));

      // Delete completed
      await syncSource.deleteCompleted();
      expect(await syncSource.getPending(), isEmpty);

      // AuditLogs: Insert and read
      final auditLog = AuditLog(
        id: 'audit_1',
        actorId: 'user_1',
        actorRole: 'PATIENT',
        action: 'MEDICATION_DOSE_CONFIRMED',
        resourceType: 'MEDICATION_LOG',
        resourceId: 'log_1',
        detailsJson: '{"status":"TAKEN"}',
        timestamp: now,
      );
      await auditSource.insertAuditLog(auditLog);

      final auditLogs = await auditSource.getRecentLogs(limit: 10);
      expect(auditLogs.length, equals(1));
      expect(auditLogs.first.action, equals('MEDICATION_DOSE_CONFIRMED'));

      // AppSettings: Set, get, update, delete
      await settingsSource.setSetting('high_contrast_mode', 'true');
      final val1 = await settingsSource.getSetting('high_contrast_mode');
      expect(val1, equals('true'));

      await settingsSource.setSetting('high_contrast_mode', 'false');
      final val2 = await settingsSource.getSetting('high_contrast_mode');
      expect(val2, equals('false'));

      final allSettings = await settingsSource.getAllSettings();
      expect(allSettings['high_contrast_mode'], equals('false'));

      await settingsSource.deleteSetting('high_contrast_mode');
      expect(await settingsSource.getSetting('high_contrast_mode'), isNull);
    });

    // -------------------------------------------------------------
    // 2. Constraints Enforcement Tests
    // -------------------------------------------------------------
    test('Foreign key constraints reject orphan inserts and cascade delete', () async {
      final now = DateTime.now();

      // Attempting to insert a patient with non-existent user_id MUST fail
      final orphanPatient = Patient(
        id: 'p_orphan',
        userId: 'non_existent_user_999',
        displayName: 'Orphan Patient',
        createdAt: now,
        updatedAt: now,
      );
      expect(
        () async => await patientSource.createPatient(orphanPatient),
        throwsA(isA<DatabaseException>()),
      );

      // Now create valid parent User, Patient, and child GameSession
      await userSource.createUser(User(
        id: 'u_cascade_test',
        phoneOrEmail: 'cascade@assam.in',
        role: UserRole.patient,
        fullName: 'Cascade User',
        createdAt: now,
        updatedAt: now,
      ));
      await patientSource.createPatient(Patient(
        id: 'p_cascade_test',
        userId: 'u_cascade_test',
        displayName: 'Cascade Patient',
        createdAt: now,
        updatedAt: now,
      ));
      await gameSource.insertSession(GameSession(
        id: 'ses_cascade_test',
        patientId: 'p_cascade_test',
        gameType: GameType.familyFaceMatch,
        startTime: now,
        difficultyLevel: 1,
        createdAt: now,
        updatedAt: now,
      ));

      // Verify session exists
      expect(await gameSource.getSessionById('ses_cascade_test'), isNotNull);

      // Deleting parent User MUST cascade and delete Patient and Session
      await userSource.deleteUser('u_cascade_test');

      expect(await patientSource.getPatientById('p_cascade_test'), isNull);
      expect(await gameSource.getSessionById('ses_cascade_test'), isNull);
    });

    test('Unique and check constraints are enforced', () async {
      final now = DateTime.now();

      // Seed unique user
      await userSource.createUser(User(
        id: 'u_unique_1',
        phoneOrEmail: 'duplicate@assam.in',
        role: UserRole.patient,
        fullName: 'User One',
        createdAt: now,
        updatedAt: now,
      ));

      // Inserting duplicate phone_or_email with different ID MUST throw UniqueConstraint violation
      final duplicateUser = User(
        id: 'u_unique_2',
        phoneOrEmail: 'duplicate@assam.in',
        role: UserRole.caregiver,
        fullName: 'User Two',
        createdAt: now,
        updatedAt: now,
      );
      final rawDb = await dbHelper.database;
      expect(
        () async => await rawDb.insert(DatabaseConstants.tableUsers, duplicateUser.toMap()),
        throwsA(isA<DatabaseException>()),
      );

      // Check constraint: role MUST be 'PATIENT' or 'CAREGIVER'
      final invalidRoleUserMap = {
        'id': 'u_invalid_role',
        'phone_or_email': 'invalid@assam.in',
        'role': 'ADMIN_SUPERUSER', // Prohibited role
        'full_name': 'Invalid Role',
        'preferred_language': 'en',
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
        'is_synced': 0,
      };
      expect(
        () async => await rawDb.insert(DatabaseConstants.tableUsers, invalidRoleUserMap),
        throwsA(isA<DatabaseException>()),
      );
    });

    // -------------------------------------------------------------
    // 3. Database Migration Test (v1 to v2)
    // -------------------------------------------------------------
    test('Migration from Version 1 to Version 2 executes successfully', () async {
      // Create a separate in-memory database strictly at Version 1
      final v1Db = await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        onCreate: (db, version) async {
          final batch = db.batch();
          for (final query in DatabaseConstants.v1SchemaQueries) {
            batch.execute(query);
          }
          await batch.commit(noResult: true);
        },
      );

      // Verify v1 schema: sync_queue does not yet have device_client_id
      final v1Columns = await v1Db.rawQuery('PRAGMA table_info(${DatabaseConstants.tableSyncQueue});');
      final hasDeviceClientIdV1 = v1Columns.any((col) => col['name'] == 'device_client_id');
      expect(hasDeviceClientIdV1, isFalse);

      // Run migration to Version 2
      final migrationRunner = MigrationRunner(migrations: [const MigrationV1ToV2()]);
      await migrationRunner.runMigrations(v1Db, 1, 2);

      // Verify v2 schema: sync_queue now HAS device_client_id
      final v2Columns = await v1Db.rawQuery('PRAGMA table_info(${DatabaseConstants.tableSyncQueue});');
      final hasDeviceClientIdV2 = v2Columns.any((col) => col['name'] == 'device_client_id');
      expect(hasDeviceClientIdV2, isTrue);

      // Verify v2 schema: game_results now HAS is_flagged column
      final v2ResultCols = await v1Db.rawQuery('PRAGMA table_info(${DatabaseConstants.tableGameResults});');
      final hasIsFlaggedV2 = v2ResultCols.any((col) => col['name'] == 'is_flagged');
      expect(hasIsFlaggedV2, isTrue);

      await v1Db.close();
    });
  });
}
