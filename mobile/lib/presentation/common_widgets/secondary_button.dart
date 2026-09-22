import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

/// Secondary elderly-first button with high-contrast outlines and clear touch target boundaries.
/// Prevents visual confusion while ensuring easy readability and touchability (>= 56px).
class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? borderColor;
  final Color? textColor;
  final bool isFullWidth;
  final double height;
  final String? semanticLabel;

  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.borderColor,
    this.textColor,
    this.isFullWidth = true,
    this.height = 56.0,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveBorder = borderColor ?? theme.colorScheme.primary;
    final effectiveText = textColor ?? theme.colorScheme.primary;

    final content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 26, color: effectiveText),
          const SizedBox(width: 10),
        ],
        Flexible(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppConstants.minBodyFontSize,
              fontWeight: FontWeight.bold,
              color: effectiveText,
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
          minWidth: isFullWidth ? double.infinity : 120.0,
        ),
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: effectiveBorder, width: 2.5),
            minimumSize: Size(isFullWidth ? double.infinity : 120.0, height),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: content,
        ),
      ),
    );
  }
}
