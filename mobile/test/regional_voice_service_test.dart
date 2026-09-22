import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:smriti_setu/core/config/app_config.dart';
import 'package:smriti_setu/core/localization/app_localizations.dart';
import 'package:smriti_setu/core/theme/accessible_theme.dart';
import 'package:smriti_setu/domain/services/voice_service.dart';
import 'package:smriti_setu/features/voice/data/datasources/bhashini_voice_provider.dart';
import 'package:smriti_setu/features/voice/data/services/patient_data_sanitizer.dart';
import 'package:smriti_setu/features/voice/data/services/speech_to_text_service_impl.dart';
import 'package:smriti_setu/features/voice/data/services/text_to_speech_service_impl.dart';
import 'package:smriti_setu/features/voice/data/services/voice_service_impl.dart';
import 'package:smriti_setu/features/voice/presentation/controllers/voice_controller.dart';
import 'package:smriti_setu/presentation/common_widgets/voice_confirmation_widget.dart';
import 'package:smriti_setu/presentation/common_widgets/voice_instruction_button.dart';

class _TestVoiceLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _TestVoiceLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale, const {
      'common.audio.listen': 'Listen Aloud',
      'medication.button.taken': 'I Have Taken It',
      'medication.button.snooze': 'Remind Me in 15 Min',
      'voice.title': 'Voice Settings',
      'voice.test_phrase': 'Hello! Voice is working.',
    });
  }

  @override
  bool shouldReload(_TestVoiceLocalizationsDelegate old) => false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    AppConfig.initialize(Environment.development);
  });

  group('Phase 11: 14 Regional Languages & Profile Coverage', () {
    test('BhashiniVoiceProvider supports all 14 mandatory regional languages', () {
      final bhashini = BhashiniVoiceProvider(simulatedLatency: Duration.zero);
      const expectedLanguages = [
        'en', 'hi', 'as', 'mni', 'bn', 'or', 'te', 'ta', 'kn', 'ml', 'mr', 'gu', 'pa', 'ur'
      ];

      for (final lang in expectedLanguages) {
        expect(
          bhashini.isLanguageSupported(lang),
          isTrue,
          reason: 'Bhashini must support regional language: $lang',
        );
      }
    });

    test('VoiceServiceImpl provides complete profiles for all 14 languages', () {
      final voiceService = VoiceServiceImpl(
        bhashiniProvider: BhashiniVoiceProvider(simulatedLatency: Duration.zero),
        nativeProvider: NativePlatformVoiceProvider(simulatedLatency: Duration.zero),
      );

      final profiles = voiceService.getSupportedLanguages();
      expect(profiles.length, greaterThanOrEqualTo(14));

      final languageCodes = profiles.map((p) => p.languageCode).toSet();
      expect(languageCodes.contains('en'), isTrue);
      expect(languageCodes.contains('hi'), isTrue);
      expect(languageCodes.contains('as'), isTrue);
      expect(languageCodes.contains('mni'), isTrue);
      expect(languageCodes.contains('bn'), isTrue);
      expect(languageCodes.contains('or'), isTrue);
      expect(languageCodes.contains('te'), isTrue);
      expect(languageCodes.contains('ta'), isTrue);
      expect(languageCodes.contains('kn'), isTrue);
      expect(languageCodes.contains('ml'), isTrue);
      expect(languageCodes.contains('mr'), isTrue);
      expect(languageCodes.contains('gu'), isTrue);
      expect(languageCodes.contains('pa'), isTrue);
      expect(languageCodes.contains('ur'), isTrue);
    });

    test('Truthful offline reporting: Never claim offline STT without on-device pack', () {
      final platformProvider = NativePlatformVoiceProvider(
        installedOfflineTtsLocales: {'en', 'hi'},
        installedOfflineSttLocales: {'en'}, // Only English installed on this device
        simulatedLatency: Duration.zero,
      );

      // English has offline STT
      expect(platformProvider.hasOfflineStt('en'), isTrue);

      // Assamese and Manipuri do not have native offline STT on standard mobile OS
      expect(platformProvider.hasOfflineStt('as'), isFalse);
      expect(platformProvider.hasOfflineStt('mni'), isFalse);
      expect(platformProvider.hasOfflineStt('hi'), isFalse);
    });
  });

  group('Phase 11: TextToSpeechService & Offline Fallback', () {
    late BhashiniVoiceProvider mockBhashini;
    late NativePlatformVoiceProvider mockPlatform;
    late TextToSpeechServiceImpl ttsService;

    setUp(() {
      mockBhashini = BhashiniVoiceProvider(simulatedLatency: Duration.zero);
      mockPlatform = NativePlatformVoiceProvider(
        installedOfflineTtsLocales: {'en', 'hi'},
        simulatedLatency: Duration.zero,
      );
      ttsService = TextToSpeechServiceImpl(
        primaryProvider: mockBhashini,
        fallbackProvider: mockPlatform,
      );
    });

    test('Speaks successfully via primary cloud provider under normal conditions', () async {
      final res = await ttsService.speak('Welcome to SmritiSetu', languageCode: 'en');
      expect(res.isSuccess, isTrue);
      expect(ttsService.isSpeaking, isFalse);
    });

    test('Automatically falls back to platform offline TTS when cloud encounters network failure', () async {
      mockBhashini.simulateNetworkFailure = true;

      // English is available on platform offline TTS -> fallback should succeed!
      final res = await ttsService.speak('Take your medication', languageCode: 'en');
      expect(res.isSuccess, isTrue);
    });

    test('Returns network failure when cloud fails and platform does not support offline TTS for that language', () async {
      mockBhashini.simulateNetworkFailure = true;

      // Assamese is not installed offline on platform
      final res = await ttsService.speak('ঔষধ খোৱাৰ সময় হৈছে', languageCode: 'as');
      expect(res.isFailure, isTrue);
      expect(res.errorType, equals(VoiceErrorType.networkFailure));
    });

    test('Rejects unsupported language codes cleanly', () async {
      final res = await ttsService.speak('Test', languageCode: 'xyz');
      expect(res.isFailure, isTrue);
      expect(res.errorType, equals(VoiceErrorType.unsupportedLanguage));
    });
  });

  group('Phase 11: SpeechToTextService & Error Handling Matrix', () {
    late BhashiniVoiceProvider mockBhashini;
    late NativePlatformVoiceProvider mockPlatform;
    late SpeechToTextServiceImpl sttService;

    setUp(() {
      mockBhashini = BhashiniVoiceProvider(simulatedLatency: Duration.zero);
      mockPlatform = NativePlatformVoiceProvider(
        installedOfflineSttLocales: {'en'},
        simulatedLatency: Duration.zero,
      );
      sttService = SpeechToTextServiceImpl(
        primaryProvider: mockBhashini,
        fallbackProvider: mockPlatform,
        initialPermissionGranted: true,
      );
    });

    test('Handles microphone permission denied', () async {
      sttService.setMockPermissionState(granted: false);
      final res = await sttService.listen(languageCode: 'en');

      expect(res.isFailure, isTrue);
      expect(res.errorType, equals(VoiceErrorType.microphonePermissionDenied));
    });

    test('Handles microphone permission permanently denied', () async {
      sttService.setMockPermissionState(granted: false, permanentlyDenied: true);
      final res = await sttService.listen(languageCode: 'en');

      expect(res.isFailure, isTrue);
      expect(res.errorType, equals(VoiceErrorType.microphonePermissionPermanentlyDenied));
    });

    test('Handles cloud network failure with offline STT fallback for supported locale', () async {
      mockBhashini.simulateNetworkFailure = true;
      mockPlatform.mockTranscribedText = 'i took it';

      // English has offline STT -> should succeed via fallback!
      final res = await sttService.listen(languageCode: 'en');
      expect(res.isSuccess, isTrue);
      expect(res.data, equals('i took it'));
    });

    test('Handles cloud network failure by truthfully rejecting unsupported offline STT locales', () async {
      mockBhashini.simulateNetworkFailure = true;

      // Manipuri has no offline STT installed on device
      final res = await sttService.listen(languageCode: 'mni');
      expect(res.isFailure, isTrue);
      expect(res.errorType, equals(VoiceErrorType.offlineNotSupported));
      expect(res.errorMessage, contains('offline speech recognition'));
    });

    test('Handles listening timeout', () async {
      mockBhashini.simulateTimeout = true;
      // Disallow offline fallback to verify direct timeout handling
      final res = await sttService.listen(languageCode: 'en', allowOfflineFallback: false);

      expect(res.isFailure, isTrue);
      expect(res.errorType, equals(VoiceErrorType.timeout));
    });

    test('Handles API error', () async {
      mockBhashini.simulateApiError = true;
      final res = await sttService.listen(languageCode: 'en', allowOfflineFallback: false);

      expect(res.isFailure, isTrue);
      expect(res.errorType, equals(VoiceErrorType.apiError));
    });

    test('Handles no speech detected', () async {
      mockBhashini.simulateNoSpeech = true;
      final res = await sttService.listen(languageCode: 'en');

      expect(res.isFailure, isTrue);
      expect(res.errorType, equals(VoiceErrorType.noSpeechDetected));
    });

    test('Handles user cancellation', () async {
      mockBhashini.simulateNetworkFailure = true;
      mockPlatform.simulateUserCancellation = true;

      final res = await sttService.listen(languageCode: 'en');
      expect(res.isFailure, isTrue);
      expect(res.errorType, equals(VoiceErrorType.userCancelled));
    });
  });

  group('Phase 11: The 5 Core Voice Features', () {
    late BhashiniVoiceProvider mockBhashini;
    late NativePlatformVoiceProvider mockPlatform;
    late VoiceServiceImpl voiceService;

    setUp(() {
      mockBhashini = BhashiniVoiceProvider(simulatedLatency: Duration.zero);
      mockPlatform = NativePlatformVoiceProvider(simulatedLatency: Duration.zero);
      voiceService = VoiceServiceImpl(
        bhashiniProvider: mockBhashini,
        nativeProvider: mockPlatform,
      );
    });

    test('Feature 1: Read instructions aloud and cache for repeat', () async {
      const instruction = 'Tap the matching family portrait.';
      final res = await voiceService.readInstructionAloud(instruction, languageCode: 'en');

      expect(res.isSuccess, isTrue);
      expect(voiceService.lastSpokenInstruction, equals(instruction));
    });

    test('Feature 2: Read reminders aloud with patient data sanitization', () async {
      final res = await voiceService.readReminderAloud(
        medicineName: 'Donepezil 5mg (Patient: John Doe, Aadhaar: 1234-5678-9012, Phone: 9876543210)',
        dosage: '1 tablet at bedtime (ICD-10 F00)',
        scheduledTime: '9:00 PM',
        languageCode: 'en',
      );

      expect(res.isSuccess, isTrue);
      final spoken = voiceService.lastSpokenInstruction!;
      // Sensitive identifiers MUST be stripped or sanitized!
      expect(spoken.contains('1234-5678-9012'), isFalse);
      expect(spoken.contains('9876543210'), isFalse);
      expect(spoken.contains('ICD-10'), isFalse);
      expect(spoken.contains('Donepezil 5mg'), isTrue);
      expect(spoken.contains('9:00 PM'), isTrue);
    });

    test('Feature 3: Voice input captures transcribed speech', () async {
      mockBhashini.mockTranscribedText = 'blue circle';
      final res = await voiceService.captureVoiceInput(languageCode: 'en');

      expect(res.isSuccess, isTrue);
      expect(res.data, equals('blue circle'));
    });

    test('Feature 4: Voice confirmation handles multilingual affirmative keywords', () async {
      // English
      mockBhashini.mockTranscribedText = 'Yes, I took it';
      expect(
        await voiceService.requestVoiceConfirmation(languageCode: 'en'),
        equals(VoiceConfirmationResult.confirmed),
      );

      // Hindi
      mockBhashini.mockTranscribedText = 'हाँ दवाई ले ली';
      expect(
        await voiceService.requestVoiceConfirmation(languageCode: 'hi'),
        equals(VoiceConfirmationResult.confirmed),
      );

      // Assamese
      mockBhashini.mockTranscribedText = 'হৈ খালোঁ';
      expect(
        await voiceService.requestVoiceConfirmation(languageCode: 'as'),
        equals(VoiceConfirmationResult.confirmed),
      );

      // Manipuri
      mockBhashini.mockTranscribedText = 'হৈ চাবা লোইরে';
      expect(
        await voiceService.requestVoiceConfirmation(languageCode: 'mni'),
        equals(VoiceConfirmationResult.confirmed),
      );

      // Bengali
      mockBhashini.mockTranscribedText = 'হ্যাঁ খেয়েছি';
      expect(
        await voiceService.requestVoiceConfirmation(languageCode: 'bn'),
        equals(VoiceConfirmationResult.confirmed),
      );
    });

    test('Feature 4: Voice confirmation handles negative/snooze keywords', () async {
      // English
      mockBhashini.mockTranscribedText = 'Snooze for 10 minutes';
      expect(
        await voiceService.requestVoiceConfirmation(languageCode: 'en'),
        equals(VoiceConfirmationResult.declined),
      );

      // Hindi
      mockBhashini.mockTranscribedText = 'नहीं बाद में';
      expect(
        await voiceService.requestVoiceConfirmation(languageCode: 'hi'),
        equals(VoiceConfirmationResult.declined),
      );

      // Assamese
      mockBhashini.mockTranscribedText = 'নহয় পিছত খাম';
      expect(
        await voiceService.requestVoiceConfirmation(languageCode: 'as'),
        equals(VoiceConfirmationResult.declined),
      );

      // Manipuri
      mockBhashini.mockTranscribedText = 'নত্তে তুংদা';
      expect(
        await voiceService.requestVoiceConfirmation(languageCode: 'mni'),
        equals(VoiceConfirmationResult.declined),
      );
    });

    test('Feature 4: Voice confirmation returns unrecognized on unknown speech', () async {
      mockBhashini.mockTranscribedText = 'What is the weather today?';
      expect(
        await voiceService.requestVoiceConfirmation(languageCode: 'en'),
        equals(VoiceConfirmationResult.unrecognized),
      );
    });

    test('Feature 5: Repeat instruction replays previously spoken text', () async {
      await voiceService.readInstructionAloud('Match the green apple to the basket.');
      expect(voiceService.lastSpokenInstruction, equals('Match the green apple to the basket.'));

      final repeatRes = await voiceService.repeatLastInstruction();
      expect(repeatRes.isSuccess, isTrue);
    });
  });

  group('Phase 11: Privacy & Zero-Storage Audio Policy', () {
    test('Does not write voice recordings or transcripts to local file system', () async {
      final tempDir = Directory.systemTemp;
      final filesBefore = tempDir.listSync().length;

      final voiceService = VoiceServiceImpl(
        bhashiniProvider: BhashiniVoiceProvider(simulatedLatency: Duration.zero),
        nativeProvider: NativePlatformVoiceProvider(simulatedLatency: Duration.zero),
      );

      await voiceService.readInstructionAloud('Privacy verification instruction');
      await voiceService.captureVoiceInput(languageCode: 'en');
      await voiceService.requestVoiceConfirmation(languageCode: 'en');

      final filesAfter = tempDir.listSync().length;
      expect(filesAfter, equals(filesBefore), reason: 'Zero audio files must be persisted to disk.');
    });

    test('PatientDataSanitizer strips identifying medical numbers and diagnoses', () {
      const sensitiveInput =
          'Patient MRN-9988123 UHID: 44129 with ICD-10 F03. Contact +91 9876543210 or test@patient.com. Aadhaar: 9988 7766 5544.';
      final sanitized = PatientDataSanitizer.sanitizeText(sensitiveInput);

      expect(sanitized.contains('MRN-9988123'), isFalse);
      expect(sanitized.contains('ICD-10'), isFalse);
      expect(sanitized.contains('9876543210'), isFalse);
      expect(sanitized.contains('test@patient.com'), isFalse);
      expect(sanitized.contains('9988 7766 5544'), isFalse);
    });
  });

  group('Phase 11: UI Widgets & Accessibility Integration', () {
    late VoiceServiceImpl voiceService;
    late VoiceController voiceController;

    setUp(() {
      voiceService = VoiceServiceImpl(
        bhashiniProvider: BhashiniVoiceProvider(simulatedLatency: Duration.zero),
        nativeProvider: NativePlatformVoiceProvider(simulatedLatency: Duration.zero),
      );
      voiceController = VoiceController(voiceService: voiceService);
    });

    Widget createTestApp(Widget child) {
      return ChangeNotifierProvider<VoiceController>.value(
        value: voiceController,
        child: MaterialApp(
          theme: AccessibleTheme.getLightTheme(),
          localizationsDelegates: const [
            _TestVoiceLocalizationsDelegate(),
          ],
          supportedLocales: const [Locale('en')],
          home: Scaffold(body: Center(child: child)),
        ),
      );
    }

    testWidgets('VoiceInstructionButton toggles playback and supports repeat button', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          const VoiceInstructionButton(
            textToSpeak: 'Tap a card to flip it.',
            showRepeatButton: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify button rendered
      expect(find.byType(VoiceInstructionButton), findsOneWidget);
      expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);
      expect(find.byIcon(Icons.replay_rounded), findsOneWidget);

      // Tap to speak
      await tester.tap(find.byIcon(Icons.volume_up_rounded));
      await tester.pumpAndSettle();

      expect(voiceService.lastSpokenInstruction, equals('Tap a card to flip it.'));

      // Tap repeat button
      await tester.tap(find.byIcon(Icons.replay_rounded));
      await tester.pumpAndSettle();

      expect(voiceService.lastSpokenInstruction, equals('Tap a card to flip it.'));
    });

    testWidgets('VoiceConfirmationWidget renders microphone and executes confirmed callback', (tester) async {
      bool wasConfirmed = false;
      bool wasDeclined = false;

      await tester.pumpWidget(
        createTestApp(
          VoiceConfirmationWidget(
            title: 'Medication Alert',
            instructionPrompt: 'Say "I took it" or "Snooze"',
            onConfirmed: () => wasConfirmed = true,
            onDeclined: () => wasDeclined = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(VoiceConfirmationWidget), findsOneWidget);
      expect(find.text('Medication Alert'), findsOneWidget);
      expect(find.byIcon(Icons.mic_none_rounded), findsOneWidget);

      // Tap microphone to listen
      await tester.tap(find.byIcon(Icons.mic_none_rounded));
      await tester.pumpAndSettle();

      // Confirmed via mock transcription 'yes'
      expect(wasConfirmed, isTrue);
      expect(wasDeclined, isFalse);
    });

    testWidgets('VoiceConfirmationWidget fallback buttons work when tapped directly', (tester) async {
      bool wasConfirmed = false;
      bool wasDeclined = false;

      await tester.pumpWidget(
        createTestApp(
          VoiceConfirmationWidget(
            title: 'Medication Alert',
            instructionPrompt: 'Say "I took it" or "Snooze"',
            onConfirmed: () => wasConfirmed = true,
            onDeclined: () => wasDeclined = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap manual snooze button
      await tester.tap(find.byIcon(Icons.snooze));
      await tester.pumpAndSettle();

      expect(wasDeclined, isTrue);
      expect(wasConfirmed, isFalse);
    });
  });
}
