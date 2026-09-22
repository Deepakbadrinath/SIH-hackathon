import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../../domain/models/game_models.dart';
import '../../../../domain/repositories/game_repository.dart';
import '../../../adaptive_difficulty/presentation/controllers/adaptive_difficulty_controller.dart';
import '../../../voice/presentation/controllers/voice_controller.dart';
import '../../domain/models/object_sorting_models.dart';

enum ObjectSortingStep {
  instructions,
  playing,
  trialFeedback,
  completed,
}

class ObjectSortingController extends ChangeNotifier {
  final GameRepository _gameRepository;
  final AdaptiveDifficultyController? _adaptiveController;
  final VoiceController? _voiceController;
  static const _uuid = Uuid();

  ObjectSortingStep _currentStep = ObjectSortingStep.instructions;
  int _currentDifficulty = 1;
  SortingDifficultyConfig _difficultyConfig = SortingDifficultyConfig.forLevel(1);
  String _patientId = 'p_elder_001';

  List<ObjectSortingTrial> _trials = [];
  int _currentTrialIndex = 0;
  final List<ObjectSortingTrialResult> _trialResults = [];
  SortingSessionScore? _sessionScore;

  DateTime? _sessionStartTime;
  DateTime? _trialStartTime;
  int? _selectedCategoryIndex;
  bool _isCorrectFeedback = false;
  bool _isSaving = false;

  // Test determinism hooks
  bool _isDeterministicForTesting = false;
  int? _fixedResponseTimeMs;
  int? _fixedHesitationMs;

  ObjectSortingController({
    required GameRepository gameRepository,
    AdaptiveDifficultyController? adaptiveController,
    VoiceController? voiceController,
  })  : _gameRepository = gameRepository,
        _adaptiveController = adaptiveController,
        _voiceController = voiceController;

  // Getters
  ObjectSortingStep get currentStep => _currentStep;
  int get currentDifficulty => _currentDifficulty;
  SortingDifficultyConfig get difficultyConfig => _difficultyConfig;
  String get patientId => _patientId;
  List<ObjectSortingTrial> get trials => List.unmodifiable(_trials);
  int get currentTrialIndex => _currentTrialIndex;
  ObjectSortingTrial? get currentTrial =>
      (_trials.isNotEmpty && _currentTrialIndex < _trials.length)
          ? _trials[_currentTrialIndex]
          : null;
  List<ObjectSortingTrialResult> get trialResults => List.unmodifiable(_trialResults);
  SortingSessionScore? get sessionScore => _sessionScore;
  int? get selectedCategoryIndex => _selectedCategoryIndex;
  bool get isCorrectFeedback => _isCorrectFeedback;
  bool get isSaving => _isSaving;

  void configureForTesting({
    bool isDeterministic = true,
    int fixedResponseTimeMs = 1800,
    int fixedHesitationMs = 350,
  }) {
    _isDeterministicForTesting = isDeterministic;
    _fixedResponseTimeMs = fixedResponseTimeMs;
    _fixedHesitationMs = fixedHesitationMs;
  }

  void initializeGame({
    String patientId = 'p_elder_001',
    int? difficultyLevel,
    List<SortableObject>? customObjects,
    List<SortCategory>? customCategories,
  }) {
    _patientId = patientId;
    _currentDifficulty = (difficultyLevel ?? 1).clamp(1, 5);
    _difficultyConfig = SortingDifficultyConfig.forLevel(_currentDifficulty);
    _currentStep = ObjectSortingStep.instructions;
    _currentTrialIndex = 0;
    _trialResults.clear();
    _sessionScore = null;
    _selectedCategoryIndex = null;
    _isSaving = false;

    _trials = ObjectSortingGenerator.generateTrials(
      config: _difficultyConfig,
      customObjects: customObjects,
      customCategories: customCategories,
      isDeterministic: _isDeterministicForTesting,
    );
    notifyListeners();
  }

  void startGame() {
    _currentStep = ObjectSortingStep.playing;
    _sessionStartTime = DateTime.now();
    _trialStartTime = DateTime.now();
    _currentTrialIndex = 0;
    _selectedCategoryIndex = null;

    _playVoicePromptForCurrentTrial();
    notifyListeners();
  }

  void _playVoicePromptForCurrentTrial() {
    if (currentTrial != null && _voiceController != null) {
      _voiceController!.speakText(
        'Look at the item on screen: ${currentTrial!.targetObject.name}. Tap the category group it belongs to below.',
      );
    }
  }

  Future<void> selectCategory(int categoryIndex) async {
    if (_currentStep != ObjectSortingStep.playing || currentTrial == null) return;

    _selectedCategoryIndex = categoryIndex;
    final now = DateTime.now();
    final trial = currentTrial!;
    final isCorrect = categoryIndex == trial.correctCategoryIndex;
    _isCorrectFeedback = isCorrect;

    final responseTimeMs = _isDeterministicForTesting
        ? (_fixedResponseTimeMs ?? 1800)
        : (_trialStartTime != null
            ? now.difference(_trialStartTime!).inMilliseconds
            : 2200);

    final hesitationMs = _isDeterministicForTesting
        ? (_fixedHesitationMs ?? 350)
        : (responseTimeMs * 0.22).round();

    final result = ObjectSortingTrialResult(
      trialNumber: trial.trialNumber,
      objectId: trial.targetObject.id,
      targetCategoryId: trial.targetObject.category.id,
      selectedCategoryId: trial.activeCategories[categoryIndex].id,
      isCorrect: isCorrect,
      responseTimeMs: responseTimeMs,
      hesitationMs: hesitationMs,
    );

    _trialResults.add(result);
    _currentStep = ObjectSortingStep.trialFeedback;
    notifyListeners();

    if (!_isDeterministicForTesting) {
      await Future.delayed(const Duration(milliseconds: 900));
    }

    _advanceNextTrialOrComplete();
  }

  void _advanceNextTrialOrComplete() {
    if (_currentTrialIndex + 1 < _trials.length) {
      _currentTrialIndex++;
      _selectedCategoryIndex = null;
      _currentStep = ObjectSortingStep.playing;
      _trialStartTime = DateTime.now();
      _playVoicePromptForCurrentTrial();
      notifyListeners();
    } else {
      finishGame();
    }
  }

  Future<void> finishGame() async {
    _isSaving = true;
    _currentStep = ObjectSortingStep.completed;

    _sessionScore = ObjectSortingScoreCalculator.calculate(
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
      gameType: GameType.objectSorting,
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
      gameType: GameType.objectSorting,
      score: _sessionScore!.calculatedScore,
      maxPossibleScore: _sessionScore!.maxPossibleScore,
      accuracyPercentage: _sessionScore!.accuracyPercentage,
      totalTrials: _sessionScore!.totalTrials,
      correctTrials: _sessionScore!.correctCount,
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
        stimulusId: r.objectId,
        userResponse: r.selectedCategoryId,
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
          gameType: GameType.objectSorting,
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
      if (kDebugMode) print('Error saving object sorting session: $e');
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  void speakCurrentInstruction() {
    if (_currentStep == ObjectSortingStep.instructions && _voiceController != null) {
      _voiceController!.speakText(
        'Look at each familiar object displayed on screen. Tap the group it belongs to. Take your time, there is no hurry.',
      );
    } else if (_currentStep == ObjectSortingStep.playing && currentTrial != null && _voiceController != null) {
      _playVoicePromptForCurrentTrial();
    }
  }
}
