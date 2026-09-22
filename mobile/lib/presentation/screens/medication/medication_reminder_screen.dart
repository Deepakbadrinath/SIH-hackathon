import 'package:flutter/material.dart';
import '../../../core/localization/app_localizations.dart';
import '../../common_widgets/accessible_card.dart';
import '../../common_widgets/large_text.dart';
import '../../common_widgets/primary_button.dart';
import '../../common_widgets/secondary_button.dart';
import '../../common_widgets/voice_instruction_button.dart';
import '../../common_widgets/voice_confirmation_widget.dart';

class MedicationReminderScreen extends StatelessWidget {
  const MedicationReminderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final medicineName = args?['medicineName'] as String? ?? 'Afternoon Medicine';
    final dosage = args?['dosage'] as String? ?? '1 tablet after food with water';

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFFFFBEB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(context.l10n.translate('reminder.alert_title')),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, size: 32),
          onPressed: () => Navigator.pop(context),
          tooltip: context.l10n.translate('common.button.close'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF854D0E) : const Color(0xFFFEF3C7),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? const Color(0xFFFACC15) : const Color(0xFFB45309),
                      width: 3.5,
                    ),
                  ),
                  child: Icon(
                    Icons.notifications_active_rounded,
                    size: 64,
                    color: isDark ? const Color(0xFFFACC15) : const Color(0xFFB45309),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              LargeText(
                context.l10n.translate('reminder.alert_title'),
                type: LargeTextType.display,
                textAlign: TextAlign.center,
                color: isDark ? const Color(0xFFFACC15) : const Color(0xFF9A3412),
                isHeader: true,
              ),
              const SizedBox(height: 12),
              LargeText(
                context.l10n.translate('reminder.take_prompt'),
                type: LargeTextType.heading,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Center(
                child: VoiceInstructionButton(
                  textToSpeak: '${context.l10n.translate("reminder.alert_title")}. $medicineName. $dosage',
                  showRepeatButton: true,
                ),
              ),
              const SizedBox(height: 28),
              AccessibleCard(
                backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderColor: isDark ? const Color(0xFFFACC15) : const Color(0xFFB45309),
                borderWidth: 2.5,
                padding: const EdgeInsets.all(22),
                child: Column(
                  children: [
                    Icon(
                      Icons.medication_rounded,
                      size: 48,
                      color: isDark ? const Color(0xFFFACC15) : const Color(0xFFB45309),
                    ),
                    const SizedBox(height: 12),
                    LargeText(
                      medicineName,
                      type: LargeTextType.heading,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    LargeText(
                      dosage,
                      type: LargeTextType.body,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              VoiceConfirmationWidget(
                title: 'Voice Confirmation',
                instructionPrompt: 'Say "I took it" to confirm or "Snooze" to delay.',
                onConfirmed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        context.l10n.translate('reminder.snack_taken'),
                        style: const TextStyle(fontSize: 18),
                      ),
                      backgroundColor: const Color(0xFF166534),
                    ),
                  );
                  Navigator.pop(context);
                },
                onDeclined: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        context.l10n.translate('reminder.snack_snoozed'),
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  );
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: context.l10n.translate('medication.button.taken'),
                icon: Icons.check_circle_rounded,
                backgroundColor: const Color(0xFF166534),
                height: 68.0,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        context.l10n.translate('reminder.snack_taken'),
                        style: const TextStyle(fontSize: 18),
                      ),
                      backgroundColor: const Color(0xFF166534),
                    ),
                  );
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 16),
              SecondaryButton(
                label: context.l10n.translate('medication.button.snooze'),
                icon: Icons.snooze_rounded,
                borderColor: const Color(0xFF9A3412),
                textColor: isDark ? const Color(0xFFFACC15) : const Color(0xFF9A3412),
                height: 60.0,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        context.l10n.translate('reminder.snack_snoozed'),
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  );
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
