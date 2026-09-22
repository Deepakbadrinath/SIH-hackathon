/// Telemetry metrics fed into the Adaptive Difficulty Engine.
class DifficultyEvaluationInput {
  final int currentDifficulty;
  final double accuracyPercentage; // 0.0 to 1.0
  final double avgResponseTimeMs;
  final double totalHesitationMs;
  final int errorCount;
  final List<double> historicalScores; // Recent session performance scores

  const DifficultyEvaluationInput({
    required this.currentDifficulty,
    double? accuracy,
    double? accuracyPercentage,
    double? averageResponseTime,
    double? avgResponseTimeMs,
    double? hesitationTime,
    double? totalHesitationMs,
    this.errorCount = 0,
    List<double>? recentSessionPerformance,
    List<double>? historicalScores,
  })  : accuracyPercentage = accuracy ?? accuracyPercentage ?? 0.0,
        avgResponseTimeMs = averageResponseTime ?? avgResponseTimeMs ?? 2000.0,
        totalHesitationMs = hesitationTime ?? totalHesitationMs ?? 500.0,
        historicalScores = recentSessionPerformance ?? historicalScores ?? const [];

  // Semantic aliases
  double get accuracy => accuracyPercentage;
  double get averageResponseTime => avgResponseTimeMs;
  double get hesitationTime => totalHesitationMs;
  List<double> get recentSessionPerformance => historicalScores;
}

/// Explicit, explainable decision produced by the Adaptive Difficulty Engine.
class DifficultyDecision {
  final int previousDifficulty;
  final int nextDifficulty;
  final double singleSessionScore;
  final double rollingPerformanceScore;
  final String reasonCode;
  final String description;
  final String reason;
  final double confidence; // 0.0 to 1.0 (statistical confidence based on session volume & stability)
  final Map<String, dynamic> configuration; // Game parameters configured for nextDifficulty

  const DifficultyDecision({
    required this.previousDifficulty,
    required this.nextDifficulty,
    required this.singleSessionScore,
    required this.rollingPerformanceScore,
    required this.reasonCode,
    required this.description,
    String? reason,
    this.confidence = 0.85,
    this.configuration = const {},
  }) : reason = reason ?? description;

  bool get isPromoted => nextDifficulty > previousDifficulty;
  bool get isDemoted => nextDifficulty < previousDifficulty;
  bool get isMaintained => nextDifficulty == previousDifficulty;
}

/// Standalone domain interface for difficulty adaptation.
abstract class IAdaptiveDifficultyEngine {
  DifficultyDecision evaluateDifficulty(DifficultyEvaluationInput input);
  Map<String, dynamic> getDifficultyConfiguration(int level);
}
