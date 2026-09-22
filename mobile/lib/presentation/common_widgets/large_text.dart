import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

enum LargeTextType {
  display,
  heading,
  title,
  body,
  caption;
}

/// Accessible text widget ensuring strict typography standards for elderly users:
/// - Display: >= 32px
/// - Heading: >= 26px
/// - Title: >= 22px
/// - Body: >= 20px
/// - Caption: >= 16px
/// Provides automated semantic header tagging for screen readers.
class LargeText extends StatelessWidget {
  final String text;
  final LargeTextType type;
  final Color? color;
  final TextAlign? textAlign;
  final FontWeight? fontWeight;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool isHeader;

  const LargeText(
    this.text, {
    super.key,
    this.type = LargeTextType.body,
    this.color,
    this.textAlign,
    this.fontWeight,
    this.maxLines,
    this.overflow,
    this.isHeader = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    double defaultSize;
    FontWeight defaultWeight;
    Color defaultColor;

    switch (type) {
      case LargeTextType.display:
        defaultSize = AppConstants.minDisplayFontSize;
        defaultWeight = FontWeight.w900;
        defaultColor = isDark ? Colors.white : const Color(0xFF0F172A);
        break;
      case LargeTextType.heading:
        defaultSize = AppConstants.minHeadingFontSize;
        defaultWeight = FontWeight.bold;
        defaultColor = isDark ? Colors.white : const Color(0xFF0F172A);
        break;
      case LargeTextType.title:
        defaultSize = 22.0;
        defaultWeight = FontWeight.bold;
        defaultColor = isDark ? const Color(0xFFFACC15) : theme.colorScheme.primary;
        break;
      case LargeTextType.body:
        defaultSize = AppConstants.minBodyFontSize;
        defaultWeight = FontWeight.w600;
        defaultColor = isDark ? const Color(0xFFF4F4F5) : const Color(0xFF1E293B);
        break;
      case LargeTextType.caption:
        defaultSize = 16.0;
        defaultWeight = FontWeight.w500;
        defaultColor = isDark ? const Color(0xFFA1A1AA) : const Color(0xFF475569);
        break;
    }

    final effectiveSize = defaultSize;
    final effectiveWeight = fontWeight ?? defaultWeight;
    final effectiveColor = color ?? defaultColor;

    final textWidget = Text(
      text,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      style: TextStyle(
        fontSize: effectiveSize,
        fontWeight: effectiveWeight,
        color: effectiveColor,
        height: 1.4,
      ),
    );

    if (isHeader || type == LargeTextType.display || type == LargeTextType.heading) {
      return Semantics(
        header: true,
        child: textWidget,
      );
    }

    return textWidget;
  }
}
