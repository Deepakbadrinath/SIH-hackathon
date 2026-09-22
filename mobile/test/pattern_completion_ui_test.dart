import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:smriti_setu/core/localization/app_localizations.dart';
import 'package:smriti_setu/core/theme/accessible_theme.dart';
import 'package:smriti_setu/domain/models/game_models.dart';
import 'package:smriti_setu/domain/repositories/game_repository.dart';
import 'package:smriti_setu/features/adaptive_difficulty/presentation/controllers/adaptive_difficulty_controller.dart';
import 'package:smriti_setu/features/games/presentation/controllers/pattern_completion_controller.dart';
import 'package:smriti_setu/features/games/presentation/screens/pattern_completion_screen.dart';
import 'package:smriti_setu/features/voice/data/services/voice_service_impl.dart';
import 'package:smriti_setu/features/voice/presentation/controllers/voice_controller.dart';

class FakePatternGameRepository implements GameRepository {
  final List<GameSession> savedSessions = [];
  final List<GameResult> savedResults = [];
  final List<PerformanceMetrics> savedMetrics = [];
  final List<DifficultyHistory> savedHistories = [];

  @override
  Future<void> saveGameSession(GameSession session) async {
    savedSessions.add(session);
  }

  @override
  Future<void> saveGameResult(GameResult result) async {
    savedResults.add(result);
  }

  @override
  Future<void> savePerformanceMetrics(List<PerformanceMetrics> metrics) async {
    savedMetrics.addAll(metrics);
  }

  @override
  Future<void> saveDifficultyHistory(DifficultyHistory history) async {
    savedHistories.add(history);
  }

  @override
  Future<int> getLatestDifficultyLevel(String patientId, GameType gameType) async => 1;

  @override
  Future<List<GameResult>> getRecentResults(String patientId, {int limit = 10}) async => savedResults;

  @override
  Future<List<DifficultyHistory>> getDifficultyHistory(String patientId, GameType gameType, {int limit = 10}) async => savedHistories;

  @override
  Future<double> getAverageAccuracyTrend(String patientId, {int days = 7}) async => 85.0;

  @override
  Future<double> getAverageResponseTimeTrend(String patientId, {int days = 7}) async => 1800.0;
}

class _PatternTestLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _PatternTestLocalizationsDelegate();
  @override
  bool isSupported(Locale locale) => true;
  @override
  Future<AppLocalizations> load(Locale locale) async {
    final file = File('assets/i18n/en.json');
    if (file.existsSync()) {
      final jsonMap = json.decode(file.readAsStringSync()) as Map<String, dynamic>;
      final map = <String, String>{};
      jsonMap.forEach((k, v) {
        if (k != '_metadata') map[k] = v.toString();
      });
      return AppLocalizations(locale, map, jsonMap['_metadata'] as Map<String, dynamic>?);
    }
    return AppLocalizations(locale, {});
  }
  @override
  bool shouldReload(_PatternTestLocalizationsDelegate old) => false;
}

Widget _buildPatternApp({
  required PatternCompletionController patternCtrl,
  required AdaptiveDifficultyController adaptiveCtrl,
  required VoiceController voiceCtrl,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<PatternCompletionController>.value(value: patternCtrl),
      ChangeNotifierProvider<AdaptiveDifficultyController>.value(value: adaptiveCtrl),
      ChangeNotifierProvider<VoiceController>.value(value: voiceCtrl),
    ],
    child: MaterialApp(
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        _PatternTestLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AccessibleTheme.getLightTheme(),
      home: const PatternCompletionScreen(),
    ),
  );
}

void main() {
  group('Phase 5: Pattern Completion Gameplay & Integration Tests', () {
    late FakePatternGameRepository fakeRepo;
    late AdaptiveDifficultyController adaptiveCtrl;
    late VoiceController voiceCtrl;
    late PatternCompletionController patternCtrl;

    setUp(() {
      fakeRepo = FakePatternGameRepository();
      adaptiveCtrl = AdaptiveDifficultyController();
      voiceCtrl = VoiceController(voiceService: VoiceServiceImpl());
      patternCtrl = PatternCompletionController(
        gameRepository: fakeRepo,
        adaptiveController: adaptiveCtrl,
        voiceController: voiceCtrl,
      );
      patternCtrl.configureForTesting(
        isDeterministic: true,
        fixedResponseTimeMs: 1600,
        fixedHesitationMs: 320,
      );
      patternCtrl.initializeGame(patientId: 'patient_pattern_001', trialCount: 3);
    });

    testWidgets('1. Start: Instructions render and Start Game transitions to Playing state',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _buildPatternApp(
          patternCtrl: patternCtrl,
          adaptiveCtrl: adaptiveCtrl,
          voiceCtrl: voiceCtrl,
        ),
      );
      await tester.pumpAndSettle();

      // Verify instruction title and instruction text
      expect(find.text('Pattern Completion'), findsWidgets);
      expect(find.text('Which symbol comes next to complete the pattern?'), findsOneWidget);
      expect(find.text('Start Game'), findsOneWidget);

      // Tap Start Game
      await tester.ensureVisible(find.text('Start Game'));
      await tester.tap(find.text('Start Game'));
      await tester.pumpAndSettle();

      expect(patternCtrl.currentStep, equals(PatternCompletionStep.playing));
      expect(find.text('Pattern 1 of 3'), findsOneWidget);
      expect(find.text('Observe the Pattern:'), findsOneWidget);
    });

    testWidgets('2. Gameplay: Displays sequence items, mystery tile, and candidate options with large touch targets',
        (WidgetTester tester) async {
      patternCtrl.startGame();

      await tester.pumpWidget(
        _buildPatternApp(
          patternCtrl: patternCtrl,
          adaptiveCtrl: adaptiveCtrl,
          voiceCtrl: voiceCtrl,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pattern 1 of 3'), findsOneWidget);
      expect(find.text('Observe the Pattern:'), findsOneWidget);
      expect(find.text('?'), findsOneWidget);
      expect(find.text('Which symbol completes the pattern?'), findsOneWidget);

      final currentTrial = patternCtrl.currentTrial!;
      expect(currentTrial.choices.length, equals(2)); // Level 1 has 2 choices

      for (final choice in currentTrial.choices) {
        expect(find.text(choice.name), findsWidgets);
      }
    });

    testWidgets('3. Answer & Progress: Tapping answers advances through all 3 trials',
        (WidgetTester tester) async {
      patternCtrl.startGame();

      await tester.pumpWidget(
        _buildPatternApp(
          patternCtrl: patternCtrl,
          adaptiveCtrl: adaptiveCtrl,
          voiceCtrl: voiceCtrl,
        ),
      );
      await tester.pumpAndSettle();

      // Trial 1
      expect(find.text('Pattern 1 of 3'), findsOneWidget);
      final trial1Target = patternCtrl.currentTrial!.targetMissingSymbol;
      await tester.tap(find.text(trial1Target.name).last);
      await tester.pumpAndSettle();

      // Trial 2
      expect(find.text('Pattern 2 of 3'), findsOneWidget);
      final trial2Target = patternCtrl.currentTrial!.targetMissingSymbol;
      await tester.tap(find.text(trial2Target.name).last);
      await tester.pumpAndSettle();

      // Trial 3
      expect(find.text('Pattern 3 of 3'), findsOneWidget);
      final trial3Target = patternCtrl.currentTrial!.targetMissingSymbol;
      await tester.tap(find.text(trial3Target.name).last);
      await tester.pumpAndSettle();

      // Completed
      expect(patternCtrl.currentStep, equals(PatternCompletionStep.completed));
    });

    testWidgets('4. Completion: Shows friendly non-clinical result, stars, and play again button',
        (WidgetTester tester) async {
      patternCtrl.startGame();

      await tester.pumpWidget(
        _buildPatternApp(
          patternCtrl: patternCtrl,
          adaptiveCtrl: adaptiveCtrl,
          voiceCtrl: voiceCtrl,
        ),
      );
      await tester.pumpAndSettle();

      // Play through all 3 trials correctly
      for (int i = 0; i < 3; i++) {
        final target = patternCtrl.currentTrial!.targetMissingSymbol;
        await tester.tap(find.text(target.name).last);
        await tester.pumpAndSettle();
      }

      // Check results view
      expect(find.text('Wonderful effort today!'), findsOneWidget);
      expect(find.text('Accuracy'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
      expect(find.text('Patterns Solved'), findsOneWidget);
      expect(find.text('3 of 3'), findsOneWidget);
      expect(find.text('Play Again'), findsOneWidget);
      expect(find.text('Back to Home'), findsOneWidget);
    });

    testWidgets('5. Saving Results: Persists session, game result, performance metrics, and difficulty to SQLite repository',
        (WidgetTester tester) async {
      patternCtrl.startGame();

      await tester.pumpWidget(
        _buildPatternApp(
          patternCtrl: patternCtrl,
          adaptiveCtrl: adaptiveCtrl,
          voiceCtrl: voiceCtrl,
        ),
      );
      await tester.pumpAndSettle();

      // Play 3 trials: trial 1 correct, trial 2 distractor (incorrect), trial 3 correct
      for (int i = 0; i < 3; i++) {
        if (i == 1) {
          // Tap incorrect choice
          final trial = patternCtrl.currentTrial!;
          final distractorIndex = trial.correctIndex == 0 ? 1 : 0;
          final distractorName = trial.choices[distractorIndex].name;
          await tester.tap(find.text(distractorName).last);
        } else {
          final target = patternCtrl.currentTrial!.targetMissingSymbol;
          await tester.tap(find.text(target.name).last);
        }
        await tester.pumpAndSettle();
      }

      // Verify GameSession was saved
      expect(fakeRepo.savedSessions.length, equals(1));
      final savedSession = fakeRepo.savedSessions.first;
      expect(savedSession.patientId, equals('patient_pattern_001'));
      expect(savedSession.gameType, equals(GameType.patternCompletion));
      expect(savedSession.isCompleted, isTrue);

      // Verify GameResult was saved
      expect(fakeRepo.savedResults.length, equals(1));
      final savedResult = fakeRepo.savedResults.first;
      expect(savedResult.sessionId, equals(savedSession.id));
      expect(savedResult.totalTrials, equals(3));
      expect(savedResult.correctTrials, equals(2));
      expect(savedResult.errorCount, equals(1));
      expect(savedResult.accuracyPercentage, equals(66.7));

      // Verify 3 PerformanceMetrics were saved
      expect(fakeRepo.savedMetrics.length, equals(3));
      expect(fakeRepo.savedMetrics.map((m) => m.trialNumber).toList(), equals([1, 2, 3]));
      expect(fakeRepo.savedMetrics.where((m) => m.isCorrect).length, equals(2));
      expect(fakeRepo.savedMetrics.where((m) => !m.isCorrect).length, equals(1));

      // Verify Adaptive Difficulty evaluation and history persistence
      expect(fakeRepo.savedHistories.length, equals(1));
      final history = fakeRepo.savedHistories.first;
      expect(history.patientId, equals('patient_pattern_001'));
      expect(history.gameType, equals(GameType.patternCompletion));
    });
  });
}
