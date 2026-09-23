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
import '../../../adaptive_difficulty/presentation/controllers/adaptive_difficulty_controller.dart';
import '../../domain/models/face_match_models.dart';
import '../controllers/face_match_controller.dart';

class FaceMatchScreen extends StatefulWidget {
  const FaceMatchScreen({super.key});

  @override
  State<FaceMatchScreen> createState() => _FaceMatchScreenState();
}

class _FaceMatchScreenState extends State<FaceMatchScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctrl = context.read<FaceMatchController>();
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
    final ctrl = context.watch<FaceMatchController>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.translate('game.face_match.title')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 30),
          onPressed: () => _safeExit(context),
          tooltip: context.l10n.translate('common.button.back'),
        ),
      ),
      body: SafeArea(
        child: switch (ctrl.currentStep) {
          FaceMatchStep.instructions => _buildInstructionsView(context, ctrl, isDark, theme),
          FaceMatchStep.playing || FaceMatchStep.trialFeedback =>
            _buildGameplayView(context, ctrl, isDark, theme),
          FaceMatchStep.completed => _buildCompletedView(context, ctrl, isDark, theme),
        },
      ),
    );
  }

  Widget _buildInstructionsView(
    BuildContext context,
    FaceMatchController ctrl,
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
                Icons.family_restroom_rounded,
                size: 54,
                color: isDark ? const Color(0xFFFACC15) : theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 18),
          LargeText(
            context.l10n.translate('game.face_match.title'),
            type: LargeTextType.heading,
            textAlign: TextAlign.center,
            isHeader: true,
          ),
          const SizedBox(height: 10),
          LargeText(
            context.l10n.translate('game.face_match.instruction'),
            type: LargeTextType.body,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Center(
            child: VoiceInstructionButton(
              textToSpeak: '${context.l10n.translate('game.face_match.title')}. ${context.l10n.translate('game.face_match.instruction')}',
            ),
          ),
          const SizedBox(height: 24),
          AccessibleCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LargeText(
                  context.l10n.translate('game.face_match.family_members_label'),
                  type: LargeTextType.title,
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: DefaultFaceProfiles.all.map((p) {
                    return Column(
                      children: [
                        _buildFaceAvatar(p.assetPath, size: 54),
                        const SizedBox(height: 6),
                        Text(
                          p.name.split(' ').first,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
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
    FaceMatchController ctrl,
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
                  context.l10n.translate('game.face_match.step_progress', args: {
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
              VoiceInstructionButton(
                textToSpeak: trial.targetFace.voicePrompt,
                isCompact: true,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Target card: Who is this?
          AccessibleCard(
            backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
            borderColor: isDark ? const Color(0xFFFACC15) : theme.colorScheme.primary,
            borderWidth: 2.5,
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                _buildFaceAvatar(trial.targetFace.assetPath, size: 100),
                const SizedBox(height: 12),
                LargeText(
                  context.l10n.translate('game.face_match.prompt_who'),
                  type: LargeTextType.title,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  context.l10n.translate('game.face_match.hint_prefix', args: {
                    'relation': trial.targetFace.relation,
                  }),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFFFACC15) : const Color(0xFF1D4ED8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: LargeText(
              context.l10n.translate('game.face_match.tap_matching'),
              type: LargeTextType.body,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // Candidate options
          ...List.generate(trial.options.length, (index) {
            final option = trial.options[index];
            final isSelected = ctrl.selectedOptionIndex == index;
            final isFeedback = ctrl.currentStep == FaceMatchStep.trialFeedback;

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
              semanticLabel: '${option.name}, ${option.relation}. Tap to choose.',
              child: Row(
                children: [
                  _buildFaceAvatar(option.assetPath, size: 64),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LargeText(
                          option.name,
                          type: LargeTextType.title,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          option.relation,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isFeedback && isSelected)
                    Icon(
                      ctrl.isCorrectFeedback ? Icons.check_circle_rounded : Icons.info_rounded,
                      size: 32,
                      color: ctrl.isCorrectFeedback ? const Color(0xFF166534) : const Color(0xFFB45309),
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
    FaceMatchController ctrl,
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
            score?.encouragementMessage ?? 'Thank you for playing!',
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
                  context.l10n.translate('game.common.accuracy'),
                  '${score?.accuracyPercentage.toStringAsFixed(0) ?? "0"}%',
                  Icons.check_circle_outline_rounded,
                  const Color(0xFF166534),
                  isDark,
                ),
                const Divider(height: 20, thickness: 1.5),
                _buildStatRow(
                  context.l10n.translate('results.matched_correctly'),
                  '${score?.correctTrials ?? 0} of ${score?.totalTrials ?? 0}',
                  Icons.people_alt_rounded,
                  const Color(0xFF0F3D78),
                  isDark,
                ),
                const Divider(height: 20, thickness: 1.5),
                _buildStatRow(
                  context.l10n.translate('results.average_speed'),
                  '${((score?.avgResponseTimeMs ?? 0) / 1000).toStringAsFixed(1)}s',
                  Icons.speed_rounded,
                  const Color(0xFFB45309),
                  isDark,
                ),
                Builder(
                  builder: (context) {
                    final adaptiveCtrl = Provider.of<AdaptiveDifficultyController?>(context);
                    final decision = adaptiveCtrl?.latestDecision;
                    if (decision == null) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(height: 20, thickness: 1.5),
                        _buildStatRow(
                          'Adaptive Difficulty',
                          'Level ${decision.nextDifficulty}',
                          Icons.auto_awesome_rounded,
                          const Color(0xFF2563EB),
                          isDark,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF3B82F6), width: 1),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.psychology_outlined, size: 18, color: Color(0xFF2563EB)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  decision.reason,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1E40AF),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
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

  Widget _buildFaceAvatar(String assetPath, {required double size}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size / 4),
      child: Image.asset(
        assetPath,
        width: size,
        height: size,
        cacheWidth: (size * 2).round(),
        cacheHeight: (size * 2).round(),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(size / 4),
            ),
            child: Icon(Icons.person_rounded, size: size * 0.6, color: const Color(0xFF64748B)),
          );
        },
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
