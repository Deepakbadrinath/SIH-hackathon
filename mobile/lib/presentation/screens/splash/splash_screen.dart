import 'package:flutter/material.dart';
import '../../../core/localization/app_localizations.dart';
import '../../common_widgets/primary_button.dart';
import '../../common_widgets/secondary_button.dart';
import '../../common_widgets/disclaimer_banner.dart';

class SplashScreen extends StatelessWidget {
  final Function(Locale) onLanguageChanged;
  final VoidCallback onToggleTheme;
  final bool isHighContrast;

  const SplashScreen({
    super.key,
    required this.onLanguageChanged,
    required this.onToggleTheme,
    required this.isHighContrast,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const DisclaimerBanner(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  // High-Contrast Toggle Button
                  Semantics(
                    button: true,
                    label: context.l10n.translate('accessibility.high_contrast'),
                    child: ActionChip(
                      avatar: Icon(
                        isHighContrast ? Icons.contrast : Icons.wb_sunny_outlined,
                        size: 24,
                      ),
                      label: Text(
                        context.l10n.translate('accessibility.high_contrast'),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      onPressed: onToggleTheme,
                    ),
                  ),

                  // Language Switcher Dropdown with 14 languages
                  DropdownButton<String>(
                    value: Localizations.localeOf(context).languageCode,
                    icon: const Icon(Icons.language, size: 28),
                    underline: Container(height: 2, color: theme.primaryColor),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                    onChanged: (String? newLang) {
                      if (newLang != null) {
                        onLanguageChanged(Locale(newLang));
                      }
                    },
                    items: const [
                      DropdownMenuItem(value: 'as', child: Text('অসমীয়া (Assamese)')),
                      DropdownMenuItem(value: 'mni', child: Text('মৈতৈলোন্ (Manipuri)')),
                      DropdownMenuItem(value: 'bn', child: Text('বাংলা (Bengali)')),
                      DropdownMenuItem(value: 'hi', child: Text('हिन्दी (Hindi)')),
                      DropdownMenuItem(value: 'en', child: Text('English')),
                      DropdownMenuItem(value: 'or', child: Text('ଓଡ଼ିଆ (Odia)')),
                      DropdownMenuItem(value: 'te', child: Text('తెలుగు (Telugu)')),
                      DropdownMenuItem(value: 'ta', child: Text('தமிழ் (Tamil)')),
                      DropdownMenuItem(value: 'kn', child: Text('ಕನ್ನಡ (Kannada)')),
                      DropdownMenuItem(value: 'ml', child: Text('മലയാളം (Malayalam)')),
                      DropdownMenuItem(value: 'mr', child: Text('मराठी (Marathi)')),
                      DropdownMenuItem(value: 'gu', child: Text('ગુજરાતી (Gujarati)')),
                      DropdownMenuItem(value: 'pa', child: Text('ਪੰਜਾਬੀ (Punjabi)')),
                      DropdownMenuItem(value: 'ur', child: Text('اردو (Urdu - RTL)')),
                      DropdownMenuItem(value: 'es', child: Text('Español (Spanish)')),
                      DropdownMenuItem(value: 'fr', child: Text('Français (French)')),
                      DropdownMenuItem(value: 'de', child: Text('Deutsch (German)')),
                      DropdownMenuItem(value: 'ar', child: Text('العربية (Arabic - RTL)')),
                      DropdownMenuItem(value: 'zh', child: Text('中文 (Chinese)')),
                      DropdownMenuItem(value: 'ja', child: Text('日本語 (Japanese)')),
                      DropdownMenuItem(value: 'ko', child: Text('한국어 (Korean)')),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // App Logo / Symbol
                    Center(
                      child: Container(
                        height: 120,
                        width: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.primaryColor.withValues(alpha: 0.12),
                          border: Border.all(color: theme.primaryColor, width: 3),
                        ),
                        child: Icon(
                          Icons.psychology_outlined,
                          size: 70,
                          color: theme.primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // App Title & Tagline
                    Text(
                      context.l10n.translate('app.name'),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.displayLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.l10n.translate('app.tagline'),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 48),

                    // Primary Action 1: Elderly User Mode
                    PrimaryButton(
                      label: context.l10n.translate('auth.role.patient'),
                      icon: Icons.face_retouching_natural,
                      onPressed: () {
                        Navigator.pushNamed(context, '/patient');
                      },
                    ),
                    const SizedBox(height: 18),

                    // Primary Action 2: Caregiver Dashboard Mode
                    SecondaryButton(
                      label: context.l10n.translate('auth.role.caregiver'),
                      icon: Icons.shield_outlined,
                      onPressed: () {
                        Navigator.pushNamed(context, '/caregiver');
                      },
                    ),
                    const SizedBox(height: 18),

                    // Primary Action 3: SIH Grand Finale Interactive Demo Hub
                    OutlinedButton.icon(
                      style: ButtonStyle(
                        padding: WidgetStateProperty.all(const EdgeInsets.symmetric(vertical: 16, horizontal: 20)),
                        side: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.hovered) || states.contains(WidgetState.focused)) {
                            return const BorderSide(color: Color(0xFFB45309), width: 2.5);
                          }
                          return const BorderSide(color: Color(0xFFD97706), width: 2);
                        }),
                        shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                        backgroundColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.pressed)) {
                            return const Color(0xFFFDE68A);
                          }
                          if (states.contains(WidgetState.hovered) || states.contains(WidgetState.focused)) {
                            return const Color(0xFFFEF3C7);
                          }
                          return const Color(0xFFFEF3C7).withValues(alpha: 0.5);
                        }),
                        elevation: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.hovered) || states.contains(WidgetState.focused)) return 3.0;
                          if (states.contains(WidgetState.pressed)) return 1.0;
                          return 0.0;
                        }),
                        shadowColor: WidgetStateProperty.all(const Color(0x33D97706)),
                        mouseCursor: WidgetStateProperty.all(SystemMouseCursors.click),
                        animationDuration: const Duration(milliseconds: 180),
                      ),
                      icon: const Icon(Icons.stars_rounded, color: Color(0xFFD97706), size: 26),
                      label: const Text(
                        'SIH Demo Hub & Jury Walkthrough',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF92400E),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pushNamed(context, '/demo');
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
