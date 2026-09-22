import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:smriti_setu/core/localization/app_localizations.dart';
import 'package:smriti_setu/core/theme/accessible_theme.dart';
import 'package:smriti_setu/features/localization/presentation/controllers/localization_controller.dart';
import 'package:smriti_setu/features/settings/presentation/controllers/settings_controller.dart';
import 'package:smriti_setu/features/voice/data/services/voice_service_impl.dart';
import 'package:smriti_setu/features/voice/presentation/controllers/voice_controller.dart';

import 'package:smriti_setu/presentation/common_widgets/accessible_card.dart';
import 'package:smriti_setu/presentation/common_widgets/large_icon_button.dart';
import 'package:smriti_setu/presentation/common_widgets/primary_button.dart';
import 'package:smriti_setu/presentation/common_widgets/secondary_button.dart';
import 'package:smriti_setu/presentation/common_widgets/voice_instruction_button.dart';

import 'package:smriti_setu/presentation/screens/caregiver/caregiver_dashboard_screen.dart';
import 'package:smriti_setu/presentation/screens/elderly_home/elderly_home_screen.dart';
import 'package:smriti_setu/presentation/screens/games/games_screen.dart';
import 'package:smriti_setu/presentation/screens/history/history_screen.dart';
import 'package:smriti_setu/presentation/screens/games/game_instructions_screen.dart';
import 'package:smriti_setu/presentation/screens/language/language_selection_screen.dart';
import 'package:smriti_setu/presentation/screens/medication/medication_screen.dart';
import 'package:smriti_setu/presentation/screens/settings/settings_screen.dart';
import 'package:smriti_setu/presentation/screens/splash/splash_screen.dart';
import 'package:smriti_setu/presentation/screens/voice/voice_settings_screen.dart';
import 'package:smriti_setu/presentation/screens/welcome/welcome_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const internationalLanguages = [
    'es', // Spanish
    'fr', // French
    'de', // German
    'ar', // Arabic (RTL)
    'zh', // Chinese (Simplified)
    'ja', // Japanese
    'ko', // Korean
  ];

  Map<String, String> loadFlatTranslations(String langCode) {
    final file = File('assets/i18n/$langCode.json');
    if (!file.existsSync()) {
      throw Exception('Missing localization resource: assets/i18n/$langCode.json');
    }
    final rawMap = json.decode(file.readAsStringSync()) as Map<String, dynamic>;
    final map = <String, String>{};
    rawMap.forEach((k, v) {
      if (k != '_metadata') map[k] = v.toString();
    });
    return map;
  }

  Map<String, dynamic> loadMetadata(String langCode) {
    final file = File('assets/i18n/$langCode.json');
    final rawMap = json.decode(file.readAsStringSync()) as Map<String, dynamic>;
    return (rawMap['_metadata'] as Map<String, dynamic>?) ?? {};
  }

  Widget createLocalizedApp(String langCode, Widget child, {double fontScale = 1.3}) {
    final flatStrings = loadFlatTranslations(langCode);
    final metadata = loadMetadata(langCode);
    final locale = Locale(langCode);
    final isRtl = AppLocalizations.isRtl(locale);
    final l10n = AppLocalizations(locale, flatStrings, metadata);

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
        theme: AccessibleTheme.getLightTheme(fontScale: fontScale),
        home: MediaQuery(
          data: MediaQueryData(
            size: const Size(400, 900),
            textScaler: TextScaler.linear(fontScale),
          ),
          child: Directionality(
            textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
            child: child,
          ),
        ),
      ),
    );
  }

  group('Phase 10: Internationalization Extension Resource Integrity & Review Flags', () {
    test('All 7 international resource files exist and are valid JSON', () {
      for (final lang in internationalLanguages) {
        final file = File('assets/i18n/$lang.json');
        expect(file.existsSync(), isTrue, reason: 'assets/i18n/$lang.json must exist');
        final content = file.readAsStringSync();
        expect(content.isNotEmpty, isTrue);
        final decoded = json.decode(content);
        expect(decoded, isA<Map<String, dynamic>>());
      }
    });

    test('All 7 international resources are explicitly flagged as human_review_required', () {
      for (final lang in internationalLanguages) {
        final metadata = loadMetadata(lang);
        expect(metadata.isNotEmpty, isTrue, reason: 'Metadata block must exist in $lang.json');
        expect(metadata['status'], equals('human_review_required'),
            reason: '$lang translation must be flagged for human review, not silently presented as certified.');
        expect(metadata['notes'], isNotNull);
        expect(metadata['notes'].toString().toLowerCase(), contains('review'),
            reason: '$lang notes must state human linguistic/clinical review required.');

        final l10n = AppLocalizations(Locale(lang), {}, metadata);
        expect(l10n.isHumanReviewRequired, isTrue);
      }
    });

    test('All 7 international resources contain required UI keys', () {
      const requiredKeys = [
        'app.name',
        'app.disclaimer.banner',
        'common.button.continue',
        'common.button.back',
        'common.button.cancel',
        'welcome.greeting',
        'welcome.subtitle',
        'login.title',
        'elderly_home.title',
        'elderly_home.card_games',
        'elderly_home.card_meds',
        'elderly_home.card_history',
        'game.common.start',
        'game.common.score',
        'games.title',
        'game.face_match.title',
        'game.pattern.title',
        'game.sequence.title',
        'game.sorting.title',
        'instructions.title',
        'instructions.ready_button',
        'results.title',
        'results.great_job',
        'medication.title',
        'history.title',
        'settings.title',
        'language.title',
        'voice.title',
        'caregiver.dashboard.title',
        'caregiver.dashboard.avg_accuracy',
        'caregiver.dashboard.avg_response_time',
        'caregiver.dashboard.difficulty_progression',
      ];

      for (final lang in internationalLanguages) {
        final strings = loadFlatTranslations(lang);
        for (final key in requiredKeys) {
          expect(strings.containsKey(key), isTrue,
              reason: 'Localization file [$lang.json] must contain essential key: $key');
          expect(strings[key]!.isNotEmpty, isTrue,
              reason: 'Value for $key in [$lang.json] must not be empty');
        }
      }
    });

    test('AppLocalizations.supportedLocales registers all 21 languages', () {
      const expectedCodes = [
        'en', 'hi', 'as', 'mni', 'bn', 'or', 'te', 'ta', 'kn', 'ml', 'mr', 'gu', 'pa', 'ur',
        'es', 'fr', 'de', 'ar', 'zh', 'ja', 'ko'
      ];

      final registeredCodes = AppLocalizations.supportedLocales.map((l) => l.languageCode).toSet();
      for (final code in expectedCodes) {
        expect(registeredCodes.contains(code), isTrue,
            reason: 'supportedLocales must contain $code');
      }
      expect(registeredCodes.length, greaterThanOrEqualTo(21));
    });
  });

  group('Phase 10: RTL and LTR Layout Directionality', () {
    test('AppLocalizations.isRtl correctly identifies Arabic and Urdu as RTL', () {
      expect(AppLocalizations.isRtl(const Locale('ar')), isTrue);
      expect(AppLocalizations.isRtl(const Locale('ur')), isTrue);

      expect(AppLocalizations.isRtl(const Locale('en')), isFalse);
      expect(AppLocalizations.isRtl(const Locale('es')), isFalse);
      expect(AppLocalizations.isRtl(const Locale('fr')), isFalse);
      expect(AppLocalizations.isRtl(const Locale('de')), isFalse);
      expect(AppLocalizations.isRtl(const Locale('zh')), isFalse);
      expect(AppLocalizations.isRtl(const Locale('ja')), isFalse);
      expect(AppLocalizations.isRtl(const Locale('ko')), isFalse);
    });

    testWidgets('Arabic renders with correct Right-to-Left Directionality', (tester) async {
      await tester.pumpWidget(
        createLocalizedApp(
          'ar',
          Builder(
            builder: (context) {
              final direction = Directionality.of(context);
              return Text(
                'اتجاه النص: $direction',
                textDirection: direction,
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      final directionality = tester.widget<Directionality>(find.byType(Directionality).last);
      expect(directionality.textDirection, equals(TextDirection.rtl));
      expect(find.textContaining('TextDirection.rtl'), findsOneWidget);
    });

    testWidgets('Spanish, French, German, Chinese, Japanese, Korean render in LTR', (tester) async {
      for (final lang in ['es', 'fr', 'de', 'zh', 'ja', 'ko']) {
        await tester.pumpWidget(
          createLocalizedApp(
            lang,
            Builder(
              builder: (context) {
                return Text('Direction: ${Directionality.of(context)}');
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        final directionality = tester.widget<Directionality>(find.byType(Directionality).last);
        expect(directionality.textDirection, equals(TextDirection.ltr),
            reason: '$lang must use LTR layout');
      }
    });
  });

  group('Phase 10: CJK Typography & Character Rendering', () {
    testWidgets('Chinese (Simplified) text renders without error', (tester) async {
      await tester.pumpWidget(createLocalizedApp('zh', const ElderlyHomeScreen()));
      await tester.pumpAndSettle();

      expect(find.text('SmritiSetu 首页'), findsOneWidget);
      expect(find.text('益智游戏'), findsOneWidget);
      expect(find.text('我的用药'), findsOneWidget);
      expect(find.text('健康进度'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Japanese Kanji and Kana text renders without error', (tester) async {
      await tester.pumpWidget(createLocalizedApp('ja', const ElderlyHomeScreen()));
      await tester.pumpAndSettle();

      expect(find.text('SmritiSetu ホーム'), findsOneWidget);
      expect(find.text('脳トレゲーム'), findsOneWidget);
      expect(find.text('お薬の確認'), findsOneWidget);
      expect(find.text('日々の記録'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Korean Hangul syllables render without error', (tester) async {
      await tester.pumpWidget(createLocalizedApp('ko', const ElderlyHomeScreen()));
      await tester.pumpAndSettle();

      expect(find.text('SmritiSetu 홈'), findsOneWidget);
      expect(find.text('두뇌 게임'), findsOneWidget);
      expect(find.text('내 약 챙기기'), findsOneWidget);
      expect(find.text('나의 활동 기록'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    test('Font family fallback list includes CJK and Arabic font stacks', () {
      final fallbacks = AccessibleTheme.fontFamilyFallback;
      expect(fallbacks, contains('PingFang SC'));
      expect(fallbacks, contains('Hiragino Sans'));
      expect(fallbacks, contains('Apple SD Gothic Neo'));
      expect(fallbacks, contains('Microsoft YaHei'));
      expect(fallbacks, contains('Noto Sans Arabic'));
    });
  });

  group('Phase 10: Core UI Elements Verification with Translated Strings', () {
    for (final lang in internationalLanguages) {
      testWidgets('Buttons render with translated strings in [$lang]', (tester) async {
        final strings = loadFlatTranslations(lang);
        final continueLabel = strings['common.button.continue']!;
        final backLabel = strings['common.button.back']!;

        await tester.pumpWidget(
          createLocalizedApp(
            lang,
            Scaffold(
              body: Column(
                children: [
                  PrimaryButton(
                    label: continueLabel,
                    onPressed: () {},
                  ),
                  SecondaryButton(
                    label: backLabel,
                    onPressed: () {},
                  ),
                  LargeIconButton(
                    label: continueLabel,
                    icon: Icons.check,
                    onPressed: () {},
                  ),
                  const VoiceInstructionButton(
                    textToSpeak: 'Test audio instruction',
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text(continueLabel), findsWidgets);
        expect(find.text(backLabel), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('AccessibleCards render with translated strings in [$lang]', (tester) async {
        final strings = loadFlatTranslations(lang);
        final title = strings['elderly_home.card_games']!;
        final subtitle = strings['elderly_home.card_games_sub']!;

        await tester.pumpWidget(
          createLocalizedApp(
            lang,
            Scaffold(
              body: AccessibleCard(
                child: Column(
                  children: [
                    Text(title),
                    Text(subtitle),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text(title), findsOneWidget);
        expect(find.text(subtitle), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('Navigation and AppBar render in [$lang]', (tester) async {
        final strings = loadFlatTranslations(lang);
        final appTitle = strings['elderly_home.title']!;

        await tester.pumpWidget(
          createLocalizedApp(
            lang,
            Scaffold(
              appBar: AppBar(
                title: Text(appTitle),
                leading: const BackButton(),
              ),
              body: const Text('Content'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text(appTitle), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('Game Instructions view renders with translated strings in [$lang]', (tester) async {
        final strings = loadFlatTranslations(lang);
        final step1Text = strings['instructions.step1']!;
        final readyButtonLabel = strings['instructions.ready_button']!;

        await tester.pumpWidget(
          createLocalizedApp(
            lang,
            const GameInstructionsScreen(),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text(step1Text), findsOneWidget);
        expect(find.text(readyButtonLabel), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('Caregiver Dashboard Charts and Metrics render in [$lang]', (tester) async {
        final strings = loadFlatTranslations(lang);
        final avgAccuracyTitle = strings['caregiver.dashboard.avg_accuracy']!;
        final avgResponseTitle = strings['caregiver.dashboard.avg_response_time']!;
        final difficultyTitle = strings['caregiver.dashboard.difficulty_progression']!;

        await tester.pumpWidget(createLocalizedApp(lang, const CaregiverDashboardScreen()));
        await tester.pumpAndSettle();

        expect(find.text(avgAccuracyTitle), findsOneWidget);
        expect(find.text(avgResponseTitle), findsOneWidget);
        await tester.scrollUntilVisible(find.text(difficultyTitle), 200);
        expect(find.text(difficultyTitle), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('Calling Caregiver Dialog renders with translated strings in [$lang]', (tester) async {
        final strings = loadFlatTranslations(lang);
        final callNowLabel = strings['elderly_home.button_call_now']!;
        final cancelLabel = strings['common.button.cancel']!;

        await tester.pumpWidget(
          createLocalizedApp(
            lang,
            Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(strings['elderly_home.card_call_caregiver']!),
                        content: Text(strings['elderly_home.call_dialog_desc']!
                            .replaceAll('{name}', 'Rahul')
                            .replaceAll('{phone}', '+91 9876543210')),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text(cancelLabel),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text(callNowLabel),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text('Open Dialog'),
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Open Dialog'));
        await tester.pumpAndSettle();

        expect(find.text(callNowLabel), findsOneWidget);
        expect(find.text(cancelLabel), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('Phase 10: Layout Expansion & Text Overflow Verification on German and French (1.3x Scale)', () {
    // German has notably long compound words like "Gedächtnisübungsbegleiter" & "Schwierigkeitsgradentwicklung"
    // French has long phrases. We test all key screens at 1.3x font scale to guarantee zero RenderFlex overflow.
    for (final lang in ['de', 'fr', 'ar']) {
      testWidgets('ElderlyHomeScreen renders without overflow in [$lang] at 1.3x font scale', (tester) async {
        await tester.pumpWidget(createLocalizedApp(lang, const ElderlyHomeScreen()));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'ElderlyHomeScreen must not overflow in $lang');
      });

      testWidgets('CaregiverDashboardScreen renders without overflow in [$lang] at 1.3x font scale', (tester) async {
        await tester.pumpWidget(createLocalizedApp(lang, const CaregiverDashboardScreen()));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'CaregiverDashboardScreen must not overflow in $lang');
      });

      testWidgets('MedicationScreen renders without overflow in [$lang] at 1.3x font scale', (tester) async {
        await tester.pumpWidget(createLocalizedApp(lang, const MedicationScreen()));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'MedicationScreen must not overflow in $lang');
      });

      testWidgets('WelcomeScreen renders without overflow in [$lang] at 1.3x font scale', (tester) async {
        await tester.pumpWidget(createLocalizedApp(lang, const WelcomeScreen()));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'WelcomeScreen must not overflow in $lang');
      });

      testWidgets('GamesScreen renders without overflow in [$lang] at 1.3x font scale', (tester) async {
        await tester.pumpWidget(createLocalizedApp(lang, const GamesScreen()));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'GamesScreen must not overflow in $lang');
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
    }
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
