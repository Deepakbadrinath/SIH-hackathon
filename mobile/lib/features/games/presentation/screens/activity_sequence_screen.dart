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
import '../controllers/activity_sequence_controller.dart';

class ActivitySequenceScreen extends StatefulWidget {
  const ActivitySequenceScreen({super.key});

  @override
  State<ActivitySequenceScreen> createState() => _ActivitySequenceScreenState();
}

class _ActivitySequenceScreenState extends State<ActivitySequenceScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctrl = context.read<ActivitySequenceController>();
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
    final ctrl = context.watch<ActivitySequenceController>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.translate('game.sequence.title')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 30),
          onPressed: () => _safeExit(context),
          tooltip: context.l10n.translate('common.button.back'),
        ),
      ),
      body: SafeArea(
        child: switch (ctrl.currentStep) {
          ActivitySequenceStep.instructions =>
            _buildInstructionsView(context, ctrl, isDark, theme),
          ActivitySequenceStep.playing || ActivitySequenceStep.trialFeedback =>
            _buildGameplayView(context, ctrl, isDark, theme),
          ActivitySequenceStep.completed =>
            _buildCompletedView(context, ctrl, isDark, theme),
        },
      ),
    );
  }

  Widget _buildInstructionsView(
    BuildContext context,
    ActivitySequenceController ctrl,
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
                Icons.format_list_numbered_rounded,
                size: 54,
                color: isDark ? const Color(0xFFFACC15) : theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 18),
          LargeText(
            context.l10n.translate('game.sequence.title'),
            type: LargeTextType.heading,
            textAlign: TextAlign.center,
            isHeader: true,
          ),
          const SizedBox(height: 10),
          LargeText(
            context.l10n.translate('game.sequence.instruction'),
            type: LargeTextType.body,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Center(
            child: VoiceInstructionButton(
              textToSpeak: '${context.l10n.translate('game.sequence.title')}. ${context.l10n.translate('game.sequence.instruction')}',
            ),
          ),
          const SizedBox(height: 24),
          AccessibleCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const LargeText(
                  'Example Routine:',
                  type: LargeTextType.title,
                ),
                const SizedBox(height: 12),
                _buildExampleStep('1', 'Wake Up in the Morning', Icons.wb_sunny_rounded, const Color(0xFFEA580C), isDark),
                const SizedBox(height: 8),
                _buildExampleStep('2', 'Brush Teeth & Wash Face', Icons.cleaning_services_rounded, const Color(0xFF0F3D78), isDark),
                const SizedBox(height: 8),
                _buildExampleStep('3', 'Drink Warm Tea & Breakfast', Icons.restaurant_rounded, const Color(0xFF166534), isDark),
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

  Widget _buildExampleStep(String num, String label, IconData icon, Color color, bool isDark) {
    return Row(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: color,
          child: Text(num, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        ),
        const SizedBox(width: 12),
        Icon(icon, size: 22, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGameplayView(
    BuildContext context,
    ActivitySequenceController ctrl,
    bool isDark,
    ThemeData theme,
  ) {
    final trial = ctrl.currentTrial;
    if (trial == null) return const SizedBox.shrink();

    final isFeedback = ctrl.currentStep == ActivitySequenceStep.trialFeedback;

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
                  'Routine ${ctrl.currentTrialIndex + 1} of ${ctrl.trials.length}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFFFACC15) : const Color(0xFF0F172A),
                  ),
                ),
              ),
              VoiceInstructionButton(
                textToSpeak: trial.routineTheme.voicePrompt,
                isCompact: true,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Theme title banner
          AccessibleCard(
            backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
            borderColor: isDark ? const Color(0xFFFACC15) : theme.colorScheme.primary,
            borderWidth: 2.0,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LargeText(
                  trial.routineTheme.title,
                  type: LargeTextType.heading,
                ),
                const SizedBox(height: 4),
                Text(
                  trial.routineTheme.description,
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

          // Numbered target slots
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.0),
            child: LargeText(
              'Numbered Steps (Tap placed card to remove):',
              type: LargeTextType.body,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          ...List.generate(trial.targetSteps.length, (slotIndex) {
            final placed = ctrl.placedSteps[slotIndex];
            final stepNum = '${slotIndex + 1}';

            Color? slotBorder;
            Color? slotBg;
            IconData? feedbackIcon;
            Color? feedbackColor;

            if (isFeedback && placed != null) {
              final isCorrect = placed.id == trial.targetSteps[slotIndex].id;
              if (isCorrect) {
                slotBorder = const Color(0xFF166534);
                slotBg = isDark ? const Color(0xFF14532D) : const Color(0xFFDCFCE7);
                feedbackIcon = Icons.check_circle_rounded;
                feedbackColor = const Color(0xFF166534);
              } else {
                slotBorder = const Color(0xFFB45309);
                slotBg = isDark ? const Color(0xFF78350F) : const Color(0xFFFFEDD5);
                feedbackIcon = Icons.info_rounded;
                feedbackColor = const Color(0xFFB45309);
              }
            }

            if (placed != null) {
              return AccessibleCard(
                onTap: isFeedback ? null : () => ctrl.removeStepFromSlot(slotIndex),
                borderColor: slotBorder,
                backgroundColor: slotBg,
                borderWidth: 2.5,
                margin: const EdgeInsets.symmetric(vertical: 5.0),
                semanticLabel: 'Step $stepNum: ${placed.label}. Tap to remove.',
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: placed.color,
                      child: Text(
                        stepNum,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: placed.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(placed.icon, size: 28, color: placed.color),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LargeText(placed.label, type: LargeTextType.title),
                          Text(
                            placed.description,
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
                    if (isFeedback && feedbackIcon != null)
                      Icon(feedbackIcon, size: 30, color: feedbackColor)
                    else
                      const Icon(Icons.remove_circle_outline_rounded, size: 26, color: Color(0xFF94A3B8)),
                  ],
                ),
              );
            } else {
              // Empty slot placeholder
              return AccessibleCard(
                margin: const EdgeInsets.symmetric(vertical: 5.0),
                borderWidth: 1.5,
                backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                semanticLabel: 'Step $stepNum is empty.',
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                      child: Text(
                        stepNum,
                        style: TextStyle(
                          color: isDark ? Colors.white : const Color(0xFF334155),
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Empty Step $stepNum — Tap an activity below to place here',
                        style: TextStyle(
                          fontSize: 15,
                          fontStyle: FontStyle.italic,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
          }),
          const SizedBox(height: 16),

          // Available unplaced choices pool
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.0),
            child: LargeText(
              'Available Activities (Tap to place):',
              type: LargeTextType.body,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          if (ctrl.unplacedChoices.isEmpty)
            AccessibleCard(
              backgroundColor: isDark ? const Color(0xFF14532D) : const Color(0xFFDCFCE7),
              borderColor: const Color(0xFF166534),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_outline_rounded, color: Color(0xFF166534), size: 30),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'All steps placed! Review above and tap Confirm Order.',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF166534),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            ...ctrl.unplacedChoices.map((choice) {
              return AccessibleCard(
                onTap: isFeedback ? null : () => ctrl.placeStep(choice),
                margin: const EdgeInsets.symmetric(vertical: 5.0),
                semanticLabel: '${choice.label}. Tap to place into next empty step.',
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: choice.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: choice.color, width: 2.0),
                      ),
                      child: Icon(choice.icon, size: 28, color: choice.color),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LargeText(choice.label, type: LargeTextType.title),
                          Text(
                            choice.description,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.add_circle_outline_rounded, size: 28, color: Color(0xFF0F3D78)),
                  ],
                ),
              );
            }),

          const SizedBox(height: 24),

          // Action buttons
          Row(
            children: [
              Expanded(
                flex: 1,
                child: SecondaryButton(
                  label: context.l10n.translate('game.sequence.reset_button'),
                  icon: Icons.refresh_rounded,
                  height: 60.0,
                  onPressed: isFeedback || !ctrl.placedSteps.any((s) => s != null)
                      ? null
                      : () => ctrl.resetPlacedSteps(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: PrimaryButton(
                  label: context.l10n.translate('game.sequence.confirm_button'),
                  icon: Icons.check_circle_rounded,
                  height: 60.0,
                  onPressed: isFeedback || !ctrl.isAllSlotsFilled
                      ? null
                      : () => ctrl.confirmSequence(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildCompletedView(
    BuildContext context,
    ActivitySequenceController ctrl,
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
            score?.encouragementMessage ?? 'Thank you for ordering everyday routines!',
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
                  'Steps Ordered Correctly',
                  '${score?.correctlyPlacedSteps ?? 0} of ${score?.totalSlotsEvaluated ?? 0}',
                  Icons.format_list_numbered_rounded,
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
