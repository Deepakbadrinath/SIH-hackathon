import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_constants.dart';
import '../../../core/database/database_helper.dart';
import '../../../domain/models/patient.dart';

abstract class PatientLocalDataSource {
  Future<void> createPatient(Patient patient);
  Future<Patient?> getPatientById(String id);
  Future<Patient?> getPatientByUserId(String userId);
  Future<void> updatePatient(Patient patient);
  Future<void> deletePatient(String id);
  Future<List<Patient>> getAllPatients();
}

class PatientLocalDataSourceImpl implements PatientLocalDataSource {
  final DatabaseHelper _dbHelper;

  PatientLocalDataSourceImpl({required DatabaseHelper dbHelper}) : _dbHelper = dbHelper;

  @override
  Future<void> createPatient(Patient patient) async {
    final db = await _dbHelper.database;
    await db.insert(
      DatabaseConstants.tablePatients,
      patient.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<Patient?> getPatientById(String id) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      DatabaseConstants.tablePatients,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isNotEmpty) {
      return Patient.fromMap(results.first);
    }
    return null;
  }

  @override
  Future<Patient?> getPatientByUserId(String userId) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      DatabaseConstants.tablePatients,
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (results.isNotEmpty) {
      return Patient.fromMap(results.first);
    }
    return null;
  }

  @override
  Future<void> updatePatient(Patient patient) async {
    final db = await _dbHelper.database;
    await db.update(
      DatabaseConstants.tablePatients,
      patient.toMap(),
      where: 'id = ?',
      whereArgs: [patient.id],
    );
  }

  @override
  Future<void> deletePatient(String id) async {
    final db = await _dbHelper.database;
    await db.delete(
      DatabaseConstants.tablePatients,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<List<Patient>> getAllPatients() async {
    final db = await _dbHelper.database;
    final results = await db.query(DatabaseConstants.tablePatients);
    return results.map((e) => Patient.fromMap(e)).toList();
  }
}
