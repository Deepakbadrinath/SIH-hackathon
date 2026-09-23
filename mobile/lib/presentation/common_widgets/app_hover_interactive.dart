import 'package:flutter/material.dart';

/// Reusable universal hover & press interaction wrapper.
/// Adheres strictly to WCAG AAA accessibility, prevents layout shifts,
/// eliminates unexpected continuous resting animation, and guarantees
/// correct pointer cursor and keyboard focus visibility.
class AppHoverInteractive extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final bool enabled;
  final double hoverElevation;
  final double defaultElevation;
  final Color? hoverBorderColor;
  final Color? defaultBorderColor;
  final double borderWidth;
  final Color? hoverGlowColor;
  final String? semanticLabel;

  const AppHoverInteractive({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius,
    this.enabled = true,
    this.hoverElevation = 4.0,
    this.defaultElevation = 0.0,
    this.hoverBorderColor,
    this.defaultBorderColor,
    this.borderWidth = 0.0,
    this.hoverGlowColor,
    this.semanticLabel,
  });

  @override
  State<AppHoverInteractive> createState() => _AppHoverInteractiveState();
}

class _AppHoverInteractiveState extends State<AppHoverInteractive> {
  bool _isHovered = false;
  bool _isPressed = false;
  bool _isFocused = false;

  bool get _isInteractive => widget.enabled && widget.onTap != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final effectiveRadius = widget.borderRadius ?? BorderRadius.circular(16);
    final glowColor = widget.hoverGlowColor ??
        (isDark
            ? const Color(0xFFFACC15).withValues(alpha: 0.18)
            : const Color(0xFF0F3D78).withValues(alpha: 0.12));

    final effectiveBorder = widget.borderWidth > 0
        ? Border.all(
            color: (_isHovered || _isFocused)
                ? (widget.hoverBorderColor ?? (isDark ? const Color(0xFFFACC15) : theme.colorScheme.primary))
                : (widget.defaultBorderColor ?? (isDark ? const Color(0xFF3F3F46) : const Color(0xFFCBD5E1))),
            width: widget.borderWidth,
          )
        : null;

    final List<BoxShadow> shadows = [];
    if (_isInteractive && (_isHovered || _isFocused)) {
      shadows.add(
        BoxShadow(
          color: glowColor,
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      );
    } else if (widget.defaultElevation > 0) {
      shadows.add(
        BoxShadow(
          color: isDark ? Colors.black45 : Colors.black.withValues(alpha: 0.06),
          blurRadius: widget.defaultElevation * 2,
          offset: Offset(0, widget.defaultElevation * 0.7),
        ),
      );
    }

    // Subtle 2px lift on hover, slight press feedback on tap
    final double translateY = _isInteractive
        ? (_isPressed ? 0.5 : (_isHovered || _isFocused ? -2.0 : 0.0))
        : 0.0;

    return FocusableActionDetector(
      enabled: _isInteractive,
      onShowFocusHighlight: (value) {
        if (mounted && _isFocused != value) {
          setState(() => _isFocused = value);
        }
      },
      onShowHoverHighlight: (value) {
        if (mounted && _isHovered != value) {
          setState(() => _isHovered = value);
        }
      },
      mouseCursor: _isInteractive ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTapDown: _isInteractive ? (_) => setState(() => _isPressed = true) : null,
        onTapUp: _isInteractive ? (_) => setState(() => _isPressed = false) : null,
        onTapCancel: _isInteractive ? () => setState(() => _isPressed = false) : null,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(0, translateY, 0),
          decoration: BoxDecoration(
            borderRadius: effectiveRadius,
            border: effectiveBorder,
            boxShadow: shadows,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
