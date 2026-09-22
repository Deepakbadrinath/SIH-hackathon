import 'package:flutter/material.dart';
import '../../../core/localization/app_localizations.dart';
import '../../common_widgets/accessible_card.dart';
import '../../common_widgets/disclaimer_banner.dart';
import '../../common_widgets/large_text.dart';
import '../../common_widgets/progress_card.dart';
import '../../common_widgets/responsive_scaffold.dart';
import '../../common_widgets/section_header.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.translate('history.title')),
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
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: DisclaimerBanner(),
            ),
            const SizedBox(height: 12),
            SectionHeader(
              title: context.l10n.translate('history.title'),
              subtitle: context.l10n.translate('history.subtitle'),
              audioText: context.l10n.translate('history.audio_prompt'),
            ),
            const SizedBox(height: 8),
            // Progress Card 1: Streak
            ProgressCard(
              title: context.l10n.translate('history.streak_label'),
              value: context.l10n.translate('history.days_streak'),
              subtitle: context.l10n.translate('history.streak_sub'),
              icon: Icons.local_fire_department_rounded,
              accentColor: const Color(0xFFB45309),
            ),
            // Progress Card 2: Games Completed
            ProgressCard(
              title: context.l10n.translate('history.games_played_label'),
              value: context.l10n.translate('history.games_count_value'),
              subtitle: context.l10n.translate('history.games_sub'),
              icon: Icons.psychology_rounded,
              accentColor: const Color(0xFF0F3D78),
            ),
            // Progress Card 3: Medicines
            ProgressCard(
              title: context.l10n.translate('history.meds_taken_label'),
              value: '95%',
              subtitle: context.l10n.translate('history.meds_sub'),
              icon: Icons.verified_rounded,
              accentColor: const Color(0xFF166534),
            ),
            const SizedBox(height: 12),
            // Encouragement Card
            AccessibleCard(
              backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
              borderColor: isDark ? const Color(0xFFFACC15) : const Color(0xFF93C5FD),
              child: Row(
                children: [
                  const Icon(Icons.thumb_up_alt_rounded, size: 40, color: Color(0xFF0F3D78)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: LargeText(
                      context.l10n.translate('history.encouragement'),
                      type: LargeTextType.body,
                    ),
                  ),
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
}
