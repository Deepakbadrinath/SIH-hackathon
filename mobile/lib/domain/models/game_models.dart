enum GameType {
  familyFaceMatch,
  patternCompletion,
  activitySequence,
  objectSorting,
}

extension GameTypeExtension on GameType {
  String toDbString() {
    switch (this) {
      case GameType.familyFaceMatch:
        return 'FAMILY_FACE_MATCH';
      case GameType.patternCompletion:
        return 'PATTERN_COMPLETION';
      case GameType.activitySequence:
        return 'ACTIVITY_SEQUENCE';
      case GameType.objectSorting:
        return 'OBJECT_SORTING';
    }
  }

  static GameType fromDbString(String str) {
    switch (str.toUpperCase()) {
      case 'FAMILY_FACE_MATCH':
        return GameType.familyFaceMatch;
      case 'PATTERN_COMPLETION':
        return GameType.patternCompletion;
      case 'ACTIVITY_SEQUENCE':
        return GameType.activitySequence;
      case 'OBJECT_SORTING':
      default:
        return GameType.objectSorting;
    }
  }
}

class GameSession {
  final String id;
  final String patientId;
  final GameType gameType;
  final DateTime startTime;
  final DateTime? endTime;
  final int difficultyLevel;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;

  const GameSession({
    required this.id,
    required this.patientId,
    required this.gameType,
    required this.startTime,
    this.endTime,
    required this.difficultyLevel,
    this.isCompleted = false,
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patient_id': patientId,
      'game_type': gameType.toDbString(),
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'difficulty_level': difficultyLevel,
      'is_completed': isCompleted ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
    };
  }

  factory GameSession.fromMap(Map<String, dynamic> map) {
    return GameSession(
      id: map['id'] as String,
      patientId: map['patient_id'] as String,
      gameType: GameTypeExtension.fromDbString(map['game_type'] as String),
      startTime: DateTime.parse(map['start_time'] as String),
      endTime: map['end_time'] != null ? DateTime.parse(map['end_time'] as String) : null,
      difficultyLevel: map['difficulty_level'] as int,
      isCompleted: (map['is_completed'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      isSynced: (map['is_synced'] as int?) == 1,
    );
  }
}

class GameResult {
  final String id;
  final String sessionId;
  final GameType gameType;
  final int score;
  final int maxPossibleScore;
  final double accuracyPercentage;
  final int totalTrials;
  final int correctTrials;
  final int errorCount;
  final double avgResponseTimeMs;
  final double totalHesitationPauseMs;
  final DateTime completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;

  const GameResult({
    required this.id,
    required this.sessionId,
    required this.gameType,
    required this.score,
    required this.maxPossibleScore,
    required this.accuracyPercentage,
    required this.totalTrials,
    required this.correctTrials,
    required this.errorCount,
    required this.avgResponseTimeMs,
    required this.totalHesitationPauseMs,
    required this.completedAt,
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'session_id': sessionId,
      'game_type': gameType.toDbString(),
      'score': score,
      'max_possible_score': maxPossibleScore,
      'accuracy_percentage': accuracyPercentage,
      'total_trials': totalTrials,
      'correct_trials': correctTrials,
      'error_count': errorCount,
      'avg_response_time_ms': avgResponseTimeMs,
      'total_hesitation_pause_ms': totalHesitationPauseMs,
      'completed_at': completedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
    };
  }

  factory GameResult.fromMap(Map<String, dynamic> map) {
    return GameResult(
      id: map['id'] as String,
      sessionId: map['session_id'] as String,
      gameType: GameTypeExtension.fromDbString(map['game_type'] as String),
      score: map['score'] as int,
      maxPossibleScore: map['max_possible_score'] as int,
      accuracyPercentage: (map['accuracy_percentage'] as num).toDouble(),
      totalTrials: map['total_trials'] as int,
      correctTrials: map['correct_trials'] as int,
      errorCount: map['error_count'] as int,
      avgResponseTimeMs: (map['avg_response_time_ms'] as num).toDouble(),
      totalHesitationPauseMs: (map['total_hesitation_pause_ms'] as num).toDouble(),
      completedAt: DateTime.parse(map['completed_at'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      isSynced: (map['is_synced'] as int?) == 1,
    );
  }
}

class PerformanceMetrics {
  final String id;
  final String sessionId;
  final int trialNumber;
  final String stimulusId;
  final String userResponse;
  final bool isCorrect;
  final int responseTimeMs;
  final int hesitationDurationMs;
  final DateTime recordedAt;
  final bool isSynced;

  const PerformanceMetrics({
    required this.id,
    required this.sessionId,
    required this.trialNumber,
    required this.stimulusId,
    required this.userResponse,
    required this.isCorrect,
    required this.responseTimeMs,
    required this.hesitationDurationMs,
    required this.recordedAt,
    this.isSynced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'session_id': sessionId,
      'trial_number': trialNumber,
      'stimulus_id': stimulusId,
      'user_response': userResponse,
      'is_correct': isCorrect ? 1 : 0,
      'response_time_ms': responseTimeMs,
      'hesitation_duration_ms': hesitationDurationMs,
      'recorded_at': recordedAt.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
    };
  }

  factory PerformanceMetrics.fromMap(Map<String, dynamic> map) {
    return PerformanceMetrics(
      id: map['id'] as String,
      sessionId: map['session_id'] as String,
      trialNumber: map['trial_number'] as int,
      stimulusId: map['stimulus_id'] as String,
      userResponse: map['user_response'] as String,
      isCorrect: (map['is_correct'] as int) == 1,
      responseTimeMs: map['response_time_ms'] as int,
      hesitationDurationMs: map['hesitation_duration_ms'] as int,
      recordedAt: DateTime.parse(map['recorded_at'] as String),
      isSynced: (map['is_synced'] as int?) == 1,
    );
  }
}

class DifficultyHistory {
  final String id;
  final String patientId;
  final GameType gameType;
  final int previousDifficulty;
  final int newDifficulty;
  final String reason;
  final double calculatedPerformanceScore;
  final DateTime calculatedAt;
  final bool isSynced;

  const DifficultyHistory({
    required this.id,
    required this.patientId,
    required this.gameType,
    required this.previousDifficulty,
    required this.newDifficulty,
    required this.reason,
    required this.calculatedPerformanceScore,
    required this.calculatedAt,
    this.isSynced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patient_id': patientId,
      'game_type': gameType.toDbString(),
      'previous_difficulty': previousDifficulty,
      'new_difficulty': newDifficulty,
      'reason': reason,
      'calculated_performance_score': calculatedPerformanceScore,
      'calculated_at': calculatedAt.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
    };
  }

  factory DifficultyHistory.fromMap(Map<String, dynamic> map) {
    return DifficultyHistory(
      id: map['id'] as String,
      patientId: map['patient_id'] as String,
      gameType: GameTypeExtension.fromDbString(map['game_type'] as String),
      previousDifficulty: map['previous_difficulty'] as int,
      newDifficulty: map['new_difficulty'] as int,
      reason: map['reason'] as String,
      calculatedPerformanceScore: (map['calculated_performance_score'] as num).toDouble(),
      calculatedAt: DateTime.parse(map['calculated_at'] as String),
      isSynced: (map['is_synced'] as int?) == 1,
    );
  }
}
