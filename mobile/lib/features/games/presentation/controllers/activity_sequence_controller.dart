import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../../domain/models/game_models.dart';
import '../../../../domain/repositories/game_repository.dart';
import '../../../adaptive_difficulty/presentation/controllers/adaptive_difficulty_controller.dart';
import '../../../voice/presentation/controllers/voice_controller.dart';
import '../../domain/models/activity_sequence_models.dart';

enum ActivitySequenceStep {
  instructions,
  playing,
  trialFeedback,
  completed,
}

class ActivitySequenceController extends ChangeNotifier {
  final GameRepository _gameRepository;
  final AdaptiveDifficultyController? _adaptiveController;
  final VoiceController? _voiceController;
  static const _uuid = Uuid();

  ActivitySequenceStep _currentStep = ActivitySequenceStep.instructions;
  int _currentDifficulty = 1;
  SequenceDifficultyConfig _difficultyConfig = SequenceDifficultyConfig.forLevel(1);
  String _patientId = 'p_elder_001';

  List<ActivitySequenceTrial> _trials = [];
  int _currentTrialIndex = 0;
  final List<ActivitySequenceTrialResult> _trialResults = [];
  SequenceSessionScore? _sessionScore;

  // Active trial slot state
  List<ActivityStep?> _placedSteps = [];
  List<ActivityStep> _unplacedChoices = [];

  DateTime? _sessionStartTime;
  DateTime? _trialStartTime;
  DateTime? _lastActionTime;
  int _accumulatedHesitationMs = 0;
  bool _isSaving = false;

  // Test determinism hooks
  bool _isDeterministicForTesting = false;
  int? _fixedResponseTimeMs;
  int? _fixedHesitationMs;

  ActivitySequenceController({
    required GameRepository gameRepository,
    AdaptiveDifficultyController? adaptiveController,
    VoiceController? voiceController,
  })  : _gameRepository = gameRepository,
        _adaptiveController = adaptiveController,
        _voiceController = voiceController;

  // Getters
  ActivitySequenceStep get currentStep => _currentStep;
  int get currentDifficulty => _currentDifficulty;
  SequenceDifficultyConfig get difficultyConfig => _difficultyConfig;
  String get patientId => _patientId;
  List<ActivitySequenceTrial> get trials => List.unmodifiable(_trials);
  int get currentTrialIndex => _currentTrialIndex;
  ActivitySequenceTrial? get currentTrial =>
      (_trials.isNotEmpty && _currentTrialIndex < _trials.length)
          ? _trials[_currentTrialIndex]
          : null;
  List<ActivitySequenceTrialResult> get trialResults => List.unmodifiable(_trialResults);
  SequenceSessionScore? get sessionScore => _sessionScore;
  List<ActivityStep?> get placedSteps => List.unmodifiable(_placedSteps);
  List<ActivityStep> get unplacedChoices => List.unmodifiable(_unplacedChoices);
  bool get isAllSlotsFilled => _placedSteps.isNotEmpty && _placedSteps.every((s) => s != null);
  bool get isSaving => _isSaving;

  void configureForTesting({
    bool isDeterministic = true,
    int fixedResponseTimeMs = 3000,
    int fixedHesitationMs = 500,
  }) {
    _isDeterministicForTesting = isDeterministic;
    _fixedResponseTimeMs = fixedResponseTimeMs;
    _fixedHesitationMs = fixedHesitationMs;
  }

  void initializeGame({
    String patientId = 'p_elder_001',
    int? difficultyLevel,
    int trialCount = 3,
    List<ActivityRoutineTheme>? customThemes,
  }) {
    _patientId = patientId;
    _currentDifficulty = (difficultyLevel ?? 1).clamp(1, 5);
    _difficultyConfig = SequenceDifficultyConfig.forLevel(_currentDifficulty);
    _currentStep = ActivitySequenceStep.instructions;
    _currentTrialIndex = 0;
    _trialResults.clear();
    _sessionScore = null;
    _isSaving = false;

    _generateTrials(trialCount: trialCount, customThemes: customThemes);
    _setupCurrentTrialSlots();
    notifyListeners();
  }

  void _generateTrials({
    required int trialCount,
    List<ActivityRoutineTheme>? customThemes,
  }) {
    _trials = List.generate(
      trialCount,
      (i) => ActivitySequenceGenerator.generateTrial(
        trialNumber: i + 1,
        config: _difficultyConfig,
        customThemes: customThemes,
        isDeterministic: _isDeterministicForTesting,
      ),
    );
  }

  void _setupCurrentTrialSlots() {
    if (currentTrial == null) {
      _placedSteps = [];
      _unplacedChoices = [];
      return;
    }

    final slotCount = currentTrial!.targetSteps.length;
    _placedSteps = List<ActivityStep?>.filled(slotCount, null);
    _unplacedChoices = List<ActivityStep>.from(currentTrial!.availableChoices);
    _accumulatedHesitationMs = 0;
  }

  void startGame() {
    _currentStep = ActivitySequenceStep.playing;
    _sessionStartTime = DateTime.now();
    _trialStartTime = DateTime.now();
    _lastActionTime = DateTime.now();
    _currentTrialIndex = 0;
    _setupCurrentTrialSlots();

    _playVoicePromptForCurrentTrial();
    notifyListeners();
  }

  void _playVoicePromptForCurrentTrial() {
    if (currentTrial != null && _voiceController != null) {
      _voiceController!.speakText(currentTrial!.routineTheme.voicePrompt);
    }
  }

  /// Tapping an available activity places it into the first vacant slot
  void placeStep(ActivityStep step) {
    if (_currentStep != ActivitySequenceStep.playing) return;

    final vacantIndex = _placedSteps.indexOf(null);
    if (vacantIndex == -1) return; // All slots already filled

    _recordActionTiming();
    _placedSteps[vacantIndex] = step;
    _unplacedChoices.remove(step);
    notifyListeners();
  }

  /// Tapping an activity inside a slot removes it and returns it to the pool
  void removeStepFromSlot(int slotIndex) {
    if (_currentStep != ActivitySequenceStep.playing) return;
    if (slotIndex < 0 || slotIndex >= _placedSteps.length) return;

    final removed = _placedSteps[slotIndex];
    if (removed != null) {
      _recordActionTiming();
      _placedSteps[slotIndex] = null;
      if (!_unplacedChoices.contains(removed)) {
        _unplacedChoices.add(removed);
      }
      notifyListeners();
    }
  }

  /// Clears all slots and restores all choices to unplaced pool
  void resetPlacedSteps() {
    if (_currentStep != ActivitySequenceStep.playing || currentTrial == null) return;

    _recordActionTiming();
    _placedSteps = List<ActivityStep?>.filled(currentTrial!.targetSteps.length, null);
    _unplacedChoices = List<ActivityStep>.from(currentTrial!.availableChoices);
    notifyListeners();
  }

  void _recordActionTiming() {
    final now = DateTime.now();
    if (_lastActionTime != null) {
      final gap = now.difference(_lastActionTime!).inMilliseconds;
      if (gap > 1500) {
        _accumulatedHesitationMs += (gap - 1500);
      }
    }
    _lastActionTime = now;
  }

  /// Evaluates sequence order when user taps Confirm Order
  Future<void> confirmSequence() async {
    if (_currentStep != ActivitySequenceStep.playing || currentTrial == null) return;
    if (!isAllSlotsFilled) return;

    final now = DateTime.now();
    final trial = currentTrial!;
    final targetSteps = trial.targetSteps;

    int correctCount = 0;
    final placedIds = <String>[];
    final targetIds = targetSteps.map((s) => s.id).toList();

    for (int i = 0; i < targetSteps.length; i++) {
      final placed = _placedSteps[i];
      if (placed != null) {
        placedIds.add(placed.id);
        if (placed.id == targetSteps[i].id) {
          correctCount++;
        }
      }
    }

    final totalSlots = targetSteps.length;
    final errorCount = totalSlots - correctCount;
    final isPerfect = correctCount == totalSlots;

    final responseTimeMs = _isDeterministicForTesting
        ? (_fixedResponseTimeMs ?? 3000)
        : (_trialStartTime != null
            ? now.difference(_trialStartTime!).inMilliseconds
            : 3500);

    final hesitationMs = _isDeterministicForTesting
        ? (_fixedHesitationMs ?? 500)
        : (_accumulatedHesitationMs > 0
            ? _accumulatedHesitationMs
            : (responseTimeMs * 0.20).round());

    final result = ActivitySequenceTrialResult(
      trialNumber: trial.trialNumber,
      routineId: trial.routineTheme.id,
      targetStepIds: targetIds,
      placedStepIds: placedIds,
      correctlyPlacedCount: correctCount,
      totalSlots: totalSlots,
      errorCount: errorCount,
      isPerfect: isPerfect,
      responseTimeMs: responseTimeMs,
      hesitationMs: hesitationMs,
    );

    _trialResults.add(result);
    _currentStep = ActivitySequenceStep.trialFeedback;
    notifyListeners();

    if (!_isDeterministicForTesting) {
      await Future.delayed(const Duration(milliseconds: 1000));
    }

    _advanceNextTrialOrComplete();
  }

  void _advanceNextTrialOrComplete() {
    if (_currentTrialIndex + 1 < _trials.length) {
      _currentTrialIndex++;
      _currentStep = ActivitySequenceStep.playing;
      _setupCurrentTrialSlots();
      _trialStartTime = DateTime.now();
      _lastActionTime = DateTime.now();
      _playVoicePromptForCurrentTrial();
      notifyListeners();
    } else {
      finishGame();
    }
  }

  Future<void> finishGame() async {
    _isSaving = true;
    _currentStep = ActivitySequenceStep.completed;

    _sessionScore = ActivitySequenceScoreCalculator.calculate(
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
      gameType: GameType.activitySequence,
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
      gameType: GameType.activitySequence,
      score: _sessionScore!.calculatedScore,
      maxPossibleScore: _sessionScore!.maxPossibleScore,
      accuracyPercentage: _sessionScore!.accuracyPercentage,
      totalTrials: _sessionScore!.totalTrials,
      correctTrials: _trialResults.where((r) => r.isPerfect).length,
      errorCount: _sessionScore!.totalErrors,
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
        stimulusId: r.routineId,
        userResponse: r.placedStepIds.join(','),
        isCorrect: r.isPerfect,
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
          errorCount: _sessionScore!.totalErrors,
        );

        final history = DifficultyHistory(
          id: _uuid.v4(),
          patientId: _patientId,
          gameType: GameType.activitySequence,
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
      if (kDebugMode) print('Error saving activity sequence session: $e');
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  void speakCurrentInstruction() {
    if (_currentStep == ActivitySequenceStep.instructions && _voiceController != null) {
      _voiceController!.speakText(
        'Read each daily activity step. Tap the activity you do first, then second, and next to put them in order. There is no rush.',
      );
    } else if (_currentStep == ActivitySequenceStep.playing && currentTrial != null && _voiceController != null) {
      _playVoicePromptForCurrentTrial();
    }
  }
}
