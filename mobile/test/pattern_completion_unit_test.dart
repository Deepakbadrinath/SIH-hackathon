import 'package:flutter_test/flutter_test.dart';
import 'package:smriti_setu/features/games/domain/models/pattern_completion_models.dart';

void main() {
  group('Phase 5: Pattern Difficulty Configuration Tests', () {
    test('Difficulty configuration scales systematically across levels 1 to 5', () {
      final config1 = PatternDifficultyConfig.forLevel(1);
      expect(config1.difficultyLevel, equals(1));
      expect(config1.sequenceLength, equals(5));
      expect(config1.choicesCount, equals(2));
      expect(config1.complexity, equals(PatternComplexity.ab));

      final config2 = PatternDifficultyConfig.forLevel(2);
      expect(config2.difficultyLevel, equals(2));
      expect(config2.sequenceLength, equals(6));
      expect(config2.choicesCount, equals(3));
      expect(config2.complexity, equals(PatternComplexity.aab));

      final config3 = PatternDifficultyConfig.forLevel(3);
      expect(config3.difficultyLevel, equals(3));
      expect(config3.sequenceLength, equals(6));
      expect(config3.choicesCount, equals(3));
      expect(config3.complexity, equals(PatternComplexity.abc));

      final config4 = PatternDifficultyConfig.forLevel(4);
      expect(config4.difficultyLevel, equals(4));
      expect(config4.sequenceLength, equals(7));
      expect(config4.choicesCount, equals(4));
      expect(config4.complexity, equals(PatternComplexity.abba));

      final config5 = PatternDifficultyConfig.forLevel(5);
      expect(config5.difficultyLevel, equals(5));
      expect(config5.sequenceLength, equals(8));
      expect(config5.choicesCount, equals(4));
      expect(config5.complexity, equals(PatternComplexity.interleaved));
    });

    test('Difficulty level safely clamps out-of-bounds inputs', () {
      final configLow = PatternDifficultyConfig.forLevel(0);
      expect(configLow.difficultyLevel, equals(1));

      final configHigh = PatternDifficultyConfig.forLevel(99);
      expect(configHigh.difficultyLevel, equals(5));
    });
  });

  group('Phase 5: Pattern Generation Tests', () {
    test('PatternGenerator generates correct sequence length, target, and choices', () {
      final config = PatternDifficultyConfig.forLevel(1);
      final trial = PatternGenerator.generateTrial(
        trialNumber: 1,
        config: config,
        isDeterministic: true,
      );

      // Visible sequence has sequenceLength - 1 items (last is missing)
      expect(trial.visibleSequence.length, equals(4));
      expect(trial.choices.length, equals(2));
      expect(trial.choices[trial.correctIndex], equals(trial.targetMissingSymbol));

      // In Level 1 AB pattern with trial 1: A = Lotus, B = Tea Leaf
      // Pattern: Lotus, Tea Leaf, Lotus, Tea Leaf, [Lotus]
      expect(trial.visibleSequence[0].id, equals('symbol_lotus'));
      expect(trial.visibleSequence[1].id, equals('symbol_tea_leaf'));
      expect(trial.visibleSequence[2].id, equals('symbol_lotus'));
      expect(trial.visibleSequence[3].id, equals('symbol_tea_leaf'));
      expect(trial.targetMissingSymbol.id, equals('symbol_lotus'));
    });

    test('PatternGenerator respects ABC complexity in level 3', () {
      final config = PatternDifficultyConfig.forLevel(3);
      final trial = PatternGenerator.generateTrial(
        trialNumber: 1,
        config: config,
        isDeterministic: true,
      );

      expect(trial.visibleSequence.length, equals(5));
      expect(trial.choices.length, equals(3));
      expect(trial.choices[trial.correctIndex], equals(trial.targetMissingSymbol));
    });
  });

  group('Phase 5: Answer Validation Tests', () {
    test('Correct answer matches target missing symbol', () {
      final config = PatternDifficultyConfig.forLevel(2);
      final trial = PatternGenerator.generateTrial(
        trialNumber: 1,
        config: config,
        isDeterministic: true,
      );

      final selectedSymbol = trial.choices[trial.correctIndex];
      final isCorrect = selectedSymbol.id == trial.targetMissingSymbol.id;

      expect(isCorrect, isTrue);
    });

    test('Incorrect answer rejects distractor selection', () {
      final config = PatternDifficultyConfig.forLevel(2);
      final trial = PatternGenerator.generateTrial(
        trialNumber: 1,
        config: config,
        isDeterministic: true,
      );

      final incorrectIndex = trial.correctIndex == 0 ? 1 : 0;
      final selectedSymbol = trial.choices[incorrectIndex];
      final isCorrect = selectedSymbol.id == trial.targetMissingSymbol.id;

      expect(isCorrect, isFalse);
    });
  });

  group('Phase 5: Scoring Calculation Tests', () {
    test('100% correct answers with prompt response earns 3 stars and high score', () {
      final results = [
        const PatternTrialResult(
          trialNumber: 1,
          targetSymbolId: 'symbol_lotus',
          selectedSymbolId: 'symbol_lotus',
          isCorrect: true,
          responseTimeMs: 1400,
          hesitationMs: 250,
        ),
        const PatternTrialResult(
          trialNumber: 2,
          targetSymbolId: 'symbol_tea_leaf',
          selectedSymbolId: 'symbol_tea_leaf',
          isCorrect: true,
          responseTimeMs: 1600,
          hesitationMs: 300,
        ),
        const PatternTrialResult(
          trialNumber: 3,
          targetSymbolId: 'symbol_bell',
          selectedSymbolId: 'symbol_bell',
          isCorrect: true,
          responseTimeMs: 1300,
          hesitationMs: 200,
        ),
        const PatternTrialResult(
          trialNumber: 4,
          targetSymbolId: 'symbol_sun',
          selectedSymbolId: 'symbol_sun',
          isCorrect: true,
          responseTimeMs: 1500,
          hesitationMs: 250,
        ),
      ];

      final score = PatternScoreCalculator.calculate(results);

      expect(score.totalTrials, equals(4));
      expect(score.correctTrials, equals(4));
      expect(score.errorCount, equals(0));
      expect(score.accuracyPercentage, equals(100.0));
      expect(score.stars, equals(3));
      expect(score.calculatedScore, greaterThanOrEqualTo(95));
      expect(score.totalHesitationMs, equals(1000.0));
    });

    test('Mixed accuracy calculates error count and appropriate rating', () {
      final results = [
        const PatternTrialResult(
          trialNumber: 1,
          targetSymbolId: 'symbol_lotus',
          selectedSymbolId: 'symbol_lotus',
          isCorrect: true,
          responseTimeMs: 2200,
          hesitationMs: 400,
        ),
        const PatternTrialResult(
          trialNumber: 2,
          targetSymbolId: 'symbol_tea_leaf',
          selectedSymbolId: 'symbol_bell', // Incorrect
          isCorrect: false,
          responseTimeMs: 3000,
          hesitationMs: 900,
        ),
      ];

      final score = PatternScoreCalculator.calculate(results);

      expect(score.totalTrials, equals(2));
      expect(score.correctTrials, equals(1));
      expect(score.errorCount, equals(1));
      expect(score.accuracyPercentage, equals(50.0));
      expect(score.stars, equals(2));
      expect(score.totalHesitationMs, equals(1300.0));
    });

    test('Zero correct answers gives minimal dignified 1 star rating without crash', () {
      final results = [
        const PatternTrialResult(
          trialNumber: 1,
          targetSymbolId: 'symbol_lotus',
          selectedSymbolId: 'symbol_bell',
          isCorrect: false,
          responseTimeMs: 4000,
          hesitationMs: 1200,
        ),
      ];

      final score = PatternScoreCalculator.calculate(results);

      expect(score.totalTrials, equals(1));
      expect(score.correctTrials, equals(0));
      expect(score.errorCount, equals(1));
      expect(score.accuracyPercentage, equals(0.0));
      expect(score.calculatedScore, equals(0));
      expect(score.stars, equals(1));
    });
  });
}
