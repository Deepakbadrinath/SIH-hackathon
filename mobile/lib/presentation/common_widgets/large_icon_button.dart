import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

/// Large icon button with mandatory text label to reduce cognitive load for elderly users.
/// Guarantees generous touch target (>= 64px) with high-contrast tactile borders.
class LargeIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? iconColor;
  final Color? textColor;
  final bool isHorizontal;
  final double minSize;

  const LargeIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.backgroundColor,
    this.iconColor,
    this.textColor,
    this.isHorizontal = false,
    this.minSize = 64.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final effectiveBg = backgroundColor ?? (isDark ? const Color(0xFF27272A) : const Color(0xFFEFF6FF));
    final effectiveBorder = isDark ? const Color(0xFFFACC15) : const Color(0xFF93C5FD);
    final effectiveIcon = iconColor ?? (isDark ? const Color(0xFFFACC15) : theme.colorScheme.primary);
    final effectiveText = textColor ?? (isDark ? Colors.white : const Color(0xFF0F172A));

    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            constraints: BoxConstraints(
              minHeight: minSize,
              minWidth: minSize,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: effectiveBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: effectiveBorder, width: 2.0),
            ),
            child: isHorizontal
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 32, color: effectiveIcon),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: AppConstants.minBodyFontSize,
                            fontWeight: FontWeight.bold,
                            color: effectiveText,
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 36, color: effectiveIcon),
                      const SizedBox(height: 8),
                      Text(
                        label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                          color: effectiveText,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
