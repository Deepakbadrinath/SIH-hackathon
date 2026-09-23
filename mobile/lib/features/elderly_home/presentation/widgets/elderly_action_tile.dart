import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../presentation/common_widgets/app_hover_interactive.dart';

class ElderlyActionTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String? badgeText;

  const ElderlyActionTile({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
    this.badgeText,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: title,
      child: AppHoverInteractive(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        hoverGlowColor: color.withValues(alpha: 0.25),
        child: Container(
          height: 120,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color, width: 2.5),
          ),
          child: Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 40, color: Colors.white),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: AppConstants.minHeadingFontSize,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    if (badgeText != null)
                      Text(
                        badgeText!,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 28, color: color),
            ],
          ),
        ),
      ),
    );
  }
}
