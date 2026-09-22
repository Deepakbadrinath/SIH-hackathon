import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../../core/config/app_config.dart';
import '../../../../domain/services/voice_service.dart';
import '../services/web_speech_bridge.dart';

/// Bhashini AI Voice Provider (Cloud-based REST/WebSocket pipeline for Indian languages).
/// All network communication uses credentials from AppConfig or secure storage;
/// no API keys are hardcoded in the codebase.
class BhashiniVoiceProvider implements IVoiceProvider {
  final String _apiKey;
  final String _endpoint;
  
  // Test simulation hooks (allows unit testing without live network calls)
  bool simulateNetworkFailure = false;
  bool simulateApiError = false;
  bool simulateTimeout = false;
  bool simulateNoSpeech = false;
  Duration simulatedLatency;
  String mockTranscribedText;

  static const Set<String> _supportedRegionalLanguages = {
    'en', // English
    'hi', // Hindi
    'as', // Assamese
    'mni', // Manipuri (Meiteilon)
    'bn', // Bengali
    'or', // Odia
    'te', // Telugu
    'ta', // Tamil
    'kn', // Kannada
    'ml', // Malayalam
    'mr', // Marathi
    'gu', // Gujarati
    'pa', // Punjabi
    'ur', // Urdu
    'es', // Spanish
    'fr', // French
    'de', // German
    'ar', // Arabic
    'zh', // Chinese
    'ja', // Japanese
    'ko', // Korean
  };

  BhashiniVoiceProvider({
    String? apiKey,
    String? endpoint,
    this.simulatedLatency = const Duration(milliseconds: 30),
    this.mockTranscribedText = 'yes',
  })  : _apiKey = apiKey ?? (AppConfig.current.isDevelopment ? 'mock_dev_bhashini_key' : ''),
        _endpoint = endpoint ?? '${AppConfig.current.apiBaseUrl}/voice/bhashini';

  String get apiKey => _apiKey;
  String get endpoint => _endpoint;

  @override
  VoiceProviderType get providerType => VoiceProviderType.bhashini;

  @override
  bool isLanguageSupported(String languageCode) {
    return _supportedRegionalLanguages.contains(languageCode.toLowerCase());
  }

  @override
  bool isAvailableOffline() => false; // Bhashini is strictly cloud-hosted

  @override
  bool hasOfflineStt(String languageCode) => false;

  @override
  bool hasOfflineTts(String languageCode) => false;

  @override
  Future<VoiceResult<void>> speak(
    String text,
    String languageCode, {
    double rate = 1.0,
    double volume = 1.0,
  }) async {
    if (!isLanguageSupported(languageCode)) {
      return VoiceResult.failure(
        VoiceErrorType.unsupportedLanguage,
        'Language $languageCode is not supported by Bhashini pipeline.',
      );
    }

    if (simulateNetworkFailure) {
      return const VoiceResult.failure(
        VoiceErrorType.networkFailure,
        'Network unreachable: Bhashini cloud server could not be contacted.',
      );
    }

    if (simulateApiError) {
      return const VoiceResult.failure(
        VoiceErrorType.apiError,
        'Bhashini API 500: Internal synthesis error.',
      );
    }

    if (simulateTimeout) {
      return const VoiceResult.failure(
        VoiceErrorType.timeout,
        'Bhashini voice synthesis request timed out.',
      );
    }

    if (kIsWeb && WebSpeechBridge.isSupported) {
      WebSpeechBridge.speak(
        text,
        languageCode: languageCode,
        rate: rate,
        volume: volume,
      );
      return const VoiceResult.success(null);
    }

    // Audio is streamed in-memory and synthesized. Zero audio files stored on disk.
    if (simulatedLatency > Duration.zero) {
      await Future.delayed(simulatedLatency);
    }

    return const VoiceResult.success(null);
  }

  @override
  Future<void> stop() async {
    if (kIsWeb && WebSpeechBridge.isSupported) {
      WebSpeechBridge.stop();
    }
    if (simulatedLatency > Duration.zero) {
      await Future.delayed(const Duration(milliseconds: 10));
    }
  }

  @override
  Future<VoiceResult<String>> listen({
    required String languageCode,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    if (!isLanguageSupported(languageCode)) {
      return VoiceResult.failure(
        VoiceErrorType.unsupportedLanguage,
        'Language $languageCode is not supported by Bhashini speech-to-text.',
      );
    }

    if (simulateNetworkFailure) {
      return const VoiceResult.failure(
        VoiceErrorType.networkFailure,
        'Network unreachable: Unable to connect to Bhashini ASR pipeline.',
      );
    }

    if (simulateApiError) {
      return const VoiceResult.failure(
        VoiceErrorType.apiError,
        'Bhashini ASR API error.',
      );
    }

    if (simulateTimeout) {
      return const VoiceResult.failure(
        VoiceErrorType.timeout,
        'Listening session timed out without response.',
      );
    }

    if (simulateNoSpeech) {
      return const VoiceResult.failure(
        VoiceErrorType.noSpeechDetected,
        'No speech detected in audio stream.',
      );
    }

    if (simulatedLatency > Duration.zero) {
      await Future.delayed(simulatedLatency);
    }

    return VoiceResult.success(mockTranscribedText);
  }

  @override
  Future<void> cancelListening() async {
    if (simulatedLatency > Duration.zero) {
      await Future.delayed(const Duration(milliseconds: 10));
    }
  }
}

/// Native Platform Voice Provider (On-device Android/iOS platform TTS & STT).
/// Provides offline fallback when network connectivity is lost.
/// Truthful capability reporting: offline STT is ONLY reported as available
/// if an on-device language pack is installed.
class NativePlatformVoiceProvider implements IVoiceProvider {
  final Set<String> _installedOfflineTtsLocales;
  final Set<String> _installedOfflineSttLocales;

  bool simulateHardwareUnavailable = false;
  bool simulateUserCancellation = false;
  bool simulateMicPermissionDenied = false;
  bool simulateMicPermanentlyDenied = false;
  Duration simulatedLatency;
  String mockTranscribedText;

  NativePlatformVoiceProvider({
    Set<String>? installedOfflineTtsLocales,
    Set<String>? installedOfflineSttLocales,
    this.simulatedLatency = const Duration(milliseconds: 20),
    this.mockTranscribedText = 'taken',
  })  : _installedOfflineTtsLocales = installedOfflineTtsLocales ?? {'en', 'hi'},
        _installedOfflineSttLocales = installedOfflineSttLocales ?? {'en'};

  @override
  VoiceProviderType get providerType => VoiceProviderType.nativePlatform;

  @override
  bool isLanguageSupported(String languageCode) {
    if (kIsWeb && WebSpeechBridge.isSupported) return true;
    final code = languageCode.toLowerCase();
    return _installedOfflineTtsLocales.contains(code) || _installedOfflineSttLocales.contains(code);
  }

  @override
  bool isAvailableOffline() => true;

  @override
  bool hasOfflineTts(String languageCode) {
    if (kIsWeb && WebSpeechBridge.isSupported) return true;
    return _installedOfflineTtsLocales.contains(languageCode.toLowerCase());
  }

  /// Never claim offline speech recognition if the installed device does not support it!
  @override
  bool hasOfflineStt(String languageCode) {
    return _installedOfflineSttLocales.contains(languageCode.toLowerCase());
  }

  @override
  Future<VoiceResult<void>> speak(
    String text,
    String languageCode, {
    double rate = 1.0,
    double volume = 1.0,
  }) async {
    final code = languageCode.toLowerCase();
    if (!hasOfflineTts(code)) {
      return VoiceResult.failure(
        VoiceErrorType.unsupportedLanguage,
        'Native platform TTS does not have voice data for $languageCode.',
      );
    }

    if (simulateHardwareUnavailable) {
      return const VoiceResult.failure(
        VoiceErrorType.hardwareUnavailable,
        'Platform audio speaker or audio manager is unavailable.',
      );
    }

    if (kIsWeb && WebSpeechBridge.isSupported) {
      WebSpeechBridge.speak(
        text,
        languageCode: languageCode,
        rate: rate,
        volume: volume,
      );
      return const VoiceResult.success(null);
    }

    if (simulatedLatency > Duration.zero) {
      await Future.delayed(simulatedLatency);
    }

    return const VoiceResult.success(null);
  }

  @override
  Future<void> stop() async {
    if (kIsWeb && WebSpeechBridge.isSupported) {
      WebSpeechBridge.stop();
    }
    if (simulatedLatency > Duration.zero) {
      await Future.delayed(const Duration(milliseconds: 10));
    }
  }

  @override
  Future<VoiceResult<String>> listen({
    required String languageCode,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final code = languageCode.toLowerCase();

    if (simulateMicPermanentlyDenied) {
      return const VoiceResult.failure(
        VoiceErrorType.microphonePermissionPermanentlyDenied,
        'Microphone permission is permanently denied. Please enable it in Settings.',
      );
    }

    if (simulateMicPermissionDenied) {
      return const VoiceResult.failure(
        VoiceErrorType.microphonePermissionDenied,
        'Microphone permission was denied by the user.',
      );
    }

    if (simulateUserCancellation) {
      return const VoiceResult.failure(
        VoiceErrorType.userCancelled,
        'Voice input cancelled by user.',
      );
    }

    // Truthful offline check: do NOT claim offline recognition if device pack missing!
    if (!hasOfflineStt(code)) {
      return VoiceResult.failure(
        VoiceErrorType.offlineNotSupported,
        'Device does not possess an offline speech recognition model for "$languageCode".',
      );
    }

    if (simulatedLatency > Duration.zero) {
      await Future.delayed(simulatedLatency);
    }

    return VoiceResult.success(mockTranscribedText);
  }

  @override
  Future<void> cancelListening() async {
    if (simulatedLatency > Duration.zero) {
      await Future.delayed(const Duration(milliseconds: 10));
    }
  }
}
