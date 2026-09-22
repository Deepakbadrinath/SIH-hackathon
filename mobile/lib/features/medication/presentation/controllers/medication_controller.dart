import 'package:flutter/foundation.dart';
import '../../../../domain/models/medication_models.dart';
import '../../../../domain/repositories/medication_repository.dart';
import '../../data/services/medication_reminder_scheduler.dart';

class MedicationController extends ChangeNotifier {
  final MedicationRepository _repository;
  final MedicationReminderScheduler? _scheduler;

  List<Medication> _medications = [];
  List<MedicationReminderItem> _todayReminders = [];
  List<MedicationReminderItem> _upcomingReminders = [];
  List<MedicationReminderItem> _completedReminders = [];
  List<MedicationReminderItem> _missedReminders = [];
  List<MedicationLog> _historyLogs = [];

  ReminderFilter _currentFilter = ReminderFilter.today;
  double _adherenceRate = 94.2;
  int _missedDoses = 0;
  bool _isLoading = false;
  String _activePatientId = 'p_1';

  MedicationController({
    required MedicationRepository repository,
    MedicationReminderScheduler? scheduler,
    String defaultPatientId = 'p_1',
  })  : _repository = repository,
        _scheduler = scheduler,
        _activePatientId = defaultPatientId;

  List<Medication> get medications => _medications;
  List<MedicationReminderItem> get todayReminders => _todayReminders;
  List<MedicationReminderItem> get upcomingReminders => _upcomingReminders;
  List<MedicationReminderItem> get completedReminders => _completedReminders;
  List<MedicationReminderItem> get missedReminders => _missedReminders;
  List<MedicationLog> get historyLogs => _historyLogs;

  ReminderFilter get currentFilter => _currentFilter;
  double get adherenceRate => _adherenceRate;
  int get missedDoses => _missedDoses;
  bool get isLoading => _isLoading;
  String get activePatientId => _activePatientId;

  List<MedicationReminderItem> get activeFilterReminders {
    switch (_currentFilter) {
      case ReminderFilter.today:
        return _todayReminders;
      case ReminderFilter.upcoming:
        return _upcomingReminders;
      case ReminderFilter.completed:
        return _completedReminders;
      case ReminderFilter.missed:
        return _missedReminders;
      case ReminderFilter.history:
        return _todayReminders;
    }
  }

  void setFilter(ReminderFilter filter) {
    _currentFilter = filter;
    notifyListeners();
  }

  Future<void> loadMedicationData([String? patientId]) async {
    final pid = patientId ?? _activePatientId;
    _activePatientId = pid;
    _isLoading = true;
    notifyListeners();

    try {
      _medications = await _repository.getMedicationsForPatient(pid);
      _todayReminders = await _repository.getTodayReminders(pid);
      _upcomingReminders = await _repository.getUpcomingReminders(pid, daysAhead: 7);
      _completedReminders = await _repository.getCompletedReminders(pid);
      _missedReminders = await _repository.getMissedReminders(pid);
      _historyLogs = await _repository.getMedicationHistory(pid, limit: 30);
      _adherenceRate = await _repository.getAdherenceRate(pid);
      _missedDoses = await _repository.getMissedDosesCount(pid);

      // Schedule rolling local alarms
      await _scheduler?.scheduleUpcomingReminders(pid);
    } catch (e) {
      if (kDebugMode) print('Error loading medication data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Mark dose as TAKEN
  Future<void> markDoseTaken({
    required String scheduleId,
    required String scheduledTime,
    String confirmedByRole = 'PATIENT',
    String? notes,
  }) async {
    await _repository.recordMedicationAction(
      scheduleId: scheduleId,
      scheduledTime: scheduledTime,
      status: MedicationLogStatus.taken,
      confirmedByRole: confirmedByRole,
      notes: notes,
    );
    await loadMedicationData(_activePatientId);
  }

  /// Backward-compatible alias
  Future<void> recordDoseTaken({
    required String scheduleId,
    required String scheduledTime,
    String? notes,
  }) => markDoseTaken(scheduleId: scheduleId, scheduledTime: scheduledTime, notes: notes);

  /// Mark dose as SKIPPED
  Future<void> markDoseSkipped({
    required String scheduleId,
    required String scheduledTime,
    String confirmedByRole = 'PATIENT',
    String? reason,
  }) async {
    await _repository.recordMedicationAction(
      scheduleId: scheduleId,
      scheduledTime: scheduledTime,
      status: MedicationLogStatus.skipped,
      confirmedByRole: confirmedByRole,
      notes: reason ?? 'Skipped by user',
    );
    await loadMedicationData(_activePatientId);
  }

  /// Mark dose as MISSED
  Future<void> markDoseMissed({
    required String scheduleId,
    required String scheduledTime,
    String confirmedByRole = 'CAREGIVER',
    String? notes,
  }) async {
    await _repository.recordMedicationAction(
      scheduleId: scheduleId,
      scheduledTime: scheduledTime,
      status: MedicationLogStatus.missed,
      confirmedByRole: confirmedByRole,
      notes: notes ?? 'Missed window',
    );
    await loadMedicationData(_activePatientId);
  }

  /// Mark dose as SNOOZED
  Future<void> markDoseSnoozed({
    required String scheduleId,
    required String scheduledTime,
    String confirmedByRole = 'PATIENT',
    int minutes = 15,
  }) async {
    await _repository.recordMedicationAction(
      scheduleId: scheduleId,
      scheduledTime: scheduledTime,
      status: MedicationLogStatus.snoozed,
      confirmedByRole: confirmedByRole,
      notes: 'Snoozed for $minutes minutes',
    );
    await loadMedicationData(_activePatientId);
  }

  /// Caregiver authorized: Add a new medication and its primary schedule
  Future<void> addMedicationWithSchedule({
    required String name,
    required String dosageDescription,
    required String timeOfDay,
    MealRelation mealRelation = MealRelation.afterMeal,
    String daysOfWeek = '1,2,3,4,5,6,7',
    String instructions = '',
    String visualColorCode = '#3B82F6',
  }) async {
    final now = DateTime.now();
    final medId = 'med_${now.millisecondsSinceEpoch}';
    final scheduleId = 'sched_${now.millisecondsSinceEpoch}';

    final medication = Medication(
      id: medId,
      patientId: _activePatientId,
      name: name,
      dosageDescription: dosageDescription,
      instructions: instructions,
      visualColorCode: visualColorCode,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );

    final schedule = MedicationSchedule(
      id: scheduleId,
      medicationId: medId,
      timeOfDay: timeOfDay,
      mealRelation: mealRelation,
      daysOfWeek: daysOfWeek,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );

    await _repository.saveMedication(medication);
    await _repository.saveMedicationSchedule(schedule);
    await loadMedicationData(_activePatientId);
  }

  /// Caregiver authorized: Update existing medication details
  Future<void> updateMedication(Medication medication) async {
    final updated = medication.copyWith(updatedAt: DateTime.now());
    await _repository.updateMedication(updated);
    await loadMedicationData(_activePatientId);
  }

  /// Caregiver authorized: Toggle active status
  Future<void> toggleMedicationActive(Medication medication) async {
    final updated = medication.copyWith(
      isActive: !medication.isActive,
      updatedAt: DateTime.now(),
    );
    await _repository.updateMedication(updated);
    await loadMedicationData(_activePatientId);
  }

  /// Caregiver authorized: Delete medication
  Future<void> deleteMedication(String id) async {
    await _repository.deleteMedication(id);
    await loadMedicationData(_activePatientId);
  }

  /// Reschedule notifications on reboot or timezone shift
  Future<void> rescheduleNotifications() async {
    await _scheduler?.onDeviceRestart(_activePatientId);
  }
}
