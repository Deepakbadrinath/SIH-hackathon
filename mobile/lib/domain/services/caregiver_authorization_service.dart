import '../models/caregiver.dart';

/// Service contract enforcing zero-trust backend authorization between caregivers and patients.
abstract class CaregiverAuthorizationService {
  /// Checks whether [caregiverId] is actively authorized to access records for [patientId].
  Future<bool> isAuthorized({
    required String caregiverId,
    required String patientId,
  });

  /// Validates authorization, throwing [CaregiverUnauthorizedException] if unauthorized.
  Future<void> validateAccess({
    required String caregiverId,
    required String patientId,
  });

  /// Returns all active patient IDs linked to [caregiverId].
  Future<List<String>> getAuthorizedPatientIds(String caregiverId);

  /// Returns active relationships for [caregiverId].
  Future<List<PatientCaregiverRelation>> getAuthorizedRelationships(String caregiverId);
}
