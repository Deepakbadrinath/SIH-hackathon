import 'package:flutter/material.dart';
import 'primary_button.dart';
import 'secondary_button.dart';

/// Accessibility button wrapper that delegates to standardized design system tokens.
/// Prefer using [PrimaryButton] or [SecondaryButton] directly.
class AccessibleButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final bool isSecondary;

  const AccessibleButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.isSecondary = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isSecondary) {
      return SecondaryButton(
        label: label,
        onPressed: onPressed,
        icon: icon,
        textColor: textColor,
      );
    }
    return PrimaryButton(
      label: label,
      onPressed: onPressed,
      icon: icon,
      backgroundColor: backgroundColor,
      foregroundColor: textColor,
    );
  }
}
