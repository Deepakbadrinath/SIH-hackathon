import 'package:flutter/foundation.dart';
import '../../../../data/adaptive/adaptive_difficulty_engine.dart';
import '../../../../domain/services/adaptive_difficulty_service.dart';

class AdaptiveDifficultyController extends ChangeNotifier {
  final IAdaptiveDifficultyEngine _engine;
  DifficultyDecision? _latestDecision;
  final List<double> _sessionHistory = [];

  AdaptiveDifficultyController({IAdaptiveDifficultyEngine? engine})
      : _engine = engine ?? AdaptiveDifficultyEngine();

  DifficultyDecision? get latestDecision => _latestDecision;
  List<double> get sessionHistory => List.unmodifiable(_sessionHistory);

  DifficultyDecision calculateNextDifficulty({
    required int currentDifficulty,
    required double accuracy,
    required double avgResponseTimeMs,
    required double hesitationMs,
    required int errorCount,
  }) {
    final input = DifficultyEvaluationInput(
      currentDifficulty: currentDifficulty,
      accuracyPercentage: accuracy,
      avgResponseTimeMs: avgResponseTimeMs,
      totalHesitationMs: hesitationMs,
      errorCount: errorCount,
      historicalScores: _sessionHistory,
    );

    final decision = _engine.evaluateDifficulty(input);
    _latestDecision = decision;
    _sessionHistory.add(decision.singleSessionScore);
    if (_sessionHistory.length > 10) {
      _sessionHistory.removeAt(0);
    }
    notifyListeners();
    return decision;
  }

  void resetHistory() {
    _sessionHistory.clear();
    _latestDecision = null;
    notifyListeners();
  }
}
