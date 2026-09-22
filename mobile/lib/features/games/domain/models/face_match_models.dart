/// Face profile representing a recognized family member for visual memory association.
class FaceProfile {
  final String id;
  final String name;
  final String relation;
  final String assetPath;
  final String voicePrompt;

  const FaceProfile({
    required this.id,
    required this.name,
    required this.relation,
    required this.assetPath,
    required this.voicePrompt,
  });
}

/// Standard demo profiles ensuring zero use of non-consensual real photographs.
class DefaultFaceProfiles {
  static const FaceProfile aita = FaceProfile(
    id: 'face_aita',
    name: 'Aita (Grandmother)',
    relation: 'Wife',
    assetPath: 'assets/images/faces/aita.png',
    voicePrompt: 'Find Aita, your loving wife',
  );

  static const FaceProfile koka = FaceProfile(
    id: 'face_koka',
    name: 'Koka (Grandfather)',
    relation: 'Brother',
    assetPath: 'assets/images/faces/koka.png',
    voicePrompt: 'Find Koka, your elder brother',
  );

  static const FaceProfile daughter = FaceProfile(
    id: 'face_daughter',
    name: 'Priya (Daughter)',
    relation: 'Daughter',
    assetPath: 'assets/images/faces/daughter.png',
    voicePrompt: 'Find Priya, your caring daughter',
  );

  static const FaceProfile grandson = FaceProfile(
    id: 'face_grandson',
    name: 'Rahul (Grandson)',
    relation: 'Grandson',
    assetPath: 'assets/images/faces/grandson.png',
    voicePrompt: 'Find Rahul, your grandson',
  );

  static const List<FaceProfile> all = [aita, koka, daughter, grandson];
}

/// A single trial presentation in the Family Face Match game.
class FaceMatchTrial {
  final int trialNumber;
  final FaceProfile targetFace;
  final List<FaceProfile> options;
  final int correctIndex;

  const FaceMatchTrial({
    required this.trialNumber,
    required this.targetFace,
    required this.options,
    required this.correctIndex,
  });
}

/// Trial metrics measured during a single interaction.
class FaceMatchTrialResult {
  final int trialNumber;
  final String targetFaceId;
  final String selectedFaceId;
  final bool isCorrect;
  final int responseTimeMs;
  final int hesitationMs;

  const FaceMatchTrialResult({
    required this.trialNumber,
    required this.targetFaceId,
    required this.selectedFaceId,
    required this.isCorrect,
    required this.responseTimeMs,
    required this.hesitationMs,
  });
}

/// Aggregate session score outcome designed for personal cognitive stimulation.
class FaceMatchSessionScore {
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

  const FaceMatchSessionScore({
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

/// Deterministic, non-stressful scoring calculator for elderly dementia care.
class FamilyFaceMatchScoreCalculator {
  static FaceMatchSessionScore calculate(
    List<FaceMatchTrialResult> results, {
    int difficultyLevel = 1,
  }) {
    if (results.isEmpty) {
      return const FaceMatchSessionScore(
        totalTrials: 0,
        correctTrials: 0,
        errorCount: 0,
        accuracyPercentage: 0.0,
        avgResponseTimeMs: 0.0,
        totalHesitationMs: 0.0,
        calculatedScore: 0,
        stars: 1,
        encouragementMessage: 'Thank you for playing today!',
      );
    }

    final totalTrials = results.length;
    final correctTrials = results.where((r) => r.isCorrect).length;
    final errorCount = totalTrials - correctTrials;
    final accuracyPercentage = (correctTrials / totalTrials) * 100.0;

    final totalResponseMs = results.fold<int>(0, (sum, r) => sum + r.responseTimeMs);
    final avgResponseTimeMs = totalResponseMs / totalTrials;

    final totalHesitationMs = results.fold<int>(0, (sum, r) => sum + r.hesitationMs).toDouble();

    // Base accuracy score: up to 80 points
    final baseAccuracy = (accuracyPercentage * 0.80).round();

    // Gentle pacing bonus: up to 20 points (does not penalize leisurely responses)
    int pacingBonus = 0;
    if (correctTrials > 0) {
      final clampedResponse = avgResponseTimeMs.clamp(1000.0, 5000.0);
      pacingBonus = (((5000.0 - clampedResponse) / 4000.0) * 20.0).round().clamp(0, 20);
    }

    final totalScore = (baseAccuracy + pacingBonus).clamp(0, 100);

    // Warm star rating for elderly encouragement
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
      message = 'Wonderful effort! You recognized your family beautifully!';
    } else if (stars == 2) {
      message = 'Great effort! Practice keeps our memories bright and warm.';
    } else {
      message = 'Good effort today! Every exercise strengthens your brain.';
    }

    return FaceMatchSessionScore(
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
