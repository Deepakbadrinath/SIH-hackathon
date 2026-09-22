import 'package:flutter/foundation.dart';

import '../../data/datasources/local/caregiver_local_data_source.dart';
import '../../data/datasources/local/game_local_data_source.dart';
import '../../data/datasources/local/medication_local_data_source.dart';
import '../../data/datasources/local/patient_local_data_source.dart';
import '../../data/datasources/local/user_local_data_source.dart';

import '../../domain/models/caregiver.dart';
import '../../domain/models/game_models.dart';
import '../../domain/models/medication_models.dart';
import '../../domain/models/patient.dart';
import '../../domain/models/user.dart';

import '../database/database_constants.dart';
import '../database/database_helper.dart';

/// Robust, repeatable Demo & Synthetic Data Manager for Smart India Hackathon (SIH) demonstrations.
///
/// Features:
/// 1. Completely offline and local SQLite backed (zero unreliable external dependencies).
/// 2. Clearly labeled synthetic patient, caregiver, cognitive game, and medication adherence data.
/// 3. Instant 1-click deterministic reset to baseline so judges can repeat the flow reliably.
class DemoDataManager {
  static const String demoPatientId = 'patient_1';
  static const String demoPatientName = 'Deka Da (দাদা)';
  static const String demoCaregiverId = 'caregiver_demo_1';
  static const String demoCaregiverName = 'Dr. Ananya Sharma';

  /// Seeds or updates baseline synthetic demo records.
  static Future<void> seedDemoData({
    required DatabaseHelper dbHelper,
    bool resetExisting = false,
  }) async {
    if (resetExisting) {
      await purgeAllData(dbHelper: dbHelper);
    } else {
      final userDataSource = UserLocalDataSourceImpl(dbHelper: dbHelper);
      final existing = await userDataSource.getUserById(demoPatientId);
      if (existing != null) {
        // Baseline data is already present; bypass redundant disk writes on warm launch
        return;
      }
    }

    final userDataSource = UserLocalDataSourceImpl(dbHelper: dbHelper);
    final patientDataSource = PatientLocalDataSourceImpl(dbHelper: dbHelper);
    final caregiverDataSource = CaregiverLocalDataSourceImpl(dbHelper: dbHelper);
    final relDataSource = RelationshipLocalDataSourceImpl(dbHelper: dbHelper);
    final gameDataSource = GameLocalDataSourceImpl(dbHelper: dbHelper);
    final medicationDataSource = MedicationLocalDataSourceImpl(dbHelper: dbHelper);

    final now = DateTime.now();

    // -------------------------------------------------------------
    // 1. Synthetic Patients
    // -------------------------------------------------------------
    final p1User = User(
      id: demoPatientId,
      phoneOrEmail: 'deka.da@smritisetu.org',
      role: UserRole.patient,
      fullName: demoPatientName,
      preferredLanguage: 'as',
      createdAt: now.subtract(const Duration(days: 30)),
      updatedAt: now,
      isSynced: true,
    );
    await userDataSource.createUser(p1User);

    final p1 = Patient(
      id: demoPatientId,
      userId: demoPatientId,
      displayName: demoPatientName,
      birthYear: 1948,
      emergencyContactPhone: '+91 98765 43210',
      regionalDialect: 'as_IN',
      highContrastEnabled: false,
      audioInstructionsEnabled: true,
      fontScale: 1.25,
      createdAt: now.subtract(const Duration(days: 30)),
      updatedAt: now,
      isSynced: true,
    );
    await patientDataSource.createPatient(p1);

    final p2User = User(
      id: 'patient_2',
      phoneOrEmail: 'baruah@smritisetu.org',
      role: UserRole.patient,
      fullName: 'Baruah Baideo (বাইদেউ)',
      preferredLanguage: 'as',
      createdAt: now.subtract(const Duration(days: 20)),
      updatedAt: now,
      isSynced: true,
    );
    await userDataSource.createUser(p2User);

    final p2 = Patient(
      id: 'patient_2',
      userId: 'patient_2',
      displayName: 'Baruah Baideo (বাইদেউ)',
      birthYear: 1952,
      emergencyContactPhone: '+91 98765 11223',
      regionalDialect: 'as_IN',
      createdAt: now.subtract(const Duration(days: 20)),
      updatedAt: now,
      isSynced: true,
    );
    await patientDataSource.createPatient(p2);

    // -------------------------------------------------------------
    // 2. Synthetic Caregiver & Authorization Relationships
    // -------------------------------------------------------------
    final cgUser = User(
      id: demoCaregiverId,
      phoneOrEmail: 'ananya@smritisetu.org',
      role: UserRole.caregiver,
      fullName: demoCaregiverName,
      preferredLanguage: 'en',
      createdAt: now.subtract(const Duration(days: 30)),
      updatedAt: now,
      isSynced: true,
    );
    await userDataSource.createUser(cgUser);

    final caregiver = Caregiver(
      id: demoCaregiverId,
      userId: demoCaregiverId,
      fullName: demoCaregiverName,
      relationshipToPatient: 'Primary Certified Caregiver',
      phone: '+91 99887 76655',
      alertNotificationsEnabled: true,
      createdAt: now.subtract(const Duration(days: 30)),
      updatedAt: now,
      isSynced: true,
    );
    await caregiverDataSource.createCaregiver(caregiver);

    await relDataSource.createRelationship(PatientCaregiverRelation(
      id: 'rel_demo_p1',
      caregiverId: demoCaregiverId,
      patientId: demoPatientId,
      accessRole: CaregiverAccessRole.primary,
      isActive: true,
      createdAt: now.subtract(const Duration(days: 30)),
      updatedAt: now,
      isSynced: true,
    ));

    await relDataSource.createRelationship(PatientCaregiverRelation(
      id: 'rel_demo_p2',
      caregiverId: demoCaregiverId,
      patientId: 'patient_2',
      accessRole: CaregiverAccessRole.secondary,
      isActive: true,
      createdAt: now.subtract(const Duration(days: 20)),
      updatedAt: now,
      isSynced: true,
    ));

    // -------------------------------------------------------------
    // 3. Synthetic Medications & Schedules
    // -------------------------------------------------------------
    final med1 = Medication(
      id: 'med_donepezil_demo',
      patientId: demoPatientId,
      name: 'Donepezil',
      dosageDescription: '5mg - 1 tablet daily after breakfast',
      instructions: 'Take with half glass of water. Do not crush.',
      isActive: true,
      createdAt: now.subtract(const Duration(days: 30)),
      updatedAt: now,
      isSynced: true,
    );
    await medicationDataSource.insertMedication(med1);

    final sched1 = MedicationSchedule(
      id: 'sched_donepezil_demo',
      medicationId: 'med_donepezil_demo',
      timeOfDay: '08:00',
      mealRelation: MealRelation.afterMeal,
      daysOfWeek: '1,2,3,4,5,6,7',
      isActive: true,
      createdAt: now.subtract(const Duration(days: 30)),
      updatedAt: now,
      isSynced: true,
    );
    await medicationDataSource.insertSchedule(sched1);

    final med2 = Medication(
      id: 'med_memantine_demo',
      patientId: demoPatientId,
      name: 'Memantine',
      dosageDescription: '10mg - 1 tablet after dinner',
      instructions: 'Take daily at bedtime.',
      isActive: true,
      createdAt: now.subtract(const Duration(days: 30)),
      updatedAt: now,
      isSynced: true,
    );
    await medicationDataSource.insertMedication(med2);

    final sched2 = MedicationSchedule(
      id: 'sched_memantine_demo',
      medicationId: 'med_memantine_demo',
      timeOfDay: '20:00',
      mealRelation: MealRelation.afterMeal,
      daysOfWeek: '1,2,3,4,5,6,7',
      isActive: true,
      createdAt: now.subtract(const Duration(days: 30)),
      updatedAt: now,
      isSynced: true,
    );
    await medicationDataSource.insertSchedule(sched2);

    // Seed 14 Days of Medication Adherence Logs (High Adherence Trend)
    for (int day = 14; day >= 1; day--) {
      final logDate = now.subtract(Duration(days: day));
      final log1 = MedicationLog(
        id: 'log_donepezil_d$day',
        scheduleId: 'sched_donepezil_demo',
        scheduledTime: '08:00',
        status: MedicationLogStatus.taken,
        actionTimestamp: DateTime(logDate.year, logDate.month, logDate.day, 8, 12),
        confirmedByRole: 'CAREGIVER',
        notes: '[SYNTHETIC DEMO LOG] Observed taking dose with breakfast',
        createdAt: logDate,
        updatedAt: logDate,
        isSynced: true,
      );
      await medicationDataSource.insertLog(log1);

      // Night dose: 1 missed 9 days ago to show realistic non-clinical trend
      final isMissed = day == 9;
      final log2 = MedicationLog(
        id: 'log_memantine_d$day',
        scheduleId: 'sched_memantine_demo',
        scheduledTime: '20:00',
        status: isMissed ? MedicationLogStatus.missed : MedicationLogStatus.taken,
        actionTimestamp: isMissed
            ? DateTime(logDate.year, logDate.month, logDate.day, 21, 30)
            : DateTime(logDate.year, logDate.month, logDate.day, 20, 15),
        confirmedByRole: 'PATIENT',
        notes: isMissed ? '[SYNTHETIC DEMO LOG] Patient was asleep early' : '[SYNTHETIC DEMO LOG] Taken after dinner',
        createdAt: logDate,
        updatedAt: logDate,
        isSynced: true,
      );
      await medicationDataSource.insertLog(log2);
    }

    // -------------------------------------------------------------
    // 4. Historical Cognitive Game Sessions & Results
    // -------------------------------------------------------------
    final historicalSessions = [
      {
        'id': 'sess_face_d10',
        'type': GameType.familyFaceMatch,
        'daysAgo': 10,
        'diff': 1,
        'accuracy': 80.0,
        'speed': 2350.0,
        'score': 80,
      },
      {
        'id': 'sess_pattern_d8',
        'type': GameType.patternCompletion,
        'daysAgo': 8,
        'diff': 1,
        'accuracy': 84.0,
        'speed': 2100.0,
        'score': 85,
      },
      {
        'id': 'sess_face_d6',
        'type': GameType.familyFaceMatch,
        'daysAgo': 6,
        'diff': 1,
        'accuracy': 90.0,
        'speed': 1900.0,
        'score': 90,
      },
      {
        'id': 'sess_seq_d4',
        'type': GameType.activitySequence,
        'daysAgo': 4,
        'diff': 1,
        'accuracy': 92.0,
        'speed': 1850.0,
        'score': 92,
      },
      {
        'id': 'sess_face_d2',
        'type': GameType.familyFaceMatch,
        'daysAgo': 2,
        'diff': 1,
        'accuracy': 95.0,
        'speed': 1720.0,
        'score': 96,
      },
      {
        'id': 'sess_sort_d1',
        'type': GameType.objectSorting,
        'daysAgo': 1,
        'diff': 1,
        'accuracy': 96.0,
        'speed': 1650.0,
        'score': 98,
      },
    ];

    for (final s in historicalSessions) {
      final daysAgo = s['daysAgo'] as int;
      final sessionTime = now.subtract(Duration(days: daysAgo, hours: 2));
      final type = s['type'] as GameType;
      final sessionId = s['id'] as String;

      final session = GameSession(
        id: sessionId,
        patientId: demoPatientId,
        gameType: type,
        startTime: sessionTime,
        endTime: sessionTime.add(const Duration(minutes: 3)),
        difficultyLevel: s['diff'] as int,
        isCompleted: true,
        createdAt: sessionTime,
        updatedAt: sessionTime,
        isSynced: true,
      );
      await gameDataSource.insertSession(session);

      final result = GameResult(
        id: 'res_$sessionId',
        sessionId: sessionId,
        gameType: type,
        score: s['score'] as int,
        maxPossibleScore: 100,
        accuracyPercentage: (s['accuracy'] as num).toDouble(),
        totalTrials: 5,
        correctTrials: 4,
        errorCount: 1,
        avgResponseTimeMs: (s['speed'] as num).toDouble(),
        totalHesitationPauseMs: 450.0,
        completedAt: sessionTime.add(const Duration(minutes: 3)),
        createdAt: sessionTime,
        updatedAt: sessionTime,
        isSynced: true,
      );
      await gameDataSource.insertResult(result);
    }

    if (kDebugMode) {
      print('SIH Demo Mode: Baseline synthetic dataset successfully seeded.');
    }
  }

  /// Completely resets all database tables to clean initial state.
  static Future<void> purgeAllData({required DatabaseHelper dbHelper}) async {
    final db = await dbHelper.database;
    await db.transaction((txn) async {
      await txn.delete(DatabaseConstants.tableAuditLogs);
      await txn.delete(DatabaseConstants.tableSyncQueue);
      await txn.delete(DatabaseConstants.tableMedicationLogs);
      await txn.delete(DatabaseConstants.tableMedicationSchedules);
      await txn.delete(DatabaseConstants.tableMedications);
      await txn.delete(DatabaseConstants.tableDifficultyHistory);
      await txn.delete(DatabaseConstants.tablePerformanceMetrics);
      await txn.delete(DatabaseConstants.tableGameResults);
      await txn.delete(DatabaseConstants.tableGameSessions);
      await txn.delete(DatabaseConstants.tableCaregiverPatientRelationships);
      await txn.delete(DatabaseConstants.tableCaregivers);
      await txn.delete(DatabaseConstants.tablePatients);
      await txn.delete(DatabaseConstants.tableUsers);
    });
  }
}
