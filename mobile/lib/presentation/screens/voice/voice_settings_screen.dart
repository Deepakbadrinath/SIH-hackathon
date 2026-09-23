import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../features/settings/presentation/controllers/settings_controller.dart';
import '../../../features/voice/presentation/controllers/voice_controller.dart';
import '../../common_widgets/accessible_card.dart';
import '../../common_widgets/large_text.dart';
import '../../common_widgets/primary_button.dart';
import '../../common_widgets/secondary_button.dart';
import '../../common_widgets/section_header.dart';

class VoiceSettingsScreen extends StatelessWidget {
  const VoiceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final settingsCtrl = context.watch<SettingsController>();
    final voiceCtrl = context.read<VoiceController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.translate('voice.title')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 30),
          onPressed: () {
            try {
              voiceCtrl.stopAll();
            } catch (_) {}
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
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          children: [
            SectionHeader(
              title: context.l10n.translate('voice.title'),
              subtitle: context.l10n.translate('voice.subtitle'),
            ),
            const SizedBox(height: 8),

            // Speech Speed Card
            AccessibleCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.speed_rounded, size: 32, color: theme.colorScheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: LargeText(
                          context.l10n.translate('voice.speed_label'),
                          type: LargeTextType.title,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSpeedOption(
                          context,
                          label: context.l10n.translate('voice.speed_slow'),
                          speed: 0.75,
                          isSelected: settingsCtrl.speechRate <= 0.8,
                          onTap: () => settingsCtrl.setSpeechRate(0.75),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildSpeedOption(
                          context,
                          label: context.l10n.translate('voice.speed_normal'),
                          speed: 0.85,
                          isSelected: settingsCtrl.speechRate > 0.8 && settingsCtrl.speechRate <= 0.95,
                          onTap: () => settingsCtrl.setSpeechRate(0.85),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildSpeedOption(
                          context,
                          label: context.l10n.translate('voice.speed_fast'),
                          speed: 1.0,
                          isSelected: settingsCtrl.speechRate > 0.95,
                          onTap: () => settingsCtrl.setSpeechRate(1.0),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Speech Volume Card
            AccessibleCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.volume_up_rounded, size: 32, color: theme.colorScheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: LargeText(
                          context.l10n.translate('voice.volume_label'),
                          type: LargeTextType.title,
                        ),
                      ),
                      Text(
                        '${(settingsCtrl.speechVolume * 100).toInt()}%',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Slider(
                    value: settingsCtrl.speechVolume,
                    min: 0.2,
                    max: 1.0,
                    divisions: 8,
                    activeColor: isDark ? const Color(0xFFFACC15) : theme.colorScheme.primary,
                    onChanged: (val) => settingsCtrl.setSpeechVolume(val),
                  ),
                ],
              ),
            ),

            // Voice Tone / Gender
            AccessibleCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.record_voice_over_rounded, size: 32, color: theme.colorScheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: LargeText(
                          context.l10n.translate('voice.gender_label'),
                          type: LargeTextType.title,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSpeedOption(
                          context,
                          label: context.l10n.translate('voice.gender_female'),
                          speed: 1.0,
                          isSelected: settingsCtrl.voiceGender == 'female',
                          onTap: () => settingsCtrl.setVoiceGender('female'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildSpeedOption(
                          context,
                          label: context.l10n.translate('voice.gender_male'),
                          speed: 1.0,
                          isSelected: settingsCtrl.voiceGender == 'male',
                          onTap: () => settingsCtrl.setVoiceGender('male'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Regional Voice Capabilities Card
            AccessibleCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.language_rounded, size: 32, color: theme.colorScheme.primary),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: LargeText(
                          'Regional Voice Engine',
                          type: LargeTextType.title,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Multi-provider architecture: Bhashini Cloud AI with Platform Offline Fallback for 14 Indian languages.',
                    style: TextStyle(
                      fontSize: 15,
                      color: isDark ? const Color(0xFFD4D4D8) : const Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildLangBadge(context, 'Assamese (অসমীয়া)', true, false),
                      _buildLangBadge(context, 'Manipuri (মৈতৈলোন্)', true, false),
                      _buildLangBadge(context, 'Bengali (বাংলা)', true, false),
                      _buildLangBadge(context, 'Hindi (हिन्दी)', true, true),
                      _buildLangBadge(context, 'English', true, true),
                      _buildLangBadge(context, 'Odia (ଓଡ଼ିଆ)', true, false),
                      _buildLangBadge(context, 'Telugu (తెలుగు)', true, false),
                      _buildLangBadge(context, 'Tamil (தமிழ்)', true, false),
                      _buildLangBadge(context, 'Kannada (ಕನ್ನಡ)', true, false),
                      _buildLangBadge(context, 'Malayalam (മലയാളം)', true, false),
                      _buildLangBadge(context, 'Marathi (मराठी)', true, false),
                      _buildLangBadge(context, 'Gujarati (ગુજરાતી)', true, false),
                      _buildLangBadge(context, 'Punjabi (ਪੰਜਾਬੀ)', true, false),
                      _buildLangBadge(context, 'Urdu (اردو)', true, false),
                    ],
                  ),
                ],
              ),
            ),

            // SIH Regional Voice Live Demonstration Card
            AccessibleCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.record_voice_over_rounded, size: 28, color: Color(0xFF0284C7)),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: LargeText(
                          'Live Regional Voice Demo (SIH)',
                          type: LargeTextType.title,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16A34A).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFF16A34A)),
                        ),
                        child: const Text(
                          'OFFLINE-SAFE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF16A34A),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap any regional button below to test immediate synthesis. Demonstrates AI cloud provider with automatic offline TTS fallback if internet is unavailable.',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? const Color(0xFFD4D4D8) : const Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildVoiceDemoRow(
                    context,
                    langName: 'Assamese (অসমীয়া)',
                    phrase: 'নমস্কাৰ, আজি আপুনি কেনে অনুভৱ কৰিছে?',
                    langCode: 'as',
                    isDark: isDark,
                    onTap: () {
                      voiceCtrl.speakText('নমস্কাৰ, আজি আপুনি কেনে অনুভৱ কৰিছে?', languageCode: 'as');
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildVoiceDemoRow(
                    context,
                    langName: 'Manipuri (মৈতৈলোন্)',
                    phrase: 'খুরুমজরি, অদোম কয়া ফনা লৈরি?',
                    langCode: 'mni',
                    isDark: isDark,
                    onTap: () {
                      voiceCtrl.speakText('খুরুমজরি, অদোম কয়া ফনা লৈরি?', languageCode: 'mni');
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildVoiceDemoRow(
                    context,
                    langName: 'Bengali (বাংলা)',
                    phrase: 'নমস্কার, আজ আপনি কেমন বোধ করছেন?',
                    langCode: 'bn',
                    isDark: isDark,
                    onTap: () {
                      voiceCtrl.speakText('নমস্কার, আজ আপনি কেমন বোধ করছেন?', languageCode: 'bn');
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildVoiceDemoRow(
                    context,
                    langName: 'Hindi (हिन्दी)',
                    phrase: 'नमस्ते, आज आप कैसा महसूस कर रहे हैं?',
                    langCode: 'hi',
                    isDark: isDark,
                    onTap: () {
                      voiceCtrl.speakText('नमस्ते, आज आप कैसा महसूस कर रहे हैं?', languageCode: 'hi');
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildVoiceDemoRow(
                    context,
                    langName: 'English',
                    phrase: 'Hello, welcome to Smriti Setu. Let us begin your daily activity.',
                    langCode: 'en',
                    isDark: isDark,
                    onTap: () {
                      voiceCtrl.speakText('Hello, welcome to Smriti Setu. Let us begin your daily activity.', languageCode: 'en');
                    },
                  ),
                ],
              ),
            ),

            // Test Voice Audio Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              child: Column(
                children: [
                  PrimaryButton(
                    label: context.l10n.translate('voice.test_button'),
                    icon: Icons.play_circle_fill_rounded,
                    height: 64.0,
                    onPressed: () {
                      voiceCtrl.speakText(context.l10n.translate('voice.test_phrase'));
                    },
                  ),
                  const SizedBox(height: 12),
                  SecondaryButton(
                    label: 'Repeat Spoken Instruction',
                    icon: Icons.replay_rounded,
                    height: 56.0,
                    onPressed: () {
                      voiceCtrl.repeatLastInstruction(
                        fallbackInstruction: context.l10n.translate('voice.test_phrase'),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceDemoRow(
    BuildContext context, {
    required String langName,
    required String phrase,
    required String langCode,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  langName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0369A1),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  phrase,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.volume_up_rounded, color: Color(0xFF0284C7)),
            tooltip: 'Play $langName sample',
            onPressed: onTap,
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedOption(
    BuildContext context, {
    required String label,
    required double speed,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? const Color(0xFFFACC15) : theme.colorScheme.primary)
                : (isDark ? const Color(0xFF27272A) : const Color(0xFFF1F5F9)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? (isDark ? Colors.white : theme.colorScheme.primary) : const Color(0xFF94A3B8),
              width: 2.0,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
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

  Widget _buildLangBadge(
    BuildContext context,
    String name,
    bool hasCloud,
    bool hasOffline,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF27272A) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? const Color(0xFF3F3F46) : const Color(0xFFCBD5E1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasCloud ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
            size: 16,
            color: hasCloud ? const Color(0xFF2563EB) : Colors.grey,
          ),
          const SizedBox(width: 4),
          Text(
            name,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          if (hasOffline) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: const Color(0xFF16A34A).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'OFFLINE',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF16A34A),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
