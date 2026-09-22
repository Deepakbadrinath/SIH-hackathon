import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_constants.dart';
import '../../../core/database/database_helper.dart';
import '../../../domain/models/system_models.dart';

abstract class SyncQueueLocalDataSource {
  Future<void> enqueue(SyncItem item);
  Future<List<SyncItem>> getPending({int limit = 25});
  Future<void> updateStatus({
    required String operationId,
    required SyncStatus status,
    String? lastError,
    bool incrementRetry = false,
  });
  Future<void> markCompleted(String operationId, String entityId, String entityType);
  Future<int> getPendingCount();
  Future<void> deleteCompleted();
  Future<void> deleteOperation(String operationId);
  Future<int> resetInProgressOperations();
  Future<void> markPermanentlyFailed(String operationId, String reason);
}

class SyncQueueLocalDataSourceImpl implements SyncQueueLocalDataSource {
  final DatabaseHelper _dbHelper;

  SyncQueueLocalDataSourceImpl({required DatabaseHelper dbHelper}) : _dbHelper = dbHelper;

  @override
  Future<void> enqueue(SyncItem item) async {
    final db = await _dbHelper.database;
    await db.insert(
      DatabaseConstants.tableSyncQueue,
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<SyncItem>> getPending({int limit = 25}) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      DatabaseConstants.tableSyncQueue,
      where: 'sync_status = ? OR sync_status = ?',
      whereArgs: ['PENDING', 'FAILED'],
      orderBy: 'timestamp ASC',
      limit: limit,
    );
    return results.map((e) => SyncItem.fromMap(e)).toList();
  }

  @override
  Future<void> updateStatus({
    required String operationId,
    required SyncStatus status,
    String? lastError,
    bool incrementRetry = false,
  }) async {
    final db = await _dbHelper.database;
    if (incrementRetry) {
      await db.rawUpdate('''
        UPDATE ${DatabaseConstants.tableSyncQueue}
        SET retry_count = retry_count + 1, sync_status = ?, last_error = ?
        WHERE operation_id = ?
      ''', [status.toDbString(), lastError, operationId]);
      return;
    }

    await db.update(
      DatabaseConstants.tableSyncQueue,
      {
        'sync_status': status.toDbString(),
        'last_error': lastError,
      },
      where: 'operation_id = ?',
      whereArgs: [operationId],
    );
  }

  @override
  Future<void> markCompleted(String operationId, String entityId, String entityType) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      await txn.update(
        DatabaseConstants.tableSyncQueue,
        {'sync_status': 'COMPLETED'},
        where: 'operation_id = ?',
        whereArgs: [operationId],
      );

      String? targetTable;
      switch (entityType) {
        case 'GAME_SESSION':
          targetTable = DatabaseConstants.tableGameSessions;
          break;
        case 'GAME_RESULT':
          targetTable = DatabaseConstants.tableGameResults;
          break;
        case 'MEDICATION_LOG':
          targetTable = DatabaseConstants.tableMedicationLogs;
          break;
      }

      if (targetTable != null) {
        await txn.update(
          targetTable,
          {'is_synced': 1},
          where: 'id = ?',
          whereArgs: [entityId],
        );
      }
    });
  }

  @override
  Future<int> getPendingCount() async {
    final db = await _dbHelper.database;
    final results = await db.rawQuery('''
      SELECT COUNT(*) as count FROM ${DatabaseConstants.tableSyncQueue}
      WHERE sync_status != 'COMPLETED'
    ''');
    if (results.isNotEmpty && results.first['count'] != null) {
      return results.first['count'] as int;
    }
    return 0;
  }

  @override
  Future<void> deleteCompleted() async {
    final db = await _dbHelper.database;
    await db.delete(
      DatabaseConstants.tableSyncQueue,
      where: 'sync_status = ?',
      whereArgs: ['COMPLETED'],
    );
  }

  @override
  Future<void> deleteOperation(String operationId) async {
    final db = await _dbHelper.database;
    await db.delete(
      DatabaseConstants.tableSyncQueue,
      where: 'operation_id = ?',
      whereArgs: [operationId],
    );
  }

  @override
  Future<int> resetInProgressOperations() async {
    final db = await _dbHelper.database;
    final updated = await db.update(
      DatabaseConstants.tableSyncQueue,
      {
        'sync_status': 'PENDING',
        'last_error': 'Recovered from unexpected process termination (app restart/crash)',
      },
      where: 'sync_status = ?',
      whereArgs: ['IN_PROGRESS'],
    );
    return updated;
  }

  @override
  Future<void> markPermanentlyFailed(String operationId, String reason) async {
    final db = await _dbHelper.database;
    await db.update(
      DatabaseConstants.tableSyncQueue,
      {
        'sync_status': 'FAILED',
        'last_error': reason,
      },
      where: 'operation_id = ?',
      whereArgs: [operationId],
    );
  }
}
