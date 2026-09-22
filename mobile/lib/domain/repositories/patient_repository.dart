import '../models/patient.dart';
import '../models/caregiver.dart';

abstract class PatientRepository {
  Future<Patient?> getPatientById(String id);
  Future<Patient?> getPatientByUserId(String userId);
  Future<void> savePatient(Patient patient);
  Future<void> updateAccessibilitySettings({
    required String patientId,
    required bool highContrastEnabled,
    required bool audioInstructionsEnabled,
    required double fontScale,
  });
  Future<List<Patient>> getPatientsForCaregiver(String caregiverId);
}

abstract class CaregiverRepository {
  Future<Caregiver?> getCaregiverById(String id);
  Future<Caregiver?> getCaregiverByUserId(String userId);
  Future<void> saveCaregiver(Caregiver caregiver);
  Future<List<PatientCaregiverRelation>> getRelationships(String caregiverId);
  Future<void> createRelationship(PatientCaregiverRelation relation);
}
