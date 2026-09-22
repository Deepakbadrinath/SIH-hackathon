import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../../domain/models/game_models.dart';
import '../../../../domain/repositories/game_repository.dart';
import '../../../adaptive_difficulty/presentation/controllers/adaptive_difficulty_controller.dart';
import '../../../voice/presentation/controllers/voice_controller.dart';
import '../../domain/models/pattern_completion_models.dart';

enum PatternCompletionStep {
  instructions,
  playing,
  trialFeedback,
  completed,
}

class PatternCompletionController extends ChangeNotifier {
  final GameRepository _gameRepository;
  final AdaptiveDifficultyController? _adaptiveController;
  final VoiceController? _voiceController;
  static const _uuid = Uuid();

  PatternCompletionStep _currentStep = PatternCompletionStep.instructions;
  int _currentDifficulty = 1;
  PatternDifficultyConfig _difficultyConfig = PatternDifficultyConfig.forLevel(1);
  String _patientId = 'p_elder_001';

  List<PatternTrial> _trials = [];
  int _currentTrialIndex = 0;
  final List<PatternTrialResult> _trialResults = [];
  PatternSessionScore? _sessionScore;

  DateTime? _sessionStartTime;
  DateTime? _trialStartTime;
  int? _selectedOptionIndex;
  bool _isCorrectFeedback = false;
  bool _isSaving = false;

  // Test determinism hooks
  bool _isDeterministicForTesting = false;
  int? _fixedResponseTimeMs;
  int? _fixedHesitationMs;

  PatternCompletionController({
    required GameRepository gameRepository,
    AdaptiveDifficultyController? adaptiveController,
    VoiceController? voiceController,
  })  : _gameRepository = gameRepository,
        _adaptiveController = adaptiveController,
        _voiceController = voiceController;

  // Getters
  PatternCompletionStep get currentStep => _currentStep;
  int get currentDifficulty => _currentDifficulty;
  PatternDifficultyConfig get difficultyConfig => _difficultyConfig;
  String get patientId => _patientId;
  List<PatternTrial> get trials => List.unmodifiable(_trials);
  int get currentTrialIndex => _currentTrialIndex;
  PatternTrial? get currentTrial =>
      (_trials.isNotEmpty && _currentTrialIndex < _trials.length)
          ? _trials[_currentTrialIndex]
          : null;
  List<PatternTrialResult> get trialResults => List.unmodifiable(_trialResults);
  PatternSessionScore? get sessionScore => _sessionScore;
  int? get selectedOptionIndex => _selectedOptionIndex;
  bool get isCorrectFeedback => _isCorrectFeedback;
  bool get isSaving => _isSaving;

  void configureForTesting({
    bool isDeterministic = true,
    int fixedResponseTimeMs = 1500,
    int fixedHesitationMs = 300,
  }) {
    _isDeterministicForTesting = isDeterministic;
    _fixedResponseTimeMs = fixedResponseTimeMs;
    _fixedHesitationMs = fixedHesitationMs;
  }

  void initializeGame({
    String patientId = 'p_elder_001',
    int? difficultyLevel,
    int trialCount = 5,
    List<PatternSymbol>? customSymbols,
  }) {
    _patientId = patientId;
    _currentDifficulty = (difficultyLevel ?? 1).clamp(1, 5);
    _difficultyConfig = PatternDifficultyConfig.forLevel(_currentDifficulty);
    _currentStep = PatternCompletionStep.instructions;
    _currentTrialIndex = 0;
    _trialResults.clear();
    _sessionScore = null;
    _selectedOptionIndex = null;
    _isSaving = false;

    _generateTrials(trialCount: trialCount, customSymbols: customSymbols);
    notifyListeners();
  }

  void _generateTrials({
    required int trialCount,
    List<PatternSymbol>? customSymbols,
  }) {
    _trials = List.generate(
      trialCount,
      (i) => PatternGenerator.generateTrial(
        trialNumber: i + 1,
        config: _difficultyConfig,
        customSymbols: customSymbols,
        isDeterministic: _isDeterministicForTesting,
      ),
    );
  }

  void startGame() {
    _currentStep = PatternCompletionStep.playing;
    _sessionStartTime = DateTime.now();
    _trialStartTime = DateTime.now();
    _currentTrialIndex = 0;
    _selectedOptionIndex = null;

    _playVoicePromptForCurrentTrial();
    notifyListeners();
  }

  void _playVoicePromptForCurrentTrial() {
    if (currentTrial != null && _voiceController != null) {
      _voiceController!.speakText(
        'Observe the symbols in row. Look at the question mark, then tap the symbol that completes the pattern.',
      );
    }
  }

  Future<void> selectAnswer(int optionIndex) async {
    if (_currentStep != PatternCompletionStep.playing || currentTrial == null) return;

    _selectedOptionIndex = optionIndex;
    final now = DateTime.now();
    final trial = currentTrial!;
    final isCorrect = optionIndex == trial.correctIndex;
    _isCorrectFeedback = isCorrect;

    final responseTimeMs = _isDeterministicForTesting
        ? (_fixedResponseTimeMs ?? 1500)
        : (_trialStartTime != null
            ? now.difference(_trialStartTime!).inMilliseconds
            : 2000);

    final hesitationMs = _isDeterministicForTesting
        ? (_fixedHesitationMs ?? 300)
        : (responseTimeMs * 0.25).round();

    final result = PatternTrialResult(
      trialNumber: trial.trialNumber,
      targetSymbolId: trial.targetMissingSymbol.id,
      selectedSymbolId: trial.choices[optionIndex].id,
      isCorrect: isCorrect,
      responseTimeMs: responseTimeMs,
      hesitationMs: hesitationMs,
    );

    _trialResults.add(result);
    _currentStep = PatternCompletionStep.trialFeedback;
    notifyListeners();

    // Gentle delay to absorb feedback, skipped in deterministic tests
    if (!_isDeterministicForTesting) {
      await Future.delayed(const Duration(milliseconds: 900));
    }

    _advanceNextTrialOrComplete();
  }

  void _advanceNextTrialOrComplete() {
    if (_currentTrialIndex + 1 < _trials.length) {
      _currentTrialIndex++;
      _selectedOptionIndex = null;
      _currentStep = PatternCompletionStep.playing;
      _trialStartTime = DateTime.now();
      _playVoicePromptForCurrentTrial();
      notifyListeners();
    } else {
      finishGame();
    }
  }

  Future<void> finishGame() async {
    _isSaving = true;
    _currentStep = PatternCompletionStep.completed;

    _sessionScore = PatternScoreCalculator.calculate(
      _trialResults,
      difficultyLevel: _currentDifficulty,
    );
    notifyListeners();

    final now = DateTime.now();
    final sessionId = _uuid.v4();

    // 1. Create GameSession
    final session = GameSession(
      id: sessionId,
      patientId: _patientId,
      gameType: GameType.patternCompletion,
      startTime: _sessionStartTime ?? now.subtract(const Duration(minutes: 2)),
      endTime: now,
      difficultyLevel: _currentDifficulty,
      isCompleted: true,
      createdAt: now,
      updatedAt: now,
      isSynced: false,
    );

    // 2. Create GameResult
    final gameResult = GameResult(
      id: _uuid.v4(),
      sessionId: sessionId,
      gameType: GameType.patternCompletion,
      score: _sessionScore!.calculatedScore,
      maxPossibleScore: _sessionScore!.maxPossibleScore,
      accuracyPercentage: _sessionScore!.accuracyPercentage,
      totalTrials: _sessionScore!.totalTrials,
      correctTrials: _sessionScore!.correctTrials,
      errorCount: _sessionScore!.errorCount,
      avgResponseTimeMs: _sessionScore!.avgResponseTimeMs,
      totalHesitationPauseMs: _sessionScore!.totalHesitationMs,
      completedAt: now,
      createdAt: now,
      updatedAt: now,
      isSynced: false,
    );

    // 3. Create PerformanceMetrics for each trial
    final metrics = _trialResults.map((r) {
      return PerformanceMetrics(
        id: _uuid.v4(),
        sessionId: sessionId,
        trialNumber: r.trialNumber,
        stimulusId: r.targetSymbolId,
        userResponse: r.selectedSymbolId,
        isCorrect: r.isCorrect,
        responseTimeMs: r.responseTimeMs,
        hesitationDurationMs: r.hesitationMs,
        recordedAt: now,
        isSynced: false,
      );
    }).toList();

    try {
      // Save locally to SQLite via Repository
      await _gameRepository.saveGameSession(session);
      await _gameRepository.saveGameResult(gameResult);
      await _gameRepository.savePerformanceMetrics(metrics);

      // 4. Feed metrics to AdaptiveDifficultyEngine
      if (_adaptiveController != null) {
        final decision = _adaptiveController!.calculateNextDifficulty(
          currentDifficulty: _currentDifficulty,
          accuracy: _sessionScore!.accuracyPercentage / 100.0,
          avgResponseTimeMs: _sessionScore!.avgResponseTimeMs,
          hesitationMs: _sessionScore!.totalHesitationMs,
          errorCount: _sessionScore!.errorCount,
        );

        final history = DifficultyHistory(
          id: _uuid.v4(),
          patientId: _patientId,
          gameType: GameType.patternCompletion,
          previousDifficulty: _currentDifficulty,
          newDifficulty: decision.nextDifficulty,
          reason: decision.description,
          calculatedPerformanceScore: decision.singleSessionScore,
          calculatedAt: now,
          isSynced: false,
        );

        await _gameRepository.saveDifficultyHistory(history);
      }
    } catch (e) {
      if (kDebugMode) print('Error saving pattern completion session: $e');
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  void speakCurrentInstruction() {
    if (_currentStep == PatternCompletionStep.instructions && _voiceController != null) {
      _voiceController!.speakText(
        'Study the sequence of symbols shown on the cards. One card is marked with a question mark. Select the symbol below that completes the sequence.',
      );
    } else if (_currentStep == PatternCompletionStep.playing && currentTrial != null && _voiceController != null) {
      _playVoicePromptForCurrentTrial();
    }
  }
}
