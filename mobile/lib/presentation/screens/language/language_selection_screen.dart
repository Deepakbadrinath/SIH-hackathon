import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../features/localization/presentation/controllers/localization_controller.dart';
import '../../common_widgets/accessible_card.dart';
import '../../common_widgets/large_text.dart';
import '../../common_widgets/responsive_scaffold.dart';
import '../../common_widgets/section_header.dart';
import '../../common_widgets/voice_instruction_button.dart';

class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final locCtrl = context.watch<LocalizationController>();
    final currentCode = locCtrl.currentLocale.languageCode;

    final languages = [
      {
        'code': 'as',
        'name': 'অসমীয়া',
        'english': 'Assamese',
        'sample': 'নমস্কাৰ! স্মৃতি সেতুত আপোনাক স্বাগতম।',
      },
      {
        'code': 'mni',
        'name': 'মৈতৈলোন্',
        'english': 'Meitei / Manipuri',
        'sample': 'খুরুমজরি! স্মৃতি সেতুদা তরাম্না ওকচরি।',
      },
      {
        'code': 'bn',
        'name': 'বাংলা',
        'english': 'Bengali',
        'sample': 'নমস্কার! স্মৃতি সেতুতে আপনাকে স্বাগতম।',
      },
      {
        'code': 'hi',
        'name': 'हिन्दी',
        'english': 'Hindi',
        'sample': 'नमस्ते! स्मृति सेतु में आपका हार्दिक स्वागत है।',
      },
      {
        'code': 'or',
        'name': 'ଓଡ଼ିଆ',
        'english': 'Odia',
        'sample': 'ନମସ୍କାର! ସ୍ମୃତି ସେତୁରେ ଆପଣଙ୍କୁ ସ୍ୱାଗତ।',
      },
      {
        'code': 'te',
        'name': 'తెలుగు',
        'english': 'Telugu',
        'sample': 'నమస్కారం! స్మృతి సేతుకి స్వాగతం.',
      },
      {
        'code': 'ta',
        'name': 'தமிழ்',
        'english': 'Tamil',
        'sample': 'வணக்கம்! ஸ்மிருதி சேதுவிற்கு நல்வரவு.',
      },
      {
        'code': 'kn',
        'name': 'ಕನ್ನಡ',
        'english': 'Kannada',
        'sample': 'ನಮಸ್ಕಾರ! ಸ್ಮೃತಿ ಸೇತುವಿಗೆ ಸುಸ್ವಾಗತ.',
      },
      {
        'code': 'ml',
        'name': 'മലയാളം',
        'english': 'Malayalam',
        'sample': 'നമസ്കാരം! സ്മൃതി സേതുവിലേക്ക് സ്വാഗതം.',
      },
      {
        'code': 'mr',
        'name': 'मराठी',
        'english': 'Marathi',
        'sample': 'नमस्कार! स्मृती सेतूमध्ये आपले स्वागत आहे.',
      },
      {
        'code': 'gu',
        'name': 'ગુજરાતી',
        'english': 'Gujarati',
        'sample': 'નમસ્તે! સ્મૃતિ સેતુમાં આપનું સ્વાગત છે.',
      },
      {
        'code': 'pa',
        'name': 'ਪੰਜਾਬੀ',
        'english': 'Punjabi',
        'sample': 'ਸਤਿ ਸ੍ਰੀ ਅਕਾਲ! ਸਮ੍ਰਿਤੀ ਸੇਤੂ ਵਿੱਚ ਜੀ ਆਇਆਂ ਨੂੰ।',
      },
      {
        'code': 'ur',
        'name': 'اردو',
        'english': 'Urdu (RTL)',
        'sample': 'سلام! اسمرتی سیتو میں خوش آمدید۔',
      },
      {
        'code': 'en',
        'name': 'English',
        'english': 'English',
        'sample': 'Namaste! Welcome to SmritiSetu.',
      },
      {
        'code': 'es',
        'name': 'Español',
        'english': 'Spanish',
        'sample': '¡Hola! Bienvenido a SmritiSetu.',
      },
      {
        'code': 'fr',
        'name': 'Français',
        'english': 'French',
        'sample': 'Bonjour ! Bienvenue sur SmritiSetu.',
      },
      {
        'code': 'de',
        'name': 'Deutsch',
        'english': 'German',
        'sample': 'Guten Tag! Willkommen bei SmritiSetu.',
      },
      {
        'code': 'ar',
        'name': 'العربية',
        'english': 'Arabic (RTL)',
        'sample': 'أهلاً وسهلاً بكم في سمريتي سيتو.',
      },
      {
        'code': 'zh',
        'name': '中文',
        'english': 'Chinese (Simplified)',
        'sample': '您好！欢迎使用 SmritiSetu。',
      },
      {
        'code': 'ja',
        'name': '日本語',
        'english': 'Japanese',
        'sample': 'こんにちは！SmritiSetuへようこそ。',
      },
      {
        'code': 'ko',
        'name': '한국어',
        'english': 'Korean',
        'sample': '안녕하세요! SmritiSetu에 오신 것을 환영합니다.',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.translate('language.title')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 30),
          onPressed: () => Navigator.pop(context),
          tooltip: context.l10n.translate('common.button.back'),
        ),
      ),
      body: SafeArea(
        child: ResponsiveContainer(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
          children: [
            SectionHeader(
              title: context.l10n.translate('language.title'),
              subtitle: context.l10n.translate('language.select_prompt'),
              audioText: context.l10n.translate('language.audio_prompt'),
            ),
            const SizedBox(height: 8),
            ...languages.map((lang) {
              final code = lang['code']!;
              final isSelected = currentCode == code;

              return AccessibleCard(
                onTap: () {
                  locCtrl.setLocale(Locale(code));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Language changed to ${lang['english']}',
                        style: const TextStyle(fontSize: 18),
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                borderColor: isSelected ? (isDark ? const Color(0xFFFACC15) : theme.colorScheme.primary) : null,
                borderWidth: isSelected ? 3.0 : 2.0,
                backgroundColor: isSelected
                    ? (isDark ? const Color(0xFF27272A) : const Color(0xFFEFF6FF))
                    : null,
                semanticLabel: '${lang['name']}, ${lang['english']}. ${isSelected ? "Currently selected" : "Tap to select"}',
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark ? const Color(0xFFFACC15) : theme.colorScheme.primary)
                            : (isDark ? const Color(0xFF3F3F46) : const Color(0xFFE2E8F0)),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: isSelected
                          ? Icon(Icons.check_rounded, color: isDark ? Colors.black : Colors.white, size: 32)
                          : Text(
                              code.toUpperCase(),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF334155),
                              ),
                            ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lang['name']!,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          LargeText(
                            lang['english']!,
                            type: LargeTextType.caption,
                          ),
                        ],
                      ),
                    ),
                    VoiceInstructionButton(
                      textToSpeak: lang['sample']!,
                      languageCode: code,
                      isCompact: true,
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 24),
          ],
        ),
      ),
    ),
  );
}
}
