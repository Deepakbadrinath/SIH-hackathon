enum UserRole { patient, caregiver }

class User {
  final String id;
  final String phoneOrEmail;
  final UserRole role;
  final String fullName;
  final String preferredLanguage;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;

  const User({
    required this.id,
    required this.phoneOrEmail,
    required this.role,
    required this.fullName,
    this.preferredLanguage = 'en',
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'phone_or_email': phoneOrEmail,
      'role': role == UserRole.patient ? 'PATIENT' : 'CAREGIVER',
      'full_name': fullName,
      'preferred_language': preferredLanguage,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as String,
      phoneOrEmail: map['phone_or_email'] as String,
      role: (map['role'] as String).toUpperCase() == 'PATIENT'
          ? UserRole.patient
          : UserRole.caregiver,
      fullName: map['full_name'] as String,
      preferredLanguage: (map['preferred_language'] as String?) ?? 'en',
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      isSynced: (map['is_synced'] as int?) == 1,
    );
  }

  User copyWith({
    String? id,
    String? phoneOrEmail,
    UserRole? role,
    String? fullName,
    String? preferredLanguage,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
  }) {
    return User(
      id: id ?? this.id,
      phoneOrEmail: phoneOrEmail ?? this.phoneOrEmail,
      role: role ?? this.role,
      fullName: fullName ?? this.fullName,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
