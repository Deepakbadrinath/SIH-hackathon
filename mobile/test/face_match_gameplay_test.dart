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
import 'package:smriti_setu/features/games/presentation/controllers/face_match_controller.dart';
import 'package:smriti_setu/features/games/presentation/screens/face_match_screen.dart';
import 'package:smriti_setu/features/voice/data/services/voice_service_impl.dart';
import 'package:smriti_setu/features/voice/presentation/controllers/voice_controller.dart';

class FakeGameRepository implements GameRepository {
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

class _TestLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _TestLocalizationsDelegate();
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
  bool shouldReload(_TestLocalizationsDelegate old) => false;
}

Widget _buildFaceMatchApp({
  required FaceMatchController faceMatchCtrl,
  required AdaptiveDifficultyController adaptiveCtrl,
  required VoiceController voiceCtrl,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<FaceMatchController>.value(value: faceMatchCtrl),
      ChangeNotifierProvider<AdaptiveDifficultyController>.value(value: adaptiveCtrl),
      ChangeNotifierProvider<VoiceController>.value(value: voiceCtrl),
    ],
    child: MaterialApp(
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        _TestLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AccessibleTheme.getLightTheme(),
      home: const FaceMatchScreen(),
    ),
  );
}

void main() {
  group('Phase 4: Family Face Match Gameplay & Integration Tests', () {
    late FakeGameRepository fakeRepo;
    late AdaptiveDifficultyController adaptiveCtrl;
    late VoiceController voiceCtrl;
    late FaceMatchController faceMatchCtrl;

    setUp(() {
      fakeRepo = FakeGameRepository();
      adaptiveCtrl = AdaptiveDifficultyController();
      voiceCtrl = VoiceController(voiceService: VoiceServiceImpl());
      faceMatchCtrl = FaceMatchController(
        gameRepository: fakeRepo,
        adaptiveController: adaptiveCtrl,
        voiceController: voiceCtrl,
      );
      faceMatchCtrl.configureForTesting(
        isDeterministic: true,
        fixedResponseTimeMs: 1400,
        fixedHesitationMs: 250,
      );
      faceMatchCtrl.initializeGame(patientId: 'patient_test_101');
    });

    testWidgets('1. Start: Instructions render and Start Game transitions to Playing state',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _buildFaceMatchApp(
          faceMatchCtrl: faceMatchCtrl,
          adaptiveCtrl: adaptiveCtrl,
          voiceCtrl: voiceCtrl,
        ),
      );
      await tester.pumpAndSettle();

      // Verify instruction header and button
      expect(find.text('Family Face Match'), findsWidgets);
      expect(find.text('Look at the photo and tap the matching family member.'), findsOneWidget);
      expect(find.text('Start Game'), findsOneWidget);

      // Tap Start Game
      await tester.ensureVisible(find.text('Start Game'));
      await tester.tap(find.text('Start Game'));
      await tester.pumpAndSettle();

      expect(faceMatchCtrl.currentStep, equals(FaceMatchStep.playing));
      expect(find.text('Face 1 of 4'), findsOneWidget);
      expect(find.text('Who is this family member?'), findsOneWidget);
    });

    testWidgets('2. Gameplay: Displays target card and candidate options with large touch targets',
        (WidgetTester tester) async {
      faceMatchCtrl.startGame();

      await tester.pumpWidget(
        _buildFaceMatchApp(
          faceMatchCtrl: faceMatchCtrl,
          adaptiveCtrl: adaptiveCtrl,
          voiceCtrl: voiceCtrl,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Face 1 of 4'), findsOneWidget);
      expect(find.text('Who is this family member?'), findsOneWidget);
      expect(find.text('Tap the matching photo:'), findsOneWidget);

      // Verify 2 options exist for level 1
      final currentTrial = faceMatchCtrl.currentTrial!;
      expect(currentTrial.options.length, equals(2));

      for (final opt in currentTrial.options) {
        expect(find.text(opt.name), findsOneWidget);
      }
    });

    testWidgets('3. Answer & Progress: Tapping answers advances through all 4 trials',
        (WidgetTester tester) async {
      faceMatchCtrl.startGame();

      await tester.pumpWidget(
        _buildFaceMatchApp(
          faceMatchCtrl: faceMatchCtrl,
          adaptiveCtrl: adaptiveCtrl,
          voiceCtrl: voiceCtrl,
        ),
      );
      await tester.pumpAndSettle();

      // Trial 1: Answer correctly
      expect(find.text('Face 1 of 4'), findsOneWidget);
      final trial1CorrectName = faceMatchCtrl.currentTrial!.targetFace.name;
      await tester.tap(find.text(trial1CorrectName));
      await tester.pumpAndSettle();

      // Trial 2
      expect(find.text('Face 2 of 4'), findsOneWidget);
      final trial2CorrectName = faceMatchCtrl.currentTrial!.targetFace.name;
      await tester.tap(find.text(trial2CorrectName));
      await tester.pumpAndSettle();

      // Trial 3
      expect(find.text('Face 3 of 4'), findsOneWidget);
      final trial3CorrectName = faceMatchCtrl.currentTrial!.targetFace.name;
      await tester.tap(find.text(trial3CorrectName));
      await tester.pumpAndSettle();

      // Trial 4
      expect(find.text('Face 4 of 4'), findsOneWidget);
      final trial4CorrectName = faceMatchCtrl.currentTrial!.targetFace.name;
      await tester.tap(find.text(trial4CorrectName));
      await tester.pumpAndSettle();

      // Completed!
      expect(faceMatchCtrl.currentStep, equals(FaceMatchStep.completed));
    });

    testWidgets('4. Completion: Shows friendly non-clinical result, stars, and play again button',
        (WidgetTester tester) async {
      faceMatchCtrl.startGame();

      await tester.pumpWidget(
        _buildFaceMatchApp(
          faceMatchCtrl: faceMatchCtrl,
          adaptiveCtrl: adaptiveCtrl,
          voiceCtrl: voiceCtrl,
        ),
      );
      await tester.pumpAndSettle();

      // Play through all 4 trials
      for (int i = 0; i < 4; i++) {
        final targetName = faceMatchCtrl.currentTrial!.targetFace.name;
        await tester.tap(find.text(targetName));
        await tester.pumpAndSettle();
      }

      // Check results view
      expect(find.text('Wonderful effort today!'), findsOneWidget);
      expect(find.text('Accuracy'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
      expect(find.text('Matched Correctly'), findsOneWidget);
      expect(find.text('4 of 4'), findsOneWidget);
      expect(find.text('Play Again'), findsOneWidget);
      expect(find.text('Back to Home'), findsOneWidget);
    });

    testWidgets('5. Saving Results: Persists session, game result, performance metrics, and difficulty to SQLite repository',
        (WidgetTester tester) async {
      faceMatchCtrl.startGame();

      await tester.pumpWidget(
        _buildFaceMatchApp(
          faceMatchCtrl: faceMatchCtrl,
          adaptiveCtrl: adaptiveCtrl,
          voiceCtrl: voiceCtrl,
        ),
      );
      await tester.pumpAndSettle();

      // Play 4 trials (3 correct, 1 distractor tap)
      for (int i = 0; i < 4; i++) {
        if (i == 1) {
          // Select distractor (incorrect)
          final trial = faceMatchCtrl.currentTrial!;
          final distractorIndex = trial.correctIndex == 0 ? 1 : 0;
          final distractorName = trial.options[distractorIndex].name;
          await tester.tap(find.text(distractorName));
        } else {
          final targetName = faceMatchCtrl.currentTrial!.targetFace.name;
          await tester.tap(find.text(targetName));
        }
        await tester.pumpAndSettle();
      }

      // Verify GameSession was saved
      expect(fakeRepo.savedSessions.length, equals(1));
      final savedSession = fakeRepo.savedSessions.first;
      expect(savedSession.patientId, equals('patient_test_101'));
      expect(savedSession.gameType, equals(GameType.familyFaceMatch));
      expect(savedSession.isCompleted, isTrue);

      // Verify GameResult was saved
      expect(fakeRepo.savedResults.length, equals(1));
      final savedResult = fakeRepo.savedResults.first;
      expect(savedResult.sessionId, equals(savedSession.id));
      expect(savedResult.totalTrials, equals(4));
      expect(savedResult.correctTrials, equals(3));
      expect(savedResult.errorCount, equals(1));
      expect(savedResult.accuracyPercentage, equals(75.0));

      // Verify 4 PerformanceMetrics were saved
      expect(fakeRepo.savedMetrics.length, equals(4));
      expect(fakeRepo.savedMetrics.map((m) => m.trialNumber).toList(), equals([1, 2, 3, 4]));
      expect(fakeRepo.savedMetrics.where((m) => m.isCorrect).length, equals(3));
      expect(fakeRepo.savedMetrics.where((m) => !m.isCorrect).length, equals(1));

      // Verify Adaptive Difficulty evaluation and history persistence
      expect(fakeRepo.savedHistories.length, equals(1));
      final history = fakeRepo.savedHistories.first;
      expect(history.patientId, equals('patient_test_101'));
      expect(history.gameType, equals(GameType.familyFaceMatch));
    });
  });
}
