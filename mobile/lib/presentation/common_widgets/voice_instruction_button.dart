import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/localization/app_localizations.dart';
import '../../features/voice/presentation/controllers/voice_controller.dart';

/// Accessible audio guidance button allowing elderly users to listen to screen instructions
/// or repeat previous instructions aloud.
/// Integrates directly with VoiceController and supports regional audio playback.
class VoiceInstructionButton extends StatelessWidget {
  final String textToSpeak;
  final String? label;
  final String? languageCode;
  final VoidCallback? onCustomSpeak;
  final bool isCompact;
  final bool showRepeatButton;
  final bool isRepeatOnly;

  const VoiceInstructionButton({
    super.key,
    required this.textToSpeak,
    this.label,
    this.languageCode,
    this.onCustomSpeak,
    this.isCompact = false,
    this.showRepeatButton = false,
    this.isRepeatOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Consumer<VoiceController>(
      builder: (context, voiceCtrl, child) {
        final isSpeaking = voiceCtrl.isSpeaking;

        if (isRepeatOnly) {
          final repeatLabel = label ?? 'Repeat Instruction';
          return Semantics(
            button: true,
            label: repeatLabel,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  voiceCtrl.repeatLastInstruction(fallbackInstruction: textToSpeak);
                },
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isCompact ? 12 : 16,
                    vertical: isCompact ? 8 : 12,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      width: 2.0,
                    ),
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: isCompact ? 140 : 260),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.replay_rounded,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          size: isCompact ? 22 : 26,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            repeatLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: isCompact ? 15.0 : 17.0,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        final defaultLabel = label ?? context.l10n.translate('common.audio.listen');
        final currentLabel = isSpeaking ? 'Stop Audio' : defaultLabel;

        final mainButton = Semantics(
          button: true,
          label: currentLabel,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                if (onCustomSpeak != null) {
                  onCustomSpeak!();
                } else {
                  if (isSpeaking) {
                    voiceCtrl.stop();
                  } else {
                    final currentLocale = Localizations.localeOf(context).languageCode;
                    final effectiveLang = languageCode ?? currentLocale;
                    voiceCtrl.readInstructionAloud(textToSpeak, languageCode: effectiveLang);
                  }
                }
              },
              borderRadius: BorderRadius.circular(30),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isCompact ? 12 : 16,
                  vertical: isCompact ? 8 : 12,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? (isSpeaking ? const Color(0xFF854D0E) : const Color(0xFF27272A))
                      : (isSpeaking ? const Color(0xFFFEF08A) : const Color(0xFFEFF6FF)),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: isDark ? const Color(0xFFFACC15) : const Color(0xFF3B82F6),
                    width: 2.0,
                  ),
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isCompact ? 140 : 260),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSpeaking ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                        color: isDark ? const Color(0xFFFACC15) : const Color(0xFF1D4ED8),
                        size: isCompact ? 24 : 28,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          currentLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: isCompact ? 15.0 : 17.0,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF1D4ED8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );

        if (!showRepeatButton) {
          return mainButton;
        }

        // Combined row with repeat button
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            mainButton,
            const SizedBox(width: 8),
            Semantics(
              button: true,
              label: 'Repeat Instruction',
              child: IconButton(
                icon: const Icon(Icons.replay_rounded),
                iconSize: isCompact ? 24 : 28,
                tooltip: 'Repeat Instruction',
                color: isDark ? const Color(0xFFFACC15) : const Color(0xFF1D4ED8),
                onPressed: () {
                  voiceCtrl.repeatLastInstruction(fallbackInstruction: textToSpeak);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
