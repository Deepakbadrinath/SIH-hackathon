import 'package:flutter/material.dart';

/// Recognizable visual symbol used in pattern sequences.
class PatternSymbol {
  final String id;
  final String name;
  final IconData icon;
  final Color color;

  const PatternSymbol({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PatternSymbol && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Standard high-contrast cultural motifs for North Eastern elderly care.
class DefaultPatternSymbols {
  static const PatternSymbol lotus = PatternSymbol(
    id: 'symbol_lotus',
    name: 'Lotus',
    icon: Icons.spa_rounded,
    color: Color(0xFFBE185D), // Vibrant Rose Pink
  );

  static const PatternSymbol teaLeaf = PatternSymbol(
    id: 'symbol_tea_leaf',
    name: 'Tea Leaf',
    icon: Icons.eco_rounded,
    color: Color(0xFF15803D), // Deep Assam Green
  );

  static const PatternSymbol bell = PatternSymbol(
    id: 'symbol_bell',
    name: 'Temple Bell',
    icon: Icons.notifications_rounded,
    color: Color(0xFFB45309), // Warm Brass Amber
  );

  static const PatternSymbol sun = PatternSymbol(
    id: 'symbol_sun',
    name: 'Morning Sun',
    icon: Icons.wb_sunny_rounded,
    color: Color(0xFFEA580C), // High-Contrast Saffron Orange
  );

  static const PatternSymbol pot = PatternSymbol(
    id: 'symbol_pot',
    name: 'Clay Pot',
    icon: Icons.coffee_rounded,
    color: Color(0xFF7C2D12), // Deep Terracotta
  );

  static const List<PatternSymbol> all = [lotus, teaLeaf, bell, sun, pot];
}

/// Logical structural pattern types.
enum PatternComplexity {
  ab, // Alternating: A, B, A, B, ?
  aab, // Repeated: A, A, B, A, A, ?
  abc, // Cyclic triplet: A, B, C, A, B, ?
  abba, // Symmetric: A, B, B, A, A, B, ?
  interleaved, // Interleaved: A, B, A, C, A, B, ?
}

/// External difficulty configuration decoupled from UI widgets.
class PatternDifficultyConfig {
  final int difficultyLevel;
  final int sequenceLength;
  final int choicesCount;
  final PatternComplexity complexity;
  final String description;

  const PatternDifficultyConfig({
    required this.difficultyLevel,
    required this.sequenceLength,
    required this.choicesCount,
    required this.complexity,
    required this.description,
  });

  /// Factory scaling difficulty variables systematically across levels 1 to 5.
  factory PatternDifficultyConfig.forLevel(int level) {
    final clampedLevel = level.clamp(1, 5);
    switch (clampedLevel) {
      case 1:
        return const PatternDifficultyConfig(
          difficultyLevel: 1,
          sequenceLength: 5,
          choicesCount: 2,
          complexity: PatternComplexity.ab,
          description: 'Simple AB Alternating Sequence',
        );
      case 2:
        return const PatternDifficultyConfig(
          difficultyLevel: 2,
          sequenceLength: 6,
          choicesCount: 3,
          complexity: PatternComplexity.aab,
          description: 'Double Step AAB Sequence',
        );
      case 3:
        return const PatternDifficultyConfig(
          difficultyLevel: 3,
          sequenceLength: 6,
          choicesCount: 3,
          complexity: PatternComplexity.abc,
          description: 'Three Symbol Cyclic ABC Sequence',
        );
      case 4:
        return const PatternDifficultyConfig(
          difficultyLevel: 4,
          sequenceLength: 7,
          choicesCount: 4,
          complexity: PatternComplexity.abba,
          description: 'Symmetric ABBA Sequence',
        );
      case 5:
      default:
        return const PatternDifficultyConfig(
          difficultyLevel: 5,
          sequenceLength: 8,
          choicesCount: 4,
          complexity: PatternComplexity.interleaved,
          description: 'Complex Interleaved Sequence',
        );
    }
  }
}

/// Single trial presentation in the Pattern Completion game.
class PatternTrial {
  final int trialNumber;
  final List<PatternSymbol> visibleSequence;
  final PatternSymbol targetMissingSymbol;
  final List<PatternSymbol> choices;
  final int correctIndex;

  const PatternTrial({
    required this.trialNumber,
    required this.visibleSequence,
    required this.targetMissingSymbol,
    required this.choices,
    required this.correctIndex,
  });
}

/// Pure pattern generation engine with zero UI dependencies.
class PatternGenerator {
  static PatternTrial generateTrial({
    required int trialNumber,
    required PatternDifficultyConfig config,
    List<PatternSymbol>? customSymbols,
    bool isDeterministic = false,
  }) {
    final pool = customSymbols ?? DefaultPatternSymbols.all;
    final symbolCount = pool.length;

    // Pick base symbols for this trial
    final symbolA = pool[(trialNumber - 1) % symbolCount];
    final symbolB = pool[(trialNumber) % symbolCount];
    final symbolC = pool[(trialNumber + 1) % symbolCount];

    List<PatternSymbol> fullPattern;

    switch (config.complexity) {
      case PatternComplexity.ab:
        // A, B, A, B, A, B...
        fullPattern = List.generate(config.sequenceLength, (i) => i % 2 == 0 ? symbolA : symbolB);
        break;
      case PatternComplexity.aab:
        // A, A, B, A, A, B...
        fullPattern = List.generate(config.sequenceLength, (i) => i % 3 == 2 ? symbolB : symbolA);
        break;
      case PatternComplexity.abc:
        // A, B, C, A, B, C...
        fullPattern = List.generate(config.sequenceLength, (i) {
          final mod = i % 3;
          if (mod == 0) return symbolA;
          if (mod == 1) return symbolB;
          return symbolC;
        });
        break;
      case PatternComplexity.abba:
        // A, B, B, A, A, B, B, A...
        fullPattern = List.generate(config.sequenceLength, (i) {
          final mod = i % 4;
          return (mod == 0 || mod == 3) ? symbolA : symbolB;
        });
        break;
      case PatternComplexity.interleaved:
        // A, B, A, C, A, B, A, C...
        fullPattern = List.generate(config.sequenceLength, (i) {
          final mod = i % 4;
          if (mod == 0 || mod == 2) return symbolA;
          if (mod == 1) return symbolB;
          return symbolC;
        });
        break;
    }

    // The last element is the missing target
    final targetMissing = fullPattern.last;
    final visibleSequence = fullPattern.sublist(0, fullPattern.length - 1);

    // Generate candidate choices including the target and distractors
    final distractors = pool.where((s) => s.id != targetMissing.id).toList();

    if (!isDeterministic) {
      distractors.shuffle();
    }

    final candidateDistractors = distractors.take(config.choicesCount - 1).toList();
    final choices = [targetMissing, ...candidateDistractors];

    if (!isDeterministic) {
      choices.shuffle();
    } else {
      // Deterministic positioning
      if (trialNumber % 2 == 0 && choices.length > 1) {
        final temp = choices[0];
        choices[0] = choices[1];
        choices[1] = temp;
      }
    }

    final correctIndex = choices.indexWhere((c) => c.id == targetMissing.id);

    return PatternTrial(
      trialNumber: trialNumber,
      visibleSequence: visibleSequence,
      targetMissingSymbol: targetMissing,
      choices: choices,
      correctIndex: correctIndex,
    );
  }
}

/// Trial metrics measured during user interaction.
class PatternTrialResult {
  final int trialNumber;
  final String targetSymbolId;
  final String selectedSymbolId;
  final bool isCorrect;
  final int responseTimeMs;
  final int hesitationMs;

  const PatternTrialResult({
    required this.trialNumber,
    required this.targetSymbolId,
    required this.selectedSymbolId,
    required this.isCorrect,
    required this.responseTimeMs,
    required this.hesitationMs,
  });
}

/// Aggregate session score outcome.
class PatternSessionScore {
  final int totalTrials;
  final int correctTrials;
  final int errorCount;
  final double accuracyPercentage;
  final double avgResponseTimeMs;
  final double totalHesitationMs;
  final int calculatedScore;
  final int maxPossibleScore;
  final int stars;
  final String encouragementMessage;

  const PatternSessionScore({
    required this.totalTrials,
    required this.correctTrials,
    required this.errorCount,
    required this.accuracyPercentage,
    required this.avgResponseTimeMs,
    required this.totalHesitationMs,
    required this.calculatedScore,
    this.maxPossibleScore = 100,
    required this.stars,
    required this.encouragementMessage,
  });
}

/// Deterministic, respectful scoring calculator for Pattern Completion.
class PatternScoreCalculator {
  static PatternSessionScore calculate(
    List<PatternTrialResult> results, {
    int difficultyLevel = 1,
  }) {
    if (results.isEmpty) {
      return const PatternSessionScore(
        totalTrials: 0,
        correctTrials: 0,
        errorCount: 0,
        accuracyPercentage: 0.0,
        avgResponseTimeMs: 0.0,
        totalHesitationMs: 0.0,
        calculatedScore: 0,
        stars: 1,
        encouragementMessage: 'Thank you for exercising your mind today!',
      );
    }

    final totalTrials = results.length;
    final correctTrials = results.where((r) => r.isCorrect).length;
    final errorCount = totalTrials - correctTrials;
    final accuracyPercentage = (correctTrials / totalTrials) * 100.0;

    final totalResponseMs = results.fold<int>(0, (sum, r) => sum + r.responseTimeMs);
    final avgResponseTimeMs = totalResponseMs / totalTrials;
    final totalHesitationMs = results.fold<int>(0, (sum, r) => sum + r.hesitationMs).toDouble();

    // Base accuracy contributes up to 80 points
    final baseAccuracy = (accuracyPercentage * 0.80).round();

    // Leisurely pacing bonus up to 20 points
    int pacingBonus = 0;
    if (correctTrials > 0) {
      final clampedResponse = avgResponseTimeMs.clamp(1000.0, 5000.0);
      pacingBonus = (((5000.0 - clampedResponse) / 4000.0) * 20.0).round().clamp(0, 20);
    }

    final totalScore = (baseAccuracy + pacingBonus).clamp(0, 100);

    int stars;
    if (accuracyPercentage >= 85.0) {
      stars = 3;
    } else if (accuracyPercentage >= 50.0) {
      stars = 2;
    } else {
      stars = 1;
    }

    String message;
    if (stars == 3) {
      message = 'Brilliant logical thinking! You completed every pattern with great skill!';
    } else if (stars == 2) {
      message = 'Good work! Recognizing patterns helps keep reasoning sharp and active.';
    } else {
      message = 'Well done for practicing! Consistency is what matters most for memory care.';
    }

    return PatternSessionScore(
      totalTrials: totalTrials,
      correctTrials: correctTrials,
      errorCount: errorCount,
      accuracyPercentage: double.parse(accuracyPercentage.toStringAsFixed(1)),
      avgResponseTimeMs: double.parse(avgResponseTimeMs.toStringAsFixed(1)),
      totalHesitationMs: totalHesitationMs,
      calculatedScore: totalScore,
      stars: stars,
      encouragementMessage: message,
    );
  }
}
