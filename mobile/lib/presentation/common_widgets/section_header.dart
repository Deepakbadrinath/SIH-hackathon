import 'package:flutter/material.dart';
import 'large_text.dart';
import 'voice_instruction_button.dart';

/// Semantic section header with accent indicator, accessible typography, and optional audio prompt.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? audioText;
  final EdgeInsetsGeometry padding;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.audioText,
    this.padding = const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 32,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFFFACC15) : theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: LargeText(
                  title,
                  type: LargeTextType.heading,
                  isHeader: true,
                ),
              ),
              if (audioText != null)
                VoiceInstructionButton(
                  textToSpeak: audioText!,
                  isCompact: true,
                ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 18.0),
              child: LargeText(
                subtitle!,
                type: LargeTextType.caption,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
