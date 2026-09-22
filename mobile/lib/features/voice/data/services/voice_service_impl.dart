import 'dart:async';
import '../../../../domain/services/voice_service.dart';
import '../datasources/bhashini_voice_provider.dart';
import 'patient_data_sanitizer.dart';
import 'speech_to_text_service_impl.dart';
import 'text_to_speech_service_impl.dart';

/// Comprehensive implementation of VoiceService coordinating TextToSpeechService,
/// SpeechToTextService, and multi-lingual voice confirmation for elderly patients.
class VoiceServiceImpl implements VoiceService {
  final TextToSpeechService _ttsService;
  final SpeechToTextService _sttService;

  String? _lastSpokenInstruction;
  String _lastSpokenLanguageCode = 'en';

  VoiceServiceImpl({
    TextToSpeechService? ttsService,
    SpeechToTextService? sttService,
    IVoiceProvider? bhashiniProvider,
    IVoiceProvider? nativeProvider,
  })  : _ttsService = ttsService ??
            TextToSpeechServiceImpl(
              primaryProvider: bhashiniProvider ?? BhashiniVoiceProvider(),
              fallbackProvider: nativeProvider ?? NativePlatformVoiceProvider(),
            ),
        _sttService = sttService ??
            SpeechToTextServiceImpl(
              primaryProvider: bhashiniProvider ?? BhashiniVoiceProvider(),
              fallbackProvider: nativeProvider ?? NativePlatformVoiceProvider(),
            );

  @override
  TextToSpeechService get ttsService => _ttsService;

  @override
  SpeechToTextService get sttService => _sttService;

  @override
  String? get lastSpokenInstruction => _lastSpokenInstruction;

  @override
  bool get isSpeaking => _ttsService.isSpeaking;

  @override
  bool get isListening => _sttService.isListening;

  @override
  Future<void> initialize() async {
    // Initial warmup if necessary
  }

  // FEATURE 1: Read instructions aloud
  @override
  Future<VoiceResult<void>> readInstructionAloud(
    String instruction, {
    String? languageCode,
    String? instructionKey,
    double rate = 1.0,
    double volume = 1.0,
  }) async {
    final lang = languageCode ?? _lastSpokenLanguageCode;
    _lastSpokenInstruction = instruction;
    _lastSpokenLanguageCode = lang;

    return await _ttsService.speak(
      instruction,
      languageCode: lang,
      rate: rate,
      volume: volume,
    );
  }

  // FEATURE 2: Read reminders aloud with patient data sanitization
  @override
  Future<VoiceResult<void>> readReminderAloud({
    required String medicineName,
    required String dosage,
    required String scheduledTime,
    String? languageCode,
    double rate = 1.0,
    double volume = 1.0,
  }) async {
    final lang = languageCode ?? _lastSpokenLanguageCode;

    // Sanitize medicine & patient data to prevent any diagnostic leak
    final safeSpokenText = PatientDataSanitizer.buildSafeMedicationReminderText(
      medicineName: medicineName,
      dosage: dosage,
      scheduledTime: scheduledTime,
    );

    _lastSpokenInstruction = safeSpokenText;
    _lastSpokenLanguageCode = lang;

    return await _ttsService.speak(
      safeSpokenText,
      languageCode: lang,
      rate: rate,
      volume: volume,
    );
  }

  // FEATURE 3: Voice input where supported
  @override
  Future<VoiceResult<String>> captureVoiceInput({
    required String languageCode,
    Duration timeout = const Duration(seconds: 10),
    bool allowOfflineFallback = true,
  }) async {
    return await _sttService.listen(
      languageCode: languageCode,
      timeout: timeout,
      allowOfflineFallback: allowOfflineFallback,
    );
  }

  // FEATURE 4: Voice confirmation ("Yes" / "No" / regional affirmations)
  @override
  Future<VoiceConfirmationResult> requestVoiceConfirmation({
    required String languageCode,
    List<String>? customAffirmatives,
    List<String>? customNegatives,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final listenResult = await _sttService.listen(
      languageCode: languageCode,
      timeout: timeout,
    );

    if (listenResult.isFailure) {
      if (listenResult.errorType == VoiceErrorType.userCancelled) {
        return VoiceConfirmationResult.cancelled;
      }
      return VoiceConfirmationResult.error;
    }

    final rawSpokenText = listenResult.data?.trim().toLowerCase() ?? '';
    if (rawSpokenText.isEmpty) {
      return VoiceConfirmationResult.unrecognized;
    }

    // Build keyword dictionaries
    final affirmatives = <String>{
      ...?customAffirmatives?.map((e) => e.toLowerCase()),
      ..._getDefaultAffirmatives(languageCode),
    };

    final negatives = <String>{
      ...?customNegatives?.map((e) => e.toLowerCase()),
      ..._getDefaultNegatives(languageCode),
    };

    // Check affirmative match
    for (final term in affirmatives) {
      if (rawSpokenText.contains(term)) {
        return VoiceConfirmationResult.confirmed;
      }
    }

    // Check negative match
    for (final term in negatives) {
      if (rawSpokenText.contains(term)) {
        return VoiceConfirmationResult.declined;
      }
    }

    return VoiceConfirmationResult.unrecognized;
  }

  // FEATURE 5: Repeat instruction
  @override
  Future<VoiceResult<void>> repeatLastInstruction({
    String? fallbackInstruction,
    String? languageCode,
    double rate = 1.0,
    double volume = 1.0,
  }) async {
    final textToRepeat = _lastSpokenInstruction ?? fallbackInstruction;
    if (textToRepeat == null || textToRepeat.isEmpty) {
      return const VoiceResult.success(null);
    }

    final lang = languageCode ?? _lastSpokenLanguageCode;
    return await _ttsService.speak(
      textToRepeat,
      languageCode: lang,
      rate: rate,
      volume: volume,
    );
  }

  // Backward compatibility methods
  @override
  Future<void> speakInstruction({
    required String promptKey,
    required String fallbackText,
    required String languageCode,
  }) async {
    await readInstructionAloud(
      fallbackText,
      languageCode: languageCode,
      instructionKey: promptKey,
    );
  }

  @override
  Future<void> stopSpeaking() async {
    await _ttsService.stop();
  }

  @override
  Future<void> stopAll() async {
    await _ttsService.stop();
    await _sttService.cancelListening();
  }

  @override
  Future<String?> listenSpeech({
    required String languageCode,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final res = await captureVoiceInput(languageCode: languageCode, timeout: timeout);
    return res.data;
  }

  @override
  LanguageVoiceProfile getProfileForLanguage(String languageCode) {
    final code = languageCode.toLowerCase();
    final all = getSupportedLanguages();
    return all.firstWhere(
      (p) => p.languageCode == code,
      orElse: () => LanguageVoiceProfile(
        languageCode: code,
        displayName: code.toUpperCase(),
        nativeName: code.toUpperCase(),
        isSupportedByBhashini: false,
        hasOfflineTts: false,
        hasOfflineStt: false,
      ),
    );
  }

  @override
  List<LanguageVoiceProfile> getSupportedLanguages() {
    return const [
      LanguageVoiceProfile(
        languageCode: 'en',
        displayName: 'English',
        nativeName: 'English',
        isSupportedByBhashini: true,
        hasOfflineTts: true,
        hasOfflineStt: true, // Typical device default
        hasPreRecordedPrompts: true,
      ),
      LanguageVoiceProfile(
        languageCode: 'hi',
        displayName: 'Hindi',
        nativeName: 'हिन्दी',
        isSupportedByBhashini: true,
        hasOfflineTts: true,
        hasOfflineStt: false, // Truthful: Requires downloaded Google/OS pack
        hasPreRecordedPrompts: true,
      ),
      LanguageVoiceProfile(
        languageCode: 'as',
        displayName: 'Assamese',
        nativeName: 'অসমীয়া',
        isSupportedByBhashini: true,
        hasOfflineTts: false,
        hasOfflineStt: false, // Cloud-based via Bhashini
        hasPreRecordedPrompts: true,
      ),
      LanguageVoiceProfile(
        languageCode: 'mni',
        displayName: 'Manipuri',
        nativeName: 'মৈতৈলোন্',
        isSupportedByBhashini: true,
        hasOfflineTts: false,
        hasOfflineStt: false, // Cloud-based via Bhashini
        hasPreRecordedPrompts: true,
      ),
      LanguageVoiceProfile(
        languageCode: 'bn',
        displayName: 'Bengali',
        nativeName: 'বাংলা',
        isSupportedByBhashini: true,
        hasOfflineTts: false,
        hasOfflineStt: false,
        hasPreRecordedPrompts: true,
      ),
      LanguageVoiceProfile(
        languageCode: 'or',
        displayName: 'Odia',
        nativeName: 'ଓଡ଼ିଆ',
        isSupportedByBhashini: true,
        hasOfflineTts: false,
        hasOfflineStt: false,
        hasPreRecordedPrompts: true,
      ),
      LanguageVoiceProfile(
        languageCode: 'te',
        displayName: 'Telugu',
        nativeName: 'తెలుగు',
        isSupportedByBhashini: true,
        hasOfflineTts: false,
        hasOfflineStt: false,
        hasPreRecordedPrompts: true,
      ),
      LanguageVoiceProfile(
        languageCode: 'ta',
        displayName: 'Tamil',
        nativeName: 'தமிழ்',
        isSupportedByBhashini: true,
        hasOfflineTts: false,
        hasOfflineStt: false,
        hasPreRecordedPrompts: true,
      ),
      LanguageVoiceProfile(
        languageCode: 'kn',
        displayName: 'Kannada',
        nativeName: 'ಕನ್ನಡ',
        isSupportedByBhashini: true,
        hasOfflineTts: false,
        hasOfflineStt: false,
        hasPreRecordedPrompts: true,
      ),
      LanguageVoiceProfile(
        languageCode: 'ml',
        displayName: 'Malayalam',
        nativeName: 'മലയാളം',
        isSupportedByBhashini: true,
        hasOfflineTts: false,
        hasOfflineStt: false,
        hasPreRecordedPrompts: true,
      ),
      LanguageVoiceProfile(
        languageCode: 'mr',
        displayName: 'Marathi',
        nativeName: 'मराठी',
        isSupportedByBhashini: true,
        hasOfflineTts: false,
        hasOfflineStt: false,
        hasPreRecordedPrompts: true,
      ),
      LanguageVoiceProfile(
        languageCode: 'gu',
        displayName: 'Gujarati',
        nativeName: 'ગુજરાતી',
        isSupportedByBhashini: true,
        hasOfflineTts: false,
        hasOfflineStt: false,
        hasPreRecordedPrompts: true,
      ),
      LanguageVoiceProfile(
        languageCode: 'pa',
        displayName: 'Punjabi',
        nativeName: 'ਪੰਜਾਬੀ',
        isSupportedByBhashini: true,
        hasOfflineTts: false,
        hasOfflineStt: false,
        hasPreRecordedPrompts: true,
      ),
      LanguageVoiceProfile(
        languageCode: 'ur',
        displayName: 'Urdu',
        nativeName: 'اردو',
        isSupportedByBhashini: true,
        hasOfflineTts: false,
        hasOfflineStt: false,
        hasPreRecordedPrompts: true,
      ),
    ];
  }

  @override
  bool canOperateOffline(String languageCode) {
    return _ttsService.isLanguageSupported(languageCode, requiresOffline: true);
  }

  @override
  bool canRecognizeOffline(String languageCode) {
    return _sttService.hasOfflineStt(languageCode);
  }

  Set<String> _getDefaultAffirmatives(String languageCode) {
    const commonEnglish = {'yes', 'taken', 'took it', 'done', 'i took it', 'confirm', 'ok', 'already'};
    switch (languageCode.toLowerCase()) {
      case 'hi':
        return {...commonEnglish, 'हाँ', 'हाँ ले ली', 'ले ली', 'खा ली', 'लिया', 'हो गया', 'हाँजी'};
      case 'as':
        return {...commonEnglish, 'হৈ', 'খালোঁ', 'ললোঁ', 'ঠিক আছে', 'খাইছো'};
      case 'mni':
        return {...commonEnglish, 'হৈ', 'য়ারে', 'চাবা লোইরে', 'লোইরে'};
      case 'bn':
        return {...commonEnglish, 'হ্যাঁ', 'খেয়েছি', 'নিয়েছি', 'ঠিক আছে', 'হাঁ'};
      case 'or':
        return {...commonEnglish, 'ହଁ', 'ଖାଇଲି', 'ନେଇଛି'};
      case 'te':
        return {...commonEnglish, 'అవును', 'వేసుకున్నాను', 'తీసుకున్నాను'};
      case 'ta':
        return {...commonEnglish, 'ஆம்', 'எடுத்துக்கொண்டேன்', 'சாப்பிட்டேன்'};
      case 'kn':
        return {...commonEnglish, 'ಹೌದು', 'ತೆಗೆದುಕೊಂಡಿದ್ದೇನೆ', 'ಆಯಿತು'};
      case 'ml':
        return {...commonEnglish, 'അതെ', 'കഴിച്ചു', 'എടുത്തു'};
      case 'mr':
        return {...commonEnglish, 'हो', 'घेतली', 'खाल्ली'};
      case 'gu':
        return {...commonEnglish, 'હા', 'લીધી', 'લઇ લીધી'};
      case 'pa':
        return {...commonEnglish, 'ਹਾਂ', 'ਲੈ ਲਈ', 'ਖਾ ਲਈ'};
      case 'ur':
        return {...commonEnglish, 'ہاں', 'لے لی', 'کھا لی'};
      case 'en':
      default:
        return commonEnglish;
    }
  }

  Set<String> _getDefaultNegatives(String languageCode) {
    const commonEnglish = {'no', 'snooze', 'not yet', 'later', 'cancel', 'skip'};
    switch (languageCode.toLowerCase()) {
      case 'hi':
        return {...commonEnglish, 'नहीं', 'नहीं ली', 'बाद में', 'अलार्म', 'रोको'};
      case 'as':
        return {...commonEnglish, 'নহয়', 'পিছত', 'পাছত', 'নাই লোৱা'};
      case 'mni':
        return {...commonEnglish, 'নত্তে', 'তুংদা', 'য়াদে'};
      case 'bn':
        return {...commonEnglish, 'না', 'পরে', 'স্নুজ', 'এখন না'};
      case 'or':
        return {...commonEnglish, 'ନାହିଁ', 'ପରେ'};
      case 'te':
        return {...commonEnglish, 'లేదు', 'తర్వాత'};
      case 'ta':
        return {...commonEnglish, 'இல்லை', 'பிறகு'};
      case 'kn':
        return {...commonEnglish, 'ಇಲ್ಲ', 'ನಂತರ'};
      case 'ml':
        return {...commonEnglish, 'ഇല്ല', 'പിന്നെ'};
      case 'mr':
        return {...commonEnglish, 'नाही', 'नंतर'};
      case 'gu':
        return {...commonEnglish, 'ના', 'પછી'};
      case 'pa':
        return {...commonEnglish, 'ਨਹੀਂ', 'ਬਾਅਦ ਵਿੱਚ'};
      case 'ur':
        return {...commonEnglish, 'نہیں', 'بعد میں'};
      case 'en':
      default:
        return commonEnglish;
    }
  }
}
