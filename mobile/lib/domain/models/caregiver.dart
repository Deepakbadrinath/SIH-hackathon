class Caregiver {
  final String id;
  final String userId;
  final String fullName;
  final String relationshipToPatient;
  final String phone;
  final bool alertNotificationsEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;

  const Caregiver({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.relationshipToPatient,
    required this.phone,
    this.alertNotificationsEnabled = true,
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'full_name': fullName,
      'relationship_to_patient': relationshipToPatient,
      'phone': phone,
      'alert_notifications_enabled': alertNotificationsEnabled ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
    };
  }

  factory Caregiver.fromMap(Map<String, dynamic> map) {
    return Caregiver(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      fullName: map['full_name'] as String,
      relationshipToPatient: map['relationship_to_patient'] as String,
      phone: map['phone'] as String,
      alertNotificationsEnabled: (map['alert_notifications_enabled'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      isSynced: (map['is_synced'] as int?) == 1,
    );
  }
}

enum CaregiverAccessRole { primary, secondary, viewer }

class PatientCaregiverRelation {
  final String id;
  final String patientId;
  final String caregiverId;
  final CaregiverAccessRole accessRole;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;

  const PatientCaregiverRelation({
    required this.id,
    required this.patientId,
    required this.caregiverId,
    this.accessRole = CaregiverAccessRole.primary,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patient_id': patientId,
      'caregiver_id': caregiverId,
      'access_role': accessRole.name.toUpperCase(),
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
    };
  }

  factory PatientCaregiverRelation.fromMap(Map<String, dynamic> map) {
    CaregiverAccessRole role;
    switch ((map['access_role'] as String? ?? '').toUpperCase()) {
      case 'SECONDARY':
        role = CaregiverAccessRole.secondary;
        break;
      case 'VIEWER':
        role = CaregiverAccessRole.viewer;
        break;
      default:
        role = CaregiverAccessRole.primary;
    }

    return PatientCaregiverRelation(
      id: map['id'] as String,
      patientId: map['patient_id'] as String,
      caregiverId: map['caregiver_id'] as String,
      accessRole: role,
      isActive: (map['is_active'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      isSynced: (map['is_synced'] as int?) == 1,
    );
  }
}
