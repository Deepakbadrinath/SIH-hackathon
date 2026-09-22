import 'game_models.dart';
import 'patient.dart';
import 'caregiver.dart';

/// Supported time windows for dashboard filtering.
enum DateRangeFilter {
  last7Days,
  last14Days,
  last30Days,
  allTime;

  String get displayName {
    switch (this) {
      case DateRangeFilter.last7Days:
        return 'Last 7 Days';
      case DateRangeFilter.last14Days:
        return 'Last 14 Days';
      case DateRangeFilter.last30Days:
        return 'Last 30 Days';
      case DateRangeFilter.allTime:
        return 'All Time';
    }
  }

  DateTime? get cutoffDate {
    final now = DateTime.now();
    switch (this) {
      case DateRangeFilter.last7Days:
        return now.subtract(const Duration(days: 7));
      case DateRangeFilter.last14Days:
        return now.subtract(const Duration(days: 14));
      case DateRangeFilter.last30Days:
        return now.subtract(const Duration(days: 30));
      case DateRangeFilter.allTime:
        return null;
    }
  }
}

/// Security exception thrown when an unauthorized caregiver attempts to access patient data.
class CaregiverUnauthorizedException implements Exception {
  final String message;
  final String? caregiverId;
  final String? patientId;

  const CaregiverUnauthorizedException(
    this.message, {
    this.caregiverId,
    this.patientId,
  });

  @override
  String toString() => 'CaregiverUnauthorizedException: $message';
}

/// Summary of an authorized connected patient.
class ConnectedPatient {
  final Patient patient;
  final CaregiverAccessRole accessRole;
  final bool isActive;

  const ConnectedPatient({
    required this.patient,
    required this.accessRole,
    required this.isActive,
  });

  String get id => patient.id;
  String get displayName => patient.displayName;
  int? get birthYear => patient.birthYear;
  String? get emergencyContactPhone => patient.emergencyContactPhone;
  String get regionalDialect => patient.regionalDialect;

  int? get estimatedAge {
    if (birthYear == null) return null;
    return DateTime.now().year - birthYear!;
  }
}

/// Data point representation for accessible simple charts.
class TrendDataPoint<T> {
  final DateTime timestamp;
  final T value;
  final String label;

  const TrendDataPoint({
    required this.timestamp,
    required this.value,
    required this.label,
  });
}

/// Aggregated metrics for cognitive game performance.
class CognitiveGamePerformanceSummary {
  final int totalGamesCompleted;
  final double averageAccuracy;
  final double averageResponseTimeSeconds;
  final int currentDifficultyLevel;
  final List<TrendDataPoint<double>> accuracyTrend;
  final List<TrendDataPoint<double>> responseTimeTrend;
  final List<TrendDataPoint<int>> difficultyProgression;
  final Map<GameType, int> gamesBreakdown;

  const CognitiveGamePerformanceSummary({
    required this.totalGamesCompleted,
    required this.averageAccuracy,
    required this.averageResponseTimeSeconds,
    required this.currentDifficultyLevel,
    required this.accuracyTrend,
    required this.responseTimeTrend,
    required this.difficultyProgression,
    required this.gamesBreakdown,
  });

  factory CognitiveGamePerformanceSummary.empty() {
    return const CognitiveGamePerformanceSummary(
      totalGamesCompleted: 0,
      averageAccuracy: 0.0,
      averageResponseTimeSeconds: 0.0,
      currentDifficultyLevel: 1,
      accuracyTrend: [],
      responseTimeTrend: [],
      difficultyProgression: [],
      gamesBreakdown: {},
    );
  }
}

/// Aggregated metrics for medication adherence.
class MedicationAdherenceSummary {
  final double adherencePercentage;
  final int totalScheduledDoses;
  final int takenDoses;
  final int skippedDoses;
  final int missedDoses;

  const MedicationAdherenceSummary({
    required this.adherencePercentage,
    required this.totalScheduledDoses,
    required this.takenDoses,
    required this.skippedDoses,
    required this.missedDoses,
  });

  factory MedicationAdherenceSummary.empty() {
    return const MedicationAdherenceSummary(
      adherencePercentage: 100.0,
      totalScheduledDoses: 0,
      takenDoses: 0,
      skippedDoses: 0,
      missedDoses: 0,
    );
  }
}

/// Summary item for a recent game session.
class RecentGameSessionSummary {
  final String sessionId;
  final GameType gameType;
  final String gameName;
  final DateTime playedAt;
  final int difficultyLevel;
  final bool isCompleted;
  final double accuracyPercentage;
  final double avgResponseTimeSeconds;
  final int score;

  const RecentGameSessionSummary({
    required this.sessionId,
    required this.gameType,
    required this.gameName,
    required this.playedAt,
    required this.difficultyLevel,
    required this.isCompleted,
    required this.accuracyPercentage,
    required this.avgResponseTimeSeconds,
    required this.score,
  });
}

/// Complete dashboard data bundle delivered to the Caregiver Dashboard.
class CaregiverDashboardData {
  final ConnectedPatient patient;
  final DateRangeFilter dateFilter;
  final CognitiveGamePerformanceSummary performanceSummary;
  final MedicationAdherenceSummary medicationSummary;
  final List<RecentGameSessionSummary> recentSessions;
  final DateTime generatedAt;

  const CaregiverDashboardData({
    required this.patient,
    required this.dateFilter,
    required this.performanceSummary,
    required this.medicationSummary,
    required this.recentSessions,
    required this.generatedAt,
  });
}
