class Patient {
  final String id;
  final String userId;
  final String displayName;
  final int? birthYear;
  final String? emergencyContactPhone;
  final String regionalDialect;
  final bool highContrastEnabled;
  final bool audioInstructionsEnabled;
  final double fontScale;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;

  const Patient({
    required this.id,
    required this.userId,
    required this.displayName,
    this.birthYear,
    this.emergencyContactPhone,
    this.regionalDialect = 'as_IN',
    this.highContrastEnabled = true,
    this.audioInstructionsEnabled = true,
    this.fontScale = 1.25,
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'display_name': displayName,
      'birth_year': birthYear,
      'emergency_contact_phone': emergencyContactPhone,
      'regional_dialect': regionalDialect,
      'high_contrast_enabled': highContrastEnabled ? 1 : 0,
      'audio_instructions_enabled': audioInstructionsEnabled ? 1 : 0,
      'font_scale': fontScale,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
    };
  }

  factory Patient.fromMap(Map<String, dynamic> map) {
    return Patient(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      displayName: map['display_name'] as String,
      birthYear: map['birth_year'] as int?,
      emergencyContactPhone: map['emergency_contact_phone'] as String?,
      regionalDialect: (map['regional_dialect'] as String?) ?? 'as_IN',
      highContrastEnabled: (map['high_contrast_enabled'] as int?) == 1,
      audioInstructionsEnabled: (map['audio_instructions_enabled'] as int?) == 1,
      fontScale: (map['font_scale'] as num?)?.toDouble() ?? 1.25,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      isSynced: (map['is_synced'] as int?) == 1,
    );
  }

  Patient copyWith({
    String? id,
    String? userId,
    String? displayName,
    int? birthYear,
    String? emergencyContactPhone,
    String? regionalDialect,
    bool? highContrastEnabled,
    bool? audioInstructionsEnabled,
    double? fontScale,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
  }) {
    return Patient(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      birthYear: birthYear ?? this.birthYear,
      emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
      regionalDialect: regionalDialect ?? this.regionalDialect,
      highContrastEnabled: highContrastEnabled ?? this.highContrastEnabled,
      audioInstructionsEnabled: audioInstructionsEnabled ?? this.audioInstructionsEnabled,
      fontScale: fontScale ?? this.fontScale,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
