import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../presentation/common_widgets/accessible_card.dart';
import '../../../../presentation/common_widgets/disclaimer_banner.dart';
import '../../../../presentation/common_widgets/large_text.dart';
import '../../../../presentation/common_widgets/primary_button.dart';
import '../../../../presentation/common_widgets/secondary_button.dart';
import '../../../../presentation/common_widgets/voice_instruction_button.dart';
import '../../../voice/presentation/controllers/voice_controller.dart';
import '../../domain/models/object_sorting_models.dart';
import '../controllers/object_sorting_controller.dart';

class ObjectSortingScreen extends StatefulWidget {
  const ObjectSortingScreen({super.key});

  @override
  State<ObjectSortingScreen> createState() => _ObjectSortingScreenState();
}

class _ObjectSortingScreenState extends State<ObjectSortingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctrl = context.read<ObjectSortingController>();
      if (ctrl.trials.isEmpty) {
        ctrl.initializeGame();
      }
    });
  }

  void _safeExit(BuildContext context) {
    try {
      context.read<VoiceController?>()?.stopAll();
    } catch (_) {}
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<ObjectSortingController>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.translate('game.sorting.title')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 30),
          onPressed: () => _safeExit(context),
          tooltip: context.l10n.translate('common.button.back'),
        ),
      ),
      body: SafeArea(
        child: switch (ctrl.currentStep) {
          ObjectSortingStep.instructions =>
            _buildInstructionsView(context, ctrl, isDark, theme),
          ObjectSortingStep.playing || ObjectSortingStep.trialFeedback =>
            _buildGameplayView(context, ctrl, isDark, theme),
          ObjectSortingStep.completed =>
            _buildCompletedView(context, ctrl, isDark, theme),
        },
      ),
    );
  }

  Widget _buildInstructionsView(
    BuildContext context,
    ObjectSortingController ctrl,
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
                Icons.category_rounded,
                size: 54,
                color: isDark ? const Color(0xFFFACC15) : theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 18),
          LargeText(
            context.l10n.translate('game.sorting.title'),
            type: LargeTextType.heading,
            textAlign: TextAlign.center,
            isHeader: true,
          ),
          const SizedBox(height: 10),
          LargeText(
            context.l10n.translate('game.sorting.instruction'),
            type: LargeTextType.body,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Center(
            child: VoiceInstructionButton(
              textToSpeak: '${context.l10n.translate('game.sorting.title')}. ${context.l10n.translate('game.sorting.instruction')}',
            ),
          ),
          const SizedBox(height: 24),
          AccessibleCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const LargeText(
                  'Categories in this activity:',
                  type: LargeTextType.title,
                ),
                const SizedBox(height: 12),
                _buildCategoryExample(DefaultSortCategories.food, 'e.g. Fresh Apples, Assam Tea', isDark),
                const SizedBox(height: 8),
                _buildCategoryExample(DefaultSortCategories.clothing, 'e.g. Gamosa, Woolen Shawl', isDark),
                const SizedBox(height: 8),
                _buildCategoryExample(DefaultSortCategories.household, 'e.g. Clay Pitcher, Brass Bell', isDark),
                const SizedBox(height: 8),
                _buildCategoryExample(DefaultSortCategories.animals, 'e.g. Courtyard Cow, Singing Bird', isDark),
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

  Widget _buildCategoryExample(SortCategory cat, String example, bool isDark) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: cat.color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(color: cat.color, width: 1.5),
          ),
          child: Icon(cat.icon, size: 20, color: cat.color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                cat.name,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              Text(
                example,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGameplayView(
    BuildContext context,
    ObjectSortingController ctrl,
    bool isDark,
    ThemeData theme,
  ) {
    final trial = ctrl.currentTrial;
    if (trial == null) return const SizedBox.shrink();

    final isFeedback = ctrl.currentStep == ObjectSortingStep.trialFeedback;

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
                  'Item ${ctrl.currentTrialIndex + 1} of ${ctrl.trials.length}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFFFACC15) : const Color(0xFF0F172A),
                  ),
                ),
              ),
              VoiceInstructionButton(
                textToSpeak:
                    'What group does ${trial.targetObject.name} belong to? Tap one of the categories below.',
                isCompact: true,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Central Object Card to be categorized
          AccessibleCard(
            backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
            borderColor: isDark ? const Color(0xFFFACC15) : theme.colorScheme.primary,
            borderWidth: 2.5,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: trial.targetObject.color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: trial.targetObject.color, width: 3.0),
                  ),
                  child: Icon(
                    trial.targetObject.icon,
                    size: 46,
                    color: trial.targetObject.color,
                  ),
                ),
                const SizedBox(height: 12),
                LargeText(
                  trial.targetObject.name,
                  type: LargeTextType.heading,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  trial.targetObject.description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: LargeText(
              context.l10n.translate('game.sorting.drag_or_tap'),
              type: LargeTextType.body,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),

          // Category choice destination cards
          ...List.generate(trial.activeCategories.length, (index) {
            final cat = trial.activeCategories[index];
            final isSelected = ctrl.selectedCategoryIndex == index;

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
              onTap: isFeedback ? null : () => ctrl.selectCategory(index),
              borderColor: cardBorder,
              borderWidth: isSelected ? 3.0 : 2.0,
              backgroundColor: cardBg,
              margin: const EdgeInsets.symmetric(vertical: 6.0),
              semanticLabel: '${cat.name}. ${cat.description}. Tap to choose.',
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: cat.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cat.color, width: 2.0),
                    ),
                    child: Icon(cat.icon, size: 32, color: cat.color),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LargeText(cat.name, type: LargeTextType.title),
                        Text(
                          cat.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
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
    ObjectSortingController ctrl,
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
            score?.encouragementMessage ?? 'Thank you for categorizing objects today!',
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
                  'Sorted Correctly',
                  '${score?.correctCount ?? 0} of ${score?.totalTrials ?? 0}',
                  Icons.category_rounded,
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
            onPressed: () => _safeExit(context),
          ),
        ],
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
