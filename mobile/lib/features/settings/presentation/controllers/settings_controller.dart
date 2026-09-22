import 'package:flutter/foundation.dart';

enum FontScalePreset {
  normal(1.0, 'Normal'),
  large(1.25, 'Large'),
  extraLarge(1.5, 'Extra Large');

  final double scale;
  final String label;
  const FontScalePreset(this.scale, this.label);
}

class SettingsController extends ChangeNotifier {
  bool _highContrast = false;
  double _fontScale = 1.25;
  bool _audioGuidanceEnabled = true;
  bool _reducedMotion = false;

  // Voice settings
  double _speechRate = 0.85; // Calibrated for elderly comprehension (slower)
  double _voicePitch = 1.0;
  double _speechVolume = 1.0;
  String _voiceGender = 'female'; // 'female' or 'male'

  bool get highContrast => _highContrast;
  double get fontScale => _fontScale;
  bool get audioGuidanceEnabled => _audioGuidanceEnabled;
  bool get reducedMotion => _reducedMotion;

  double get speechRate => _speechRate;
  double get voicePitch => _voicePitch;
  double get speechVolume => _speechVolume;
  String get voiceGender => _voiceGender;

  FontScalePreset get currentFontPreset {
    if (_fontScale <= 1.0) return FontScalePreset.normal;
    if (_fontScale <= 1.3) return FontScalePreset.large;
    return FontScalePreset.extraLarge;
  }

  void toggleHighContrast() {
    _highContrast = !_highContrast;
    notifyListeners();
  }

  void setHighContrast(bool value) {
    _highContrast = value;
    notifyListeners();
  }

  void setFontScale(double scale) {
    _fontScale = scale;
    notifyListeners();
  }

  void setFontPreset(FontScalePreset preset) {
    _fontScale = preset.scale;
    notifyListeners();
  }

  void toggleAudioGuidance() {
    _audioGuidanceEnabled = !_audioGuidanceEnabled;
    notifyListeners();
  }

  void setAudioGuidance(bool value) {
    _audioGuidanceEnabled = value;
    notifyListeners();
  }

  void toggleReducedMotion() {
    _reducedMotion = !_reducedMotion;
    notifyListeners();
  }

  void setReducedMotion(bool value) {
    _reducedMotion = value;
    notifyListeners();
  }

  void setSpeechRate(double rate) {
    _speechRate = rate.clamp(0.5, 1.5);
    notifyListeners();
  }

  void setVoicePitch(double pitch) {
    _voicePitch = pitch.clamp(0.5, 1.5);
    notifyListeners();
  }

  void setSpeechVolume(double volume) {
    _speechVolume = volume.clamp(0.0, 1.0);
    notifyListeners();
  }

  void setVoiceGender(String gender) {
    _voiceGender = gender;
    notifyListeners();
  }
}
