import 'package:flutter/material.dart';
import 'accessible_card.dart';
import 'large_text.dart';
import 'voice_instruction_button.dart';

/// Accessible GameCard displaying cognitive game details, cultural icon,
/// domain badge (e.g., Memory, Attention), difficulty rating, and audio prompt.
class GameCard extends StatelessWidget {
  final String title;
  final String description;
  final String domain;
  final int difficultyLevel;
  final IconData icon;
  final Color cardColor;
  final VoidCallback onPlay;
  final String? audioText;

  const GameCard({
    super.key,
    required this.title,
    required this.description,
    required this.domain,
    required this.difficultyLevel,
    required this.icon,
    this.cardColor = const Color(0xFF0F3D78),
    required this.onPlay,
    this.audioText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AccessibleCard(
      onTap: onPlay,
      semanticLabel: '$title, $domain game. $description. Tap to play.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF27272A) : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? const Color(0xFFFACC15) : cardColor,
                    width: 2.0,
                  ),
                ),
                child: Icon(
                  icon,
                  size: 36,
                  color: isDark ? const Color(0xFFFACC15) : cardColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LargeText(
                      title,
                      type: LargeTextType.title,
                      isHeader: true,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF3F3F46) : const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            domain,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark ? const Color(0xFFFACC15) : const Color(0xFF0F3D78),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Row(
                          children: List.generate(
                            3,
                            (index) => Icon(
                              index < difficultyLevel ? Icons.star_rounded : Icons.star_border_rounded,
                              size: 20,
                              color: const Color(0xFFB45309),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LargeText(
            description,
            type: LargeTextType.body,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (audioText != null)
                VoiceInstructionButton(
                  textToSpeak: audioText!,
                  isCompact: true,
                )
              else
                const SizedBox.shrink(),
              ElevatedButton.icon(
                onPressed: onPlay,
                icon: const Icon(Icons.play_arrow_rounded, size: 28),
                label: const Text(
                  'Play',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
