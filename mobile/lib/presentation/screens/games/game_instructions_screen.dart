import 'package:flutter/material.dart';
import '../../../core/localization/app_localizations.dart';
import '../../common_widgets/accessible_card.dart';
import '../../common_widgets/large_text.dart';
import '../../common_widgets/primary_button.dart';
import '../../common_widgets/responsive_scaffold.dart';
import '../../common_widgets/voice_instruction_button.dart';

class GameInstructionsScreen extends StatelessWidget {
  const GameInstructionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final title = args?['title'] as String? ?? 'Cognitive Exercise';
    final instruction = args?['instruction'] as String? ??
        context.l10n.translate('instructions.audio_prompt');
    final iconData = args?['icon'] as IconData? ?? Icons.psychology_rounded;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 30),
          onPressed: () => Navigator.pop(context),
          tooltip: context.l10n.translate('common.button.back'),
        ),
      ),
      body: SafeArea(
        child: ResponsiveContainer(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF27272A) : const Color(0xFFEFF6FF),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? const Color(0xFFFACC15) : theme.colorScheme.primary,
                      width: 2.5,
                    ),
                  ),
                  child: Icon(
                    iconData,
                    size: 50,
                    color: isDark ? const Color(0xFFFACC15) : theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              LargeText(
                title,
                type: LargeTextType.heading,
                textAlign: TextAlign.center,
                isHeader: true,
              ),
              const SizedBox(height: 12),
              LargeText(
                instruction,
                type: LargeTextType.body,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Center(
                child: VoiceInstructionButton(
                  textToSpeak: '$title. $instruction',
                ),
              ),
              const SizedBox(height: 24),
              _buildStepCard(
                context,
                stepNumber: '1',
                text: context.l10n.translate('instructions.step1'),
                icon: Icons.visibility_rounded,
              ),
              const SizedBox(height: 12),
              _buildStepCard(
                context,
                stepNumber: '2',
                text: context.l10n.translate('instructions.step2'),
                icon: Icons.hourglass_empty_rounded,
              ),
              const SizedBox(height: 12),
              _buildStepCard(
                context,
                stepNumber: '3',
                text: context.l10n.translate('instructions.step3'),
                icon: Icons.touch_app_rounded,
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                label: context.l10n.translate('instructions.ready_button'),
                icon: Icons.play_arrow_rounded,
                height: 68.0,
                onPressed: () {
                  final gameId = args?['gameId'] as String? ?? 'face_match';
                  if (gameId == 'face_match') {
                    Navigator.pushReplacementNamed(context, '/face_match');
                  } else if (gameId == 'pattern') {
                    Navigator.pushReplacementNamed(context, '/pattern_completion');
                  } else if (gameId == 'sequence') {
                    Navigator.pushReplacementNamed(context, '/activity_sequence');
                  } else if (gameId == 'sorting') {
                    Navigator.pushReplacementNamed(context, '/object_sorting');
                  } else {
                    Navigator.pushReplacementNamed(
                      context,
                      '/game_results',
                      arguments: {
                        'gameTitle': title,
                      },
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _buildStepCard(
    BuildContext context, {
    required String stepNumber,
    required String text,
    required IconData icon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AccessibleCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      margin: EdgeInsets.zero,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFFFACC15) : const Color(0xFF0F3D78),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              stepNumber,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.black : Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: LargeText(
              text,
              type: LargeTextType.body,
            ),
          ),
        ],
      ),
    );
  }
}
