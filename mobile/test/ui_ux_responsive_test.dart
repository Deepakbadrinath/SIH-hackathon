import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smriti_setu/core/localization/app_localizations.dart';
import 'package:smriti_setu/core/theme/accessible_theme.dart';
import 'package:smriti_setu/core/theme/design_tokens.dart';
import 'package:smriti_setu/features/localization/presentation/controllers/localization_controller.dart';
import 'package:smriti_setu/features/settings/presentation/controllers/settings_controller.dart';
import 'package:smriti_setu/features/voice/data/services/voice_service_impl.dart';
import 'package:smriti_setu/features/voice/presentation/controllers/voice_controller.dart';
import 'package:smriti_setu/presentation/common_widgets/feedback_states.dart';
import 'package:smriti_setu/presentation/common_widgets/primary_button.dart';
import 'package:smriti_setu/presentation/common_widgets/responsive_scaffold.dart';
import 'package:smriti_setu/presentation/common_widgets/secondary_button.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:smriti_setu/presentation/screens/caregiver/caregiver_dashboard_screen.dart';
import 'package:smriti_setu/presentation/screens/elderly_home/elderly_home_screen.dart';
import 'package:smriti_setu/presentation/screens/medication/medication_screen.dart';
import 'package:smriti_setu/presentation/screens/welcome/welcome_screen.dart';

class _TestLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _TestLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale, const {
      'app_name': 'SmritiSetu',
      'common.audio.listen': 'Listen',
      'common.button.back': 'Back',
      'welcome.title': 'SmritiSetu',
      'welcome.greeting': 'Welcome to SmritiSetu',
      'welcome.subtitle': 'Elderly Cognitive Engagement Platform',
      'welcome.choose_language': 'Language',
      'welcome.audio_button': 'Listen',
      'welcome.audio_prompt': 'Welcome to SmritiSetu.',
      'welcome.elderly_button': 'I am an Elder',
      'welcome.caregiver_button': 'Caregiver Portal',
      'elderly_home.title': 'Home',
      'elderly_home.greeting': 'Welcome back!',
      'elderly_home.audio_prompt': 'This is your home screen.',
      'elderly_home.card_games': 'Cognitive Games',
      'elderly_home.card_games_sub': 'Play fun brain exercises',
      'elderly_home.card_reminders': 'Reminders',
      'elderly_home.card_reminders_sub': 'View your daily schedule',
      'elderly_home.card_caregiver': 'Call Caregiver',
      'elderly_home.card_caregiver_sub': 'Tap to reach your caregiver',
      'elderly_home.card_settings': 'Settings',
      'elderly_home.card_settings_sub': 'Change app appearance',
      'caregiver.dashboard.title': 'Caregiver Dashboard',
      'caregiver.dashboard.offline_ready': 'Offline Ready',
      'caregiver.dashboard.avg_accuracy': 'Average Accuracy',
      'caregiver.dashboard.avg_response_time': 'Response Speed',
      'caregiver.dashboard.difficulty_progression': 'Difficulty Progression',
      'medication.title': 'Daily Medication Reminders',
      'medication.today_schedule': "Today's Schedule",
      'medication.schedule_subtitle': 'Check off doses as taken',
      'medication.audio_prompt': 'Here are your reminders.',
      'medication.adherence.rate': 'Adherence Rate',
    }, const {});
  }

  @override
  bool shouldReload(_TestLocalizationsDelegate old) => false;
}

Widget createTestApp(Widget screen, {Locale locale = const Locale('en')}) {
  final voiceCtrl = VoiceController(voiceService: VoiceServiceImpl());
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<VoiceController>.value(value: voiceCtrl),
      ChangeNotifierProvider(create: (_) => LocalizationController()..setLocale(locale)),
      ChangeNotifierProvider(create: (_) => SettingsController()),
    ],
    child: MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        _TestLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AccessibleTheme.getLightTheme(),
      home: screen,
    ),
  );
}

void main() {
  group('Phase 18: Professional UI/UX & Responsive Layout Tests', () {
    // 1. Compact Screen (360 x 640 dp)
    testWidgets('WelcomeScreen renders without overflow on compact screen (360x640)', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp(const WelcomeScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(WelcomeScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ElderlyHomeScreen renders without overflow on compact screen (360x640)', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp(const ElderlyHomeScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(ElderlyHomeScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('CaregiverDashboardScreen renders without overflow on compact screen (360x640)', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp(const CaregiverDashboardScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(CaregiverDashboardScreen), findsOneWidget);
    });

    testWidgets('MedicationScreen renders without overflow on compact screen (360x640)', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp(const MedicationScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(MedicationScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // 2. Large Tablet Screen (768 x 1024 dp)
    testWidgets('ResponsiveContainer constrains content width on tablet (768x1024)', (tester) async {
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: AccessibleTheme.getLightTheme(),
          home: Scaffold(
            body: ResponsiveContainer(
              child: Container(
                key: const Key('tablet_content'),
                color: Colors.blue,
                height: 200,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final size = tester.getSize(find.byKey(const Key('tablet_content')));
      expect(size.width, lessThanOrEqualTo(AppBreakpoints.maxContentWidth));
    });

    // 3. Feedback States
    testWidgets('EmptyStateWidget renders icon, title, description, and action button', (tester) async {
      bool actionTapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AccessibleTheme.getLightTheme(),
          home: Scaffold(
            body: EmptyStateWidget(
              icon: Icons.medication_outlined,
              title: 'No Reminders',
              description: 'You have no scheduled reminders for today.',
              actionLabel: 'Add Reminder',
              onAction: () => actionTapped = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No Reminders'), findsOneWidget);
      expect(find.text('You have no scheduled reminders for today.'), findsOneWidget);
      expect(find.text('Add Reminder'), findsOneWidget);

      await tester.tap(find.text('Add Reminder'));
      await tester.pump();
      expect(actionTapped, isTrue);
    });

    testWidgets('LoadingStateWidget renders non-jarring loading message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AccessibleTheme.getLightTheme(),
          home: const Scaffold(
            body: LoadingStateWidget(statusMessage: 'Loading patient records...'),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Loading patient records...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('ErrorStateWidget renders title, message, and retry button', (tester) async {
      bool retryTapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AccessibleTheme.getLightTheme(),
          home: Scaffold(
            body: ErrorStateWidget(
              title: 'Connection Error',
              errorMessage: 'Could not connect to server.',
              onRetry: () => retryTapped = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Connection Error'), findsOneWidget);
      expect(find.text('Could not connect to server.'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);

      await tester.tap(find.text('Try Again'));
      await tester.pump();
      expect(retryTapped, isTrue);
    });

    testWidgets('SuccessStateWidget renders checkmark and success message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AccessibleTheme.getLightTheme(),
          home: const Scaffold(
            body: SuccessStateWidget(
              title: 'Dose Confirmed',
              message: 'Morning medication marked as taken.',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Dose Confirmed'), findsOneWidget);
      expect(find.text('Morning medication marked as taken.'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    // 4. Button Touch Target Hierarchy
    testWidgets('PrimaryButton and SecondaryButton enforce minimum accessible touch targets (>= 56dp)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AccessibleTheme.getLightTheme(),
          home: Scaffold(
            body: Column(
              children: [
                PrimaryButton(
                  label: 'Primary Action',
                  onPressed: () {},
                ),
                const SizedBox(height: 12),
                SecondaryButton(
                  label: 'Secondary Action',
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final primarySize = tester.getSize(find.widgetWithText(PrimaryButton, 'Primary Action'));
      final secondarySize = tester.getSize(find.widgetWithText(SecondaryButton, 'Secondary Action'));

      expect(primarySize.height, greaterThanOrEqualTo(56.0));
      expect(secondarySize.height, greaterThanOrEqualTo(56.0));
    });
  });
}
