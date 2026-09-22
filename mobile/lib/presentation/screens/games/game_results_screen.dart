import 'package:flutter/material.dart';
import '../../../core/localization/app_localizations.dart';
import '../../common_widgets/accessible_card.dart';
import '../../common_widgets/disclaimer_banner.dart';
import '../../common_widgets/large_text.dart';
import '../../common_widgets/primary_button.dart';
import '../../common_widgets/responsive_scaffold.dart';
import '../../common_widgets/secondary_button.dart';
import '../../common_widgets/voice_instruction_button.dart';

class GameResultsScreen extends StatelessWidget {
  const GameResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final gameTitle = args?['gameTitle'] as String? ?? 'Cognitive Activity';

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.translate('results.title')),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: ResponsiveContainer(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const DisclaimerBanner(),
              const SizedBox(height: 16),
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF27272A) : const Color(0xFFDCFCE7),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF166534),
                      width: 3.0,
                    ),
                  ),
                  child: Icon(
                    Icons.celebration_rounded,
                    size: 56,
                    color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF166534),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              LargeText(
                context.l10n.translate('results.great_job'),
                type: LargeTextType.heading,
                textAlign: TextAlign.center,
                isHeader: true,
              ),
              const SizedBox(height: 8),
              LargeText(
                gameTitle,
                type: LargeTextType.title,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Center(
                child: VoiceInstructionButton(
                  textToSpeak: '${context.l10n.translate("results.great_job")} You finished $gameTitle.',
                ),
              ),
              const SizedBox(height: 24),
              AccessibleCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildResultRow(
                      context,
                      label: context.l10n.translate('results.stat_accuracy'),
                      value: '85%',
                      icon: Icons.check_circle_rounded,
                      iconColor: const Color(0xFF166534),
                    ),
                    const Divider(height: 24, thickness: 1.5),
                    _buildResultRow(
                      context,
                      label: context.l10n.translate('results.stat_time'),
                      value: '2m 15s',
                      icon: Icons.timer_rounded,
                      iconColor: const Color(0xFF0F3D78),
                    ),
                    const Divider(height: 24, thickness: 1.5),
                    _buildResultRow(
                      context,
                      label: context.l10n.translate('results.stat_level'),
                      value: 'Level 1 (Gentle)',
                      icon: Icons.auto_awesome_rounded,
                      iconColor: const Color(0xFFB45309),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                label: context.l10n.translate('results.play_again'),
                icon: Icons.replay_rounded,
                height: 64.0,
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/games');
                },
              ),
              const SizedBox(height: 14),
              SecondaryButton(
                label: context.l10n.translate('results.home_button'),
                icon: Icons.home_rounded,
                height: 56.0,
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(context, '/elderly_home', (route) => false);
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _buildResultRow(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Icon(icon, size: 32, color: isDark ? const Color(0xFFFACC15) : iconColor),
        const SizedBox(width: 14),
        Expanded(
          child: LargeText(
            label,
            type: LargeTextType.body,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}
