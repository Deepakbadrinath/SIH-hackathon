import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../domain/models/caregiver_dashboard_models.dart';

/// Accessible simple chart depicting accuracy percentage trend over time.
class AccuracyTrendChart extends StatelessWidget {
  final List<TrendDataPoint<double>> trendPoints;
  final double height;

  const AccuracyTrendChart({
    super.key,
    required this.trendPoints,
    this.height = 160.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final displayPoints = trendPoints.isEmpty
        ? [
            TrendDataPoint(timestamp: DateTime.now().subtract(const Duration(days: 4)), value: 75.0, label: 'Mon'),
            TrendDataPoint(timestamp: DateTime.now().subtract(const Duration(days: 3)), value: 80.0, label: 'Tue'),
            TrendDataPoint(timestamp: DateTime.now().subtract(const Duration(days: 2)), value: 82.5, label: 'Wed'),
            TrendDataPoint(timestamp: DateTime.now().subtract(const Duration(days: 1)), value: 88.0, label: 'Thu'),
            TrendDataPoint(timestamp: DateTime.now(), value: 86.4, label: 'Today'),
          ]
        : trendPoints.take(7).toList();

    return Semantics(
      label: 'Accuracy Trend Chart showing ${displayPoints.length} recent sessions. Latest accuracy is ${displayPoints.last.value.toStringAsFixed(1)} percent.',
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    'Accuracy Over Time (%)',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.grey.shade300 : const Color(0xFF334155),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Target: 80%+',
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF166534),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: displayPoints.map((pt) {
                  final clampedVal = pt.value.clamp(0.0, 100.0);
                  final ratio = clampedVal / 100.0;

                  return Flexible(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '${clampedVal.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white70 : const Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Expanded(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: FractionallySizedBox(
                                heightFactor: max(0.1, ratio),
                                child: Container(
                                  width: 28,
                                  decoration: BoxDecoration(
                                    color: clampedVal >= 80
                                        ? const Color(0xFF2563EB)
                                        : (clampedVal >= 60 ? const Color(0xFF3B82F6) : const Color(0xFF93C5FD)),
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            pt.label,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Accessible simple chart depicting response-time trend over time.
class ResponseTimeTrendChart extends StatelessWidget {
  final List<TrendDataPoint<double>> trendPoints;
  final double height;

  const ResponseTimeTrendChart({
    super.key,
    required this.trendPoints,
    this.height = 160.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final displayPoints = trendPoints.isEmpty
        ? [
            TrendDataPoint(timestamp: DateTime.now().subtract(const Duration(days: 4)), value: 3.2, label: 'Mon'),
            TrendDataPoint(timestamp: DateTime.now().subtract(const Duration(days: 3)), value: 2.8, label: 'Tue'),
            TrendDataPoint(timestamp: DateTime.now().subtract(const Duration(days: 2)), value: 2.6, label: 'Wed'),
            TrendDataPoint(timestamp: DateTime.now().subtract(const Duration(days: 1)), value: 2.4, label: 'Thu'),
            TrendDataPoint(timestamp: DateTime.now(), value: 2.3, label: 'Today'),
          ]
        : trendPoints.take(7).toList();

    return Semantics(
      label: 'Response Time Trend Chart showing average speed of ${displayPoints.last.value.toStringAsFixed(1)} seconds.',
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    'Response Speed (Seconds)',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.grey.shade300 : const Color(0xFF334155),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Lower is faster',
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: displayPoints.map((pt) {
                  // Normalize 0s to 5s scale
                  final ratio = (pt.value / 5.0).clamp(0.1, 1.0);

                  return Flexible(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '${pt.value.toStringAsFixed(1)}s',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white70 : const Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Expanded(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: FractionallySizedBox(
                                heightFactor: ratio,
                                child: Container(
                                  width: 28,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF0D9488),
                                    borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            pt.label,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Accessible simple chart depicting adaptive difficulty level progression (1 to 5).
class DifficultyProgressionChart extends StatelessWidget {
  final List<TrendDataPoint<int>> progressionPoints;
  final int currentDifficulty;
  final double height;

  const DifficultyProgressionChart({
    super.key,
    required this.progressionPoints,
    required this.currentDifficulty,
    this.height = 140.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Semantics(
      label: 'Difficulty Progression Chart. Current adaptive difficulty is Level $currentDifficulty of 5.',
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    'Difficulty Progression',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.grey.shade300 : const Color(0xFF334155),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD97706).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Level $currentDifficulty of 5',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFD97706),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 5-Level Progress Bar Stepper
            Row(
              children: List.generate(5, (index) {
                final level = index + 1;
                final isReached = level <= currentDifficulty;
                final isCurrent = level == currentDifficulty;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3.0),
                    child: Column(
                      children: [
                        Container(
                          height: 24,
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? const Color(0xFFD97706)
                                : (isReached ? const Color(0xFFF59E0B) : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1))),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(
                            child: Text(
                              '$level',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isReached ? Colors.white : (isDark ? Colors.grey.shade400 : Colors.black54),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _getLevelLabel(level),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                            color: isCurrent
                                ? const Color(0xFFD97706)
                                : (isDark ? Colors.grey.shade400 : const Color(0xFF64748B)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  String _getLevelLabel(int level) {
    switch (level) {
      case 1:
        return 'Gentle';
      case 2:
        return 'Moderate';
      case 3:
        return 'Standard';
      case 4:
        return 'Advanced';
      case 5:
        return 'Expert';
      default:
        return 'L$level';
    }
  }
}
