import 'package:flutter/material.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/design_tokens.dart';
import '../../common_widgets/accessible_card.dart';
import '../../common_widgets/disclaimer_banner.dart';
import '../../common_widgets/large_text.dart';
import '../../common_widgets/responsive_scaffold.dart';
import '../../common_widgets/voice_instruction_button.dart';

class ElderlyHomeScreen extends StatelessWidget {
  const ElderlyHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.translate('elderly_home.title')),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded, size: 30),
            tooltip: context.l10n.translate('elderly_home.card_settings'),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: SafeArea(
        child: ResponsiveContainer(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const DisclaimerBanner(),
              const SizedBox(height: 12),
              AccessibleCard(
                backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
                borderColor: isDark ? const Color(0xFFFACC15) : const Color(0xFF93C5FD),
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: LargeText(
                            context.l10n.translate('elderly_home.greeting'),
                            type: LargeTextType.heading,
                            isHeader: true,
                          ),
                        ),
                        VoiceInstructionButton(
                          textToSpeak: context.l10n.translate('elderly_home.audio_prompt'),
                          isCompact: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LargeText(
                      context.l10n.translate('elderly_home.date_summary'),
                      type: LargeTextType.body,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Card 1: Brain Games
              _buildLargeHomeActionCard(
                context,
                title: context.l10n.translate('elderly_home.card_games'),
                subtitle: context.l10n.translate('elderly_home.card_games_sub'),
                icon: Icons.psychology_rounded,
                accentColor: const Color(0xFF0F3D78),
                onTap: () => Navigator.pushNamed(context, '/games'),
              ),
              // Card 2: My Medicines
              _buildLargeHomeActionCard(
                context,
                title: context.l10n.translate('elderly_home.card_meds'),
                subtitle: context.l10n.translate('elderly_home.card_meds_sub'),
                icon: Icons.medication_rounded,
                accentColor: const Color(0xFF166534),
                onTap: () => Navigator.pushNamed(context, '/medication'),
              ),
              // Card 3: My Progress
              _buildLargeHomeActionCard(
                context,
                title: context.l10n.translate('elderly_home.card_history'),
                subtitle: context.l10n.translate('elderly_home.card_history_sub'),
                icon: Icons.military_tech_rounded,
                accentColor: const Color(0xFFB45309),
                onTap: () => Navigator.pushNamed(context, '/history'),
              ),
              // Card 4: Call Caregiver
              _buildLargeHomeActionCard(
                context,
                title: context.l10n.translate('elderly_home.card_call_caregiver'),
                subtitle: context.l10n.translate('elderly_home.card_call_caregiver_sub'),
                icon: Icons.phone_in_talk_rounded,
                accentColor: const Color(0xFF7E22CE),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (dialogCtx) => AlertDialog(
                      title: Text(
                        context.l10n.translate('elderly_home.card_call_caregiver'),
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      content: Text(
                        context.l10n.translate('elderly_home.call_dialog_desc', args: {
                          'name': 'Priya Sharma',
                          'phone': '+91 98765 43210',
                        }),
                        style: const TextStyle(fontSize: 20),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogCtx),
                          child: Text(
                            context.l10n.translate('common.button.cancel'),
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(dialogCtx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  context.l10n.translate('elderly_home.calling_connecting'),
                                  style: const TextStyle(fontSize: 18),
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.call),
                          label: Text(
                            context.l10n.translate('elderly_home.button_call_now'),
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _buildLargeHomeActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AccessibleCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      semanticLabel: '$title: $subtitle. Tap to open.',
      child: Row(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF27272A) : accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? const Color(0xFFFACC15) : accentColor,
                width: 2.5,
              ),
            ),
            child: Icon(
              icon,
              size: 40,
              color: isDark ? const Color(0xFFFACC15) : accentColor,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LargeText(
                  title,
                  type: LargeTextType.title,
                ),
                const SizedBox(height: 4),
                LargeText(
                  subtitle,
                  type: LargeTextType.caption,
                  maxLines: 2,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.chevron_right_rounded,
            size: 36,
            color: isDark ? const Color(0xFFFACC15) : const Color(0xFF64748B),
          ),
        ],
      ),
    );
  }
}
