import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_constants.dart';
import '../../../core/database/database_helper.dart';
import '../../../domain/models/game_models.dart';

abstract class GameLocalDataSource {
  Future<void> insertSession(GameSession session);
  Future<GameSession?> getSessionById(String id);
  Future<void> updateSession(GameSession session);
  Future<void> deleteSession(String id);

  Future<void> insertResult(GameResult result);
  Future<GameResult?> getResultBySessionId(String sessionId);
  Future<List<GameResult>> getRecentResults(String patientId, {int limit = 10});

  Future<void> insertPerformanceMetrics(List<PerformanceMetrics> metrics);
  Future<List<PerformanceMetrics>> getMetricsForSession(String sessionId);

  Future<void> insertDifficultyHistory(DifficultyHistory history);
  Future<List<DifficultyHistory>> getDifficultyHistory(String patientId, GameType gameType, {int limit = 10});
  Future<int> getLatestDifficulty(String patientId, GameType gameType);
}

class GameLocalDataSourceImpl implements GameLocalDataSource {
  final DatabaseHelper _dbHelper;

  GameLocalDataSourceImpl({required DatabaseHelper dbHelper}) : _dbHelper = dbHelper;

  @override
  Future<void> insertSession(GameSession session) async {
    final db = await _dbHelper.database;
    await db.insert(
      DatabaseConstants.tableGameSessions,
      session.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<GameSession?> getSessionById(String id) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      DatabaseConstants.tableGameSessions,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isNotEmpty) {
      return GameSession.fromMap(results.first);
    }
    return null;
  }

  @override
  Future<void> updateSession(GameSession session) async {
    final db = await _dbHelper.database;
    await db.update(
      DatabaseConstants.tableGameSessions,
      session.toMap(),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  @override
  Future<void> deleteSession(String id) async {
    final db = await _dbHelper.database;
    await db.delete(
      DatabaseConstants.tableGameSessions,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> insertResult(GameResult result) async {
    final db = await _dbHelper.database;
    await db.insert(
      DatabaseConstants.tableGameResults,
      result.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<GameResult?> getResultBySessionId(String sessionId) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      DatabaseConstants.tableGameResults,
      where: 'session_id = ?',
      whereArgs: [sessionId],
      limit: 1,
    );
    if (results.isNotEmpty) {
      return GameResult.fromMap(results.first);
    }
    return null;
  }

  @override
  Future<List<GameResult>> getRecentResults(String patientId, {int limit = 10}) async {
    final db = await _dbHelper.database;
    final results = await db.rawQuery('''
      SELECT gr.* FROM ${DatabaseConstants.tableGameResults} gr
      INNER JOIN ${DatabaseConstants.tableGameSessions} gs ON gr.session_id = gs.id
      WHERE gs.patient_id = ?
      ORDER BY gr.completed_at DESC
      LIMIT ?
    ''', [patientId, limit]);
    return results.map((e) => GameResult.fromMap(e)).toList();
  }

  @override
  Future<void> insertPerformanceMetrics(List<PerformanceMetrics> metrics) async {
    final db = await _dbHelper.database;
    final batch = db.batch();
    for (final m in metrics) {
      batch.insert(
        DatabaseConstants.tablePerformanceMetrics,
        m.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<List<PerformanceMetrics>> getMetricsForSession(String sessionId) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      DatabaseConstants.tablePerformanceMetrics,
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'trial_number ASC',
    );
    return results.map((e) => PerformanceMetrics.fromMap(e)).toList();
  }

  @override
  Future<void> insertDifficultyHistory(DifficultyHistory history) async {
    final db = await _dbHelper.database;
    await db.insert(
      DatabaseConstants.tableDifficultyHistory,
      history.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<DifficultyHistory>> getDifficultyHistory(
    String patientId,
    GameType gameType, {
    int limit = 10,
  }) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      DatabaseConstants.tableDifficultyHistory,
      where: 'patient_id = ? AND game_type = ?',
      whereArgs: [patientId, gameType.toDbString()],
      orderBy: 'calculated_at DESC',
      limit: limit,
    );
    return results.map((e) => DifficultyHistory.fromMap(e)).toList();
  }

  @override
  Future<int> getLatestDifficulty(String patientId, GameType gameType) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      DatabaseConstants.tableDifficultyHistory,
      where: 'patient_id = ? AND game_type = ?',
      whereArgs: [patientId, gameType.toDbString()],
      orderBy: 'calculated_at DESC',
      limit: 1,
    );
    if (results.isNotEmpty) {
      return results.first['new_difficulty'] as int;
    }
    return 1;
  }
}
