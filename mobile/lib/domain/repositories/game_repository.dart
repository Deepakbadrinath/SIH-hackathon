import '../models/game_models.dart';

abstract class GameRepository {
  Future<void> saveGameSession(GameSession session);
  Future<void> saveGameResult(GameResult result);
  Future<void> savePerformanceMetrics(List<PerformanceMetrics> metrics);
  Future<void> saveDifficultyHistory(DifficultyHistory history);
  Future<int> getLatestDifficultyLevel(String patientId, GameType gameType);
  Future<List<GameResult>> getRecentResults(String patientId, {int limit = 10});
  Future<List<DifficultyHistory>> getDifficultyHistory(String patientId, GameType gameType, {int limit = 10});
  Future<double> getAverageAccuracyTrend(String patientId, {int days = 7});
  Future<double> getAverageResponseTimeTrend(String patientId, {int days = 7});
}
