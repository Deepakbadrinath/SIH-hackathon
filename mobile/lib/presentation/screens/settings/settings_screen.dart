import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../features/settings/presentation/controllers/settings_controller.dart';
import '../../common_widgets/accessible_card.dart';
import '../../common_widgets/disclaimer_banner.dart';
import '../../common_widgets/large_text.dart';
import '../../common_widgets/responsive_scaffold.dart';
import '../../common_widgets/section_header.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final settingsCtrl = context.watch<SettingsController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.translate('settings.title')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 30),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            }
          },
          tooltip: context.l10n.translate('common.button.back'),
        ),
      ),
      body: SafeArea(
        child: ResponsiveContainer(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: DisclaimerBanner(),
            ),
            const SizedBox(height: 12),
            SectionHeader(
              title: context.l10n.translate('settings.title'),
              subtitle: 'Customize text size, contrast, and voice feedback.',
              audioText: context.l10n.translate('settings.audio_prompt'),
            ),
            const SizedBox(height: 8),

            // Font Size Section
            AccessibleCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.format_size_rounded, size: 32, color: theme.colorScheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: LargeText(
                          context.l10n.translate('settings.font_size_label'),
                          type: LargeTextType.title,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _buildFontOption(
                          context,
                          label: context.l10n.translate('settings.font_normal'),
                          scale: 1.0,
                          isSelected: settingsCtrl.fontScale <= 1.05,
                          onTap: () => settingsCtrl.setFontScale(1.0),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildFontOption(
                          context,
                          label: context.l10n.translate('settings.font_large'),
                          scale: 1.25,
                          isSelected: settingsCtrl.fontScale > 1.05 && settingsCtrl.fontScale <= 1.35,
                          onTap: () => settingsCtrl.setFontScale(1.25),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildFontOption(
                          context,
                          label: context.l10n.translate('settings.font_extra_large'),
                          scale: 1.5,
                          isSelected: settingsCtrl.fontScale > 1.35,
                          onTap: () => settingsCtrl.setFontScale(1.5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF27272A) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? const Color(0xFFFACC15) : const Color(0xFFCBD5E1)),
                    ),
                    child: Text(
                      context.l10n.translate('settings.preview_text'),
                      style: TextStyle(
                        fontSize: 18.0 * settingsCtrl.fontScale,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // High Contrast Mode Toggle
            AccessibleCard(
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: LargeText(
                  context.l10n.translate('settings.high_contrast_label'),
                  type: LargeTextType.title,
                ),
                subtitle: LargeText(
                  context.l10n.translate('settings.high_contrast_sub'),
                  type: LargeTextType.caption,
                ),
                value: settingsCtrl.highContrast,
                activeThumbColor: const Color(0xFFFACC15),
                onChanged: (_) => settingsCtrl.toggleHighContrast(),
              ),
            ),

            // Reduced Motion Toggle
            AccessibleCard(
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: LargeText(
                  context.l10n.translate('settings.reduced_motion_label'),
                  type: LargeTextType.title,
                ),
                subtitle: LargeText(
                  context.l10n.translate('settings.reduced_motion_sub'),
                  type: LargeTextType.caption,
                ),
                value: settingsCtrl.reducedMotion,
                activeThumbColor: isDark ? const Color(0xFFFACC15) : theme.colorScheme.primary,
                onChanged: (_) => settingsCtrl.toggleReducedMotion(),
              ),
            ),

            // Audio Guidance Toggle
            AccessibleCard(
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: LargeText(
                  context.l10n.translate('settings.voice_guidance_label'),
                  type: LargeTextType.title,
                ),
                subtitle: LargeText(
                  context.l10n.translate('settings.voice_guidance_sub'),
                  type: LargeTextType.caption,
                ),
                value: settingsCtrl.audioGuidanceEnabled,
                activeThumbColor: isDark ? const Color(0xFFFACC15) : theme.colorScheme.primary,
                onChanged: (_) => settingsCtrl.toggleAudioGuidance(),
              ),
            ),

            // Language Selection Navigation Card
            AccessibleCard(
              onTap: () => Navigator.pushNamed(context, '/language'),
              child: Row(
                children: [
                  Icon(Icons.language_rounded, size: 36, color: theme.colorScheme.primary),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LargeText(
                          context.l10n.translate('settings.language_button'),
                          type: LargeTextType.title,
                        ),
                        const SizedBox(height: 4),
                        LargeText(
                          context.l10n.translate('settings.language_sub'),
                          type: LargeTextType.caption,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, size: 36),
                ],
              ),
            ),

            // Voice Settings Navigation Card
            AccessibleCard(
              onTap: () => Navigator.pushNamed(context, '/voice_settings'),
              child: Row(
                children: [
                  Icon(Icons.record_voice_over_rounded, size: 36, color: theme.colorScheme.primary),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LargeText(
                          context.l10n.translate('settings.voice_settings_button'),
                          type: LargeTextType.title,
                        ),
                        const SizedBox(height: 4),
                        LargeText(
                          context.l10n.translate('settings.voice_sub'),
                          type: LargeTextType.caption,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, size: 36),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildFontOption(
    BuildContext context, {
    required String label,
    required double scale,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Semantics(
      button: true,
      selected: isSelected,
      label: '$label text size',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? const Color(0xFFFACC15) : theme.colorScheme.primary)
                : (isDark ? const Color(0xFF27272A) : const Color(0xFFF1F5F9)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? (isDark ? Colors.white : theme.colorScheme.primary)
                  : const Color(0xFF94A3B8),
              width: 2.0,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isSelected
                  ? (isDark ? Colors.black : Colors.white)
                  : (isDark ? Colors.white : const Color(0xFF0F172A)),
            ),
          ),
        ),
      ),
    );
  }
}
