import '../../../../core/database/database_constants.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../domain/models/caregiver.dart';
import '../../../../domain/models/caregiver_dashboard_models.dart';
import '../../../../domain/services/caregiver_authorization_service.dart';

/// Database-backed implementation enforcing backend authorization checks.
/// Never trusts client claims; directly verifies relational integrity in SQLite storage.
class CaregiverAuthorizationServiceImpl implements CaregiverAuthorizationService {
  final DatabaseHelper _dbHelper;

  CaregiverAuthorizationServiceImpl({required DatabaseHelper dbHelper}) : _dbHelper = dbHelper;

  @override
  Future<bool> isAuthorized({
    required String caregiverId,
    required String patientId,
  }) async {
    if (caregiverId.trim().isEmpty || patientId.trim().isEmpty) {
      return false;
    }

    try {
      final db = await _dbHelper.database;
      final results = await db.query(
        DatabaseConstants.tableCaregiverPatientRelationships,
        where: 'caregiver_id = ? AND patient_id = ? AND is_active = 1',
        whereArgs: [caregiverId, patientId],
        limit: 1,
      );

      return results.isNotEmpty;
    } catch (_) {
      // Fail closed on any database or query error
      return false;
    }
  }

  @override
  Future<void> validateAccess({
    required String caregiverId,
    required String patientId,
  }) async {
    final authorized = await isAuthorized(caregiverId: caregiverId, patientId: patientId);
    if (!authorized) {
      throw CaregiverUnauthorizedException(
        'Caregiver "$caregiverId" is not authorized to access records for patient "$patientId".',
        caregiverId: caregiverId,
        patientId: patientId,
      );
    }
  }

  @override
  Future<List<String>> getAuthorizedPatientIds(String caregiverId) async {
    if (caregiverId.trim().isEmpty) return [];

    try {
      final db = await _dbHelper.database;
      final results = await db.query(
        DatabaseConstants.tableCaregiverPatientRelationships,
        columns: ['patient_id'],
        where: 'caregiver_id = ? AND is_active = 1',
        whereArgs: [caregiverId],
      );

      return results.map((row) => row['patient_id'] as String).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<PatientCaregiverRelation>> getAuthorizedRelationships(String caregiverId) async {
    if (caregiverId.trim().isEmpty) return [];

    try {
      final db = await _dbHelper.database;
      final results = await db.query(
        DatabaseConstants.tableCaregiverPatientRelationships,
        where: 'caregiver_id = ? AND is_active = 1',
        whereArgs: [caregiverId],
      );

      return results.map((row) => PatientCaregiverRelation.fromMap(row)).toList();
    } catch (_) {
      return [];
    }
  }
}
