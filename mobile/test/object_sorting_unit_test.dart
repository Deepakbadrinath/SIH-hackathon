import 'package:flutter_test/flutter_test.dart';
import 'package:smriti_setu/features/games/domain/models/object_sorting_models.dart';

void main() {
  group('Phase 7: Object Sorting Difficulty Configuration Tests', () {
    test('Difficulty configuration scales active categories and object count across levels 1 to 5', () {
      final lvl1 = SortingDifficultyConfig.forLevel(1);
      expect(lvl1.difficultyLevel, equals(1));
      expect(lvl1.activeCategoriesCount, equals(2));
      expect(lvl1.objectCount, equals(4));

      final lvl2 = SortingDifficultyConfig.forLevel(2);
      expect(lvl2.difficultyLevel, equals(2));
      expect(lvl2.activeCategoriesCount, equals(2));
      expect(lvl2.objectCount, equals(6));

      final lvl3 = SortingDifficultyConfig.forLevel(3);
      expect(lvl3.difficultyLevel, equals(3));
      expect(lvl3.activeCategoriesCount, equals(3));
      expect(lvl3.objectCount, equals(6));

      final lvl4 = SortingDifficultyConfig.forLevel(4);
      expect(lvl4.difficultyLevel, equals(4));
      expect(lvl4.activeCategoriesCount, equals(3));
      expect(lvl4.objectCount, equals(8));

      final lvl5 = SortingDifficultyConfig.forLevel(5);
      expect(lvl5.difficultyLevel, equals(5));
      expect(lvl5.activeCategoriesCount, equals(4));
      expect(lvl5.objectCount, equals(10));
    });

    test('Difficulty level safely clamps out-of-bounds inputs', () {
      final low = SortingDifficultyConfig.forLevel(-3);
      expect(low.difficultyLevel, equals(1));
      expect(low.objectCount, equals(4));

      final high = SortingDifficultyConfig.forLevel(88);
      expect(high.difficultyLevel, equals(5));
      expect(high.objectCount, equals(10));
    });
  });

  group('Phase 7: Object Sorting Generator Tests', () {
    test('ObjectSortingGenerator generates correct trial count and valid categories for level 1', () {
      final config = SortingDifficultyConfig.forLevel(1);
      final trials = ObjectSortingGenerator.generateTrials(
        config: config,
        isDeterministic: true,
      );

      expect(trials.length, equals(4));
      for (final trial in trials) {
        expect(trial.activeCategories.length, equals(2));
        final targetCatId = trial.targetObject.category.id;
        expect(trial.activeCategories.any((c) => c.id == targetCatId), isTrue);
        expect(trial.activeCategories[trial.correctCategoryIndex].id, equals(targetCatId));
      }
    });

    test('ObjectSortingGenerator generates 4 categories and 10 trials in level 5', () {
      final config = SortingDifficultyConfig.forLevel(5);
      final trials = ObjectSortingGenerator.generateTrials(
        config: config,
        isDeterministic: true,
      );

      expect(trials.length, equals(10));
      for (final trial in trials) {
        expect(trial.activeCategories.length, equals(4));
        final targetCatId = trial.targetObject.category.id;
        expect(trial.activeCategories[trial.correctCategoryIndex].id, equals(targetCatId));
      }
    });
  });

  group('Phase 7: Answer Categorization Validation Tests', () {
    test('Correct category selection registers isCorrect true', () {
      final trial = ObjectSortingTrial(
        trialNumber: 1,
        targetObject: DefaultSortableObjects.tea,
        activeCategories: [DefaultSortCategories.food, DefaultSortCategories.clothing],
        correctCategoryIndex: 0,
      );

      final selectedCat = trial.activeCategories[0]; // Food
      final isCorrect = selectedCat.id == trial.targetObject.category.id;

      final result = ObjectSortingTrialResult(
        trialNumber: 1,
        objectId: trial.targetObject.id,
        targetCategoryId: trial.targetObject.category.id,
        selectedCategoryId: selectedCat.id,
        isCorrect: isCorrect,
        responseTimeMs: 1500,
        hesitationMs: 300,
      );

      expect(result.isCorrect, isTrue);
      expect(result.selectedCategoryId, equals('cat_food'));
    });

    test('Incorrect category selection registers isCorrect false', () {
      final trial = ObjectSortingTrial(
        trialNumber: 1,
        targetObject: DefaultSortableObjects.tea,
        activeCategories: [DefaultSortCategories.food, DefaultSortCategories.clothing],
        correctCategoryIndex: 0,
      );

      final selectedCat = trial.activeCategories[1]; // Clothing (incorrect)
      final isCorrect = selectedCat.id == trial.targetObject.category.id;

      final result = ObjectSortingTrialResult(
        trialNumber: 1,
        objectId: trial.targetObject.id,
        targetCategoryId: trial.targetObject.category.id,
        selectedCategoryId: selectedCat.id,
        isCorrect: isCorrect,
        responseTimeMs: 2200,
        hesitationMs: 500,
      );

      expect(result.isCorrect, isFalse);
      expect(result.selectedCategoryId, equals('cat_clothing'));
    });
  });

  group('Phase 7: Scoring Calculation Tests', () {
    test('100% correct sorting earns 3 stars and high score', () {
      final results = [
        const ObjectSortingTrialResult(
          trialNumber: 1,
          objectId: 'food_tea',
          targetCategoryId: 'cat_food',
          selectedCategoryId: 'cat_food',
          isCorrect: true,
          responseTimeMs: 1800,
          hesitationMs: 350,
        ),
        const ObjectSortingTrialResult(
          trialNumber: 2,
          objectId: 'cloth_gamosa',
          targetCategoryId: 'cat_clothing',
          selectedCategoryId: 'cat_clothing',
          isCorrect: true,
          responseTimeMs: 2000,
          hesitationMs: 400,
        ),
      ];

      final score = ObjectSortingScoreCalculator.calculate(results);
      expect(score.accuracyPercentage, equals(100.0));
      expect(score.correctCount, equals(2));
      expect(score.errorCount, equals(0));
      expect(score.stars, equals(3));
      expect(score.calculatedScore, greaterThanOrEqualTo(90));
      expect(score.encouragementMessage, contains('Brilliant'));
    });

    test('Partial accuracy calculates respectful 2 stars', () {
      final results = [
        const ObjectSortingTrialResult(
          trialNumber: 1,
          objectId: 'food_tea',
          targetCategoryId: 'cat_food',
          selectedCategoryId: 'cat_food',
          isCorrect: true,
          responseTimeMs: 2000,
          hesitationMs: 400,
        ),
        const ObjectSortingTrialResult(
          trialNumber: 2,
          objectId: 'cloth_gamosa',
          targetCategoryId: 'cat_clothing',
          selectedCategoryId: 'cat_food', // Incorrect
          isCorrect: false,
          responseTimeMs: 2500,
          hesitationMs: 500,
        ),
      ];

      final score = ObjectSortingScoreCalculator.calculate(results);
      expect(score.accuracyPercentage, equals(50.0));
      expect(score.correctCount, equals(1));
      expect(score.errorCount, equals(1));
      expect(score.stars, equals(2));
      expect(score.encouragementMessage, contains('Good work'));
    });

    test('Zero correct answers gives dignified 1 star without error', () {
      final results = [
        const ObjectSortingTrialResult(
          trialNumber: 1,
          objectId: 'food_tea',
          targetCategoryId: 'cat_food',
          selectedCategoryId: 'cat_clothing',
          isCorrect: false,
          responseTimeMs: 3000,
          hesitationMs: 700,
        ),
      ];

      final score = ObjectSortingScoreCalculator.calculate(results);
      expect(score.accuracyPercentage, equals(0.0));
      expect(score.correctCount, equals(0));
      expect(score.errorCount, equals(1));
      expect(score.stars, equals(1));
      expect(score.encouragementMessage, contains('Well done'));
    });
  });
}
