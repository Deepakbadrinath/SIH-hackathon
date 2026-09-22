import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

/// Primary elderly-first button adhering to WCAG AAA touch targets and typography.
/// Guaranteed minimum height of 64px, bold typography (>= 20px), and explicit semantic labeling.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool isFullWidth;
  final double height;
  final String? semanticLabel;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.isFullWidth = true,
    this.height = 64.0,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveBg = backgroundColor ?? theme.colorScheme.primary;
    final effectiveFg = foregroundColor ?? theme.colorScheme.onPrimary;

    final content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 28, color: effectiveFg),
          const SizedBox(width: 12),
        ],
        Flexible(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppConstants.minBodyFontSize,
              fontWeight: FontWeight.bold,
              color: effectiveFg,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ],
    );

    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: semanticLabel ?? label,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: height,
          minWidth: isFullWidth ? double.infinity : 140.0,
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: effectiveBg,
            foregroundColor: effectiveFg,
            minimumSize: Size(isFullWidth ? double.infinity : 140.0, height),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 3,
          ),
          child: content,
        ),
      ),
    );
  }
}
