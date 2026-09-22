import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/localization/app_localizations.dart';
import '../../domain/services/voice_service.dart';
import '../../features/voice/presentation/controllers/voice_controller.dart';
import 'large_text.dart';

/// Accessible Voice Confirmation widget for elderly users.
/// Provides large touch targets, high contrast, animated listening feedback,
/// and manual fallback buttons in case voice input is unavailable.
class VoiceConfirmationWidget extends StatefulWidget {
  final String title;
  final String instructionPrompt;
  final String languageCode;
  final VoidCallback onConfirmed;
  final VoidCallback onDeclined;
  final VoidCallback? onCancelled;
  final List<String>? customAffirmatives;
  final List<String>? customNegatives;

  const VoiceConfirmationWidget({
    super.key,
    required this.title,
    required this.instructionPrompt,
    this.languageCode = 'en',
    required this.onConfirmed,
    required this.onDeclined,
    this.onCancelled,
    this.customAffirmatives,
    this.customNegatives,
  });

  @override
  State<VoiceConfirmationWidget> createState() => _VoiceConfirmationWidgetState();
}

class _VoiceConfirmationWidgetState extends State<VoiceConfirmationWidget> {
  String? _statusFeedback;
  bool _hasError = false;

  Future<void> _startVoiceListening(VoiceController voiceCtrl) async {
    setState(() {
      _statusFeedback = 'Listening... Please speak clearly.';
      _hasError = false;
    });

    final result = await voiceCtrl.requestVoiceConfirmation(
      languageCode: widget.languageCode,
      customAffirmatives: widget.customAffirmatives,
      customNegatives: widget.customNegatives,
    );

    if (!mounted) return;

    switch (result) {
      case VoiceConfirmationResult.confirmed:
        setState(() {
          _statusFeedback = 'Confirmed! ✓';
          _hasError = false;
        });
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) widget.onConfirmed();
        break;

      case VoiceConfirmationResult.declined:
        setState(() {
          _statusFeedback = 'Declined / Snoozed.';
          _hasError = false;
        });
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) widget.onDeclined();
        break;

      case VoiceConfirmationResult.unrecognized:
        setState(() {
          _statusFeedback = "Didn't catch that. Tap microphone to retry or choose below.";
          _hasError = true;
        });
        break;

      case VoiceConfirmationResult.cancelled:
        setState(() {
          _statusFeedback = 'Voice listening cancelled.';
          _hasError = false;
        });
        if (widget.onCancelled != null) widget.onCancelled!();
        break;

      case VoiceConfirmationResult.error:
        final err = voiceCtrl.lastErrorMessage ?? 'Could not listen right now.';
        setState(() {
          _statusFeedback = err;
          _hasError = true;
        });
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Consumer<VoiceController>(
      builder: (context, voiceCtrl, child) {
        final isListening = voiceCtrl.isListening;

        return Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF18181B) : const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? const Color(0xFFFACC15) : const Color(0xFF3B82F6),
              width: 2.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LargeText(
                widget.title,
                type: LargeTextType.title,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              LargeText(
                widget.instructionPrompt,
                type: LargeTextType.body,
                textAlign: TextAlign.center,
                color: isDark ? const Color(0xFFE4E4E7) : const Color(0xFF334155),
              ),
              const SizedBox(height: 20),

              // Microphone button with pulse effect
              Semantics(
                button: true,
                label: isListening ? 'Listening for your voice...' : 'Tap to speak confirmation',
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: isListening ? null : () => _startVoiceListening(voiceCtrl),
                    customBorder: const CircleBorder(),
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isListening
                            ? (isDark ? const Color(0xFFB45309) : const Color(0xFFDC2626))
                            : (isDark ? const Color(0xFFFACC15) : const Color(0xFF2563EB)),
                        boxShadow: isListening
                            ? [
                                BoxShadow(
                                  color: (isDark ? const Color(0xFFFACC15) : const Color(0xFFDC2626))
                                      .withValues(alpha: 0.5),
                                  blurRadius: 16,
                                  spreadRadius: 4,
                                )
                              ]
                            : null,
                      ),
                      child: Icon(
                        isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                        color: isListening
                            ? Colors.white
                            : (isDark ? Colors.black : Colors.white),
                        size: 42,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Spoken feedback text
              if (_statusFeedback != null) ...[
                Text(
                  _statusFeedback!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _hasError
                        ? (isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626))
                        : (isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A)),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Fallback / manual response buttons
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  TextButton.icon(
                    onPressed: widget.onConfirmed,
                    icon: const Icon(Icons.check_circle_outline, color: Color(0xFF16A34A)),
                    label: Text(
                      AppLocalizations.of(context)?.translate('medication.button.taken') ?? 'I Took It',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: widget.onDeclined,
                    icon: const Icon(Icons.snooze, color: Color(0xFFD97706)),
                    label: Text(
                      AppLocalizations.of(context)?.translate('medication.button.snooze') ?? 'Snooze',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
