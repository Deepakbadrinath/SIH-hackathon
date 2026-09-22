import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:smriti_setu/core/config/app_config.dart';
import 'package:smriti_setu/features/adaptive_difficulty/presentation/controllers/adaptive_difficulty_controller.dart';
import 'package:smriti_setu/features/elderly_home/presentation/controllers/elderly_home_controller.dart';
import 'package:smriti_setu/features/localization/presentation/controllers/localization_controller.dart';
import 'package:smriti_setu/features/settings/presentation/controllers/settings_controller.dart';

void main() {
  setUpAll(() {
    AppConfig.initialize(Environment.development);
  });

  group('Phase 1 Architecture & State Management Tests', () {
    test('AppConfig initializes development environment correctly', () {
      expect(AppConfig.current.isDevelopment, isTrue);
      expect(AppConfig.current.isProduction, isFalse);
      expect(AppConfig.current.syncBatchSize, equals(10));
      expect(AppConfig.current.enableMockVoice, isTrue);
    });

    test('LocalizationController changes locale and detects RTL', () {
      final locController = LocalizationController();
      expect(locController.currentLocale.languageCode, equals('as'));
      expect(locController.isRtl, isFalse);

      locController.setLanguageCode('ar');
      expect(locController.currentLocale.languageCode, equals('ar'));
      expect(locController.isRtl, isTrue);

      locController.setLanguageCode('en');
      expect(locController.currentLocale.languageCode, equals('en'));
      expect(locController.isRtl, isFalse);
    });

    test('SettingsController toggles high contrast and font scale', () {
      final settingsController = SettingsController();
      expect(settingsController.highContrast, isFalse);

      settingsController.toggleHighContrast();
      expect(settingsController.highContrast, isTrue);

      settingsController.setFontScale(1.4);
      expect(settingsController.fontScale, equals(1.4));
    });

    test('ElderlyHomeController updates counts cleanly', () {
      final elderlyController = ElderlyHomeController();
      expect(elderlyController.pendingMedicationsCount, equals(1));
      expect(elderlyController.completedGamesToday, equals(2));

      elderlyController.markMedicationTaken();
      expect(elderlyController.pendingMedicationsCount, equals(0));

      elderlyController.incrementGamesPlayed();
      expect(elderlyController.completedGamesToday, equals(3));
    });

    test('AdaptiveDifficultyController records history and calculates decision', () {
      final difficultyController = AdaptiveDifficultyController();
      expect(difficultyController.sessionHistory, isEmpty);

      final decision = difficultyController.calculateNextDifficulty(
        currentDifficulty: 1,
        accuracy: 1.0,
        avgResponseTimeMs: 1500,
        hesitationMs: 500,
        errorCount: 0,
      );

      expect(decision.nextDifficulty, equals(1)); // Single session does not promote
      expect(difficultyController.sessionHistory.length, equals(1));
    });

    testWidgets('MultiProvider widget tree pumps without crashing', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ElderlyHomeController()),
            ChangeNotifierProvider(create: (_) => LocalizationController()),
            ChangeNotifierProvider(create: (_) => SettingsController()),
            ChangeNotifierProvider(create: (_) => AdaptiveDifficultyController()),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Consumer<ElderlyHomeController>(
                builder: (context, controller, _) {
                  return Text('Patient: ${controller.patientName}');
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('Patient: Deka Da (দাদা)'), findsOneWidget);
    });
  });
}
