import '../../../../domain/services/voice_service.dart';

/// Concrete implementation of TextToSpeechService.
/// Manages speech synthesis routing: attempts primary cloud provider (Bhashini)
/// and seamlessly falls back to native on-device platform TTS if network fails.
class TextToSpeechServiceImpl implements TextToSpeechService {
  final IVoiceProvider _primaryProvider;
  final IVoiceProvider _fallbackProvider;
  bool _isSpeaking = false;

  TextToSpeechServiceImpl({
    required IVoiceProvider primaryProvider,
    required IVoiceProvider fallbackProvider,
  })  : _primaryProvider = primaryProvider,
        _fallbackProvider = fallbackProvider;

  @override
  bool get isSpeaking => _isSpeaking;

  @override
  bool isLanguageSupported(String languageCode, {bool requiresOffline = false}) {
    if (requiresOffline) {
      return _fallbackProvider.hasOfflineTts(languageCode);
    }
    return _primaryProvider.isLanguageSupported(languageCode) ||
        _fallbackProvider.isLanguageSupported(languageCode);
  }

  @override
  Future<VoiceResult<void>> speak(
    String text, {
    required String languageCode,
    double rate = 1.0,
    double volume = 1.0,
  }) async {
    if (text.trim().isEmpty) {
      return const VoiceResult.success(null);
    }

    _isSpeaking = true;
    try {
      // 1. Check if primary cloud provider supports the language
      if (_primaryProvider.isLanguageSupported(languageCode)) {
        final cloudResult = await _primaryProvider.speak(
          text,
          languageCode,
          rate: rate,
          volume: volume,
        );

        if (cloudResult.isSuccess) {
          return cloudResult;
        }

        // If cloud fails due to network or API error, attempt platform offline fallback
        if (cloudResult.errorType == VoiceErrorType.networkFailure ||
            cloudResult.errorType == VoiceErrorType.apiError ||
            cloudResult.errorType == VoiceErrorType.timeout) {
          if (_fallbackProvider.hasOfflineTts(languageCode)) {
            final fallbackResult = await _fallbackProvider.speak(
              text,
              languageCode,
              rate: rate,
              volume: volume,
            );
            if (fallbackResult.isSuccess) {
              return fallbackResult;
            }
          }
        }

        return cloudResult;
      }

      // 2. Direct fallback if primary provider doesn't support the language
      if (_fallbackProvider.hasOfflineTts(languageCode)) {
        return await _fallbackProvider.speak(
          text,
          languageCode,
          rate: rate,
          volume: volume,
        );
      }

      return VoiceResult.failure(
        VoiceErrorType.unsupportedLanguage,
        'Neither cloud nor platform voice synthesis supports language: $languageCode',
      );
    } finally {
      _isSpeaking = false;
    }
  }

  @override
  Future<void> stop() async {
    await _primaryProvider.stop();
    await _fallbackProvider.stop();
    _isSpeaking = false;
  }
}
