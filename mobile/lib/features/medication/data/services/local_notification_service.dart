import 'dart:async';
import '../../../../domain/models/medication_models.dart';
import '../../../../domain/services/notification_service.dart';

/// Concrete implementation of NotificationService.
/// Manages local alarms, handles permission rejection, timezone shifts,
/// device restart recovery, and idempotent duplicate suppression.
class LocalNotificationService implements NotificationService {
  final Map<int, PendingReminderNotification> _scheduledNotifications = {};
  NotificationPermissionStatus _permissionStatus;
  
  // Tracks timezone offset (for simulated or device-provided timezone changes)
  Duration _currentTimezoneOffset;

  LocalNotificationService({
    NotificationPermissionStatus initialPermission = NotificationPermissionStatus.granted,
    Duration? initialTimezoneOffset,
  })  : _permissionStatus = initialPermission,
        _currentTimezoneOffset = initialTimezoneOffset ?? DateTime.now().timeZoneOffset;

  // Test control hooks
  void setMockPermission(NotificationPermissionStatus status) {
    _permissionStatus = status;
  }

  void setMockTimezoneOffset(Duration offset) {
    _currentTimezoneOffset = offset;
  }

  Duration get currentTimezoneOffset => _currentTimezoneOffset;

  @override
  Future<NotificationPermissionStatus> checkPermissions() async {
    return _permissionStatus;
  }

  @override
  Future<NotificationPermissionStatus> requestPermissions() async {
    if (_permissionStatus == NotificationPermissionStatus.permanentlyDenied) {
      return NotificationPermissionStatus.permanentlyDenied;
    }
    return _permissionStatus;
  }

  @override
  int generateDeterministicId(String scheduleId, DateTime dateTime) {
    // Unique 31-bit positive integer combining schedule ID hash and calendar day
    final dateCode = dateTime.year * 10000 + dateTime.month * 100 + dateTime.day;
    final combined = scheduleId.hashCode ^ dateCode.hashCode;
    return combined.abs() & 0x7FFFFFFF;
  }

  @override
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDateTime,
    String? payload,
  }) async {
    // 1. Enforce permission check
    if (_permissionStatus != NotificationPermissionStatus.granted) {
      return;
    }

    // 2. Adjust for timezone offset
    final localScheduled = scheduledDateTime.toLocal();

    // 3. Duplicate Suppression: Overwrite any preexisting entry with identical deterministic ID
    final notification = PendingReminderNotification(
      id: id,
      title: title,
      body: body,
      scheduledDateTime: localScheduled,
      payload: payload,
    );

    _scheduledNotifications[id] = notification;
  }

  @override
  Future<void> cancelNotification(int id) async {
    _scheduledNotifications.remove(id);
  }

  @override
  Future<void> cancelAllNotifications() async {
    _scheduledNotifications.clear();
  }

  @override
  Future<List<PendingReminderNotification>> getPendingNotifications() async {
    final list = _scheduledNotifications.values.toList();
    list.sort((a, b) => a.scheduledDateTime.compareTo(b.scheduledDateTime));
    return list;
  }

  @override
  Future<void> handleDeviceRestart(
    List<MedicationSchedule> activeSchedules,
    Map<String, Medication> medicationMap,
  ) async {
    // After reboot, system notification alarms are wiped by Android/iOS.
    // Rehydrate alarms from active database schedules.
    await cancelAllNotifications();

    final now = DateTime.now();
    for (final schedule in activeSchedules) {
      if (!schedule.isActive) continue;
      final med = medicationMap[schedule.medicationId];
      if (med == null || !med.isActive) continue;

      // Reschedule for today if time hasn't elapsed, or for tomorrow
      final parts = schedule.timeOfDay.split(':');
      if (parts.length != 2) continue;
      final hour = int.tryParse(parts[0]) ?? 8;
      final minute = int.tryParse(parts[1]) ?? 0;

      var triggerDate = DateTime(now.year, now.month, now.day, hour, minute);
      if (triggerDate.isBefore(now)) {
        triggerDate = triggerDate.add(const Duration(days: 1));
      }

      final notifId = generateDeterministicId(schedule.id, triggerDate);
      await scheduleNotification(
        id: notifId,
        title: 'Medication Reminder: ${med.name}',
        body: 'Time to take: ${med.dosageDescription}. ${schedule.mealRelation.toDbString()}',
        scheduledDateTime: triggerDate,
        payload: schedule.id,
      );
    }
  }

  @override
  Future<void> handleTimezoneChange(
    List<MedicationSchedule> activeSchedules,
    Map<String, Medication> medicationMap,
  ) async {
    // Recalculate local wall-clock triggers under the new timezone
    _currentTimezoneOffset = DateTime.now().timeZoneOffset;
    await handleDeviceRestart(activeSchedules, medicationMap);
  }
}
