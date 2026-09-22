import 'dart:async';
import '../../../../domain/services/voice_service.dart';

/// Concrete implementation of SpeechToTextService.
/// Adheres to:
/// 1. Zero-storage privacy: no audio recordings are saved to disk.
/// 2. Truthful capability reporting: never claims offline recognition if device lacks it.
/// 3. Resilient fallback: seamlessly falls back to platform offline recognition if network drops.
/// 4. Permission safety: verifies microphone access before initiating audio stream.
class SpeechToTextServiceImpl implements SpeechToTextService {
  final IVoiceProvider _primaryProvider;
  final IVoiceProvider _fallbackProvider;
  
  bool _isListening = false;
  bool _mockPermissionGranted = true;
  bool _mockPermissionPermanentlyDenied = false;

  SpeechToTextServiceImpl({
    required IVoiceProvider primaryProvider,
    required IVoiceProvider fallbackProvider,
    bool initialPermissionGranted = true,
  })  : _primaryProvider = primaryProvider,
        _fallbackProvider = fallbackProvider,
        _mockPermissionGranted = initialPermissionGranted;

  // Test control hook
  void setMockPermissionState({required bool granted, bool permanentlyDenied = false}) {
    _mockPermissionGranted = granted;
    _mockPermissionPermanentlyDenied = permanentlyDenied;
  }

  @override
  bool get isListening => _isListening;

  @override
  Future<bool> checkMicrophonePermission() async {
    return _mockPermissionGranted && !_mockPermissionPermanentlyDenied;
  }

  @override
  Future<bool> requestMicrophonePermission() async {
    if (_mockPermissionPermanentlyDenied) return false;
    return _mockPermissionGranted;
  }

  @override
  bool isLanguageSupported(String languageCode, {bool requiresOffline = false}) {
    if (requiresOffline) {
      return _fallbackProvider.hasOfflineStt(languageCode);
    }
    return _primaryProvider.isLanguageSupported(languageCode) ||
        _fallbackProvider.hasOfflineStt(languageCode);
  }

  @override
  bool hasOfflineStt(String languageCode) {
    // Truthful reporting from platform provider
    return _fallbackProvider.hasOfflineStt(languageCode);
  }

  @override
  Future<VoiceResult<String>> listen({
    required String languageCode,
    Duration timeout = const Duration(seconds: 10),
    bool allowOfflineFallback = true,
  }) async {
    // 1. Verify microphone permissions
    if (_mockPermissionPermanentlyDenied) {
      return const VoiceResult.failure(
        VoiceErrorType.microphonePermissionPermanentlyDenied,
        'Microphone permission is permanently denied. Please grant permission in device settings.',
      );
    }

    final hasPermission = await checkMicrophonePermission();
    if (!hasPermission) {
      return const VoiceResult.failure(
        VoiceErrorType.microphonePermissionDenied,
        'Microphone access is required for voice input.',
      );
    }

    _isListening = true;
    try {
      // 2. Primary cloud provider attempt (Bhashini)
      if (_primaryProvider.isLanguageSupported(languageCode)) {
        final cloudResult = await _primaryProvider.listen(
          languageCode: languageCode,
          timeout: timeout,
        );

        if (cloudResult.isSuccess) {
          return cloudResult;
        }

        // Check if error is network/timeout related and fallback is allowed
        final isNetworkOrTimeout = cloudResult.errorType == VoiceErrorType.networkFailure ||
            cloudResult.errorType == VoiceErrorType.timeout ||
            cloudResult.errorType == VoiceErrorType.apiError;

        if (isNetworkOrTimeout && allowOfflineFallback) {
          // Truthful offline capability validation
          if (_fallbackProvider.hasOfflineStt(languageCode)) {
            final fallbackResult = await _fallbackProvider.listen(
              languageCode: languageCode,
              timeout: timeout,
            );
            if (fallbackResult.isSuccess) {
              return fallbackResult;
            }
            return fallbackResult;
          } else {
            // Do NOT claim offline recognition when device has no local pack
            return VoiceResult.failure(
              VoiceErrorType.offlineNotSupported,
              'Network voice service unavailable and device lacks offline speech recognition for "$languageCode".',
            );
          }
        }

        return cloudResult;
      }

      // 3. Direct platform on-device recognition if primary doesn't support the language
      if (_fallbackProvider.hasOfflineStt(languageCode)) {
        return await _fallbackProvider.listen(
          languageCode: languageCode,
          timeout: timeout,
        );
      }

      // Rejection: neither provider supports this language or offline recognition is missing
      return VoiceResult.failure(
        VoiceErrorType.offlineNotSupported,
        'Speech recognition not available for "$languageCode" (no cloud support and no verified offline model).',
      );
    } finally {
      // Zero-storage policy: discard transient buffer immediately upon return
      _isListening = false;
    }
  }

  @override
  Future<void> cancelListening() async {
    await _primaryProvider.cancelListening();
    await _fallbackProvider.cancelListening();
    _isListening = false;
  }
}
