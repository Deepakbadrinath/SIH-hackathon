import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_constants.dart';
import '../../../core/database/database_helper.dart';
import '../../../domain/models/medication_models.dart';

abstract class MedicationLocalDataSource {
  Future<void> insertMedication(Medication medication);
  Future<Medication?> getMedicationById(String id);
  Future<List<Medication>> getMedicationsForPatient(String patientId);
  Future<void> updateMedication(Medication medication);
  Future<void> deleteMedication(String id);

  Future<void> insertSchedule(MedicationSchedule schedule);
  Future<List<MedicationSchedule>> getSchedulesForMedication(String medicationId);
  Future<void> updateSchedule(MedicationSchedule schedule);
  Future<void> deleteSchedule(String id);

  Future<void> insertLog(MedicationLog log);
  Future<List<MedicationLog>> getLogsForSchedule(String scheduleId, {int limit = 20});
  Future<List<MedicationLog>> getAllLogsForPatient(String patientId);
  Future<void> updateLog(MedicationLog log);
  Future<void> deleteLog(String id);
}

class MedicationLocalDataSourceImpl implements MedicationLocalDataSource {
  final DatabaseHelper _dbHelper;

  MedicationLocalDataSourceImpl({required DatabaseHelper dbHelper}) : _dbHelper = dbHelper;

  @override
  Future<void> insertMedication(Medication medication) async {
    final db = await _dbHelper.database;
    await db.insert(
      DatabaseConstants.tableMedications,
      medication.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<Medication?> getMedicationById(String id) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      DatabaseConstants.tableMedications,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isNotEmpty) {
      return Medication.fromMap(results.first);
    }
    return null;
  }

  @override
  Future<List<Medication>> getMedicationsForPatient(String patientId) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      DatabaseConstants.tableMedications,
      where: 'patient_id = ? AND is_active = 1',
      whereArgs: [patientId],
    );
    return results.map((e) => Medication.fromMap(e)).toList();
  }

  @override
  Future<void> updateMedication(Medication medication) async {
    final db = await _dbHelper.database;
    await db.update(
      DatabaseConstants.tableMedications,
      medication.toMap(),
      where: 'id = ?',
      whereArgs: [medication.id],
    );
  }

  @override
  Future<void> deleteMedication(String id) async {
    final db = await _dbHelper.database;
    await db.delete(
      DatabaseConstants.tableMedications,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> insertSchedule(MedicationSchedule schedule) async {
    final db = await _dbHelper.database;
    await db.insert(
      DatabaseConstants.tableMedicationSchedules,
      schedule.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<MedicationSchedule>> getSchedulesForMedication(String medicationId) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      DatabaseConstants.tableMedicationSchedules,
      where: 'medication_id = ? AND is_active = 1',
      whereArgs: [medicationId],
    );
    return results.map((e) => MedicationSchedule.fromMap(e)).toList();
  }

  @override
  Future<void> updateSchedule(MedicationSchedule schedule) async {
    final db = await _dbHelper.database;
    await db.update(
      DatabaseConstants.tableMedicationSchedules,
      schedule.toMap(),
      where: 'id = ?',
      whereArgs: [schedule.id],
    );
  }

  @override
  Future<void> deleteSchedule(String id) async {
    final db = await _dbHelper.database;
    await db.delete(
      DatabaseConstants.tableMedicationSchedules,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> insertLog(MedicationLog log) async {
    final db = await _dbHelper.database;
    await db.insert(
      DatabaseConstants.tableMedicationLogs,
      log.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<MedicationLog>> getLogsForSchedule(String scheduleId, {int limit = 20}) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      DatabaseConstants.tableMedicationLogs,
      where: 'schedule_id = ?',
      whereArgs: [scheduleId],
      orderBy: 'action_timestamp DESC',
      limit: limit,
    );
    return results.map((e) => MedicationLog.fromMap(e)).toList();
  }

  @override
  Future<List<MedicationLog>> getAllLogsForPatient(String patientId) async {
    final db = await _dbHelper.database;
    final results = await db.rawQuery('''
      SELECT ml.* FROM ${DatabaseConstants.tableMedicationLogs} ml
      INNER JOIN ${DatabaseConstants.tableMedicationSchedules} ms ON ml.schedule_id = ms.id
      INNER JOIN ${DatabaseConstants.tableMedications} m ON ms.medication_id = m.id
      WHERE m.patient_id = ?
      ORDER BY ml.action_timestamp DESC
    ''', [patientId]);
    return results.map((e) => MedicationLog.fromMap(e)).toList();
  }

  @override
  Future<void> updateLog(MedicationLog log) async {
    final db = await _dbHelper.database;
    await db.update(
      DatabaseConstants.tableMedicationLogs,
      log.toMap(),
      where: 'id = ?',
      whereArgs: [log.id],
    );
  }

  @override
  Future<void> deleteLog(String id) async {
    final db = await _dbHelper.database;
    await db.delete(
      DatabaseConstants.tableMedicationLogs,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
