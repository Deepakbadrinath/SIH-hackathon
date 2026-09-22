import '../models/caregiver.dart';

abstract class CaregiverRepository {
  Future<Caregiver?> getCaregiverById(String id);
  Future<Caregiver?> getCaregiverByUserId(String userId);
  Future<void> saveCaregiver(Caregiver caregiver);
  Future<List<PatientCaregiverRelation>> getRelationships(String caregiverId);
  Future<void> createRelationship(PatientCaregiverRelation relation);
}
