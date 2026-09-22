import 'package:flutter_test/flutter_test.dart';
import 'package:smriti_setu/features/games/domain/models/face_match_models.dart';

void main() {
  group('FamilyFaceMatchScoreCalculator Tests', () {
    test('Empty trial list returns safe defaults with 0 score and encouraging message', () {
      final score = FamilyFaceMatchScoreCalculator.calculate([]);

      expect(score.totalTrials, equals(0));
      expect(score.correctTrials, equals(0));
      expect(score.errorCount, equals(0));
      expect(score.accuracyPercentage, equals(0.0));
      expect(score.calculatedScore, equals(0));
      expect(score.stars, equals(1));
    });

    test('100% correct answers with prompt response earns 3 stars and high score', () {
      final trials = [
        const FaceMatchTrialResult(
          trialNumber: 1,
          targetFaceId: 'aita',
          selectedFaceId: 'aita',
          isCorrect: true,
          responseTimeMs: 1200,
          hesitationMs: 200,
        ),
        const FaceMatchTrialResult(
          trialNumber: 2,
          targetFaceId: 'koka',
          selectedFaceId: 'koka',
          isCorrect: true,
          responseTimeMs: 1400,
          hesitationMs: 300,
        ),
        const FaceMatchTrialResult(
          trialNumber: 3,
          targetFaceId: 'daughter',
          selectedFaceId: 'daughter',
          isCorrect: true,
          responseTimeMs: 1300,
          hesitationMs: 250,
        ),
        const FaceMatchTrialResult(
          trialNumber: 4,
          targetFaceId: 'grandson',
          selectedFaceId: 'grandson',
          isCorrect: true,
          responseTimeMs: 1100,
          hesitationMs: 150,
        ),
      ];

      final score = FamilyFaceMatchScoreCalculator.calculate(trials);

      expect(score.totalTrials, equals(4));
      expect(score.correctTrials, equals(4));
      expect(score.errorCount, equals(0));
      expect(score.accuracyPercentage, equals(100.0));
      expect(score.totalHesitationMs, equals(900.0));
      expect(score.avgResponseTimeMs, equals(1250.0));
      expect(score.stars, equals(3));
      expect(score.calculatedScore, greaterThanOrEqualTo(95));
      expect(score.calculatedScore, lessThanOrEqualTo(100));
    });

    test('50% correct answers earns 2 stars and accurate error tracking', () {
      final trials = [
        const FaceMatchTrialResult(
          trialNumber: 1,
          targetFaceId: 'aita',
          selectedFaceId: 'aita',
          isCorrect: true,
          responseTimeMs: 2000,
          hesitationMs: 400,
        ),
        const FaceMatchTrialResult(
          trialNumber: 2,
          targetFaceId: 'koka',
          selectedFaceId: 'daughter', // Error
          isCorrect: false,
          responseTimeMs: 3500,
          hesitationMs: 1200,
        ),
        const FaceMatchTrialResult(
          trialNumber: 3,
          targetFaceId: 'daughter',
          selectedFaceId: 'daughter',
          isCorrect: true,
          responseTimeMs: 1800,
          hesitationMs: 300,
        ),
        const FaceMatchTrialResult(
          trialNumber: 4,
          targetFaceId: 'grandson',
          selectedFaceId: 'aita', // Error
          isCorrect: false,
          responseTimeMs: 4000,
          hesitationMs: 1500,
        ),
      ];

      final score = FamilyFaceMatchScoreCalculator.calculate(trials);

      expect(score.totalTrials, equals(4));
      expect(score.correctTrials, equals(2));
      expect(score.errorCount, equals(2));
      expect(score.accuracyPercentage, equals(50.0));
      expect(score.stars, equals(2));
      expect(score.totalHesitationMs, equals(3400.0));
      expect(score.calculatedScore, greaterThanOrEqualTo(40));
    });

    test('0% correct answers maintains dignity with 1 star and safe clamped score', () {
      final trials = [
        const FaceMatchTrialResult(
          trialNumber: 1,
          targetFaceId: 'aita',
          selectedFaceId: 'koka',
          isCorrect: false,
          responseTimeMs: 4500,
          hesitationMs: 2000,
        ),
        const FaceMatchTrialResult(
          trialNumber: 2,
          targetFaceId: 'koka',
          selectedFaceId: 'aita',
          isCorrect: false,
          responseTimeMs: 5000,
          hesitationMs: 2200,
        ),
      ];

      final score = FamilyFaceMatchScoreCalculator.calculate(trials);

      expect(score.totalTrials, equals(2));
      expect(score.correctTrials, equals(0));
      expect(score.errorCount, equals(2));
      expect(score.accuracyPercentage, equals(0.0));
      expect(score.calculatedScore, equals(0));
      expect(score.stars, equals(1)); // Respectful minimal rating
    });

    test('Score calculation is strictly deterministic across repeated invocations', () {
      final trials = [
        const FaceMatchTrialResult(
          trialNumber: 1,
          targetFaceId: 'aita',
          selectedFaceId: 'aita',
          isCorrect: true,
          responseTimeMs: 2500,
          hesitationMs: 600,
        ),
        const FaceMatchTrialResult(
          trialNumber: 2,
          targetFaceId: 'daughter',
          selectedFaceId: 'daughter',
          isCorrect: true,
          responseTimeMs: 2100,
          hesitationMs: 400,
        ),
      ];

      final score1 = FamilyFaceMatchScoreCalculator.calculate(trials);
      final score2 = FamilyFaceMatchScoreCalculator.calculate(trials);

      expect(score1.calculatedScore, equals(score2.calculatedScore));
      expect(score1.accuracyPercentage, equals(score2.accuracyPercentage));
      expect(score1.stars, equals(score2.stars));
      expect(score1.totalHesitationMs, equals(score2.totalHesitationMs));
    });
  });
}
