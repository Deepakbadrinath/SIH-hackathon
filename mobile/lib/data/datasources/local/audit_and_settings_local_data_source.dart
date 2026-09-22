import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_constants.dart';
import '../../../core/database/database_helper.dart';
import '../../../domain/models/system_models.dart';

abstract class AuditLocalDataSource {
  Future<void> insertAuditLog(AuditLog log);
  Future<List<AuditLog>> getRecentLogs({int limit = 50});
  Future<void> deleteLogsOlderThan(DateTime cutoff);
}

class AuditLocalDataSourceImpl implements AuditLocalDataSource {
  final DatabaseHelper _dbHelper;

  AuditLocalDataSourceImpl({required DatabaseHelper dbHelper}) : _dbHelper = dbHelper;

  @override
  Future<void> insertAuditLog(AuditLog log) async {
    final db = await _dbHelper.database;
    await db.insert(
      DatabaseConstants.tableAuditLogs,
      log.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<AuditLog>> getRecentLogs({int limit = 50}) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      DatabaseConstants.tableAuditLogs,
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    return results.map((e) => AuditLog.fromMap(e)).toList();
  }

  @override
  Future<void> deleteLogsOlderThan(DateTime cutoff) async {
    final db = await _dbHelper.database;
    await db.delete(
      DatabaseConstants.tableAuditLogs,
      where: 'timestamp < ?',
      whereArgs: [cutoff.toIso8601String()],
    );
  }
}

abstract class SettingsLocalDataSource {
  Future<void> setSetting(String key, String value);
  Future<String?> getSetting(String key);
  Future<Map<String, String>> getAllSettings();
  Future<void> deleteSetting(String key);
}

class SettingsLocalDataSourceImpl implements SettingsLocalDataSource {
  final DatabaseHelper _dbHelper;

  SettingsLocalDataSourceImpl({required DatabaseHelper dbHelper}) : _dbHelper = dbHelper;

  @override
  Future<void> setSetting(String key, String value) async {
    final db = await _dbHelper.database;
    final setting = AppSetting(key: key, value: value, updatedAt: DateTime.now());
    await db.insert(
      DatabaseConstants.tableAppSettings,
      setting.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<String?> getSetting(String key) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      DatabaseConstants.tableAppSettings,
      where: 'setting_key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (results.isNotEmpty) {
      return results.first['setting_value'] as String?;
    }
    return null;
  }

  @override
  Future<Map<String, String>> getAllSettings() async {
    final db = await _dbHelper.database;
    final results = await db.query(DatabaseConstants.tableAppSettings);
    final map = <String, String>{};
    for (final row in results) {
      map[row['setting_key'] as String] = row['setting_value'] as String;
    }
    return map;
  }

  @override
  Future<void> deleteSetting(String key) async {
    final db = await _dbHelper.database;
    await db.delete(
      DatabaseConstants.tableAppSettings,
      where: 'setting_key = ?',
      whereArgs: [key],
    );
  }
}
