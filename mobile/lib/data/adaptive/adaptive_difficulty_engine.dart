import 'dart:math' as math;
import '../../domain/services/adaptive_difficulty_service.dart';

/// Pure domain service implementing the SmritiSetu Adaptive Difficulty Engine.
///
/// Strictly decoupled from Flutter UI with zero UI dependencies.
/// Governed by transparent, explainable mathematical telemetry scoring.
/// NEVER makes clinical or medical diagnostic assertions.
class AdaptiveDifficultyEngine implements IAdaptiveDifficultyEngine {
  // Bounded difficulty levels
  static const int minDifficulty = 1;
  static const int maxDifficulty = 5;

  // Weighted Linear Scoring Coefficients (Sum = 1.0)
  static const double weightAccuracy = 0.50;
  static const double weightResponseTime = 0.25;
  static const double weightHesitation = 0.15;
  static const double weightErrorPenalty = 0.10;

  // Normalization Telemetry Benchmarks
  static const double optimalResponseTimeMs = 1500.0;
  static const double maxTolerableResponseTimeMs = 8000.0;
  static const double hesitationThresholdMs = 5000.0;
  static const int maxTolerableErrors = 5;

  // Decision Thresholds
  static const double promotionThreshold = 0.82;
  static const double demotionThreshold = 0.45;
  static const double severeStruggleThreshold = 0.30;
  static const double rollingAlpha = 0.60;

  @override
  DifficultyDecision evaluateDifficulty(DifficultyEvaluationInput input) {
    // 1. Normalize Accuracy factor [0.0, 1.0]
    final double fAcc = input.accuracy.clamp(0.0, 1.0);

    // 2. Normalize Response time factor [0.0, 1.0]
    final double rawRt = input.averageResponseTime <= 0 ? optimalResponseTimeMs : input.averageResponseTime;
    final double fRt = (1.0 -
            ((rawRt - optimalResponseTimeMs) /
                (maxTolerableResponseTimeMs - optimalResponseTimeMs)))
        .clamp(0.0, 1.0);

    // 3. Normalize Hesitation factor [0.0, 1.0]
    final double rawHes = input.hesitationTime < 0 ? 0.0 : input.hesitationTime;
    final double fHes = (1.0 - (rawHes / hesitationThresholdMs)).clamp(0.0, 1.0);

    // 4. Normalize Error penalty factor [0.0, 1.0]
    final int rawErr = input.errorCount < 0 ? 0 : input.errorCount;
    final double fErr = (rawErr / maxTolerableErrors).clamp(0.0, 1.0);

    // 5. Compute Raw Single-Session Score [0.0, 1.0]
    final double rawSessionScore = (weightAccuracy * fAcc) +
        (weightResponseTime * fRt) +
        (weightHesitation * fHes) -
        (weightErrorPenalty * fErr);
    final double singleSessionScore = rawSessionScore.clamp(0.0, 1.0);

    // 6. Multi-Session Exponential Rolling Smoothing
    final double rollingScore;
    if (input.recentSessionPerformance.isEmpty) {
      rollingScore = singleSessionScore;
    } else {
      final double previousScore = input.recentSessionPerformance.last.clamp(0.0, 1.0);
      rollingScore = (rollingAlpha * singleSessionScore) + ((1.0 - rollingAlpha) * previousScore);
    }

    // 7. Clamp current difficulty to valid range
    final int clampedCurrentDifficulty = input.currentDifficulty.clamp(minDifficulty, maxDifficulty);

    // 8. Transition Logic
    int nextDifficulty = clampedCurrentDifficulty;
    String reasonCode;
    String description;
    String reason;

    // Check for Promotion (requires consistent excellence across consecutive observations)
    final bool hasConsecutiveHigh = input.recentSessionPerformance.isNotEmpty &&
        input.recentSessionPerformance.last >= 0.80 &&
        singleSessionScore >= 0.80;

    if (rollingScore >= promotionThreshold && fAcc >= 0.80 && hasConsecutiveHigh) {
      nextDifficulty = math.min(clampedCurrentDifficulty + 1, maxDifficulty);
      if (nextDifficulty > clampedCurrentDifficulty) {
        reasonCode = 'PROMOTED_HIGH_PERFORMANCE';
        description = 'User demonstrated consistent mastery and low hesitation across consecutive sessions.';
        reason = 'Increase from Level $clampedCurrentDifficulty → Level $nextDifficulty';
      } else {
        reasonCode = 'MAINTAINED_AT_CEILING';
        description = 'User has mastered highest difficulty level (Level 5).';
        reason = 'Maintain at Level 5 (Maximum Challenge)';
      }
    }
    // Check for Demotion
    else {
      final bool persistentStruggle = input.recentSessionPerformance.isNotEmpty &&
          input.recentSessionPerformance.last < demotionThreshold &&
          rollingScore < demotionThreshold;
      final bool severeStruggleInCurrentSession = singleSessionScore < severeStruggleThreshold;

      if (persistentStruggle || severeStruggleInCurrentSession) {
        nextDifficulty = math.max(clampedCurrentDifficulty - 1, minDifficulty);
        if (nextDifficulty < clampedCurrentDifficulty) {
          reasonCode = 'DEMOTED_REDUCE_FRUSTRATION';
          description = 'Difficulty reduced gently to prevent cognitive fatigue and frustration.';
          reason = 'Reduce from Level $clampedCurrentDifficulty → Level $nextDifficulty to maintain confidence';
        } else {
          reasonCode = 'MAINTAINED_AT_FLOOR';
          description = 'Already at introductory level (Level 1). Extra auditory cues enabled.';
          reason = 'Maintain at Level 1 (Introductory Level)';
        }
      }
      // Maintain Current Level
      else {
        reasonCode = 'MAINTAINED_STEADY_ZONE';
        description = 'User performance is stable within their comfortable cognitive engagement zone.';
        reason = 'Maintain Level $clampedCurrentDifficulty for consistent practice';
      }
    }

    // 9. Statistical Confidence Calculation
    final int historyCount = input.recentSessionPerformance.length;
    double baseConfidence;
    if (historyCount == 0) {
      baseConfidence = 0.55;
    } else if (historyCount == 1) {
      baseConfidence = 0.72;
    } else if (historyCount == 2) {
      baseConfidence = 0.85;
    } else {
      baseConfidence = 0.94;
    }

    // Volatility penalty if current session deviates sharply from recent history
    if (historyCount > 0) {
      final double dev = (singleSessionScore - input.recentSessionPerformance.last).abs();
      if (dev > 0.35) {
        baseConfidence = (baseConfidence - 0.10).clamp(0.40, 0.99);
      }
    }
    final double confidence = double.parse(baseConfidence.toStringAsFixed(2));

    // 10. Generate Concrete Target Configuration for Next Difficulty
    final configuration = getDifficultyConfiguration(nextDifficulty);

    return DifficultyDecision(
      previousDifficulty: clampedCurrentDifficulty,
      nextDifficulty: nextDifficulty,
      singleSessionScore: double.parse(singleSessionScore.toStringAsFixed(4)),
      rollingPerformanceScore: double.parse(rollingScore.toStringAsFixed(4)),
      reasonCode: reasonCode,
      description: description,
      reason: reason,
      confidence: confidence,
      configuration: configuration,
    );
  }

  @override
  Map<String, dynamic> getDifficultyConfiguration(int level) {
    final clampedLevel = level.clamp(minDifficulty, maxDifficulty);
    switch (clampedLevel) {
      case 1:
        return const {
          'level': 1,
          'choicesCount': 2,
          'sequenceLength': 3,
          'distractorCount': 0,
          'guidanceLevel': 'maximum_audio',
          'targetResponseSec': 10.0,
          'paceTolerance': 'very_relaxed',
        };
      case 2:
        return const {
          'level': 2,
          'choicesCount': 3,
          'sequenceLength': 4,
          'distractorCount': 1,
          'guidanceLevel': 'high_audio',
          'targetResponseSec': 8.0,
          'paceTolerance': 'relaxed',
        };
      case 3:
        return const {
          'level': 3,
          'choicesCount': 3,
          'sequenceLength': 5,
          'distractorCount': 1,
          'guidanceLevel': 'standard',
          'targetResponseSec': 7.0,
          'paceTolerance': 'standard',
        };
      case 4:
        return const {
          'level': 4,
          'choicesCount': 4,
          'sequenceLength': 6,
          'distractorCount': 2,
          'guidanceLevel': 'standard',
          'targetResponseSec': 6.0,
          'paceTolerance': 'moderate',
        };
      case 5:
      default:
        return const {
          'level': 5,
          'choicesCount': 4,
          'sequenceLength': 8,
          'distractorCount': 2,
          'guidanceLevel': 'minimal_cue',
          'targetResponseSec': 5.0,
          'paceTolerance': 'active',
        };
    }
  }
}
