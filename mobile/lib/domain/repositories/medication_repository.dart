import '../models/medication_models.dart';

abstract class MedicationRepository {
  Future<List<Medication>> getMedicationsForPatient(String patientId);
  Future<Medication?> getMedicationById(String id);
  Future<void> saveMedication(Medication medication);
  Future<void> updateMedication(Medication medication);
  Future<void> deleteMedication(String id);

  Future<List<MedicationSchedule>> getSchedulesForMedication(String medicationId);
  Future<List<MedicationSchedule>> getAllActiveSchedulesForPatient(String patientId);
  Future<void> saveMedicationSchedule(MedicationSchedule schedule);
  Future<void> updateMedicationSchedule(MedicationSchedule schedule);
  Future<void> deleteMedicationSchedule(String id);

  Future<List<MedicationLog>> getLogsForSchedule(String scheduleId, {int limit = 20});
  Future<List<MedicationLog>> getMedicationHistory(String patientId, {int limit = 50});

  Future<void> recordMedicationAction({
    required String scheduleId,
    required String scheduledTime,
    required MedicationLogStatus status,
    required String confirmedByRole,
    String? notes,
  });

  // Categorized Reminders
  Future<List<MedicationReminderItem>> getTodayReminders(String patientId, {DateTime? forDate});
  Future<List<MedicationReminderItem>> getUpcomingReminders(String patientId, {int daysAhead = 7, DateTime? fromDate});
  Future<List<MedicationReminderItem>> getCompletedReminders(String patientId, {DateTime? forDate});
  Future<List<MedicationReminderItem>> getMissedReminders(String patientId, {DateTime? forDate});

  Future<double> getAdherenceRate(String patientId, {int days = 7});
  Future<int> getMissedDosesCount(String patientId, {int days = 7});
}
