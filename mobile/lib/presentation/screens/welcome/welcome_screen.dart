import 'package:flutter/material.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/design_tokens.dart';
import '../../common_widgets/disclaimer_banner.dart';
import '../../common_widgets/large_text.dart';
import '../../common_widgets/primary_button.dart';
import '../../common_widgets/responsive_scaffold.dart';
import '../../common_widgets/secondary_button.dart';
import '../../common_widgets/voice_instruction_button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.translate('app.name')),
        actions: [
          IconButton(
            tooltip: context.l10n.translate('welcome.choose_language'),
            icon: const Icon(Icons.language_rounded, size: 28),
            onPressed: () => Navigator.pushNamed(context, '/language'),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: SafeArea(
        child: ResponsiveContainer(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const DisclaimerBanner(),
              const SizedBox(height: 24),
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF27272A) : const Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? const Color(0xFFFACC15) : theme.colorScheme.primary,
                    width: 3.0,
                  ),
                ),
                child: Icon(
                  Icons.favorite_rounded,
                  size: 60,
                  color: isDark ? const Color(0xFFFACC15) : theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              LargeText(
                context.l10n.translate('welcome.greeting'),
                type: LargeTextType.display,
                textAlign: TextAlign.center,
                isHeader: true,
              ),
              const SizedBox(height: 12),
              LargeText(
                context.l10n.translate('welcome.subtitle'),
                type: LargeTextType.body,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              VoiceInstructionButton(
                textToSpeak: context.l10n.translate('welcome.audio_prompt'),
              ),
              const SizedBox(height: 36),
              PrimaryButton(
                label: context.l10n.translate('welcome.elder_button'),
                icon: Icons.person_rounded,
                height: 68.0,
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/elderly_home');
                },
              ),
              const SizedBox(height: 16),
              SecondaryButton(
                label: context.l10n.translate('welcome.caregiver_button'),
                icon: Icons.shield_rounded,
                height: 60.0,
                onPressed: () {
                  Navigator.pushNamed(context, '/caregiver');
                },
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/login'),
                icon: const Icon(Icons.login_rounded, size: 24),
                label: Text(
                  context.l10n.translate('auth.login'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFFFACC15) : theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
}
