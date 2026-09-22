import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../presentation/common_widgets/accessible_card.dart';
import '../../../../presentation/common_widgets/disclaimer_banner.dart';
import '../../../../presentation/common_widgets/large_text.dart';
import '../../../../presentation/common_widgets/primary_button.dart';
import '../../../../presentation/common_widgets/secondary_button.dart';
import '../../../../presentation/common_widgets/voice_instruction_button.dart';
import '../../domain/models/pattern_completion_models.dart';
import '../controllers/pattern_completion_controller.dart';

class PatternCompletionScreen extends StatefulWidget {
  const PatternCompletionScreen({super.key});

  @override
  State<PatternCompletionScreen> createState() => _PatternCompletionScreenState();
}

class _PatternCompletionScreenState extends State<PatternCompletionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctrl = context.read<PatternCompletionController>();
      if (ctrl.trials.isEmpty) {
        ctrl.initializeGame();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<PatternCompletionController>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.translate('game.pattern.title')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 30),
          onPressed: () => Navigator.pop(context),
          tooltip: context.l10n.translate('common.button.back'),
        ),
      ),
      body: SafeArea(
        child: switch (ctrl.currentStep) {
          PatternCompletionStep.instructions =>
            _buildInstructionsView(context, ctrl, isDark, theme),
          PatternCompletionStep.playing || PatternCompletionStep.trialFeedback =>
            _buildGameplayView(context, ctrl, isDark, theme),
          PatternCompletionStep.completed =>
            _buildCompletedView(context, ctrl, isDark, theme),
        },
      ),
    );
  }

  Widget _buildInstructionsView(
    BuildContext context,
    PatternCompletionController ctrl,
    bool isDark,
    ThemeData theme,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const DisclaimerBanner(),
          const SizedBox(height: 20),
          Center(
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF27272A) : const Color(0xFFEFF6FF),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? const Color(0xFFFACC15) : theme.colorScheme.primary,
                  width: 3.0,
                ),
              ),
              child: Icon(
                Icons.auto_awesome_mosaic_rounded,
                size: 54,
                color: isDark ? const Color(0xFFFACC15) : theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 18),
          LargeText(
            context.l10n.translate('game.pattern.title'),
            type: LargeTextType.heading,
            textAlign: TextAlign.center,
            isHeader: true,
          ),
          const SizedBox(height: 10),
          LargeText(
            context.l10n.translate('game.pattern.instruction'),
            type: LargeTextType.body,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Center(
            child: VoiceInstructionButton(
              textToSpeak: '${context.l10n.translate('game.pattern.title')}. ${context.l10n.translate('game.pattern.instruction')}',
            ),
          ),
          const SizedBox(height: 24),
          AccessibleCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const LargeText(
                  'Example Sequence:',
                  type: LargeTextType.title,
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildSymbolTile(DefaultPatternSymbols.lotus, isDark: isDark),
                      const SizedBox(width: 8),
                      _buildSymbolTile(DefaultPatternSymbols.teaLeaf, isDark: isDark),
                      const SizedBox(width: 8),
                      _buildSymbolTile(DefaultPatternSymbols.lotus, isDark: isDark),
                      const SizedBox(width: 8),
                      _buildSymbolTile(DefaultPatternSymbols.teaLeaf, isDark: isDark),
                      const SizedBox(width: 8),
                      _buildMysteryTile(isDark: isDark, theme: theme),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'What comes next? The Lotus completes the pattern!',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          PrimaryButton(
            label: context.l10n.translate('game.common.start'),
            icon: Icons.play_arrow_rounded,
            height: 68.0,
            onPressed: () => ctrl.startGame(),
          ),
        ],
      ),
    );
  }

  Widget _buildGameplayView(
    BuildContext context,
    PatternCompletionController ctrl,
    bool isDark,
    ThemeData theme,
  ) {
    final trial = ctrl.currentTrial;
    if (trial == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Step progress indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  context.l10n.translate('game.pattern.step_progress', args: {
                    'current': context.l10n.formatNumber(ctrl.currentTrialIndex + 1),
                    'total': context.l10n.formatNumber(ctrl.trials.length),
                  }),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFFFACC15) : const Color(0xFF0F172A),
                  ),
                ),
              ),
              const VoiceInstructionButton(
                textToSpeak:
                    'Observe the symbols in row. Look at the question mark, then tap the symbol that completes the pattern.',
                isCompact: true,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Pattern sequence card
          AccessibleCard(
            backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
            borderColor: isDark ? const Color(0xFFFACC15) : theme.colorScheme.primary,
            borderWidth: 2.5,
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LargeText(
                  context.l10n.translate('game.pattern.observe_label'),
                  type: LargeTextType.title,
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ...trial.visibleSequence.map((sym) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: _buildSymbolTile(sym, isDark: isDark),
                        );
                      }),
                      _buildMysteryTile(
                        isDark: isDark,
                        theme: theme,
                        revealedSymbol: (ctrl.currentStep == PatternCompletionStep.trialFeedback &&
                                ctrl.selectedOptionIndex != null)
                            ? trial.choices[ctrl.selectedOptionIndex!]
                            : null,
                        isCorrect: ctrl.isCorrectFeedback,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: LargeText(
              context.l10n.translate('game.pattern.which_completes'),
              type: LargeTextType.body,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),

          // Candidate choice options
          ...List.generate(trial.choices.length, (index) {
            final choice = trial.choices[index];
            final isSelected = ctrl.selectedOptionIndex == index;
            final isFeedback = ctrl.currentStep == PatternCompletionStep.trialFeedback;

            Color? cardBorder;
            Color? cardBg;
            if (isFeedback && isSelected) {
              if (ctrl.isCorrectFeedback) {
                cardBorder = const Color(0xFF166534);
                cardBg = isDark ? const Color(0xFF14532D) : const Color(0xFFDCFCE7);
              } else {
                cardBorder = const Color(0xFFB45309);
                cardBg = isDark ? const Color(0xFF78350F) : const Color(0xFFFFEDD5);
              }
            }

            return AccessibleCard(
              onTap: isFeedback ? null : () => ctrl.selectAnswer(index),
              borderColor: cardBorder,
              borderWidth: isSelected ? 3.0 : 2.0,
              backgroundColor: cardBg,
              margin: const EdgeInsets.symmetric(vertical: 6.0),
              semanticLabel: '${choice.name}. Tap to choose.',
              child: Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: choice.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: choice.color, width: 2.0),
                    ),
                    child: Icon(choice.icon, size: 36, color: choice.color),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: LargeText(
                      choice.name,
                      type: LargeTextType.title,
                    ),
                  ),
                  if (isFeedback && isSelected)
                    Icon(
                      ctrl.isCorrectFeedback
                          ? Icons.check_circle_rounded
                          : Icons.info_rounded,
                      size: 32,
                      color: ctrl.isCorrectFeedback
                          ? const Color(0xFF166534)
                          : const Color(0xFFB45309),
                    )
                  else
                    const Icon(Icons.touch_app_rounded, size: 28, color: Color(0xFF94A3B8)),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildCompletedView(
    BuildContext context,
    PatternCompletionController ctrl,
    bool isDark,
    ThemeData theme,
  ) {
    final score = ctrl.sessionScore;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const DisclaimerBanner(),
          const SizedBox(height: 16),
          Center(
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF27272A) : const Color(0xFFDCFCE7),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF166534),
                  width: 3.0,
                ),
              ),
              child: const Icon(
                Icons.celebration_rounded,
                size: 52,
                color: Color(0xFF166534),
              ),
            ),
          ),
          const SizedBox(height: 16),
          LargeText(
            context.l10n.translate('game.common.great_job'),
            type: LargeTextType.heading,
            textAlign: TextAlign.center,
            isHeader: true,
          ),
          const SizedBox(height: 8),
          LargeText(
            score?.encouragementMessage ?? 'Thank you for exercising your pattern reasoning!',
            type: LargeTextType.body,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),

          // Star rating
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              final isEarned = score != null && index < score.stars;
              return Icon(
                isEarned ? Icons.star_rounded : Icons.star_border_rounded,
                size: 40,
                color: const Color(0xFFB45309),
              );
            }),
          ),
          const SizedBox(height: 18),

          // Score details card
          AccessibleCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildStatRow(
                  'Accuracy',
                  '${score?.accuracyPercentage.toStringAsFixed(0) ?? "0"}%',
                  Icons.check_circle_outline_rounded,
                  const Color(0xFF166534),
                  isDark,
                ),
                const Divider(height: 20, thickness: 1.5),
                _buildStatRow(
                  'Patterns Solved',
                  '${score?.correctTrials ?? 0} of ${score?.totalTrials ?? 0}',
                  Icons.auto_awesome_mosaic_rounded,
                  const Color(0xFF0F3D78),
                  isDark,
                ),
                const Divider(height: 20, thickness: 1.5),
                _buildStatRow(
                  'Average Speed',
                  '${((score?.avgResponseTimeMs ?? 0) / 1000).toStringAsFixed(1)} sec',
                  Icons.speed_rounded,
                  const Color(0xFFB45309),
                  isDark,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          PrimaryButton(
            label: context.l10n.translate('results.play_again'),
            icon: Icons.replay_rounded,
            height: 64.0,
            onPressed: () => ctrl.initializeGame(),
          ),
          const SizedBox(height: 12),
          SecondaryButton(
            label: context.l10n.translate('results.home_button'),
            icon: Icons.home_rounded,
            height: 56.0,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSymbolTile(PatternSymbol symbol, {required bool isDark}) {
    return Container(
      width: 64,
      height: 76,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF27272A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: symbol.color,
          width: 2.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(symbol.icon, size: 32, color: symbol.color),
          const SizedBox(height: 4),
          Text(
            symbol.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMysteryTile({
    required bool isDark,
    required ThemeData theme,
    PatternSymbol? revealedSymbol,
    bool isCorrect = false,
  }) {
    if (revealedSymbol != null) {
      return Container(
        width: 64,
        height: 76,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: isCorrect
              ? (isDark ? const Color(0xFF14532D) : const Color(0xFFDCFCE7))
              : (isDark ? const Color(0xFF78350F) : const Color(0xFFFFEDD5)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCorrect ? const Color(0xFF166534) : const Color(0xFFB45309),
            width: 3.0,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              revealedSymbol.icon,
              size: 32,
              color: isCorrect ? const Color(0xFF166534) : const Color(0xFFB45309),
            ),
            const SizedBox(height: 4),
            Text(
              revealedSymbol.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: 64,
      height: 76,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFFFACC15) : theme.colorScheme.primary,
          width: 2.5,
        ),
      ),
      child: Center(
        child: Text(
          '?',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: isDark ? const Color(0xFFFACC15) : theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(
    String label,
    String value,
    IconData icon,
    Color iconColor,
    bool isDark,
  ) {
    return Row(
      children: [
        Icon(icon, size: 28, color: iconColor),
        const SizedBox(width: 12),
        Expanded(
          child: LargeText(
            label,
            type: LargeTextType.body,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}
