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
import 'package:smriti_setu/features/games/presentation/controllers/object_sorting_controller.dart';
import 'package:smriti_setu/features/games/presentation/screens/object_sorting_screen.dart';
import 'package:smriti_setu/features/voice/data/services/voice_service_impl.dart';
import 'package:smriti_setu/features/voice/presentation/controllers/voice_controller.dart';

class FakeSortingGameRepository implements GameRepository {
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

class _SortingTestLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _SortingTestLocalizationsDelegate();
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
  bool shouldReload(_SortingTestLocalizationsDelegate old) => false;
}

Widget _buildSortingApp({
  required ObjectSortingController sortingCtrl,
  required AdaptiveDifficultyController adaptiveCtrl,
  required VoiceController voiceCtrl,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<ObjectSortingController>.value(value: sortingCtrl),
      ChangeNotifierProvider<AdaptiveDifficultyController>.value(value: adaptiveCtrl),
      ChangeNotifierProvider<VoiceController>.value(value: voiceCtrl),
    ],
    child: MaterialApp(
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        _SortingTestLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AccessibleTheme.getLightTheme(),
      home: const ObjectSortingScreen(),
    ),
  );
}

void main() {
  group('Phase 7: Object Sorting Gameplay & Integration Tests', () {
    late FakeSortingGameRepository fakeRepo;
    late AdaptiveDifficultyController adaptiveCtrl;
    late VoiceController voiceCtrl;
    late ObjectSortingController sortingCtrl;

    setUp(() {
      fakeRepo = FakeSortingGameRepository();
      adaptiveCtrl = AdaptiveDifficultyController();
      voiceCtrl = VoiceController(voiceService: VoiceServiceImpl());
      sortingCtrl = ObjectSortingController(
        gameRepository: fakeRepo,
        adaptiveController: adaptiveCtrl,
        voiceController: voiceCtrl,
      );
      sortingCtrl.configureForTesting(
        isDeterministic: true,
        fixedResponseTimeMs: 1600,
        fixedHesitationMs: 320,
      );
      sortingCtrl.initializeGame(patientId: 'patient_sort_001');
    });

    testWidgets('1. Start: Instructions render and Start Game transitions to Playing state',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _buildSortingApp(
          sortingCtrl: sortingCtrl,
          adaptiveCtrl: adaptiveCtrl,
          voiceCtrl: voiceCtrl,
        ),
      );
      await tester.pumpAndSettle();

      // Verify instruction title and instruction text
      expect(find.text('Object Sorting'), findsWidgets);
      expect(find.text('Tap each object into its matching group.'), findsOneWidget);
      expect(find.text('Start Game'), findsOneWidget);

      // Tap Start Game
      await tester.ensureVisible(find.text('Start Game'));
      await tester.tap(find.text('Start Game'));
      await tester.pumpAndSettle();

      expect(sortingCtrl.currentStep, equals(ObjectSortingStep.playing));
      expect(find.text('Item 1 of 4'), findsOneWidget);
      expect(find.text('Which group does this belong to?'), findsOneWidget);
    });

    testWidgets('2. Gameplay: Displays central object card and accessible category cards',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      sortingCtrl.startGame();

      await tester.pumpWidget(
        _buildSortingApp(
          sortingCtrl: sortingCtrl,
          adaptiveCtrl: adaptiveCtrl,
          voiceCtrl: voiceCtrl,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Item 1 of 4'), findsOneWidget);
      expect(find.text('Which group does this belong to?'), findsOneWidget);

      final currentTrial = sortingCtrl.currentTrial!;
      expect(find.text(currentTrial.targetObject.name), findsOneWidget);
      expect(find.text(currentTrial.targetObject.description), findsOneWidget);

      for (final cat in currentTrial.activeCategories) {
        expect(find.text(cat.name), findsOneWidget);
      }
    });

    testWidgets('3. Interaction: Tapping category advances through all 4 items',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      sortingCtrl.startGame();

      await tester.pumpWidget(
        _buildSortingApp(
          sortingCtrl: sortingCtrl,
          adaptiveCtrl: adaptiveCtrl,
          voiceCtrl: voiceCtrl,
        ),
      );
      await tester.pumpAndSettle();

      // Item 1
      expect(find.text('Item 1 of 4'), findsOneWidget);
      final correctCat1 = sortingCtrl.currentTrial!.activeCategories[sortingCtrl.currentTrial!.correctCategoryIndex];
      await tester.ensureVisible(find.text(correctCat1.name));
      await tester.tap(find.text(correctCat1.name));
      await tester.pumpAndSettle();

      // Item 2
      expect(find.text('Item 2 of 4'), findsOneWidget);
      final correctCat2 = sortingCtrl.currentTrial!.activeCategories[sortingCtrl.currentTrial!.correctCategoryIndex];
      await tester.ensureVisible(find.text(correctCat2.name));
      await tester.tap(find.text(correctCat2.name));
      await tester.pumpAndSettle();

      // Item 3
      expect(find.text('Item 3 of 4'), findsOneWidget);
      final correctCat3 = sortingCtrl.currentTrial!.activeCategories[sortingCtrl.currentTrial!.correctCategoryIndex];
      await tester.ensureVisible(find.text(correctCat3.name));
      await tester.tap(find.text(correctCat3.name));
      await tester.pumpAndSettle();

      // Item 4
      expect(find.text('Item 4 of 4'), findsOneWidget);
      final correctCat4 = sortingCtrl.currentTrial!.activeCategories[sortingCtrl.currentTrial!.correctCategoryIndex];
      await tester.ensureVisible(find.text(correctCat4.name));
      await tester.tap(find.text(correctCat4.name));
      await tester.pumpAndSettle();

      // Completed
      expect(sortingCtrl.currentStep, equals(ObjectSortingStep.completed));
    });

    testWidgets('4. Completion: Shows friendly non-clinical result, stars, and play again button',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      sortingCtrl.startGame();

      await tester.pumpWidget(
        _buildSortingApp(
          sortingCtrl: sortingCtrl,
          adaptiveCtrl: adaptiveCtrl,
          voiceCtrl: voiceCtrl,
        ),
      );
      await tester.pumpAndSettle();

      // Play all 4 trials correctly
      for (int i = 0; i < 4; i++) {
        final correctCat = sortingCtrl.currentTrial!.activeCategories[sortingCtrl.currentTrial!.correctCategoryIndex];
        await tester.ensureVisible(find.text(correctCat.name));
        await tester.tap(find.text(correctCat.name));
        await tester.pumpAndSettle();
      }

      // Check results view
      expect(find.text('Wonderful effort today!'), findsOneWidget);
      expect(find.text('Accuracy'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
      expect(find.text('Sorted Correctly'), findsOneWidget);
      expect(find.text('4 of 4'), findsOneWidget);
      expect(find.text('Play Again'), findsOneWidget);
      expect(find.text('Back to Home'), findsOneWidget);
    });

    testWidgets('5. Saving Results: Persists session, game result, performance metrics, and difficulty to SQLite repository',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      sortingCtrl.startGame();

      await tester.pumpWidget(
        _buildSortingApp(
          sortingCtrl: sortingCtrl,
          adaptiveCtrl: adaptiveCtrl,
          voiceCtrl: voiceCtrl,
        ),
      );
      await tester.pumpAndSettle();

      // Play 4 trials: 3 correct, 1 incorrect
      for (int i = 0; i < 4; i++) {
        final trial = sortingCtrl.currentTrial!;
        if (i == 1) {
          // Select wrong category
          final wrongIdx = trial.correctCategoryIndex == 0 ? 1 : 0;
          final wrongCat = trial.activeCategories[wrongIdx];
          await tester.ensureVisible(find.text(wrongCat.name));
          await tester.tap(find.text(wrongCat.name));
        } else {
          final correctCat = trial.activeCategories[trial.correctCategoryIndex];
          await tester.ensureVisible(find.text(correctCat.name));
          await tester.tap(find.text(correctCat.name));
        }
        await tester.pumpAndSettle();
      }

      // Verify GameSession was saved
      expect(fakeRepo.savedSessions.length, equals(1));
      final savedSession = fakeRepo.savedSessions.first;
      expect(savedSession.patientId, equals('patient_sort_001'));
      expect(savedSession.gameType, equals(GameType.objectSorting));
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
      expect(history.patientId, equals('patient_sort_001'));
      expect(history.gameType, equals(GameType.objectSorting));
    });
  });
}
