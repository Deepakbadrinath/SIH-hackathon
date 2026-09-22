import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smriti_setu/core/localization/app_localizations.dart';
import 'package:smriti_setu/features/localization/presentation/controllers/localization_controller.dart';
import 'package:smriti_setu/features/settings/presentation/controllers/settings_controller.dart';
import 'package:smriti_setu/features/voice/data/services/voice_service_impl.dart';
import 'package:smriti_setu/features/voice/presentation/controllers/voice_controller.dart';

import 'package:smriti_setu/presentation/screens/splash/splash_screen.dart';
import 'package:smriti_setu/presentation/screens/welcome/welcome_screen.dart';
import 'package:smriti_setu/presentation/screens/elderly_home/elderly_home_screen.dart';
import 'package:smriti_setu/presentation/screens/games/games_screen.dart';
import 'package:smriti_setu/presentation/screens/medication/medication_screen.dart';
import 'package:smriti_setu/presentation/screens/history/history_screen.dart';
import 'package:smriti_setu/presentation/screens/settings/settings_screen.dart';
import 'package:smriti_setu/presentation/screens/language/language_selection_screen.dart';
import 'package:smriti_setu/presentation/screens/voice/voice_settings_screen.dart';
import 'package:smriti_setu/presentation/screens/caregiver/caregiver_dashboard_screen.dart';

void main() {
  const all14Languages = [
    'en', // English
    'hi', // Hindi
    'as', // Assamese
    'mni', // Manipuri
    'bn', // Bengali
    'or', // Odia
    'te', // Telugu
    'ta', // Tamil
    'kn', // Kannada
    'ml', // Malayalam
    'mr', // Marathi
    'gu', // Gujarati
    'pa', // Punjabi
    'ur', // Urdu (RTL)
  ];

  group('Phase 9: Translation Files Integrity & Key Parity', () {
    test('All 14 language JSON files exist and are valid JSON', () {
      for (final code in all14Languages) {
        final file = File('assets/i18n/$code.json');
        expect(file.existsSync(), isTrue, reason: 'assets/i18n/$code.json must exist');

        final content = file.readAsStringSync();
        expect(() => json.decode(content), returnsNormally, reason: '$code.json must be valid JSON');

        final map = json.decode(content) as Map<String, dynamic>;
        expect(map.containsKey('_metadata'), isTrue, reason: '$code.json must contain _metadata');
      }
    });

    test('All 14 files contain essential application keys', () {
      const requiredKeys = [
        'app.name',
        'app.tagline',
        'app.disclaimer.banner',
        'app.disclaimer.full',
        'common.button.continue',
        'common.button.back',
        'welcome.greeting',
        'welcome.elder_button',
        'auth.role.patient',
        'elderly_home.title',
        'elderly_home.greeting',
        'game.common.start',
        'games.title',
        'game.face_match.title',
        'game.pattern.title',
        'game.sequence.title',
        'game.sorting.title',
        'instructions.title',
        'results.title',
        'medication.title',
        'history.title',
        'settings.title',
        'language.title',
        'voice.title',
        'caregiver.dashboard.title',
        'accessibility.high_contrast',
      ];

      for (final code in all14Languages) {
        final content = File('assets/i18n/$code.json').readAsStringSync();
        final map = json.decode(content) as Map<String, dynamic>;

        for (final key in requiredKeys) {
          expect(
            map.containsKey(key),
            isTrue,
            reason: 'File $code.json must contain key "$key"',
          );
          expect(
            map[key].toString().trim().isNotEmpty,
            isTrue,
            reason: 'Key "$key" in $code.json cannot be empty',
          );
        }
      }
    });

    test('Unverified translations are explicitly marked for human review', () {
      const verifiedLanguages = {'en', 'as', 'hi', 'mni'};
      const humanReviewLanguages = {'bn', 'or', 'te', 'ta', 'kn', 'ml', 'mr', 'gu', 'pa', 'ur'};

      for (final code in verifiedLanguages) {
        final content = File('assets/i18n/$code.json').readAsStringSync();
        final map = json.decode(content) as Map<String, dynamic>;
        final meta = map['_metadata'] as Map<String, dynamic>;
        expect(meta['status'], equals('verified'));
      }

      for (final code in humanReviewLanguages) {
        final content = File('assets/i18n/$code.json').readAsStringSync();
        final map = json.decode(content) as Map<String, dynamic>;
        final meta = map['_metadata'] as Map<String, dynamic>;
        expect(
          meta['status'],
          equals('human_review_required'),
          reason: 'Language $code must be marked as human_review_required',
        );
        expect(meta['notes'].toString().isNotEmpty, isTrue);
      }
    });
  });

  group('Phase 9: AppLocalizations Domain Features', () {
    test('RTL detection correctly identifies Urdu and Arabic', () {
      expect(AppLocalizations.isRtl(const Locale('ur')), isTrue);
      expect(AppLocalizations.isRtl(const Locale('ar')), isTrue);

      expect(AppLocalizations.isRtl(const Locale('en')), isFalse);
      expect(AppLocalizations.isRtl(const Locale('hi')), isFalse);
      expect(AppLocalizations.isRtl(const Locale('as')), isFalse);
      expect(AppLocalizations.isRtl(const Locale('kn')), isFalse);
      expect(AppLocalizations.isRtl(const Locale('ta')), isFalse);
      expect(AppLocalizations.isRtl(const Locale('te')), isFalse);
    });

    test('All 14 locales are in AppLocalizations.supportedLocales', () {
      final supportedCodes = AppLocalizations.supportedLocales.map((l) => l.languageCode).toSet();
      for (final code in all14Languages) {
        expect(supportedCodes.contains(code), isTrue, reason: 'Locales must include $code');
      }
    });

    test('translate with dynamic arguments works correctly', () {
      final l10n = AppLocalizations(
        const Locale('en'),
        {'welcome.message': 'Welcome, {name}! You have {count} items.'},
      );

      final result = l10n.translate('welcome.message', args: {'name': 'Dadu', 'count': 5});
      expect(result, equals('Welcome, Dadu! You have 5 items.'));
    });

    test('translatePlural supports singular and plural rules', () {
      final l10n = AppLocalizations(
        const Locale('en'),
        {
          'plural.day.one': '{count} Day',
          'plural.day.other': '{count} Days',
          'plural.day.zero': 'No Days',
        },
      );

      expect(l10n.translatePlural('plural.day', 1), equals('1 Day'));
      expect(l10n.translatePlural('plural.day', 5), equals('5 Days'));
      expect(l10n.translatePlural('plural.day', 0), equals('No Days'));
    });

    test('formatNumber converts to regional digits when requested', () {
      final l10nAssamese = AppLocalizations(const Locale('as'), {});
      expect(l10nAssamese.formatNumber(12345, useNativeDigits: true), equals('১২৩৪৫'));

      final l10nHindi = AppLocalizations(const Locale('hi'), {});
      expect(l10nHindi.formatNumber(12345, useNativeDigits: true), equals('१२३४५'));

      final l10nUrdu = AppLocalizations(const Locale('ur'), {});
      expect(l10nUrdu.formatNumber(12345, useNativeDigits: true), equals('۱۲۳۴۵'));

      final l10nKannada = AppLocalizations(const Locale('kn'), {});
      expect(l10nKannada.formatNumber(12345, useNativeDigits: true), equals('೧೨೩೪೫'));
    });

    test('formatDate produces formatted localized date', () {
      final l10n = AppLocalizations(
        const Locale('en'),
        {
          'date.month.9': 'September',
          'date.weekday.6': 'Saturday',
        },
      );

      final date = DateTime(2026, 9, 12);
      expect(l10n.formatDate(date), equals('12 September 2026'));
      expect(l10n.formatDate(date, includeWeekday: true), equals('Saturday, 12 September 2026'));
    });

    test('formatTime produces formatted localized time', () {
      final l10n = AppLocalizations(
        const Locale('en'),
        {
          'time.am': 'AM',
          'time.pm': 'PM',
        },
      );

      expect(l10n.formatTime(const TimeOfDay(hour: 8, minute: 30)), equals('8:30 AM'));
      expect(l10n.formatTime(const TimeOfDay(hour: 14, minute: 5)), equals('2:05 PM'));
    });

    test('getAccessibilityLabel resolves semantic keys correctly', () {
      final l10n = AppLocalizations(
        const Locale('en'),
        {
          'accessibility.high_contrast': 'High Contrast Mode Enabled',
          'settings.title': 'Settings',
        },
      );

      expect(l10n.getAccessibilityLabel('high_contrast'), equals('High Contrast Mode Enabled'));
      expect(l10n.getAccessibilityLabel('settings.title'), equals('Settings'));
      expect(l10n.getAccessibilityLabel('non_existent', defaultFallback: 'Fallback'), equals('Fallback'));
    });
  });

  group('Phase 9: Screen Layout & Text Overflow Verification Across Locales', () {
    const testLocales = [
      'en', // English baseline
      'hi', // Hindi
      'as', // Assamese
      'mni', // Manipuri
      'kn', // Kannada (complex script)
      'ta', // Tamil (long words)
      'te', // Telugu
      'ur', // Urdu (RTL)
      'ml', // Malayalam (long compound script)
    ];

    Widget createLocalizedApp(String langCode, Widget screen, {double fontScale = 1.3}) {
      final content = File('assets/i18n/$langCode.json').readAsStringSync();
      final rawMap = json.decode(content) as Map<String, dynamic>;
      final flatStrings = <String, String>{};
      rawMap.forEach((k, v) {
        if (k != '_metadata') flatStrings[k] = v.toString();
      });

      final locale = Locale(langCode);
      final isRtl = AppLocalizations.isRtl(locale);
      final l10n = AppLocalizations(locale, flatStrings, rawMap['_metadata'] as Map<String, dynamic>?);

      final voiceCtrl = VoiceController(voiceService: VoiceServiceImpl());
      final locCtrl = LocalizationController()..setLanguageCode(langCode);
      final settingsCtrl = SettingsController()..setFontScale(fontScale);

      return MultiProvider(
        providers: [
          ChangeNotifierProvider<VoiceController>.value(value: voiceCtrl),
          ChangeNotifierProvider<LocalizationController>.value(value: locCtrl),
          ChangeNotifierProvider<SettingsController>.value(value: settingsCtrl),
        ],
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: [
            _TestLocalizationsDelegate(l10n),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            AppLocalizations.fallbackMaterialDelegate,
            AppLocalizations.fallbackCupertinoDelegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: MediaQuery(
            data: MediaQueryData(
              size: const Size(400, 900),
              textScaler: TextScaler.linear(fontScale),
            ),
            child: Directionality(
              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
              child: screen,
            ),
          ),
        ),
      );
    }

    for (final lang in testLocales) {
      testWidgets('SplashScreen renders without overflow in [$lang] at 1.3x font scale', (tester) async {
        await tester.pumpWidget(
          createLocalizedApp(
            lang,
            SplashScreen(
              onLanguageChanged: (_) {},
              onToggleTheme: () {},
              isHighContrast: false,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'SplashScreen must not overflow in $lang');
      });

      testWidgets('WelcomeScreen renders without overflow in [$lang] at 1.3x font scale', (tester) async {
        await tester.pumpWidget(createLocalizedApp(lang, const WelcomeScreen()));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'WelcomeScreen must not overflow in $lang');
      });

      testWidgets('ElderlyHomeScreen renders without overflow in [$lang] at 1.3x font scale', (tester) async {
        await tester.pumpWidget(createLocalizedApp(lang, const ElderlyHomeScreen()));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'ElderlyHomeScreen must not overflow in $lang');
      });

      testWidgets('GamesScreen renders without overflow in [$lang] at 1.3x font scale', (tester) async {
        await tester.pumpWidget(createLocalizedApp(lang, const GamesScreen()));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'GamesScreen must not overflow in $lang');
      });

      testWidgets('MedicationScreen renders without overflow in [$lang] at 1.3x font scale', (tester) async {
        await tester.pumpWidget(createLocalizedApp(lang, const MedicationScreen()));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'MedicationScreen must not overflow in $lang');
      });

      testWidgets('HistoryScreen renders without overflow in [$lang] at 1.3x font scale', (tester) async {
        await tester.pumpWidget(createLocalizedApp(lang, const HistoryScreen()));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'HistoryScreen must not overflow in $lang');
      });

      testWidgets('SettingsScreen renders without overflow in [$lang] at 1.3x font scale', (tester) async {
        await tester.pumpWidget(createLocalizedApp(lang, const SettingsScreen()));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'SettingsScreen must not overflow in $lang');
      });

      testWidgets('LanguageSelectionScreen renders without overflow in [$lang]', (tester) async {
        await tester.pumpWidget(createLocalizedApp(lang, const LanguageSelectionScreen()));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'LanguageSelectionScreen must not overflow in $lang');
      });

      testWidgets('VoiceSettingsScreen renders without overflow in [$lang]', (tester) async {
        await tester.pumpWidget(createLocalizedApp(lang, const VoiceSettingsScreen()));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'VoiceSettingsScreen must not overflow in $lang');
      });

      testWidgets('CaregiverDashboardScreen renders without overflow in [$lang]', (tester) async {
        await tester.pumpWidget(createLocalizedApp(lang, const CaregiverDashboardScreen()));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'CaregiverDashboardScreen must not overflow in $lang');
      });
    }

    testWidgets('Urdu (RTL) renders with correct Right-to-Left Directionality', (tester) async {
      await tester.pumpWidget(createLocalizedApp('ur', const ElderlyHomeScreen()));
      await tester.pumpAndSettle();

      final directionalityFinder = find.byType(Directionality);
      expect(directionalityFinder, findsWidgets);

      final Directionality topDirectionality = tester.widget(directionalityFinder.first);
      expect(topDirectionality.textDirection, equals(TextDirection.rtl));
      expect(tester.takeException(), isNull);
    });
  });
}

class _TestLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  final AppLocalizations instance;
  const _TestLocalizationsDelegate(this.instance);

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<AppLocalizations> load(Locale locale) async => instance;

  @override
  bool shouldReload(_TestLocalizationsDelegate old) => false;
}
