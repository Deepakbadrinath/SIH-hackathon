import 'package:flutter/material.dart';

/// Accessible card container engineered for elderly users.
/// Provides high-contrast borders, tactile padding, gentle elevation without glare,
/// and full accessibility semantics.
class AccessibleCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final String? semanticLabel;

  const AccessibleCard({
    super.key,
    required this.child,
    this.onTap,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 2.0,
    this.padding = const EdgeInsets.all(20.0),
    this.margin = const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final effectiveBg = backgroundColor ??
        (isDark ? const Color(0xFF18181B) : Colors.white);
    final effectiveBorder = borderColor ??
        (isDark ? const Color(0xFFFACC15) : const Color(0xFFCBD5E1));

    Widget content = Padding(
      padding: padding,
      child: child,
    );

    if (onTap != null) {
      content = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: content,
      );
    }

    final cardBody = Container(
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: effectiveBorder, width: borderWidth),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: content,
      ),
    );

    return Padding(
      padding: margin,
      child: Semantics(
        container: true,
        button: onTap != null,
        label: semanticLabel,
        child: cardBody,
      ),
    );
  }
}
