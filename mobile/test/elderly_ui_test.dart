import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:smriti_setu/core/constants/app_constants.dart';
import 'package:smriti_setu/core/localization/app_localizations.dart';
import 'package:smriti_setu/core/theme/accessible_theme.dart';
import 'package:smriti_setu/features/settings/presentation/controllers/settings_controller.dart';
import 'package:smriti_setu/features/voice/data/services/voice_service_impl.dart';
import 'package:smriti_setu/features/voice/presentation/controllers/voice_controller.dart';
import 'package:smriti_setu/presentation/common_widgets/accessible_card.dart';
import 'package:smriti_setu/presentation/common_widgets/game_card.dart';
import 'package:smriti_setu/presentation/common_widgets/large_icon_button.dart';
import 'package:smriti_setu/presentation/common_widgets/large_text.dart';
import 'package:smriti_setu/presentation/common_widgets/primary_button.dart';
import 'package:smriti_setu/presentation/common_widgets/progress_card.dart';
import 'package:smriti_setu/presentation/common_widgets/secondary_button.dart';
import 'package:smriti_setu/presentation/common_widgets/section_header.dart';
import 'package:smriti_setu/presentation/common_widgets/voice_instruction_button.dart';
import 'package:smriti_setu/presentation/screens/welcome/welcome_screen.dart';
import 'package:smriti_setu/presentation/screens/elderly_home/elderly_home_screen.dart';
import 'package:smriti_setu/presentation/screens/medication/medication_reminder_screen.dart';
import 'package:smriti_setu/presentation/screens/settings/settings_screen.dart';

class _TestLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _TestLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale, {
      'app.name': 'SmritiSetu',
      'app.tagline': 'Cognitive Memory Bridge for Elderly Care',
      'app.disclaimer.banner': 'Assistive cognitive-support only. Not a medical diagnosis.',
      'common.button.continue': 'Continue',
      'common.button.back': 'Go Back',
      'common.button.cancel': 'Cancel',
      'common.button.save': 'Save Changes',
      'common.button.retry': 'Try Again',
      'common.button.close': 'Close',
      'common.audio.listen': 'Listen Aloud',
      'welcome.greeting': 'Namaste & Welcome',
      'welcome.subtitle': 'Your friendly daily companion for memory exercises and health reminders.',
      'welcome.elder_button': 'Enter as Elderly User',
      'welcome.caregiver_button': 'Family Caregiver Sign In',
      'welcome.choose_language': 'Change Language',
      'welcome.audio_prompt': 'Welcome to SmritiSetu.',
      'auth.login': 'Sign In',
      'login.title': 'Simple Sign In',
      'login.subtitle': 'Enter your phone number.',
      'login.input_label': 'Your Phone Number',
      'login.input_hint': 'e.g. 9876543210',
      'login.quick_elder_demo': 'Quick Access (Demo Elder)',
      'login.audio_help': 'Please enter your phone number.',
      'elderly_home.title': 'SmritiSetu Home',
      'elderly_home.greeting': 'Good Day, Dadu!',
      'elderly_home.date_summary': 'Today is a beautiful day to exercise your memory.',
      'elderly_home.card_games': 'Brain Games',
      'elderly_home.card_games_sub': 'Fun daily memory & pattern activities',
      'elderly_home.card_meds': 'My Medicines',
      'elderly_home.card_meds_sub': 'Check your schedule and mark taken',
      'elderly_home.card_history': 'My Progress',
      'elderly_home.card_history_sub': 'View your daily achievements & streaks',
      'elderly_home.card_call_caregiver': 'Call Caregiver',
      'elderly_home.card_call_caregiver_sub': 'Reach your family member with one tap',
      'elderly_home.card_settings': 'Accessibility Settings',
      'elderly_home.audio_prompt': 'This is your home screen.',
      'reminder.alert_title': 'Medication Alert!',
      'reminder.take_prompt': 'It is time for your afternoon medicine.',
      'reminder.instructions_label': 'Take 1 tablet after food.',
      'reminder.button_taken': 'I Have Taken It',
      'reminder.button_snooze': 'Remind Me in 15 Min',
      'settings.title': 'Accessibility Settings',
      'settings.font_size_label': 'Text Size',
      'settings.font_normal': 'Standard',
      'settings.font_large': 'Large (Recommended)',
      'settings.font_extra_large': 'Extra Large',
      'settings.high_contrast_label': 'High Contrast Mode',
      'settings.high_contrast_sub': 'Deep black background with vivid gold highlights',
      'settings.reduced_motion_label': 'Reduced Motion',
      'settings.reduced_motion_sub': 'Minimizes animations to avoid dizziness',
      'settings.voice_guidance_label': 'Voice Audio Prompts',
      'settings.voice_guidance_sub': 'Speaks instructions aloud automatically',
      'settings.language_button': 'Regional Language Selection',
      'settings.voice_settings_button': 'Voice & Speech Settings',
      'settings.audio_prompt': 'You can customize settings.',
      'accessibility.high_contrast': 'High Contrast Mode',
      'accessibility.large_text': 'Large Text Size',
      'accessibility.voice_guidance': 'Voice Audio Prompts',
    });
  }

  @override
  bool shouldReload(_TestLocalizationsDelegate old) => false;
}

Widget _buildTestApp({
  required Widget child,
  SettingsController? settingsCtrl,
  VoiceController? voiceCtrl,
}) {
  final sCtrl = settingsCtrl ?? SettingsController();
  final vCtrl = voiceCtrl ?? VoiceController(voiceService: VoiceServiceImpl());

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<SettingsController>.value(value: sCtrl),
      ChangeNotifierProvider<VoiceController>.value(value: vCtrl),
    ],
    child: MaterialApp(
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        _TestLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: sCtrl.highContrast
          ? AccessibleTheme.getHighContrastTheme(fontScale: sCtrl.fontScale)
          : AccessibleTheme.getLightTheme(fontScale: sCtrl.fontScale),
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  group('Phase 3: Elderly-First UI Design System Component Tests', () {
    testWidgets('PrimaryButton enforces minimum touch target >= 56px and semantic button role',
        (WidgetTester tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        _buildTestApp(
          child: Center(
            child: PrimaryButton(
              label: 'Test Primary Action',
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final buttonFinder = find.byType(ElevatedButton);
      expect(buttonFinder, findsOneWidget);

      final size = tester.getSize(buttonFinder);
      expect(size.height, greaterThanOrEqualTo(56.0));
      expect(size.height, equals(64.0)); // Default primary button height

      await tester.tap(buttonFinder);
      await tester.pump();
      expect(pressed, isTrue);

      // Verify semantics
      final semantics = tester.getSemantics(buttonFinder);
      expect(semantics.label, contains('Test Primary Action'));
    });

    testWidgets('SecondaryButton enforces minimum touch target >= 56px and high-contrast outline',
        (WidgetTester tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        _buildTestApp(
          child: Center(
            child: SecondaryButton(
              label: 'Go Back',
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final buttonFinder = find.byType(OutlinedButton);
      expect(buttonFinder, findsOneWidget);

      final size = tester.getSize(buttonFinder);
      expect(size.height, greaterThanOrEqualTo(56.0));

      await tester.tap(buttonFinder);
      await tester.pump();
      expect(pressed, isTrue);
    });

    testWidgets('LargeIconButton enforces minimum size >= 64px and text label',
        (WidgetTester tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        _buildTestApp(
          child: Center(
            child: LargeIconButton(
              icon: Icons.favorite,
              label: 'Help Button',
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Help Button'), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsOneWidget);

      final buttonFinder = find.byType(LargeIconButton);
      final size = tester.getSize(buttonFinder);
      expect(size.height, greaterThanOrEqualTo(64.0));
      expect(size.width, greaterThanOrEqualTo(64.0));

      await tester.tap(buttonFinder);
      await tester.pump();
      expect(pressed, isTrue);
    });

    testWidgets('AccessibleCard provides tactile padding, borders, and handles tap feedback',
        (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        _buildTestApp(
          child: AccessibleCard(
            onTap: () => tapped = true,
            child: const Text('Accessible Card Content'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Accessible Card Content'), findsOneWidget);
      await tester.tap(find.text('Accessible Card Content'));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('GameCard renders domain chip, difficulty stars, and triggers onPlay',
        (WidgetTester tester) async {
      bool played = false;

      await tester.pumpWidget(
        _buildTestApp(
          child: GameCard(
            title: 'Pattern Completion',
            description: 'Identify the next symbol in the sequence.',
            domain: 'Logic',
            difficultyLevel: 2,
            icon: Icons.auto_awesome,
            onPlay: () => played = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pattern Completion'), findsOneWidget);
      expect(find.text('Logic'), findsOneWidget);
      expect(find.text('Play'), findsOneWidget);

      await tester.tap(find.text('Play'));
      await tester.pump();
      expect(played, isTrue);
    });

    testWidgets('ProgressCard displays large metric figures and accessibility label',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          child: const ProgressCard(
            title: 'Daily Streak',
            value: '5 Days',
            subtitle: 'Consistent memory training',
            icon: Icons.local_fire_department,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Daily Streak'), findsOneWidget);
      expect(find.text('5 Days'), findsOneWidget);
      expect(find.text('Consistent memory training'), findsOneWidget);
    });

    testWidgets('SectionHeader renders header semantics and optional voice instruction button',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          child: const SectionHeader(
            title: 'Today Activities',
            subtitle: 'Recommended brain games',
            audioText: 'Listen to today activities',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Today Activities'), findsOneWidget);
      expect(find.text('Recommended brain games'), findsOneWidget);
      expect(find.byType(VoiceInstructionButton), findsOneWidget);
    });

    testWidgets('LargeText enforces minimum typography and header semantics',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          child: const Column(
            children: [
              LargeText('Display Title', type: LargeTextType.display),
              LargeText('Heading Section', type: LargeTextType.heading),
              LargeText('Body Description', type: LargeTextType.body),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      final displayText = tester.widget<Text>(find.text('Display Title'));
      expect(displayText.style!.fontSize, greaterThanOrEqualTo(AppConstants.minDisplayFontSize));

      final headingText = tester.widget<Text>(find.text('Heading Section'));
      expect(headingText.style!.fontSize, greaterThanOrEqualTo(AppConstants.minHeadingFontSize));

      final bodyText = tester.widget<Text>(find.text('Body Description'));
      expect(bodyText.style!.fontSize, greaterThanOrEqualTo(AppConstants.minBodyFontSize));
    });

    testWidgets('VoiceInstructionButton speaks instruction aloud through VoiceController',
        (WidgetTester tester) async {
      final voiceCtrl = VoiceController(voiceService: VoiceServiceImpl());

      await tester.pumpWidget(
        _buildTestApp(
          voiceCtrl: voiceCtrl,
          child: const VoiceInstructionButton(
            textToSpeak: 'Hello elder friend',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(VoiceInstructionButton), findsOneWidget);
      await tester.tap(find.byType(VoiceInstructionButton));
      await tester.pump(const Duration(milliseconds: 100));

      expect(voiceCtrl.lastSpokenText, equals('Hello elder friend'));
    });
  });

  group('Phase 3: SettingsController & Accessibility Adaptation Tests', () {
    test('SettingsController toggles high contrast and notifies listeners', () {
      final ctrl = SettingsController();
      bool notified = false;
      ctrl.addListener(() => notified = true);

      expect(ctrl.highContrast, isFalse);
      ctrl.toggleHighContrast();
      expect(ctrl.highContrast, isTrue);
      expect(notified, isTrue);
    });

    test('SettingsController adjusts dynamic font scale and presets', () {
      final ctrl = SettingsController();
      expect(ctrl.fontScale, equals(1.25));

      ctrl.setFontPreset(FontScalePreset.extraLarge);
      expect(ctrl.fontScale, equals(1.5));
      expect(ctrl.currentFontPreset, equals(FontScalePreset.extraLarge));

      ctrl.setFontPreset(FontScalePreset.normal);
      expect(ctrl.fontScale, equals(1.0));
      expect(ctrl.currentFontPreset, equals(FontScalePreset.normal));
    });

    test('SettingsController toggles reduced motion and audio guidance', () {
      final ctrl = SettingsController();
      expect(ctrl.reducedMotion, isFalse);
      ctrl.toggleReducedMotion();
      expect(ctrl.reducedMotion, isTrue);

      expect(ctrl.audioGuidanceEnabled, isTrue);
      ctrl.toggleAudioGuidance();
      expect(ctrl.audioGuidanceEnabled, isFalse);
    });

    test('SettingsController calibrates elderly speech rate and volume', () {
      final ctrl = SettingsController();
      expect(ctrl.speechRate, equals(0.85)); // Calibrated slower for elderly

      ctrl.setSpeechRate(0.75);
      expect(ctrl.speechRate, equals(0.75));

      ctrl.setSpeechVolume(0.8);
      expect(ctrl.speechVolume, equals(0.8));

      ctrl.setVoiceGender('male');
      expect(ctrl.voiceGender, equals('male'));
    });
  });

  group('Phase 3: Screen Smoke & Layout Overflow Tests', () {
    testWidgets('WelcomeScreen renders cleanly with high contrast theme',
        (WidgetTester tester) async {
      final settings = SettingsController()..setHighContrast(true);

      await tester.pumpWidget(
        _buildTestApp(
          settingsCtrl: settings,
          child: const WelcomeScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(WelcomeScreen), findsOneWidget);
      expect(find.byType(PrimaryButton), findsOneWidget);
      expect(find.byType(SecondaryButton), findsOneWidget);
    });

    testWidgets('ElderlyHomeScreen renders all 4 action cards without overflow',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          child: const ElderlyHomeScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ElderlyHomeScreen), findsOneWidget);
      expect(find.byType(AccessibleCard), findsWidgets);
    });

    testWidgets('MedicationReminderScreen renders high-contrast alert and buttons',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          child: const MedicationReminderScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MedicationReminderScreen), findsOneWidget);
      expect(find.byType(PrimaryButton), findsOneWidget);
      expect(find.byType(SecondaryButton), findsOneWidget);
    });

    testWidgets('SettingsScreen renders font size pickers and switches',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _buildTestApp(
          child: const SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.byType(SwitchListTile), findsNWidgets(3));
    });
  });
}
