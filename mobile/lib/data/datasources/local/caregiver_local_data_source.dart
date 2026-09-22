import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_constants.dart';
import '../../../core/database/database_helper.dart';
import '../../../domain/models/caregiver.dart';

abstract class CaregiverLocalDataSource {
  Future<void> createCaregiver(Caregiver caregiver);
  Future<Caregiver?> getCaregiverById(String id);
  Future<Caregiver?> getCaregiverByUserId(String userId);
  Future<void> updateCaregiver(Caregiver caregiver);
  Future<void> deleteCaregiver(String id);
}

class CaregiverLocalDataSourceImpl implements CaregiverLocalDataSource {
  final DatabaseHelper _dbHelper;

  CaregiverLocalDataSourceImpl({required DatabaseHelper dbHelper}) : _dbHelper = dbHelper;

  @override
  Future<void> createCaregiver(Caregiver caregiver) async {
    final db = await _dbHelper.database;
    await db.insert(
      DatabaseConstants.tableCaregivers,
      caregiver.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<Caregiver?> getCaregiverById(String id) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      DatabaseConstants.tableCaregivers,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isNotEmpty) {
      return Caregiver.fromMap(results.first);
    }
    return null;
  }

  @override
  Future<Caregiver?> getCaregiverByUserId(String userId) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      DatabaseConstants.tableCaregivers,
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (results.isNotEmpty) {
      return Caregiver.fromMap(results.first);
    }
    return null;
  }

  @override
  Future<void> updateCaregiver(Caregiver caregiver) async {
    final db = await _dbHelper.database;
    await db.update(
      DatabaseConstants.tableCaregivers,
      caregiver.toMap(),
      where: 'id = ?',
      whereArgs: [caregiver.id],
    );
  }

  @override
  Future<void> deleteCaregiver(String id) async {
    final db = await _dbHelper.database;
    await db.delete(
      DatabaseConstants.tableCaregivers,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

abstract class RelationshipLocalDataSource {
  Future<void> createRelationship(PatientCaregiverRelation relation);
  Future<List<PatientCaregiverRelation>> getRelationshipsForCaregiver(String caregiverId);
  Future<List<PatientCaregiverRelation>> getRelationshipsForPatient(String patientId);
  Future<void> updateRelationship(PatientCaregiverRelation relation);
  Future<void> deleteRelationship(String id);
}

class RelationshipLocalDataSourceImpl implements RelationshipLocalDataSource {
  final DatabaseHelper _dbHelper;

  RelationshipLocalDataSourceImpl({required DatabaseHelper dbHelper}) : _dbHelper = dbHelper;

  @override
  Future<void> createRelationship(PatientCaregiverRelation relation) async {
    final db = await _dbHelper.database;
    await db.insert(
      DatabaseConstants.tableCaregiverPatientRelationships,
      relation.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<PatientCaregiverRelation>> getRelationshipsForCaregiver(String caregiverId) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      DatabaseConstants.tableCaregiverPatientRelationships,
      where: 'caregiver_id = ? AND is_active = 1',
      whereArgs: [caregiverId],
    );
    return results.map((e) => PatientCaregiverRelation.fromMap(e)).toList();
  }

  @override
  Future<List<PatientCaregiverRelation>> getRelationshipsForPatient(String patientId) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      DatabaseConstants.tableCaregiverPatientRelationships,
      where: 'patient_id = ? AND is_active = 1',
      whereArgs: [patientId],
    );
    return results.map((e) => PatientCaregiverRelation.fromMap(e)).toList();
  }

  @override
  Future<void> updateRelationship(PatientCaregiverRelation relation) async {
    final db = await _dbHelper.database;
    await db.update(
      DatabaseConstants.tableCaregiverPatientRelationships,
      relation.toMap(),
      where: 'id = ?',
      whereArgs: [relation.id],
    );
  }

  @override
  Future<void> deleteRelationship(String id) async {
    final db = await _dbHelper.database;
    await db.delete(
      DatabaseConstants.tableCaregiverPatientRelationships,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
