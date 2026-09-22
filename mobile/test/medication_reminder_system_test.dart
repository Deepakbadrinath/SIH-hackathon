import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:smriti_setu/core/config/app_config.dart';
import 'package:smriti_setu/core/localization/app_localizations.dart';
import 'package:smriti_setu/core/theme/accessible_theme.dart';
import 'package:smriti_setu/domain/models/medication_models.dart';
import 'package:smriti_setu/domain/repositories/medication_repository.dart';
import 'package:smriti_setu/domain/services/notification_service.dart';
import 'package:smriti_setu/features/medication/data/services/local_notification_service.dart';
import 'package:smriti_setu/features/medication/data/services/medication_reminder_scheduler.dart';
import 'package:smriti_setu/features/medication/presentation/controllers/medication_controller.dart';
import 'package:smriti_setu/features/voice/data/services/voice_service_impl.dart';
import 'package:smriti_setu/features/voice/presentation/controllers/voice_controller.dart';
import 'package:smriti_setu/presentation/common_widgets/disclaimer_banner.dart';
import 'package:smriti_setu/presentation/screens/medication/medication_screen.dart';
import 'package:smriti_setu/presentation/screens/medication/widgets/medication_edit_dialog.dart';

/// In-memory mock implementation of MedicationRepository for isolated, fast unit and widget testing.
class MockMedicationRepository implements MedicationRepository {
  final Map<String, Medication> _medications = {};
  final Map<String, List<MedicationSchedule>> _schedules = {};
  final List<MedicationLog> _logs = [];

  void seedInitialData() {
    final now = DateTime.now();
    final med1 = Medication(
      id: 'med_1',
      patientId: 'p_1',
      name: 'Donepezil',
      dosageDescription: '5mg - 1 tablet after breakfast',
      instructions: 'Take with full glass of water',
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );

    final sched1 = MedicationSchedule(
      id: 'sched_1',
      medicationId: 'med_1',
      timeOfDay: '08:00',
      mealRelation: MealRelation.afterMeal,
      daysOfWeek: '1,2,3,4,5,6,7',
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );

    final med2 = Medication(
      id: 'med_2',
      patientId: 'p_1',
      name: 'Multivitamin',
      dosageDescription: '1 capsule after lunch',
      instructions: 'Do not crush',
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );

    final sched2 = MedicationSchedule(
      id: 'sched_2',
      medicationId: 'med_2',
      timeOfDay: '13:30',
      mealRelation: MealRelation.afterMeal,
      daysOfWeek: '1,2,3,4,5,6,7',
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );

    _medications[med1.id] = med1;
    _schedules[med1.id] = [sched1];

    _medications[med2.id] = med2;
    _schedules[med2.id] = [sched2];
  }

  @override
  Future<List<Medication>> getMedicationsForPatient(String patientId) async {
    return _medications.values.where((m) => m.patientId == patientId && m.isActive).toList();
  }

  @override
  Future<Medication?> getMedicationById(String id) async {
    return _medications[id];
  }

  @override
  Future<void> saveMedication(Medication medication) async {
    _medications[medication.id] = medication;
  }

  @override
  Future<void> updateMedication(Medication medication) async {
    _medications[medication.id] = medication;
  }

  @override
  Future<void> deleteMedication(String id) async {
    _medications.remove(id);
    _schedules.remove(id);
  }

  @override
  Future<List<MedicationSchedule>> getSchedulesForMedication(String medicationId) async {
    return _schedules[medicationId] ?? [];
  }

  @override
  Future<List<MedicationSchedule>> getAllActiveSchedulesForPatient(String patientId) async {
    final List<MedicationSchedule> result = [];
    for (final med in _medications.values) {
      if (med.patientId == patientId && med.isActive) {
        final scheds = _schedules[med.id] ?? [];
        result.addAll(scheds.where((s) => s.isActive));
      }
    }
    return result;
  }

  @override
  Future<void> saveMedicationSchedule(MedicationSchedule schedule) async {
    final list = _schedules[schedule.medicationId] ?? [];
    list.add(schedule);
    _schedules[schedule.medicationId] = list;
  }

  @override
  Future<void> updateMedicationSchedule(MedicationSchedule schedule) async {
    final list = _schedules[schedule.medicationId] ?? [];
    final idx = list.indexWhere((s) => s.id == schedule.id);
    if (idx >= 0) {
      list[idx] = schedule;
    }
  }

  @override
  Future<void> deleteMedicationSchedule(String id) async {
    for (final key in _schedules.keys) {
      _schedules[key]?.removeWhere((s) => s.id == id);
    }
  }

  @override
  Future<List<MedicationLog>> getLogsForSchedule(String scheduleId, {int limit = 20}) async {
    final filtered = _logs.where((l) => l.scheduleId == scheduleId).toList();
    filtered.sort((a, b) => b.actionTimestamp.compareTo(a.actionTimestamp));
    return filtered.take(limit).toList();
  }

  @override
  Future<List<MedicationLog>> getMedicationHistory(String patientId, {int limit = 50}) async {
    final sorted = List<MedicationLog>.from(_logs);
    sorted.sort((a, b) => b.actionTimestamp.compareTo(a.actionTimestamp));
    return sorted.take(limit).toList();
  }

  @override
  Future<void> recordMedicationAction({
    required String scheduleId,
    required String scheduledTime,
    required MedicationLogStatus status,
    required String confirmedByRole,
    String? notes,
  }) async {
    final now = DateTime.now();
    final log = MedicationLog(
      id: 'log_${now.millisecondsSinceEpoch}_${_logs.length}',
      scheduleId: scheduleId,
      scheduledTime: scheduledTime,
      status: status,
      actionTimestamp: now,
      confirmedByRole: confirmedByRole,
      notes: notes,
      createdAt: now,
      updatedAt: now,
    );
    _logs.add(log);
  }

  @override
  Future<List<MedicationReminderItem>> getTodayReminders(String patientId, {DateTime? forDate}) async {
    final targetDate = forDate ?? DateTime.now();
    final dayOfWeekStr = targetDate.weekday.toString();
    final List<MedicationReminderItem> items = [];

    for (final med in _medications.values) {
      if (med.patientId != patientId || !med.isActive) continue;
      final schedules = _schedules[med.id] ?? [];

      for (final sched in schedules) {
        if (!sched.isActive) continue;
        final days = sched.daysOfWeek.split(',').map((s) => s.trim()).toSet();
        if (!days.contains(dayOfWeekStr)) continue;

        final parts = sched.timeOfDay.split(':');
        final hour = int.tryParse(parts[0]) ?? 8;
        final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
        final scheduledDateTime = DateTime(targetDate.year, targetDate.month, targetDate.day, hour, minute);

        // Find log on this date
        MedicationLog? matchingLog;
        for (final log in _logs) {
          if (log.scheduleId == sched.id &&
              log.actionTimestamp.year == targetDate.year &&
              log.actionTimestamp.month == targetDate.month &&
              log.actionTimestamp.day == targetDate.day) {
            matchingLog = log;
            break;
          }
        }

        final now = DateTime.now();
        final diff = now.difference(scheduledDateTime).inMinutes;
        final isDueNow = diff >= -30 && diff <= 60 && matchingLog == null;
        final isOverdue = diff > 60 && matchingLog == null;

        items.add(MedicationReminderItem(
          medication: med,
          schedule: sched,
          scheduledDateTime: scheduledDateTime,
          status: matchingLog?.status,
          log: matchingLog,
          isDueNow: isDueNow,
          isOverdue: isOverdue,
        ));
      }
    }
    items.sort((a, b) => a.scheduledDateTime.compareTo(b.scheduledDateTime));
    return items;
  }

  @override
  Future<List<MedicationReminderItem>> getUpcomingReminders(
    String patientId, {
    int daysAhead = 7,
    DateTime? fromDate,
  }) async {
    final start = fromDate ?? DateTime.now();
    final List<MedicationReminderItem> list = [];

    for (int d = 0; d < daysAhead; d++) {
      final date = start.add(Duration(days: d));
      final dayItems = await getTodayReminders(patientId, forDate: date);
      for (final item in dayItems) {
        if (item.scheduledDateTime.isAfter(start) && !item.isTaken) {
          list.add(item);
        }
      }
    }
    list.sort((a, b) => a.scheduledDateTime.compareTo(b.scheduledDateTime));
    return list;
  }

  @override
  Future<List<MedicationReminderItem>> getCompletedReminders(String patientId, {DateTime? forDate}) async {
    final today = await getTodayReminders(patientId, forDate: forDate);
    return today.where((r) => r.isTaken).toList();
  }

  @override
  Future<List<MedicationReminderItem>> getMissedReminders(String patientId, {DateTime? forDate}) async {
    final today = await getTodayReminders(patientId, forDate: forDate);
    return today.where((r) => r.isMissed || r.isSkipped).toList();
  }

  @override
  Future<double> getAdherenceRate(String patientId, {int days = 7}) async {
    if (_logs.isEmpty) return 94.2;
    final taken = _logs.where((l) => l.status == MedicationLogStatus.taken).length;
    return double.parse(((taken / _logs.length) * 100).toStringAsFixed(1));
  }

  @override
  Future<int> getMissedDosesCount(String patientId, {int days = 7}) async {
    return _logs.where((l) => l.status == MedicationLogStatus.missed).length;
  }
}

class _TestMedLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _TestMedLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale, const {
      'medication.title': 'Medication Schedule',
      'medication.today_schedule': "Today's Schedule",
      'medication.schedule_subtitle': 'Keep track of daily medicines',
      'medication.audio_prompt': 'This is your medication schedule screen.',
      'medication.time_morning': 'Morning',
      'medication.time_afternoon': 'Afternoon',
      'medication.time_evening': 'Evening',
      'medication.button.taken': 'I Have Taken It',
      'medication.button.snooze': 'Remind Me in 15 Min',
      'common.button.back': 'Back',
      'common.button.cancel': 'Cancel',
      'common.audio.listen': 'Listen Aloud',
    });
  }

  @override
  bool shouldReload(_TestMedLocalizationsDelegate old) => false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    AppConfig.initialize(Environment.development);
  });

  group('Phase 12: Non-Prescription Safety & Domain Boundaries', () {
    test('Preserves user-entered dosage text without inventing medical recommendations', () {
      const caregiverEnteredDosage = 'Take 1 blue capsule with warm milk after dinner';
      final med = Medication(
        id: 'med_test_1',
        patientId: 'patient_1',
        name: 'Calcium + Vitamin D',
        dosageDescription: caregiverEnteredDosage,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // System preserves exact authorized text without modification
      expect(med.dosageDescription, equals(caregiverEnteredDosage));
      expect(med.name, equals('Calcium + Vitamin D'));
    });

    test('MedicationReminderItem accurately identifies status states', () {
      final now = DateTime.now();
      final med = Medication(
        id: 'med_1',
        patientId: 'p_1',
        name: 'Aspirin',
        dosageDescription: '75mg',
        createdAt: now,
        updatedAt: now,
      );
      final sched = MedicationSchedule(
        id: 'sched_1',
        medicationId: 'med_1',
        timeOfDay: '08:00',
        createdAt: now,
        updatedAt: now,
      );

      // Pending
      final pendingItem = MedicationReminderItem(
        medication: med,
        schedule: sched,
        scheduledDateTime: now,
        status: null,
      );
      expect(pendingItem.isPending, isTrue);
      expect(pendingItem.isTaken, isFalse);

      // Taken
      final takenItem = pendingItem.copyWith(status: MedicationLogStatus.taken);
      expect(takenItem.isTaken, isTrue);
      expect(takenItem.isPending, isFalse);

      // Skipped
      final skippedItem = pendingItem.copyWith(status: MedicationLogStatus.skipped);
      expect(skippedItem.isSkipped, isTrue);

      // Overdue becomes Missed
      final overdueItem = pendingItem.copyWith(isOverdue: true);
      expect(overdueItem.isMissed, isTrue);
    });
  });

  group('Phase 12: Categorized Reminders & Caregiver CRUD', () {
    late MockMedicationRepository repository;
    late MedicationController controller;
    late LocalNotificationService notificationService;
    late MedicationReminderScheduler scheduler;

    setUp(() {
      repository = MockMedicationRepository()..seedInitialData();
      notificationService = LocalNotificationService();
      scheduler = MedicationReminderScheduler(
        repository: repository,
        notificationService: notificationService,
      );
      controller = MedicationController(
        repository: repository,
        scheduler: scheduler,
      );
    });

    test('Loads and categorizes Today Reminders for patient', () async {
      await controller.loadMedicationData('p_1');

      expect(controller.medications.length, equals(2));
      expect(controller.todayReminders.length, equals(2));
      expect(controller.todayReminders.first.medication.name, equals('Donepezil'));
      expect(controller.todayReminders.last.medication.name, equals('Multivitamin'));
    });

    test('Records dose taken and updates Completed Reminders category', () async {
      await controller.loadMedicationData('p_1');
      expect(controller.completedReminders.length, equals(0));

      final firstDose = controller.todayReminders.first;
      await controller.markDoseTaken(
        scheduleId: firstDose.schedule.id,
        scheduledTime: firstDose.schedule.timeOfDay,
        confirmedByRole: 'PATIENT',
      );

      expect(controller.completedReminders.length, equals(1));
      expect(controller.completedReminders.first.isTaken, isTrue);
      expect(controller.historyLogs.length, equals(1));
      expect(controller.historyLogs.first.status, equals(MedicationLogStatus.taken));
    });

    test('Records dose skipped with reason and moves to Missed/Skipped category', () async {
      await controller.loadMedicationData('p_1');

      final secondDose = controller.todayReminders.last;
      await controller.markDoseSkipped(
        scheduleId: secondDose.schedule.id,
        scheduledTime: secondDose.schedule.timeOfDay,
        reason: 'Upset stomach',
      );

      expect(controller.missedReminders.any((r) => r.isSkipped && r.schedule.id == secondDose.schedule.id), isTrue);
      expect(controller.historyLogs.first.notes, equals('Upset stomach'));
    });

    test('Caregiver can add new medication with custom dosage text and schedule', () async {
      await controller.loadMedicationData('p_1');
      final countBefore = controller.medications.length;

      await controller.addMedicationWithSchedule(
        name: 'Blood Pressure Pill',
        dosageDescription: 'Amlodipine 5mg - 1 tablet',
        timeOfDay: '20:00',
        mealRelation: MealRelation.afterMeal,
        instructions: 'Take after dinner',
      );

      expect(controller.medications.length, equals(countBefore + 1));
      expect(controller.todayReminders.any((r) => r.medication.name == 'Blood Pressure Pill'), isTrue);
    });

    test('Caregiver can edit existing medication and toggle active/inactive status', () async {
      await controller.loadMedicationData('p_1');
      final med = controller.medications.first;

      final updated = med.copyWith(
        name: 'Donepezil Hydrochloride',
        dosageDescription: '10mg increased dose by caregiver',
      );

      await controller.updateMedication(updated);
      final reloaded = await repository.getMedicationById(med.id);
      expect(reloaded?.name, equals('Donepezil Hydrochloride'));
      expect(reloaded?.dosageDescription, equals('10mg increased dose by caregiver'));

      // Toggle inactive
      await controller.toggleMedicationActive(reloaded!);
      final deactivated = await repository.getMedicationById(med.id);
      expect(deactivated?.isActive, isFalse);
    });

    test('Caregiver can delete medication', () async {
      await controller.loadMedicationData('p_1');
      final medId = controller.medications.first.id;

      await controller.deleteMedication(medId);
      final deleted = await repository.getMedicationById(medId);
      expect(deleted, isNull);
    });
  });

  group('Phase 12: Notification Service Abstraction & Edge Cases', () {
    late LocalNotificationService notifService;

    setUp(() {
      notifService = LocalNotificationService();
    });

    test('Schedules reminder notification when permission is granted', () async {
      final scheduledTime = DateTime.now().add(const Duration(hours: 2));
      const notifId = 1001;

      await notifService.scheduleNotification(
        id: notifId,
        title: 'Medication Alert',
        body: 'Take 1 tablet of Donepezil',
        scheduledDateTime: scheduledTime,
      );

      final pending = await notifService.getPendingNotifications();
      expect(pending.length, equals(1));
      expect(pending.first.id, equals(notifId));
      expect(pending.first.title, equals('Medication Alert'));
    });

    test('Suppresses scheduling when notification permission is denied or permanently denied', () async {
      notifService.setMockPermission(NotificationPermissionStatus.denied);
      final scheduledTime = DateTime.now().add(const Duration(hours: 2));

      await notifService.scheduleNotification(
        id: 2002,
        title: 'Medication Alert',
        body: 'Take 1 tablet',
        scheduledDateTime: scheduledTime,
      );

      var pending = await notifService.getPendingNotifications();
      expect(pending.isEmpty, isTrue, reason: 'Must not schedule when permission denied');

      notifService.setMockPermission(NotificationPermissionStatus.permanentlyDenied);
      await notifService.scheduleNotification(
        id: 2003,
        title: 'Medication Alert',
        body: 'Take 1 tablet',
        scheduledDateTime: scheduledTime,
      );

      pending = await notifService.getPendingNotifications();
      expect(pending.isEmpty, isTrue, reason: 'Must not schedule when permission permanently denied');
    });

    test('Suppresses duplicate notifications using deterministic scheduling IDs', () async {
      final scheduledTime = DateTime(2026, 9, 15, 8, 0);
      const scheduleId = 'sched_morning_dose';

      final id1 = notifService.generateDeterministicId(scheduleId, scheduledTime);
      final id2 = notifService.generateDeterministicId(scheduleId, scheduledTime);

      expect(id1, equals(id2), reason: 'Deterministic ID must match for identical schedule & day');

      // Schedule first
      await notifService.scheduleNotification(
        id: id1,
        title: 'First Alert',
        body: 'Take morning medicine',
        scheduledDateTime: scheduledTime,
      );

      // Schedule duplicate
      await notifService.scheduleNotification(
        id: id2,
        title: 'Updated Alert',
        body: 'Take morning medicine (updated text)',
        scheduledDateTime: scheduledTime,
      );

      final pending = await notifService.getPendingNotifications();
      expect(pending.length, equals(1), reason: 'Duplicate notification must be cleanly replaced without duplicate firing');
      expect(pending.first.title, equals('Updated Alert'));
    });

    test('Handles device restart by re-registering active database schedules', () async {
      final now = DateTime.now();
      final med = Medication(
        id: 'med_restart',
        patientId: 'p_1',
        name: 'Blood Pressure Med',
        dosageDescription: '1 tablet',
        createdAt: now,
        updatedAt: now,
      );
      final sched = MedicationSchedule(
        id: 'sched_restart',
        medicationId: 'med_restart',
        timeOfDay: '09:00',
        createdAt: now,
        updatedAt: now,
      );

      // Precondition: 0 pending notifications after reboot
      await notifService.cancelAllNotifications();
      expect((await notifService.getPendingNotifications()).isEmpty, isTrue);

      // Trigger recovery on device restart
      await notifService.handleDeviceRestart([sched], {med.id: med});

      final rehydrated = await notifService.getPendingNotifications();
      expect(rehydrated.length, equals(1));
      expect(rehydrated.first.title, contains('Blood Pressure Med'));
    });

    test('Adjusts notification triggers on timezone offset shift', () async {
      final now = DateTime.now();
      final med = Medication(
        id: 'med_tz',
        patientId: 'p_1',
        name: 'Thyroid Medication',
        dosageDescription: '1 tablet before breakfast',
        createdAt: now,
        updatedAt: now,
      );
      final sched = MedicationSchedule(
        id: 'sched_tz',
        medicationId: 'med_tz',
        timeOfDay: '07:00',
        createdAt: now,
        updatedAt: now,
      );

      // Device shifts timezone from UTC+0 to UTC+5:30
      notifService.setMockTimezoneOffset(const Duration(hours: 5, minutes: 30));
      await notifService.handleTimezoneChange([sched], {med.id: med});

      final pending = await notifService.getPendingNotifications();
      expect(pending.length, equals(1));
      expect(pending.first.title, contains('Thyroid Medication'));
    });
  });

  group('Phase 12: UI Widgets & User Interactions', () {
    late MockMedicationRepository repository;
    late MedicationController controller;
    late LocalNotificationService notificationService;
    late MedicationReminderScheduler scheduler;
    late VoiceController voiceController;

    setUp(() {
      repository = MockMedicationRepository()..seedInitialData();
      notificationService = LocalNotificationService();
      scheduler = MedicationReminderScheduler(
        repository: repository,
        notificationService: notificationService,
      );
      controller = MedicationController(
        repository: repository,
        scheduler: scheduler,
      );
      voiceController = VoiceController(voiceService: VoiceServiceImpl());
    });

    Widget createTestApp(Widget child) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<MedicationController>.value(value: controller),
          ChangeNotifierProvider<VoiceController>.value(value: voiceController),
        ],
        child: MaterialApp(
          theme: AccessibleTheme.getLightTheme(),
          localizationsDelegates: const [
            _TestMedLocalizationsDelegate(),
          ],
          supportedLocales: const [Locale('en')],
          home: child,
        ),
      );
    }

    testWidgets('MedicationScreen renders disclaimer banner and category filter chips', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestApp(const MedicationScreen(patientId: 'p_1')));
      await tester.pumpAndSettle();

      expect(find.byType(MedicationScreen), findsOneWidget);
      expect(find.byType(DisclaimerBanner), findsOneWidget);
      expect(find.text("Today's Reminders"), findsOneWidget);
      expect(find.text("Upcoming"), findsOneWidget);
      expect(find.text("Completed"), findsOneWidget);
      expect(find.text("Missed / Skipped"), findsOneWidget);
      expect(find.text("History"), findsOneWidget);
      expect(find.text('Add Medication (Caregiver)'), findsOneWidget);
    });

    testWidgets('Tapping Take Dose updates UI to completed status', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestApp(const MedicationScreen(patientId: 'p_1')));
      await tester.pumpAndSettle();

      expect(find.text('Donepezil'), findsOneWidget);
      expect(find.text('Take Dose'), findsWidgets);

      // Tap Take Dose on the first card
      await tester.tap(find.text('Take Dose').first);
      await tester.pumpAndSettle();

      expect(find.text('Dose recorded as taken.'), findsOneWidget);
    });

    testWidgets('Switching category tab to Completed shows taken doses', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestApp(const MedicationScreen(patientId: 'p_1')));
      await tester.pumpAndSettle();

      // Take first dose
      await tester.tap(find.text('Take Dose').first);
      await tester.pumpAndSettle();

      // Tap Completed tab
      await tester.tap(find.text('Completed'));
      await tester.pumpAndSettle();

      expect(find.text('Donepezil'), findsOneWidget);
      expect(find.text('TAKEN'), findsOneWidget);
    });

    testWidgets('Caregiver Add Medication dialog opens and validates user entry', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestApp(const MedicationScreen(patientId: 'p_1')));
      await tester.pumpAndSettle();

      // Tap Add Medication button
      await tester.tap(find.text('Add Medication (Caregiver)').first);
      await tester.pumpAndSettle();

      expect(find.byType(MedicationEditDialog), findsOneWidget);
      expect(find.text('Add Medication Reminder'), findsOneWidget);
      expect(find.text('Medication Name *'), findsOneWidget);
      expect(find.text('Dosage Text *'), findsOneWidget);

      // Attempt to submit empty form to trigger validation
      await tester.tap(find.text('Create Reminder'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter medication name'), findsOneWidget);
      expect(find.text('Please enter prescribed dosage'), findsOneWidget);

      // Enter valid caregiver inputs
      await tester.enterText(find.byType(TextFormField).at(0), 'Ginkgo Biloba');
      await tester.enterText(find.byType(TextFormField).at(1), '120mg - 1 capsule');
      await tester.tap(find.text('Create Reminder'));
      await tester.pumpAndSettle();

      // Verify dialog dismissed and new reminder appears
      expect(find.byType(MedicationEditDialog), findsNothing);
      expect(find.text('Ginkgo Biloba'), findsOneWidget);
    });
  });
}
