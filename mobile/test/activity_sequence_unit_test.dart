import 'package:flutter_test/flutter_test.dart';
import 'package:smriti_setu/features/games/domain/models/activity_sequence_models.dart';

void main() {
  group('Phase 6: Activity Sequence Difficulty Configuration Tests', () {
    test('Difficulty configuration scales stepCount and distractorCount across levels 1 to 5', () {
      final lvl1 = SequenceDifficultyConfig.forLevel(1);
      expect(lvl1.difficultyLevel, equals(1));
      expect(lvl1.stepCount, equals(3));
      expect(lvl1.distractorCount, equals(0));

      final lvl2 = SequenceDifficultyConfig.forLevel(2);
      expect(lvl2.difficultyLevel, equals(2));
      expect(lvl2.stepCount, equals(3));
      expect(lvl2.distractorCount, equals(1));

      final lvl3 = SequenceDifficultyConfig.forLevel(3);
      expect(lvl3.difficultyLevel, equals(3));
      expect(lvl3.stepCount, equals(4));
      expect(lvl3.distractorCount, equals(0));

      final lvl4 = SequenceDifficultyConfig.forLevel(4);
      expect(lvl4.difficultyLevel, equals(4));
      expect(lvl4.stepCount, equals(4));
      expect(lvl4.distractorCount, equals(1));

      final lvl5 = SequenceDifficultyConfig.forLevel(5);
      expect(lvl5.difficultyLevel, equals(5));
      expect(lvl5.stepCount, equals(5));
      expect(lvl5.distractorCount, equals(2));
    });

    test('Difficulty safely clamps out-of-bounds inputs', () {
      final low = SequenceDifficultyConfig.forLevel(-5);
      expect(low.difficultyLevel, equals(1));
      expect(low.stepCount, equals(3));

      final high = SequenceDifficultyConfig.forLevel(99);
      expect(high.difficultyLevel, equals(5));
      expect(high.stepCount, equals(5));
    });
  });

  group('Phase 6: Routine Generation & Distractor Tests', () {
    test('ActivitySequenceGenerator generates correct target sequence length and distractors for level 2', () {
      final config = SequenceDifficultyConfig.forLevel(2); // 3 steps, 1 distractor
      final trial = ActivitySequenceGenerator.generateTrial(
        trialNumber: 1,
        config: config,
        isDeterministic: true,
      );

      expect(trial.targetSteps.length, equals(3));
      expect(trial.availableChoices.length, equals(4)); // 3 targets + 1 distractor
      final distractorsInChoices = trial.availableChoices.where((c) => c.isDistractor).toList();
      expect(distractorsInChoices.length, equals(1));
    });

    test('ActivitySequenceGenerator generates full 5 steps with 2 distractors in level 5', () {
      final config = SequenceDifficultyConfig.forLevel(5); // 5 steps, 2 distractors
      final trial = ActivitySequenceGenerator.generateTrial(
        trialNumber: 2, // Second theme (Assam Tea)
        config: config,
        isDeterministic: true,
      );

      expect(trial.routineTheme.id, equals('routine_tea'));
      expect(trial.targetSteps.length, equals(5));
      expect(trial.availableChoices.length, equals(7)); // 5 targets + 2 distractors
      final distractors = trial.availableChoices.where((c) => c.isDistractor).toList();
      expect(distractors.length, equals(2));
    });
  });

  group('Phase 6: Answer Placement Validation Tests', () {
    test('Correct sequence matches target order perfectly', () {
      final config = SequenceDifficultyConfig.forLevel(1); // 3 steps
      final trial = ActivitySequenceGenerator.generateTrial(
        trialNumber: 1,
        config: config,
      );

      final placedIds = trial.targetSteps.map((s) => s.id).toList();
      final targetIds = trial.targetSteps.map((s) => s.id).toList();

      int correctCount = 0;
      for (int i = 0; i < targetIds.length; i++) {
        if (i < placedIds.length && placedIds[i] == targetIds[i]) {
          correctCount++;
        }
      }

      final isPerfect = correctCount == targetIds.length;
      final errorCount = targetIds.length - correctCount;

      final result = ActivitySequenceTrialResult(
        trialNumber: 1,
        routineId: trial.routineTheme.id,
        targetStepIds: targetIds,
        placedStepIds: placedIds,
        correctlyPlacedCount: correctCount,
        totalSlots: targetIds.length,
        errorCount: errorCount,
        isPerfect: isPerfect,
        responseTimeMs: 3200,
        hesitationMs: 600,
      );

      expect(result.correctlyPlacedCount, equals(3));
      expect(result.errorCount, equals(0));
      expect(result.isPerfect, isTrue);
    });

    test('Out-of-order sequence identifies misplaced slots accurately', () {
      final config = SequenceDifficultyConfig.forLevel(1); // 3 steps: A, B, C
      final trial = ActivitySequenceGenerator.generateTrial(
        trialNumber: 1,
        config: config,
      );

      final targetIds = trial.targetSteps.map((s) => s.id).toList();
      // Swap step 1 and step 2: B, A, C (only C is in correct slot)
      final placedIds = [targetIds[1], targetIds[0], targetIds[2]];

      int correctCount = 0;
      for (int i = 0; i < targetIds.length; i++) {
        if (i < placedIds.length && placedIds[i] == targetIds[i]) {
          correctCount++;
        }
      }

      final errorCount = targetIds.length - correctCount;

      final result = ActivitySequenceTrialResult(
        trialNumber: 1,
        routineId: trial.routineTheme.id,
        targetStepIds: targetIds,
        placedStepIds: placedIds,
        correctlyPlacedCount: correctCount,
        totalSlots: targetIds.length,
        errorCount: errorCount,
        isPerfect: correctCount == targetIds.length,
        responseTimeMs: 4000,
        hesitationMs: 900,
      );

      expect(result.correctlyPlacedCount, equals(1)); // Only slot 3 (C) matches
      expect(result.errorCount, equals(2));
      expect(result.isPerfect, isFalse);
    });
  });

  group('Phase 6: Scoring Calculation Tests', () {
    test('100% correct placement earns 3 stars and high score', () {
      final results = [
        const ActivitySequenceTrialResult(
          trialNumber: 1,
          routineId: 'routine_morning',
          targetStepIds: ['m_wake', 'm_brush', 'm_breakfast'],
          placedStepIds: ['m_wake', 'm_brush', 'm_breakfast'],
          correctlyPlacedCount: 3,
          totalSlots: 3,
          errorCount: 0,
          isPerfect: true,
          responseTimeMs: 3500,
          hesitationMs: 700,
        ),
      ];

      final score = ActivitySequenceScoreCalculator.calculate(results);
      expect(score.accuracyPercentage, equals(100.0));
      expect(score.correctlyPlacedSteps, equals(3));
      expect(score.totalErrors, equals(0));
      expect(score.stars, equals(3));
      expect(score.calculatedScore, greaterThanOrEqualTo(90));
      expect(score.encouragementMessage, contains('Outstanding'));
    });

    test('Partial accuracy calculates respectful 2 stars', () {
      final results = [
        const ActivitySequenceTrialResult(
          trialNumber: 1,
          routineId: 'routine_morning',
          targetStepIds: ['m_wake', 'm_brush', 'm_breakfast', 'm_dress'],
          placedStepIds: ['m_wake', 'm_brush', 'm_dress', 'm_breakfast'], // 2 correct (0 & 1), 2 swapped
          correctlyPlacedCount: 2,
          totalSlots: 4,
          errorCount: 2,
          isPerfect: false,
          responseTimeMs: 5000,
          hesitationMs: 1200,
        ),
      ];

      final score = ActivitySequenceScoreCalculator.calculate(results);
      expect(score.accuracyPercentage, equals(50.0));
      expect(score.correctlyPlacedSteps, equals(2));
      expect(score.totalErrors, equals(2));
      expect(score.stars, equals(2));
      expect(score.encouragementMessage, contains('Good work'));
    });

    test('Zero correct steps gives dignified 1 star without error', () {
      final results = [
        const ActivitySequenceTrialResult(
          trialNumber: 1,
          routineId: 'routine_morning',
          targetStepIds: ['m_wake', 'm_brush', 'm_breakfast'],
          placedStepIds: ['d_pajamas', 'd_lights_out', 'm_wake'], // None in correct slot
          correctlyPlacedCount: 0,
          totalSlots: 3,
          errorCount: 3,
          isPerfect: false,
          responseTimeMs: 6000,
          hesitationMs: 1500,
        ),
      ];

      final score = ActivitySequenceScoreCalculator.calculate(results);
      expect(score.accuracyPercentage, equals(0.0));
      expect(score.stars, equals(1));
      expect(score.encouragementMessage, contains('Well done'));
    });
  });
}
