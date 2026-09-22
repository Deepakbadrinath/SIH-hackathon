import 'package:flutter/material.dart';
import 'accessible_card.dart';
import 'large_text.dart';

/// Accessible progress card displaying non-clinical cognitive activity stats.
/// Highlights achievements with large readable figures and clear plain-language labels.
class ProgressCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color? accentColor;
  final VoidCallback? onTap;

  const ProgressCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    this.accentColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final effectiveAccent = accentColor ?? (isDark ? const Color(0xFFFACC15) : theme.colorScheme.primary);

    return AccessibleCard(
      onTap: onTap,
      padding: const EdgeInsets.all(20),
      semanticLabel: '$title: $value. ${subtitle ?? ""}',
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: effectiveAccent.withValues(alpha: isDark ? 0.25 : 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: effectiveAccent, width: 2.0),
            ),
            child: Icon(icon, size: 36, color: effectiveAccent),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                LargeText(
                  title,
                  type: LargeTextType.caption,
                  fontWeight: FontWeight.bold,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 34.0,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    letterSpacing: 0.5,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  LargeText(
                    subtitle!,
                    type: LargeTextType.caption,
                    color: isDark ? const Color(0xFFE4E4E7) : const Color(0xFF475569),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
