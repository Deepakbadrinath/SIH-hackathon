import 'package:flutter/foundation.dart';
import '../../../../domain/services/voice_service.dart';

/// Presentation controller orchestrating voice synthesis, speech recognition,
/// and voice confirmation for elderly accessibility across screens.
class VoiceController extends ChangeNotifier {
  final VoiceService _voiceService;

  bool _isPlaying = false;
  bool _isListening = false;
  String? _lastSpokenText;
  VoiceErrorType? _lastErrorType;
  String? _lastErrorMessage;

  VoiceController({required VoiceService voiceService}) : _voiceService = voiceService;

  VoiceService get voiceService => _voiceService;
  bool get isPlaying => _isPlaying;
  bool get isSpeaking => _isPlaying || _voiceService.isSpeaking;
  bool get isListening => _isListening || _voiceService.isListening;
  String? get lastSpokenText => _lastSpokenText ?? _voiceService.lastSpokenInstruction;
  String? get lastSpokenInstruction => _voiceService.lastSpokenInstruction;
  VoiceErrorType? get lastErrorType => _lastErrorType;
  String? get lastErrorMessage => _lastErrorMessage;

  void clearError() {
    _lastErrorType = null;
    _lastErrorMessage = null;
    notifyListeners();
  }

  /// FEATURE 1: Read instructions aloud
  Future<VoiceResult<void>> readInstructionAloud(
    String instruction, {
    String? languageCode = 'en',
    double rate = 1.0,
    double volume = 1.0,
  }) async {
    _isPlaying = true;
    _lastSpokenText = instruction;
    _lastErrorType = null;
    _lastErrorMessage = null;
    notifyListeners();

    try {
      final res = await _voiceService.readInstructionAloud(
        instruction,
        languageCode: languageCode,
        rate: rate,
        volume: volume,
      );
      if (res.isFailure) {
        _lastErrorType = res.errorType;
        _lastErrorMessage = res.errorMessage;
      }
      return res;
    } catch (e) {
      _lastErrorType = VoiceErrorType.unknown;
      _lastErrorMessage = e.toString();
      return VoiceResult.failure(VoiceErrorType.unknown, e.toString());
    } finally {
      _isPlaying = false;
      notifyListeners();
    }
  }

  /// FEATURE 2: Read reminders aloud (with PHI protection)
  Future<VoiceResult<void>> readReminderAloud({
    required String medicineName,
    required String dosage,
    required String scheduledTime,
    String? languageCode = 'en',
    double rate = 1.0,
    double volume = 1.0,
  }) async {
    _isPlaying = true;
    _lastErrorType = null;
    _lastErrorMessage = null;
    notifyListeners();

    try {
      final res = await _voiceService.readReminderAloud(
        medicineName: medicineName,
        dosage: dosage,
        scheduledTime: scheduledTime,
        languageCode: languageCode,
        rate: rate,
        volume: volume,
      );
      _lastSpokenText = _voiceService.lastSpokenInstruction;
      if (res.isFailure) {
        _lastErrorType = res.errorType;
        _lastErrorMessage = res.errorMessage;
      }
      return res;
    } catch (e) {
      _lastErrorType = VoiceErrorType.unknown;
      _lastErrorMessage = e.toString();
      return VoiceResult.failure(VoiceErrorType.unknown, e.toString());
    } finally {
      _isPlaying = false;
      notifyListeners();
    }
  }

  /// FEATURE 3: Voice input where supported
  Future<VoiceResult<String>> captureVoiceInput({
    required String languageCode,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    _isListening = true;
    _lastErrorType = null;
    _lastErrorMessage = null;
    notifyListeners();

    try {
      final res = await _voiceService.captureVoiceInput(
        languageCode: languageCode,
        timeout: timeout,
      );
      if (res.isFailure) {
        _lastErrorType = res.errorType;
        _lastErrorMessage = res.errorMessage;
      }
      return res;
    } catch (e) {
      _lastErrorType = VoiceErrorType.unknown;
      _lastErrorMessage = e.toString();
      return VoiceResult.failure(VoiceErrorType.unknown, e.toString());
    } finally {
      _isListening = false;
      notifyListeners();
    }
  }

  /// FEATURE 4: Voice confirmation ("Yes" / "No" / regional affirmations)
  Future<VoiceConfirmationResult> requestVoiceConfirmation({
    required String languageCode,
    List<String>? customAffirmatives,
    List<String>? customNegatives,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    _isListening = true;
    _lastErrorType = null;
    _lastErrorMessage = null;
    notifyListeners();

    try {
      return await _voiceService.requestVoiceConfirmation(
        languageCode: languageCode,
        customAffirmatives: customAffirmatives,
        customNegatives: customNegatives,
        timeout: timeout,
      );
    } catch (e) {
      _lastErrorType = VoiceErrorType.unknown;
      _lastErrorMessage = e.toString();
      return VoiceConfirmationResult.error;
    } finally {
      _isListening = false;
      notifyListeners();
    }
  }

  /// FEATURE 5: Repeat instruction button
  Future<VoiceResult<void>> repeatLastInstruction({
    String? fallbackInstruction,
    String? languageCode,
    double rate = 1.0,
    double volume = 1.0,
  }) async {
    _isPlaying = true;
    notifyListeners();

    try {
      return await _voiceService.repeatLastInstruction(
        fallbackInstruction: fallbackInstruction,
        languageCode: languageCode,
        rate: rate,
        volume: volume,
      );
    } finally {
      _isPlaying = false;
      notifyListeners();
    }
  }

  // Backward compatibility methods
  Future<void> speakPrompt({
    String? promptKey,
    required String text,
    String languageCode = 'en',
  }) async {
    await readInstructionAloud(text, languageCode: languageCode);
  }

  Future<void> speakText(String text, {String? promptKey, String languageCode = 'en'}) =>
      speakPrompt(promptKey: promptKey, text: text, languageCode: languageCode);

  Future<void> stop() async {
    await _voiceService.stopSpeaking();
    _isPlaying = false;
    notifyListeners();
  }

  Future<void> stopAll() async {
    await _voiceService.stopAll();
    _isPlaying = false;
    _isListening = false;
    notifyListeners();
  }
}
