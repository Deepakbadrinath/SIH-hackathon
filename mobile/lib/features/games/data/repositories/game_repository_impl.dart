import '../../../../core/constants/app_constants.dart';
import '../../../../data/datasources/local/game_local_data_source.dart';
import '../../../../domain/models/game_models.dart';
import '../../../../domain/repositories/game_repository.dart';

class GameRepositoryImpl implements GameRepository {
  final GameLocalDataSource _localDataSource;

  GameRepositoryImpl({required GameLocalDataSource localDataSource})
      : _localDataSource = localDataSource;

  @override
  Future<void> saveGameSession(GameSession session) async {
    await _localDataSource.insertSession(session);
  }

  @override
  Future<void> saveGameResult(GameResult result) async {
    await _localDataSource.insertResult(result);
  }

  @override
  Future<void> savePerformanceMetrics(List<PerformanceMetrics> metrics) async {
    await _localDataSource.insertPerformanceMetrics(metrics);
  }

  @override
  Future<void> saveDifficultyHistory(DifficultyHistory history) async {
    await _localDataSource.insertDifficultyHistory(history);
  }

  @override
  Future<int> getLatestDifficultyLevel(String patientId, GameType gameType) async {
    return await _localDataSource.getLatestDifficulty(patientId, gameType);
  }

  @override
  Future<List<GameResult>> getRecentResults(String patientId, {int limit = 10}) async {
    return await _localDataSource.getRecentResults(patientId, limit: limit);
  }

  @override
  Future<List<DifficultyHistory>> getDifficultyHistory(
    String patientId,
    GameType gameType, {
    int limit = 10,
  }) async {
    return await _localDataSource.getDifficultyHistory(patientId, gameType, limit: limit);
  }

  @override
  Future<double> getAverageAccuracyTrend(String patientId, {int days = 7}) async {
    final sampleLimit = (days * 2).clamp(7, 30);
    final results = await _localDataSource.getRecentResults(patientId, limit: sampleLimit);
    if (results.isEmpty) return AppConstants.defaultAccuracyBaseline;
    final sum = results.fold<double>(0.0, (prev, curr) => prev + curr.accuracyPercentage);
    return double.parse((sum / results.length).toStringAsFixed(1));
  }

  @override
  Future<double> getAverageResponseTimeTrend(String patientId, {int days = 7}) async {
    final sampleLimit = (days * 2).clamp(7, 30);
    final results = await _localDataSource.getRecentResults(patientId, limit: sampleLimit);
    if (results.isEmpty) return AppConstants.defaultResponseTimeBaselineMs;
    final sum = results.fold<double>(0.0, (prev, curr) => prev + curr.avgResponseTimeMs);
    return double.parse((sum / results.length).toStringAsFixed(1));
  }
}
