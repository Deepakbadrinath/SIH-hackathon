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
import 'package:smriti_setu/features/games/presentation/controllers/activity_sequence_controller.dart';
import 'package:smriti_setu/features/games/presentation/screens/activity_sequence_screen.dart';
import 'package:smriti_setu/features/voice/data/services/voice_service_impl.dart';
import 'package:smriti_setu/features/voice/presentation/controllers/voice_controller.dart';

class FakeSequenceGameRepository implements GameRepository {
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

class _SequenceTestLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _SequenceTestLocalizationsDelegate();
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
  bool shouldReload(_SequenceTestLocalizationsDelegate old) => false;
}

Widget _buildSequenceApp({
  required ActivitySequenceController sequenceCtrl,
  required AdaptiveDifficultyController adaptiveCtrl,
  required VoiceController voiceCtrl,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<ActivitySequenceController>.value(value: sequenceCtrl),
      ChangeNotifierProvider<AdaptiveDifficultyController>.value(value: adaptiveCtrl),
      ChangeNotifierProvider<VoiceController>.value(value: voiceCtrl),
    ],
    child: MaterialApp(
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        _SequenceTestLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AccessibleTheme.getLightTheme(),
      home: const ActivitySequenceScreen(),
    ),
  );
}

void main() {
  group('Phase 6: Activity Sequence Gameplay & Integration Tests', () {
    late FakeSequenceGameRepository fakeRepo;
    late AdaptiveDifficultyController adaptiveCtrl;
    late VoiceController voiceCtrl;
    late ActivitySequenceController sequenceCtrl;

    setUp(() {
      fakeRepo = FakeSequenceGameRepository();
      adaptiveCtrl = AdaptiveDifficultyController();
      voiceCtrl = VoiceController(voiceService: VoiceServiceImpl());
      sequenceCtrl = ActivitySequenceController(
        gameRepository: fakeRepo,
        adaptiveController: adaptiveCtrl,
        voiceController: voiceCtrl,
      );
      sequenceCtrl.configureForTesting(
        isDeterministic: true,
        fixedResponseTimeMs: 2800,
        fixedHesitationMs: 450,
      );
      sequenceCtrl.initializeGame(patientId: 'patient_seq_001', trialCount: 2);
    });

    testWidgets('1. Start: Instructions render and Start Game transitions to Playing state',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _buildSequenceApp(
          sequenceCtrl: sequenceCtrl,
          adaptiveCtrl: adaptiveCtrl,
          voiceCtrl: voiceCtrl,
        ),
      );
      await tester.pumpAndSettle();

      // Verify instruction title and instruction text
      expect(find.text('Daily Activity Sequence'), findsWidgets);
      expect(find.text('Arrange these everyday steps in the correct order.'), findsOneWidget);
      expect(find.text('Start Game'), findsOneWidget);

      // Tap Start Game
      await tester.ensureVisible(find.text('Start Game'));
      await tester.tap(find.text('Start Game'));
      await tester.pumpAndSettle();

      expect(sequenceCtrl.currentStep, equals(ActivitySequenceStep.playing));
      expect(find.text('Routine 1 of 2'), findsOneWidget);
      expect(find.text('Numbered Steps (Tap placed card to remove):'), findsOneWidget);
    });

    testWidgets('2. Gameplay: Displays numbered empty slots and unplaced available choices',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      sequenceCtrl.startGame();

      await tester.pumpWidget(
        _buildSequenceApp(
          sequenceCtrl: sequenceCtrl,
          adaptiveCtrl: adaptiveCtrl,
          voiceCtrl: voiceCtrl,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Routine 1 of 2'), findsOneWidget);
      expect(find.text('Empty Step 1 — Tap an activity below to place here'), findsOneWidget);
      expect(find.text('Empty Step 2 — Tap an activity below to place here'), findsOneWidget);
      expect(find.text('Empty Step 3 — Tap an activity below to place here'), findsOneWidget);
      expect(find.text('Available Activities (Tap to place):'), findsOneWidget);

      final currentTrial = sequenceCtrl.currentTrial!;
      expect(currentTrial.targetSteps.length, equals(3));
      for (final step in currentTrial.availableChoices) {
        expect(find.text(step.label), findsWidgets);
      }
    });

    testWidgets('3. Interaction: Placing an activity occupies next slot, tapping placed removes it, and full slots enable Confirm Order',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      sequenceCtrl.startGame();

      await tester.pumpWidget(
        _buildSequenceApp(
          sequenceCtrl: sequenceCtrl,
          adaptiveCtrl: adaptiveCtrl,
          voiceCtrl: voiceCtrl,
        ),
      );
      await tester.pumpAndSettle();

      // Tap first available choice
      final choice1 = sequenceCtrl.unplacedChoices.first;
      await tester.ensureVisible(find.text(choice1.label).last);
      await tester.tap(find.text(choice1.label).last);
      await tester.pumpAndSettle();

      // Slot 1 should now be filled with choice1
      expect(sequenceCtrl.placedSteps[0]?.id, equals(choice1.id));
      expect(sequenceCtrl.unplacedChoices.contains(choice1), isFalse);

      // Tap the placed card in Slot 1 to remove it
      await tester.ensureVisible(find.text(choice1.label).first);
      await tester.tap(find.text(choice1.label).first);
      await tester.pumpAndSettle();

      // Slot 1 is empty again and choice1 is back in unplaced
      expect(sequenceCtrl.placedSteps[0], isNull);
      expect(sequenceCtrl.unplacedChoices.contains(choice1), isTrue);

      // Now place 3 items to fill all slots
      for (final targetStep in sequenceCtrl.currentTrial!.targetSteps) {
        await tester.ensureVisible(find.text(targetStep.label).last);
        await tester.tap(find.text(targetStep.label).last);
        await tester.pumpAndSettle();
      }

      expect(sequenceCtrl.isAllSlotsFilled, isTrue);

      // Confirm Order button is enabled and taps successfully
      await tester.ensureVisible(find.text('Confirm Order'));
      await tester.tap(find.text('Confirm Order'));
      await tester.pumpAndSettle();

      // Moves to Routine 2
      expect(find.text('Routine 2 of 2'), findsOneWidget);
    });

    testWidgets('4. Completion: Shows friendly non-clinical result, stars, and play again button',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      sequenceCtrl.startGame();

      await tester.pumpWidget(
        _buildSequenceApp(
          sequenceCtrl: sequenceCtrl,
          adaptiveCtrl: adaptiveCtrl,
          voiceCtrl: voiceCtrl,
        ),
      );
      await tester.pumpAndSettle();

      // Play trial 1 (fill in correct canonical order)
      for (final step in sequenceCtrl.currentTrial!.targetSteps) {
        await tester.ensureVisible(find.text(step.label).last);
        await tester.tap(find.text(step.label).last);
        await tester.pumpAndSettle();
      }
      await tester.ensureVisible(find.text('Confirm Order'));
      await tester.tap(find.text('Confirm Order'));
      await tester.pumpAndSettle();

      // Play trial 2 (fill in correct canonical order)
      for (final step in sequenceCtrl.currentTrial!.targetSteps) {
        await tester.ensureVisible(find.text(step.label).last);
        await tester.tap(find.text(step.label).last);
        await tester.pumpAndSettle();
      }
      await tester.ensureVisible(find.text('Confirm Order'));
      await tester.tap(find.text('Confirm Order'));
      await tester.pumpAndSettle();

      // Completed view
      expect(sequenceCtrl.currentStep, equals(ActivitySequenceStep.completed));
      expect(find.text('Wonderful effort today!'), findsOneWidget);
      expect(find.text('Accuracy'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
      expect(find.text('Steps Ordered Correctly'), findsOneWidget);
      expect(find.text('6 of 6'), findsOneWidget);
      expect(find.text('Play Again'), findsOneWidget);
      expect(find.text('Back to Home'), findsOneWidget);
    });

    testWidgets('5. Saving Results: Persists session, game result, performance metrics, and difficulty to SQLite repository',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      sequenceCtrl.startGame();

      await tester.pumpWidget(
        _buildSequenceApp(
          sequenceCtrl: sequenceCtrl,
          adaptiveCtrl: adaptiveCtrl,
          voiceCtrl: voiceCtrl,
        ),
      );
      await tester.pumpAndSettle();

      // Trial 1: Place all correctly
      for (final step in sequenceCtrl.currentTrial!.targetSteps) {
        await tester.ensureVisible(find.text(step.label).last);
        await tester.tap(find.text(step.label).last);
        await tester.pumpAndSettle();
      }
      await tester.ensureVisible(find.text('Confirm Order'));
      await tester.tap(find.text('Confirm Order'));
      await tester.pumpAndSettle();

      // Trial 2: Place in reverse order (swapping slots)
      final reversedSteps = sequenceCtrl.currentTrial!.targetSteps.reversed.toList();
      for (final step in reversedSteps) {
        await tester.ensureVisible(find.text(step.label).last);
        await tester.tap(find.text(step.label).last);
        await tester.pumpAndSettle();
      }
      await tester.ensureVisible(find.text('Confirm Order'));
      await tester.tap(find.text('Confirm Order'));
      await tester.pumpAndSettle();

      // Verify GameSession was saved
      expect(fakeRepo.savedSessions.length, equals(1));
      final savedSession = fakeRepo.savedSessions.first;
      expect(savedSession.patientId, equals('patient_seq_001'));
      expect(savedSession.gameType, equals(GameType.activitySequence));
      expect(savedSession.isCompleted, isTrue);

      // Verify GameResult was saved
      expect(fakeRepo.savedResults.length, equals(1));
      final savedResult = fakeRepo.savedResults.first;
      expect(savedResult.sessionId, equals(savedSession.id));
      expect(savedResult.totalTrials, equals(2));
      expect(savedResult.gameType, equals(GameType.activitySequence));

      // Verify PerformanceMetrics were saved for each trial
      expect(fakeRepo.savedMetrics.length, equals(2));
      expect(fakeRepo.savedMetrics[0].trialNumber, equals(1));
      expect(fakeRepo.savedMetrics[1].trialNumber, equals(2));

      // Verify Adaptive Difficulty evaluation and history persistence
      expect(fakeRepo.savedHistories.length, equals(1));
      final history = fakeRepo.savedHistories.first;
      expect(history.patientId, equals('patient_seq_001'));
      expect(history.gameType, equals(GameType.activitySequence));
    });
  });
}
