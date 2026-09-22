import 'dart:async';
import '../../../../domain/repositories/medication_repository.dart';
import '../../../../domain/services/notification_service.dart';

/// Bridges MedicationRepository schedules and NotificationService to ensure
/// local alarms are scheduled, updated, and re-synchronized.
class MedicationReminderScheduler {
  final MedicationRepository _repository;
  final NotificationService _notificationService;

  MedicationReminderScheduler({
    required MedicationRepository repository,
    required NotificationService notificationService,
  })  : _repository = repository,
        _notificationService = notificationService;

  /// Schedules notifications for a patient for the next [daysAhead] days
  Future<void> scheduleUpcomingReminders(String patientId, {int daysAhead = 7}) async {
    final medications = await _repository.getMedicationsForPatient(patientId);
    final medMap = {for (final m in medications) m.id: m};

    final schedules = await _repository.getAllActiveSchedulesForPatient(patientId);
    final now = DateTime.now();

    for (int dayOffset = 0; dayOffset < daysAhead; dayOffset++) {
      final targetDate = now.add(Duration(days: dayOffset));
      final dayOfWeekStr = targetDate.weekday.toString(); // 1=Mon, 7=Sun

      for (final schedule in schedules) {
        if (!schedule.isActive) continue;

        // Check if schedule applies to target day of week
        final applicableDays = schedule.daysOfWeek.split(',').map((s) => s.trim()).toSet();
        if (!applicableDays.contains(dayOfWeekStr)) continue;

        final med = medMap[schedule.medicationId];
        if (med == null || !med.isActive) continue;

        final parts = schedule.timeOfDay.split(':');
        if (parts.length != 2) continue;
        final hour = int.tryParse(parts[0]) ?? 8;
        final minute = int.tryParse(parts[1]) ?? 0;

        final scheduledDateTime = DateTime(
          targetDate.year,
          targetDate.month,
          targetDate.day,
          hour,
          minute,
        );

        // Don't schedule notifications for times in the past
        if (scheduledDateTime.isBefore(now)) continue;

        final notifId = _notificationService.generateDeterministicId(schedule.id, scheduledDateTime);

        await _notificationService.scheduleNotification(
          id: notifId,
          title: 'Medication Reminder: ${med.name}',
          body: '${med.dosageDescription}. Scheduled for ${schedule.timeOfDay}.',
          scheduledDateTime: scheduledDateTime,
          payload: schedule.id,
        );
      }
    }
  }

  /// Triggered after device reboot to recover all alarms
  Future<void> onDeviceRestart(String patientId) async {
    final medications = await _repository.getMedicationsForPatient(patientId);
    final medMap = {for (final m in medications) m.id: m};
    final schedules = await _repository.getAllActiveSchedulesForPatient(patientId);

    await _notificationService.handleDeviceRestart(schedules, medMap);
  }

  /// Triggered when the device clock / timezone changes
  Future<void> onTimezoneShift(String patientId) async {
    final medications = await _repository.getMedicationsForPatient(patientId);
    final medMap = {for (final m in medications) m.id: m};
    final schedules = await _repository.getAllActiveSchedulesForPatient(patientId);

    await _notificationService.handleTimezoneChange(schedules, medMap);
  }
}
