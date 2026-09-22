enum MealRelation { beforeMeal, afterMeal, withMeal, anytime }

extension MealRelationExtension on MealRelation {
  String get displayName {
    switch (this) {
      case MealRelation.beforeMeal:
        return 'Before Meal';
      case MealRelation.afterMeal:
        return 'After Meal';
      case MealRelation.withMeal:
        return 'With Meal';
      case MealRelation.anytime:
        return 'Anytime';
    }
  }

  String toDbString() {
    switch (this) {
      case MealRelation.beforeMeal:
        return 'BEFORE_MEAL';
      case MealRelation.afterMeal:
        return 'AFTER_MEAL';
      case MealRelation.withMeal:
        return 'WITH_MEAL';
      case MealRelation.anytime:
        return 'ANYTIME';
    }
  }

  static MealRelation fromDbString(String str) {
    switch (str.toUpperCase()) {
      case 'BEFORE_MEAL':
        return MealRelation.beforeMeal;
      case 'WITH_MEAL':
        return MealRelation.withMeal;
      case 'ANYTIME':
        return MealRelation.anytime;
      case 'AFTER_MEAL':
      default:
        return MealRelation.afterMeal;
    }
  }
}

enum MedicationLogStatus { taken, missed, snoozed, skipped }

extension MedicationLogStatusExtension on MedicationLogStatus {
  String toDbString() {
    switch (this) {
      case MedicationLogStatus.taken:
        return 'TAKEN';
      case MedicationLogStatus.missed:
        return 'MISSED';
      case MedicationLogStatus.snoozed:
        return 'SNOOZED';
      case MedicationLogStatus.skipped:
        return 'SKIPPED';
    }
  }

  static MedicationLogStatus fromDbString(String str) {
    switch (str.toUpperCase()) {
      case 'MISSED':
        return MedicationLogStatus.missed;
      case 'SNOOZED':
        return MedicationLogStatus.snoozed;
      case 'SKIPPED':
        return MedicationLogStatus.skipped;
      case 'TAKEN':
      default:
        return MedicationLogStatus.taken;
    }
  }
}

enum ReminderFilter { today, upcoming, completed, missed, history }

class Medication {
  final String id;
  final String patientId;
  final String name;
  final String dosageDescription;
  final String visualColorCode;
  final String instructions;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;

  const Medication({
    required this.id,
    required this.patientId,
    required this.name,
    required this.dosageDescription,
    this.visualColorCode = '#3B82F6',
    this.instructions = '',
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = false,
  });

  Medication copyWith({
    String? id,
    String? patientId,
    String? name,
    String? dosageDescription,
    String? visualColorCode,
    String? instructions,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
  }) {
    return Medication(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      name: name ?? this.name,
      dosageDescription: dosageDescription ?? this.dosageDescription,
      visualColorCode: visualColorCode ?? this.visualColorCode,
      instructions: instructions ?? this.instructions,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patient_id': patientId,
      'name': name,
      'dosage_description': dosageDescription,
      'visual_color_code': visualColorCode,
      'instructions': instructions,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
    };
  }

  factory Medication.fromMap(Map<String, dynamic> map) {
    return Medication(
      id: map['id'] as String,
      patientId: map['patient_id'] as String,
      name: map['name'] as String,
      dosageDescription: map['dosage_description'] as String,
      visualColorCode: (map['visual_color_code'] as String?) ?? '#3B82F6',
      instructions: (map['instructions'] as String?) ?? '',
      isActive: (map['is_active'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      isSynced: (map['is_synced'] as int?) == 1,
    );
  }
}

class MedicationSchedule {
  final String id;
  final String medicationId;
  final String timeOfDay; // Format: "HH:mm", e.g., "08:00"
  final MealRelation mealRelation;
  final String daysOfWeek; // e.g., "1,2,3,4,5,6,7" (1=Monday, 7=Sunday)
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;

  const MedicationSchedule({
    required this.id,
    required this.medicationId,
    required this.timeOfDay,
    this.mealRelation = MealRelation.afterMeal,
    this.daysOfWeek = '1,2,3,4,5,6,7',
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = false,
  });

  MedicationSchedule copyWith({
    String? id,
    String? medicationId,
    String? timeOfDay,
    MealRelation? mealRelation,
    String? daysOfWeek,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
  }) {
    return MedicationSchedule(
      id: id ?? this.id,
      medicationId: medicationId ?? this.medicationId,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      mealRelation: mealRelation ?? this.mealRelation,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'medication_id': medicationId,
      'time_of_day': timeOfDay,
      'meal_relation': mealRelation.toDbString(),
      'days_of_week': daysOfWeek,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
    };
  }

  factory MedicationSchedule.fromMap(Map<String, dynamic> map) {
    return MedicationSchedule(
      id: map['id'] as String,
      medicationId: map['medication_id'] as String,
      timeOfDay: map['time_of_day'] as String,
      mealRelation: MealRelationExtension.fromDbString(map['meal_relation'] as String),
      daysOfWeek: (map['days_of_week'] as String?) ?? '1,2,3,4,5,6,7',
      isActive: (map['is_active'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      isSynced: (map['is_synced'] as int?) == 1,
    );
  }
}

class MedicationLog {
  final String id;
  final String scheduleId;
  final String scheduledTime;
  final MedicationLogStatus status;
  final DateTime actionTimestamp;
  final String confirmedByRole; // 'PATIENT' or 'CAREGIVER'
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;

  const MedicationLog({
    required this.id,
    required this.scheduleId,
    required this.scheduledTime,
    required this.status,
    required this.actionTimestamp,
    this.confirmedByRole = 'PATIENT',
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = false,
  });

  MedicationLog copyWith({
    String? id,
    String? scheduleId,
    String? scheduledTime,
    MedicationLogStatus? status,
    DateTime? actionTimestamp,
    String? confirmedByRole,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
  }) {
    return MedicationLog(
      id: id ?? this.id,
      scheduleId: scheduleId ?? this.scheduleId,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      status: status ?? this.status,
      actionTimestamp: actionTimestamp ?? this.actionTimestamp,
      confirmedByRole: confirmedByRole ?? this.confirmedByRole,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'schedule_id': scheduleId,
      'scheduled_time': scheduledTime,
      'status': status.toDbString(),
      'action_timestamp': actionTimestamp.toIso8601String(),
      'confirmed_by_role': confirmedByRole.toUpperCase(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
    };
  }

  factory MedicationLog.fromMap(Map<String, dynamic> map) {
    return MedicationLog(
      id: map['id'] as String,
      scheduleId: map['schedule_id'] as String,
      scheduledTime: map['scheduled_time'] as String,
      status: MedicationLogStatusExtension.fromDbString(map['status'] as String),
      actionTimestamp: DateTime.parse(map['action_timestamp'] as String),
      confirmedByRole: (map['confirmed_by_role'] as String?) ?? 'PATIENT',
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      isSynced: (map['is_synced'] as int?) == 1,
    );
  }
}

/// Aggregate model representing a single scheduled medication dose instance for a specific day.
class MedicationReminderItem {
  final Medication medication;
  final MedicationSchedule schedule;
  final DateTime scheduledDateTime;
  final MedicationLogStatus? status; // null = pending
  final MedicationLog? log;
  final bool isDueNow;
  final bool isOverdue;

  const MedicationReminderItem({
    required this.medication,
    required this.schedule,
    required this.scheduledDateTime,
    this.status,
    this.log,
    this.isDueNow = false,
    this.isOverdue = false,
  });

  bool get isTaken => status == MedicationLogStatus.taken;
  bool get isSkipped => status == MedicationLogStatus.skipped;
  bool get isSnoozed => status == MedicationLogStatus.snoozed;
  bool get isMissed => status == MedicationLogStatus.missed || (status == null && isOverdue);
  bool get isPending => status == null && !isOverdue;

  String get timeOfDay => schedule.timeOfDay;

  MedicationReminderItem copyWith({
    Medication? medication,
    MedicationSchedule? schedule,
    DateTime? scheduledDateTime,
    MedicationLogStatus? status,
    MedicationLog? log,
    bool? isDueNow,
    bool? isOverdue,
  }) {
    return MedicationReminderItem(
      medication: medication ?? this.medication,
      schedule: schedule ?? this.schedule,
      scheduledDateTime: scheduledDateTime ?? this.scheduledDateTime,
      status: status ?? this.status,
      log: log ?? this.log,
      isDueNow: isDueNow ?? this.isDueNow,
      isOverdue: isOverdue ?? this.isOverdue,
    );
  }
}
