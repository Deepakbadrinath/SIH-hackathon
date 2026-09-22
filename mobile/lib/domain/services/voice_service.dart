enum VoiceProviderType {
  bhashini,
  nativePlatform,
  localAssetBank,
  mockTest,
}

enum VoiceErrorType {
  microphonePermissionDenied,
  microphonePermissionPermanentlyDenied,
  networkFailure,
  unsupportedLanguage,
  timeout,
  apiError,
  noSpeechDetected,
  userCancelled,
  offlineNotSupported,
  hardwareUnavailable,
  unknown,
}

class VoiceResult<T> {
  final bool isSuccess;
  final T? data;
  final VoiceErrorType? errorType;
  final String? errorMessage;

  const VoiceResult.success(this.data)
      : isSuccess = true,
        errorType = null,
        errorMessage = null;

  const VoiceResult.failure(this.errorType, [this.errorMessage])
      : isSuccess = false,
        data = null;

  bool get isFailure => !isSuccess;

  @override
  String toString() {
    if (isSuccess) return 'VoiceResult.success($data)';
    return 'VoiceResult.failure($errorType: $errorMessage)';
  }
}

enum VoiceConfirmationResult {
  confirmed,
  declined,
  unrecognized,
  cancelled,
  error,
}

class LanguageVoiceProfile {
  final String languageCode; // e.g., 'as', 'mni', 'bn', 'hi', 'en', etc.
  final String displayName;
  final String nativeName;
  final bool isSupportedByBhashini;
  final bool hasOfflineTts;
  final bool hasOfflineStt;
  final bool hasPreRecordedPrompts;

  const LanguageVoiceProfile({
    required this.languageCode,
    required this.displayName,
    this.nativeName = '',
    this.isSupportedByBhashini = false,
    this.hasOfflineTts = false,
    this.hasOfflineStt = false,
    this.hasPreRecordedPrompts = false,
  });

  bool get hasOfflineVoicePack => hasOfflineTts;
}

abstract class IVoiceProvider {
  VoiceProviderType get providerType;
  bool isLanguageSupported(String languageCode);
  bool isAvailableOffline();
  bool hasOfflineStt(String languageCode);
  bool hasOfflineTts(String languageCode);
  Future<VoiceResult<void>> speak(String text, String languageCode, {double rate = 1.0, double volume = 1.0});
  Future<void> stop();
  Future<VoiceResult<String>> listen({required String languageCode, Duration timeout = const Duration(seconds: 10)});
  Future<void> cancelListening();
}

/// Abstract contract for Speech Synthesis
abstract class TextToSpeechService {
  Future<VoiceResult<void>> speak(
    String text, {
    required String languageCode,
    double rate = 1.0,
    double volume = 1.0,
  });
  Future<void> stop();
  bool isLanguageSupported(String languageCode, {bool requiresOffline = false});
  bool get isSpeaking;
}

/// Abstract contract for Speech Recognition
abstract class SpeechToTextService {
  Future<VoiceResult<String>> listen({
    required String languageCode,
    Duration timeout = const Duration(seconds: 10),
    bool allowOfflineFallback = true,
  });
  Future<void> cancelListening();
  Future<bool> checkMicrophonePermission();
  Future<bool> requestMicrophonePermission();
  bool isLanguageSupported(String languageCode, {bool requiresOffline = false});
  bool hasOfflineStt(String languageCode);
  bool get isListening;
}

/// Orchestrator abstraction for regional voice interactions across the application
abstract class VoiceService {
  Future<void> initialize();

  // Core 5 Voice Features:
  // 1. Read instructions aloud
  Future<VoiceResult<void>> readInstructionAloud(
    String instruction, {
    String? languageCode,
    String? instructionKey,
    double rate = 1.0,
    double volume = 1.0,
  });

  // 2. Read reminders aloud (with PHI protection)
  Future<VoiceResult<void>> readReminderAloud({
    required String medicineName,
    required String dosage,
    required String scheduledTime,
    String? languageCode,
    double rate = 1.0,
    double volume = 1.0,
  });

  // 3. Voice input where supported
  Future<VoiceResult<String>> captureVoiceInput({
    required String languageCode,
    Duration timeout = const Duration(seconds: 10),
    bool allowOfflineFallback = true,
  });

  // 4. Voice confirmation ("Yes" / "No" / regional affirmations)
  Future<VoiceConfirmationResult> requestVoiceConfirmation({
    required String languageCode,
    List<String>? customAffirmatives,
    List<String>? customNegatives,
    Duration timeout = const Duration(seconds: 8),
  });

  // 5. Repeat instruction
  Future<VoiceResult<void>> repeatLastInstruction({
    String? fallbackInstruction,
    String? languageCode,
    double rate = 1.0,
    double volume = 1.0,
  });

  // Backward compatibility & lifecycle controls
  Future<void> speakInstruction({
    required String promptKey,
    required String fallbackText,
    required String languageCode,
  });
  Future<void> stopSpeaking();
  Future<void> stopAll();
  Future<String?> listenSpeech({
    required String languageCode,
    Duration timeout = const Duration(seconds: 10),
  });

  LanguageVoiceProfile getProfileForLanguage(String languageCode);
  List<LanguageVoiceProfile> getSupportedLanguages();
  bool canOperateOffline(String languageCode);
  bool canRecognizeOffline(String languageCode);

  String? get lastSpokenInstruction;
  bool get isSpeaking;
  bool get isListening;
  TextToSpeechService get ttsService;
  SpeechToTextService get sttService;
}
