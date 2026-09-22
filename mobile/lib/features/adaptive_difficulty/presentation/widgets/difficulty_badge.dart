import 'package:flutter/material.dart';

class DifficultyBadge extends StatelessWidget {
  final int level;
  final bool isCompact;

  const DifficultyBadge({
    super.key,
    required this.level,
    this.isCompact = false,
  });

  Color _getLevelColor(int lvl) {
    switch (lvl) {
      case 1:
        return const Color(0xFF059669); // Green
      case 2:
        return const Color(0xFF0D9488); // Teal
      case 3:
        return const Color(0xFF2563EB); // Blue
      case 4:
        return const Color(0xFFD97706); // Amber
      case 5:
      default:
        return const Color(0xFF7C3AED); // Purple
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getLevelColor(level);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 10 : 16,
        vertical: isCompact ? 6 : 10,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_graph_rounded, color: color, size: isCompact ? 18 : 24),
          const SizedBox(width: 8),
          Text(
            'Level $level of 5',
            style: TextStyle(
              fontSize: isCompact ? 14 : 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
