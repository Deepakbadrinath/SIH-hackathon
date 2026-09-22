import 'package:flutter/material.dart';
import '../../../core/localization/app_localizations.dart';
import '../../common_widgets/disclaimer_banner.dart';
import '../../common_widgets/game_card.dart';
import '../../common_widgets/responsive_scaffold.dart';
import '../../common_widgets/section_header.dart';

class GamesScreen extends StatelessWidget {
  const GamesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.translate('games.title')),
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
              title: context.l10n.translate('games.title'),
              subtitle: context.l10n.translate('games.subtitle'),
              audioText: context.l10n.translate('games.audio_prompt'),
            ),
            const SizedBox(height: 8),
            // Game 1: Family Face Match
            GameCard(
              title: context.l10n.translate('game.face_match.title'),
              description: context.l10n.translate('game.face_match.desc'),
              domain: context.l10n.translate('games.domain.memory'),
              difficultyLevel: 1,
              icon: Icons.family_restroom_rounded,
              cardColor: const Color(0xFF0F3D78),
              audioText: context.l10n.translate('game.face_match.instruction'),
              onPlay: () {
                Navigator.pushNamed(
                  context,
                  '/game_instructions',
                  arguments: {
                    'gameId': 'face_match',
                    'title': context.l10n.translate('game.face_match.title'),
                    'instruction': context.l10n.translate('game.face_match.instruction'),
                    'icon': Icons.family_restroom_rounded,
                  },
                );
              },
            ),
            // Game 2: Pattern Completion
            GameCard(
              title: context.l10n.translate('game.pattern.title'),
              description: context.l10n.translate('game.pattern.desc'),
              domain: context.l10n.translate('games.domain.executive'),
              difficultyLevel: 2,
              icon: Icons.auto_awesome_mosaic_rounded,
              cardColor: const Color(0xFFB45309),
              audioText: context.l10n.translate('game.pattern.instruction'),
              onPlay: () {
                Navigator.pushNamed(
                  context,
                  '/game_instructions',
                  arguments: {
                    'gameId': 'pattern',
                    'title': context.l10n.translate('game.pattern.title'),
                    'instruction': context.l10n.translate('game.pattern.instruction'),
                    'icon': Icons.auto_awesome_mosaic_rounded,
                  },
                );
              },
            ),
            // Game 3: Daily Activity Sequence
            GameCard(
              title: context.l10n.translate('game.sequence.title'),
              description: context.l10n.translate('game.sequence.desc'),
              domain: context.l10n.translate('games.domain.executive'),
              difficultyLevel: 1,
              icon: Icons.format_list_numbered_rounded,
              cardColor: const Color(0xFF166534),
              audioText: context.l10n.translate('game.sequence.instruction'),
              onPlay: () {
                Navigator.pushNamed(
                  context,
                  '/game_instructions',
                  arguments: {
                    'gameId': 'sequence',
                    'title': context.l10n.translate('game.sequence.title'),
                    'instruction': context.l10n.translate('game.sequence.instruction'),
                    'icon': Icons.format_list_numbered_rounded,
                  },
                );
              },
            ),
            // Game 4: Object Sorting
            GameCard(
              title: context.l10n.translate('game.sorting.title'),
              description: context.l10n.translate('game.sorting.desc'),
              domain: context.l10n.translate('games.domain.attention'),
              difficultyLevel: 2,
              icon: Icons.category_rounded,
              cardColor: const Color(0xFF7E22CE),
              audioText: context.l10n.translate('game.sorting.instruction'),
              onPlay: () {
                Navigator.pushNamed(
                  context,
                  '/game_instructions',
                  arguments: {
                    'gameId': 'sorting',
                    'title': context.l10n.translate('game.sorting.title'),
                    'instruction': context.l10n.translate('game.sorting.instruction'),
                    'icon': Icons.category_rounded,
                  },
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    ),
  );
}
}
