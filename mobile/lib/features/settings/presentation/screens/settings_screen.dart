import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../presentation/common_widgets/disclaimer_banner.dart';
import '../controllers/settings_controller.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsCtrl = context.watch<SettingsController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accessibility & Settings', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const DisclaimerBanner(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  SwitchListTile(
                    title: Text(
                      context.l10n.translate('accessibility.high_contrast'),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text('Increase visual contrast for low-vision users', style: TextStyle(fontSize: 16)),
                    value: settingsCtrl.highContrast,
                    onChanged: (_) => settingsCtrl.toggleHighContrast(),
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: Text(
                      context.l10n.translate('accessibility.voice_guidance'),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text('Read aloud instructions and questions automatically', style: TextStyle(fontSize: 16)),
                    value: settingsCtrl.audioGuidanceEnabled,
                    onChanged: (_) => settingsCtrl.toggleAudioGuidance(),
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text(
                      'Reduced Motion',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text('Minimize rapid transitions and animated effects', style: TextStyle(fontSize: 16)),
                    value: settingsCtrl.reducedMotion,
                    onChanged: (_) => settingsCtrl.toggleReducedMotion(),
                  ),
                  const Divider(),
                  ListTile(
                    title: Text(
                      context.l10n.translate('accessibility.large_text'),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Slider(
                      value: settingsCtrl.fontScale,
                      min: 1.0,
                      max: 1.6,
                      divisions: 3,
                      label: '${(settingsCtrl.fontScale * 100).toInt()}%',
                      onChanged: (val) => settingsCtrl.setFontScale(val),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Card(
                    color: Color(0xFFFEF3C7),
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        AppConstants.medicalDisclaimer,
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF78350F)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
