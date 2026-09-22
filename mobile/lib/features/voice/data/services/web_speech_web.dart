// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:js' as js;

class WebSpeechPlatformBridge {
  static bool isSupported() {
    try {
      final voiceObj = js.context['smritiVoice'];
      if (voiceObj != null) {
        return voiceObj.callMethod('isAvailable') == true;
      }
      return js.context.hasProperty('speechSynthesis');
    } catch (_) {
      return false;
    }
  }

  static bool speak(
    String text, {
    required String languageCode,
    double rate = 0.88,
    double volume = 1.0,
  }) {
    try {
      final voiceObj = js.context['smritiVoice'];
      if (voiceObj != null) {
        final res = voiceObj.callMethod('speak', [text, languageCode, rate, volume]);
        return res == true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  static void stop() {
    try {
      final voiceObj = js.context['smritiVoice'];
      if (voiceObj != null) {
        voiceObj.callMethod('stop');
      }
    } catch (_) {}
  }

  static bool isSpeaking() {
    try {
      final voiceObj = js.context['smritiVoice'];
      if (voiceObj != null) {
        return voiceObj.callMethod('isSpeaking') == true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
