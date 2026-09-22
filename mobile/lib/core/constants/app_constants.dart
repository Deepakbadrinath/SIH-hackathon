class AppConstants {
  // App Identifiers
  static const String appName = 'SmritiSetu';
  static const String appTagline = 'Cognitive Memory Bridge for Elderly Care';
  static const String appVersion = '1.0.0';

  // Medical Positioning Disclaimer
  static const String medicalDisclaimer =
      'NOTICE: SmritiSetu is an assistive cognitive-support and non-clinical monitoring '
      'prototype. It does NOT medically diagnose dementia, Alzheimer\'s, or any neurological '
      'condition, nor does it replace professional medical consultation, treatment, or clinical prescriptions.';

  // Default Language & Dialect
  static const String defaultLanguage = 'as'; // Assamese as initial NE regional target
  static const String fallbackLanguage = 'en';

  // Accessibility Defaults
  static const double minTouchTargetSize = 56.0; // logical px
  static const double defaultFontScale = 1.25;
  static const double minBodyFontSize = 20.0;
  static const double minHeadingFontSize = 26.0;
  static const double minDisplayFontSize = 32.0;

  // Cognitive Game Parameters
  static const int minDifficultyLevel = 1;
  static const int maxDifficultyLevel = 5;
  static const int defaultTrialsPerSession = 5;
  static const double defaultAccuracyBaseline = 85.0;
  static const double defaultResponseTimeBaselineMs = 2400.0;

  // Sync Configuration
  static const int maxSyncBatchSize = 25;
  static const int maxSyncRetries = 5;
  static const int syncIntervalSeconds = 60;

  // REST API Endpoints
  static const String baseApiUrl = 'https://api.smritisetu.gov.in/api/v1';
  static const String syncBatchEndpoint = '/sync/batch';
  static const String authLoginEndpoint = '/auth/login';
}
