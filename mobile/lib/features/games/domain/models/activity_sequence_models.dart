import 'package:flutter/material.dart';

/// Single step of a daily living routine or activity.
class ActivityStep {
  final String id;
  final String label;
  final String description;
  final IconData icon;
  final Color color;
  final int canonicalOrder; // 1-based index in the correct sequence (-1 if distractor)
  final bool isDistractor;

  const ActivityStep({
    required this.id,
    required this.label,
    required this.description,
    required this.icon,
    required this.color,
    required this.canonicalOrder,
    this.isDistractor = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActivityStep && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// A structured daily activity routine with target steps and plausible distractors.
class ActivityRoutineTheme {
  final String id;
  final String title;
  final String description;
  final String voicePrompt;
  final List<ActivityStep> canonicalSteps;
  final List<ActivityStep> distractors;

  const ActivityRoutineTheme({
    required this.id,
    required this.title,
    required this.description,
    required this.voicePrompt,
    required this.canonicalSteps,
    required this.distractors,
  });
}

/// Culturally authentic routines tailored for North Eastern elderly memory care.
class DefaultActivityRoutines {
  static const ActivityRoutineTheme morningRoutine = ActivityRoutineTheme(
    id: 'routine_morning',
    title: 'Morning Routine',
    description: 'Put everyday morning steps in the correct order.',
    voicePrompt:
        'Think of your usual morning. Tap the activity that comes first, then what you do next.',
    canonicalSteps: [
      ActivityStep(
        id: 'm_wake',
        label: 'Wake Up',
        description: 'Open eyes and sit up gently in bed',
        icon: Icons.wb_sunny_rounded,
        color: Color(0xFFEA580C),
        canonicalOrder: 1,
      ),
      ActivityStep(
        id: 'm_brush',
        label: 'Brush Teeth & Wash',
        description: 'Clean teeth and rinse face with water',
        icon: Icons.cleaning_services_rounded,
        color: Color(0xFF0F3D78),
        canonicalOrder: 2,
      ),
      ActivityStep(
        id: 'm_breakfast',
        label: 'Eat Breakfast',
        description: 'Have morning tea and a healthy breakfast',
        icon: Icons.restaurant_rounded,
        color: Color(0xFF166534),
        canonicalOrder: 3,
      ),
      ActivityStep(
        id: 'm_dress',
        label: 'Get Dressed',
        description: 'Put on clean daytime clothes',
        icon: Icons.checkroom_rounded,
        color: Color(0xFF7E22CE),
        canonicalOrder: 4,
      ),
      ActivityStep(
        id: 'm_walk',
        label: 'Morning Stroll',
        description: 'Take a gentle morning walk outside',
        icon: Icons.directions_walk_rounded,
        color: Color(0xFF0891B2),
        canonicalOrder: 5,
      ),
    ],
    distractors: [
      ActivityStep(
        id: 'd_pajamas',
        label: 'Put on Pajamas',
        description: 'Sleepwear for going to bed at night',
        icon: Icons.bedtime_rounded,
        color: Color(0xFF64748B),
        canonicalOrder: -1,
        isDistractor: true,
      ),
      ActivityStep(
        id: 'd_lights_out',
        label: 'Turn Off All Lights',
        description: 'Switching off room lights for night sleep',
        icon: Icons.nightlight_round,
        color: Color(0xFF475569),
        canonicalOrder: -1,
        isDistractor: true,
      ),
    ],
  );

  static const ActivityRoutineTheme makingAssamTea = ActivityRoutineTheme(
    id: 'routine_tea',
    title: 'Making Assam Tea',
    description: 'Arrange the steps to brew fresh aromatic morning tea.',
    voicePrompt:
        'Remember making a warm cup of Assam tea. Tap what needs to be done first, second, and next.',
    canonicalSteps: [
      ActivityStep(
        id: 't_boil',
        label: 'Boil Fresh Water',
        description: 'Heat clean drinking water in the kettle',
        icon: Icons.local_fire_department_rounded,
        color: Color(0xFFEA580C),
        canonicalOrder: 1,
      ),
      ActivityStep(
        id: 't_leaves',
        label: 'Add Tea Leaves',
        description: 'Put flavorful Assam tea leaves into boiling water',
        icon: Icons.eco_rounded,
        color: Color(0xFF166534),
        canonicalOrder: 2,
      ),
      ActivityStep(
        id: 't_milk',
        label: 'Add Warm Milk',
        description: 'Pour fresh warm milk and a pinch of spice',
        icon: Icons.local_cafe_rounded,
        color: Color(0xFFB45309),
        canonicalOrder: 3,
      ),
      ActivityStep(
        id: 't_strain',
        label: 'Strain into Cup',
        description: 'Filter the hot tea carefully into a cup',
        icon: Icons.emoji_food_beverage_rounded,
        color: Color(0xFF0F3D78),
        canonicalOrder: 4,
      ),
      ActivityStep(
        id: 't_sip',
        label: 'Sip and Enjoy',
        description: 'Relax and take your first warm sip',
        icon: Icons.sentiment_very_satisfied_rounded,
        color: Color(0xFF7E22CE),
        canonicalOrder: 5,
      ),
    ],
    distractors: [
      ActivityStep(
        id: 'd_garden_rake',
        label: 'Clean Garden Rake',
        description: 'Cleaning agricultural garden tools',
        icon: Icons.hardware_rounded,
        color: Color(0xFF64748B),
        canonicalOrder: -1,
        isDistractor: true,
      ),
      ActivityStep(
        id: 'd_chop_wood',
        label: 'Chop Firewood',
        description: 'Splitting outdoor heavy logs',
        icon: Icons.carpenter_rounded,
        color: Color(0xFF475569),
        canonicalOrder: -1,
        isDistractor: true,
      ),
    ],
  );

  static const ActivityRoutineTheme wateringGarden = ActivityRoutineTheme(
    id: 'routine_garden',
    title: 'Watering the Garden',
    description: 'Order the steps to nurture courtyard flowers.',
    voicePrompt:
        'Think of caring for your home garden. What do you do first to water the blooming plants?',
    canonicalSteps: [
      ActivityStep(
        id: 'g_pot',
        label: 'Take Watering Can',
        description: 'Pick up the light watering can from the porch',
        icon: Icons.coffee_rounded,
        color: Color(0xFFB45309),
        canonicalOrder: 1,
      ),
      ActivityStep(
        id: 'g_fill',
        label: 'Fill with Fresh Water',
        description: 'Fill the can with clean cool tap water',
        icon: Icons.water_drop_rounded,
        color: Color(0xFF0284C7),
        canonicalOrder: 2,
      ),
      ActivityStep(
        id: 'g_walk',
        label: 'Walk to Flowerbeds',
        description: 'Step outside to the garden flowers and marigolds',
        icon: Icons.yard_rounded,
        color: Color(0xFF166534),
        canonicalOrder: 3,
      ),
      ActivityStep(
        id: 'g_water',
        label: 'Water Roots Gently',
        description: 'Shower cool water near the flower roots',
        icon: Icons.local_florist_rounded,
        color: Color(0xFFBE185D),
        canonicalOrder: 4,
      ),
      ActivityStep(
        id: 'g_rest',
        label: 'Put Can Back',
        description: 'Place the can safely back on the dry stand',
        icon: Icons.check_circle_outline_rounded,
        color: Color(0xFF7E22CE),
        canonicalOrder: 5,
      ),
    ],
    distractors: [
      ActivityStep(
        id: 'd_umbrella',
        label: 'Open Rain Umbrella',
        description: 'Opening a rain umbrella indoors',
        icon: Icons.beach_access_rounded,
        color: Color(0xFF64748B),
        canonicalOrder: -1,
        isDistractor: true,
      ),
      ActivityStep(
        id: 'd_bed_candle',
        label: 'Light Night Candle',
        description: 'Lighting bedside bedtime candles',
        icon: Icons.light_mode_rounded,
        color: Color(0xFF475569),
        canonicalOrder: -1,
        isDistractor: true,
      ),
    ],
  );

  static const List<ActivityRoutineTheme> all = [
    morningRoutine,
    makingAssamTea,
    wateringGarden,
  ];
}

/// Difficulty configuration for Activity Sequence decoupled from UI widgets.
class SequenceDifficultyConfig {
  final int difficultyLevel;
  final int stepCount;
  final int distractorCount;
  final String description;

  const SequenceDifficultyConfig({
    required this.difficultyLevel,
    required this.stepCount,
    required this.distractorCount,
    required this.description,
  });

  /// Factory scaling sequence length and distractors across levels 1 to 5.
  factory SequenceDifficultyConfig.forLevel(int level) {
    final clamped = level.clamp(1, 5);
    switch (clamped) {
      case 1:
        return const SequenceDifficultyConfig(
          difficultyLevel: 1,
          stepCount: 3,
          distractorCount: 0,
          description: 'Simple 3-Step Routine without distractors',
        );
      case 2:
        return const SequenceDifficultyConfig(
          difficultyLevel: 2,
          stepCount: 3,
          distractorCount: 1,
          description: '3-Step Routine with 1 distractor card',
        );
      case 3:
        return const SequenceDifficultyConfig(
          difficultyLevel: 3,
          stepCount: 4,
          distractorCount: 0,
          description: '4-Step Routine without distractors',
        );
      case 4:
        return const SequenceDifficultyConfig(
          difficultyLevel: 4,
          stepCount: 4,
          distractorCount: 1,
          description: '4-Step Routine with 1 distractor card',
        );
      case 5:
      default:
        return const SequenceDifficultyConfig(
          difficultyLevel: 5,
          stepCount: 5,
          distractorCount: 2,
          description: 'Comprehensive 5-Step Routine with 2 distractors',
        );
    }
  }
}

/// Single trial presentation in Activity Sequence.
class ActivitySequenceTrial {
  final int trialNumber;
  final ActivityRoutineTheme routineTheme;
  final List<ActivityStep> targetSteps; // In correct chronological order (1..N)
  final List<ActivityStep> availableChoices; // Shuffled pool of target steps + distractors

  const ActivitySequenceTrial({
    required this.trialNumber,
    required this.routineTheme,
    required this.targetSteps,
    required this.availableChoices,
  });
}

/// Pure generator producing routine sequence trials without UI dependencies.
class ActivitySequenceGenerator {
  static ActivitySequenceTrial generateTrial({
    required int trialNumber,
    required SequenceDifficultyConfig config,
    List<ActivityRoutineTheme>? customThemes,
    bool isDeterministic = false,
  }) {
    final pool = customThemes ?? DefaultActivityRoutines.all;
    final theme = pool[(trialNumber - 1) % pool.length];

    // Pick target steps for this difficulty level (e.g. first 3, 4, or 5 steps)
    final targetSteps = theme.canonicalSteps.take(config.stepCount).toList();

    // Pick distractors for this difficulty
    final distractors = theme.distractors.take(config.distractorCount).toList();

    // Pool of available cards to choose from
    final choices = <ActivityStep>[...targetSteps, ...distractors];

    if (!isDeterministic) {
      choices.shuffle();
    } else {
      // Deterministic reverse ordering so user has to actively re-sequence
      choices.sort((a, b) => b.label.compareTo(a.label));
    }

    return ActivitySequenceTrial(
      trialNumber: trialNumber,
      routineTheme: theme,
      targetSteps: targetSteps,
      availableChoices: choices,
    );
  }
}

/// Outcome of a single routine ordering trial.
class ActivitySequenceTrialResult {
  final int trialNumber;
  final String routineId;
  final List<String> targetStepIds;
  final List<String> placedStepIds;
  final int correctlyPlacedCount;
  final int totalSlots;
  final int errorCount;
  final bool isPerfect;
  final int responseTimeMs;
  final int hesitationMs;

  const ActivitySequenceTrialResult({
    required this.trialNumber,
    required this.routineId,
    required this.targetStepIds,
    required this.placedStepIds,
    required this.correctlyPlacedCount,
    required this.totalSlots,
    required this.errorCount,
    required this.isPerfect,
    required this.responseTimeMs,
    required this.hesitationMs,
  });
}

/// Overall session score outcome for Activity Sequence.
class SequenceSessionScore {
  final int totalTrials;
  final int totalSlotsEvaluated;
  final int correctlyPlacedSteps;
  final int totalErrors;
  final double accuracyPercentage;
  final double avgResponseTimeMs;
  final double totalHesitationMs;
  final int calculatedScore;
  final int maxPossibleScore;
  final int stars;
  final String encouragementMessage;

  const SequenceSessionScore({
    required this.totalTrials,
    required this.totalSlotsEvaluated,
    required this.correctlyPlacedSteps,
    required this.totalErrors,
    required this.accuracyPercentage,
    required this.avgResponseTimeMs,
    required this.totalHesitationMs,
    required this.calculatedScore,
    this.maxPossibleScore = 100,
    required this.stars,
    required this.encouragementMessage,
  });
}

/// Deterministic, respectful score calculator for Activity Sequence.
class ActivitySequenceScoreCalculator {
  static SequenceSessionScore calculate(
    List<ActivitySequenceTrialResult> results, {
    int difficultyLevel = 1,
  }) {
    if (results.isEmpty) {
      return const SequenceSessionScore(
        totalTrials: 0,
        totalSlotsEvaluated: 0,
        correctlyPlacedSteps: 0,
        totalErrors: 0,
        accuracyPercentage: 0.0,
        avgResponseTimeMs: 0.0,
        totalHesitationMs: 0.0,
        calculatedScore: 0,
        stars: 1,
        encouragementMessage: 'Thank you for exercising daily routines today!',
      );
    }

    final totalTrials = results.length;
    final totalSlots = results.fold<int>(0, (sum, r) => sum + r.totalSlots);
    final correctSteps = results.fold<int>(0, (sum, r) => sum + r.correctlyPlacedCount);
    final totalErrors = results.fold<int>(0, (sum, r) => sum + r.errorCount);

    final accuracyPercentage = totalSlots > 0 ? (correctSteps / totalSlots) * 100.0 : 0.0;

    final totalResponseMs = results.fold<int>(0, (sum, r) => sum + r.responseTimeMs);
    final avgResponseTimeMs = totalResponseMs / totalTrials;
    final totalHesitationMs = results.fold<int>(0, (sum, r) => sum + r.hesitationMs).toDouble();

    // Base accuracy contributes up to 80 points
    final baseAccuracy = (accuracyPercentage * 0.80).round();

    // Pace bonus up to 20 points
    int paceBonus = 0;
    if (correctSteps > 0) {
      final clampedResponse = avgResponseTimeMs.clamp(2000.0, 10000.0);
      paceBonus = (((10000.0 - clampedResponse) / 8000.0) * 20.0).round().clamp(0, 20);
    }

    final totalScore = (baseAccuracy + paceBonus).clamp(0, 100);

    int stars;
    if (accuracyPercentage >= 80.0) {
      stars = 3;
    } else if (accuracyPercentage >= 50.0) {
      stars = 2;
    } else {
      stars = 1;
    }

    String message;
    if (stars == 3) {
      message = 'Outstanding sequence recall! You remembered the daily routine in perfect order!';
    } else if (stars == 2) {
      message = 'Good work! Ordering everyday activities helps strengthen daily procedural memory.';
    } else {
      message = 'Well done for practicing! Daily routine exercises help maintain independence.';
    }

    return SequenceSessionScore(
      totalTrials: totalTrials,
      totalSlotsEvaluated: totalSlots,
      correctlyPlacedSteps: correctSteps,
      totalErrors: totalErrors,
      accuracyPercentage: double.parse(accuracyPercentage.toStringAsFixed(1)),
      avgResponseTimeMs: double.parse(avgResponseTimeMs.toStringAsFixed(1)),
      totalHesitationMs: totalHesitationMs,
      calculatedScore: totalScore,
      stars: stars,
      encouragementMessage: message,
    );
  }
}
