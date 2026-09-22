import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../../domain/models/game_models.dart';
import '../../../../domain/repositories/game_repository.dart';
import '../../../adaptive_difficulty/presentation/controllers/adaptive_difficulty_controller.dart';
import '../../../voice/presentation/controllers/voice_controller.dart';
import '../../domain/models/face_match_models.dart';

enum FaceMatchStep {
  instructions,
  playing,
  trialFeedback,
  completed,
}

class FaceMatchController extends ChangeNotifier {
  final GameRepository _gameRepository;
  final AdaptiveDifficultyController? _adaptiveController;
  final VoiceController? _voiceController;
  static const _uuid = Uuid();

  FaceMatchStep _currentStep = FaceMatchStep.instructions;
  int _currentDifficulty = 1;
  String _patientId = 'p_elder_001';

  List<FaceMatchTrial> _trials = [];
  int _currentTrialIndex = 0;
  final List<FaceMatchTrialResult> _trialResults = [];
  FaceMatchSessionScore? _sessionScore;

  DateTime? _sessionStartTime;
  DateTime? _trialStartTime;
  int? _selectedOptionIndex;
  bool _isCorrectFeedback = false;
  bool _isSaving = false;

  // Test determinism hooks
  bool _isDeterministicForTesting = false;
  int? _fixedResponseTimeMs;
  int? _fixedHesitationMs;

  FaceMatchController({
    required GameRepository gameRepository,
    AdaptiveDifficultyController? adaptiveController,
    VoiceController? voiceController,
  })  : _gameRepository = gameRepository,
        _adaptiveController = adaptiveController,
        _voiceController = voiceController;

  // Getters
  FaceMatchStep get currentStep => _currentStep;
  int get currentDifficulty => _currentDifficulty;
  String get patientId => _patientId;
  List<FaceMatchTrial> get trials => List.unmodifiable(_trials);
  int get currentTrialIndex => _currentTrialIndex;
  FaceMatchTrial? get currentTrial =>
      (_trials.isNotEmpty && _currentTrialIndex < _trials.length)
          ? _trials[_currentTrialIndex]
          : null;
  List<FaceMatchTrialResult> get trialResults => List.unmodifiable(_trialResults);
  FaceMatchSessionScore? get sessionScore => _sessionScore;
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
    List<FaceProfile>? customProfiles,
  }) {
    _patientId = patientId;
    _currentDifficulty = difficultyLevel ?? 1;
    _currentStep = FaceMatchStep.instructions;
    _currentTrialIndex = 0;
    _trialResults.clear();
    _sessionScore = null;
    _selectedOptionIndex = null;
    _isSaving = false;

    _generateTrials(customProfiles ?? DefaultFaceProfiles.all);
    notifyListeners();
  }

  void _generateTrials(List<FaceProfile> profiles) {
    _trials = [];
    final count = profiles.length;
    if (count < 2) return;

    // Number of options based on difficulty: 2 options for lvl 1, 3 for lvl 2, 4 for lvl 3+
    final optionsCount = (_currentDifficulty == 1 ? 2 : (_currentDifficulty == 2 ? 3 : 4))
        .clamp(2, count);

    for (int i = 0; i < count; i++) {
      final target = profiles[i];
      final distractors = profiles.where((p) => p.id != target.id).toList();

      if (!_isDeterministicForTesting) {
        distractors.shuffle();
      }

      final options = [target, ...distractors.take(optionsCount - 1)];

      if (!_isDeterministicForTesting) {
        options.shuffle();
      } else {
        // Deterministic: alternate target between index 0 and index 1
        if (i % 2 == 1 && options.length > 1) {
          final temp = options[0];
          options[0] = options[1];
          options[1] = temp;
        }
      }

      final correctIndex = options.indexWhere((p) => p.id == target.id);

      _trials.add(
        FaceMatchTrial(
          trialNumber: i + 1,
          targetFace: target,
          options: options,
          correctIndex: correctIndex,
        ),
      );
    }
  }

  void startGame() {
    _currentStep = FaceMatchStep.playing;
    _sessionStartTime = DateTime.now();
    _trialStartTime = DateTime.now();
    _currentTrialIndex = 0;
    _selectedOptionIndex = null;

    _playVoicePromptForCurrentTrial();
    notifyListeners();
  }

  void _playVoicePromptForCurrentTrial() {
    if (currentTrial != null && _voiceController != null) {
      _voiceController!.speakText(currentTrial!.targetFace.voicePrompt);
    }
  }

  Future<void> selectAnswer(int optionIndex) async {
    if (_currentStep != FaceMatchStep.playing || currentTrial == null) return;

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

    final result = FaceMatchTrialResult(
      trialNumber: trial.trialNumber,
      targetFaceId: trial.targetFace.id,
      selectedFaceId: trial.options[optionIndex].id,
      isCorrect: isCorrect,
      responseTimeMs: responseTimeMs,
      hesitationMs: hesitationMs,
    );

    _trialResults.add(result);
    _currentStep = FaceMatchStep.trialFeedback;
    notifyListeners();

    // Brief delay to display gentle feedback, then proceed
    if (!_isDeterministicForTesting) {
      await Future.delayed(const Duration(milliseconds: 900));
    }

    _advanceNextTrialOrComplete();
  }

  void _advanceNextTrialOrComplete() {
    if (_currentTrialIndex + 1 < _trials.length) {
      _currentTrialIndex++;
      _selectedOptionIndex = null;
      _currentStep = FaceMatchStep.playing;
      _trialStartTime = DateTime.now();
      _playVoicePromptForCurrentTrial();
      notifyListeners();
    } else {
      finishGame();
    }
  }

  Future<void> finishGame() async {
    _isSaving = true;
    _currentStep = FaceMatchStep.completed;

    _sessionScore = FamilyFaceMatchScoreCalculator.calculate(
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
      gameType: GameType.familyFaceMatch,
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
      gameType: GameType.familyFaceMatch,
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
        stimulusId: r.targetFaceId,
        userResponse: r.selectedFaceId,
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
          gameType: GameType.familyFaceMatch,
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
      if (kDebugMode) print('Error saving face match session: $e');
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  void speakCurrentInstruction() {
    if (_currentStep == FaceMatchStep.instructions && _voiceController != null) {
      _voiceController!.speakText(
        'Look closely at the family member shown on screen, then tap the matching photo below.',
      );
    } else if (_currentStep == FaceMatchStep.playing && currentTrial != null && _voiceController != null) {
      _voiceController!.speakText(currentTrial!.targetFace.voicePrompt);
    }
  }
}
