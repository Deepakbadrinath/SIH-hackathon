class WebSpeechPlatformBridge {
  static bool isSupported() => false;

  static bool speak(
    String text, {
    required String languageCode,
    double rate = 0.88,
    double volume = 1.0,
  }) =>
      false;

  static void stop() {}

  static bool isSpeaking() => false;
}
