import 'web_speech_stub.dart'
    if (dart.library.js) 'web_speech_web.dart';

class WebSpeechBridge {
  static bool get isSupported => WebSpeechPlatformBridge.isSupported();

  static bool speak(
    String text, {
    required String languageCode,
    double rate = 0.88,
    double volume = 1.0,
  }) {
    return WebSpeechPlatformBridge.speak(
      text,
      languageCode: languageCode,
      rate: rate,
      volume: volume,
    );
  }

  static void stop() => WebSpeechPlatformBridge.stop();

  static bool get isSpeaking => WebSpeechPlatformBridge.isSpeaking();
}
