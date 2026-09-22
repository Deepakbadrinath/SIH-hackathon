/// Utility to sanitize patient data prior to passing text to third-party or cloud voice pipelines.
/// Adheres to healthcare privacy standards (NDHM, HIPAA, GDPR): strips MRNs, diagnostic codes,
/// phone numbers, Aadhaar/ID numbers, and sensitive diagnostic annotations.
class PatientDataSanitizer {
  static final RegExp _phoneRegex = RegExp(r'(\+91[\-\s]?)?[6789]\d{9}');
  static final RegExp _aadhaarRegex = RegExp(r'\b\d{4}[\s\-]?\d{4}[\s\-]?\d{4}\b');
  static final RegExp _emailRegex = RegExp(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}');
  static final RegExp _mrnRegex = RegExp(r'\b(MRN|UHID|PATIENT_ID|PID)[:\s-]*[A-Z0-9]+\b', caseSensitive: false);
  static final RegExp _icdRegex = RegExp(r'\b(ICD[-0-9]*|DIAGNOSIS)[:\s-]*[A-Z0-9\.]+\b', caseSensitive: false);

  /// Sanitizes generic instruction or prompt text
  static String sanitizeText(String input) {
    if (input.isEmpty) return input;

    String sanitized = input;
    sanitized = sanitized.replaceAll(_phoneRegex, '[PHONE]');
    sanitized = sanitized.replaceAll(_aadhaarRegex, '[ID]');
    sanitized = sanitized.replaceAll(_emailRegex, '[EMAIL]');
    sanitized = sanitized.replaceAll(_mrnRegex, '');
    sanitized = sanitized.replaceAll(_icdRegex, '');

    // Remove any accidental JSON/code artifacts
    sanitized = sanitized.replaceAll(RegExp(r'\{[^\}]*\}'), '');

    return sanitized.trim();
  }

  /// Builds a safe, non-sensitive reminder speech string containing only
  /// essential assistive information (medicine name, dosage, time).
  static String buildSafeMedicationReminderText({
    required String medicineName,
    required String dosage,
    required String scheduledTime,
    String? prefix,
  }) {
    final cleanMedName = sanitizeText(medicineName);
    final cleanDosage = sanitizeText(dosage);
    final cleanTime = sanitizeText(scheduledTime);

    final intro = prefix ?? 'Reminder:';
    return '$intro $cleanMedName. $cleanDosage. Scheduled for $cleanTime.';
  }
}
