import '../models/medication_models.dart';

enum NotificationPermissionStatus {
  granted,
  denied,
  permanentlyDenied,
}

class PendingReminderNotification {
  final int id;
  final String title;
  final String body;
  final DateTime scheduledDateTime;
  final String? payload;

  const PendingReminderNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledDateTime,
    this.payload,
  });

  @override
  String toString() => 'PendingReminderNotification(id: $id, time: $scheduledDateTime, title: $title)';
}

/// Abstract contract for local medication reminder notifications.
/// Decouples platform alarm managers and system notifications from domain logic.
abstract class NotificationService {
  Future<NotificationPermissionStatus> requestPermissions();
  Future<NotificationPermissionStatus> checkPermissions();

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDateTime,
    String? payload,
  });

  Future<void> cancelNotification(int id);
  Future<void> cancelAllNotifications();
  Future<List<PendingReminderNotification>> getPendingNotifications();

  /// Reschedules all active reminders following a system device restart
  Future<void> handleDeviceRestart(List<MedicationSchedule> activeSchedules, Map<String, Medication> medicationMap);

  /// Adjusts scheduled notification triggers when the device timezone changes
  Future<void> handleTimezoneChange(List<MedicationSchedule> activeSchedules, Map<String, Medication> medicationMap);

  /// Computes a deterministic integer ID to prevent duplicate alarms for the same schedule & date
  int generateDeterministicId(String scheduleId, DateTime dateTime);
}
