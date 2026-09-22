class DatabaseConstants {
  static const String databaseName = 'smriti_setu.db';
  static const int databaseVersion = 2; // Incremented for migration support

  // Table Names (14 required entities)
  static const String tableUsers = 'users';
  static const String tablePatients = 'patients';
  static const String tableCaregivers = 'caregivers';
  static const String tableCaregiverPatientRelationships = 'caregiver_patient_relationships';
  static const String tablePatientCaregiverRelations = tableCaregiverPatientRelationships; // Alias
  static const String tableGameSessions = 'game_sessions';
  static const String tableGameResults = 'game_results';
  static const String tablePerformanceMetrics = 'performance_metrics';
  static const String tableDifficultyHistory = 'difficulty_history';
  static const String tableMedications = 'medications';
  static const String tableMedicationSchedules = 'medication_schedules';
  static const String tableMedicationLogs = 'medication_logs';
  static const String tableSyncQueue = 'sync_queue';
  static const String tableAuditLogs = 'audit_logs';
  static const String tableAppSettings = 'app_settings';

  // Version 1 DDL Scripts (Baseline normalized schema)
  static const List<String> v1SchemaQueries = [
    // 1. Users
    '''
    CREATE TABLE $tableUsers (
      id TEXT PRIMARY KEY,
      phone_or_email TEXT UNIQUE NOT NULL,
      role TEXT CHECK(role IN ('PATIENT', 'CAREGIVER')) NOT NULL,
      full_name TEXT NOT NULL,
      preferred_language TEXT DEFAULT 'en' NOT NULL,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      is_synced INTEGER DEFAULT 0 CHECK(is_synced IN (0, 1))
    );
    ''',

    // 2. Patients
    '''
    CREATE TABLE $tablePatients (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      display_name TEXT NOT NULL,
      birth_year INTEGER,
      emergency_contact_phone TEXT,
      regional_dialect TEXT DEFAULT 'as_IN',
      high_contrast_enabled INTEGER DEFAULT 1 CHECK(high_contrast_enabled IN (0, 1)),
      audio_instructions_enabled INTEGER DEFAULT 1 CHECK(audio_instructions_enabled IN (0, 1)),
      font_scale REAL DEFAULT 1.25,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      is_synced INTEGER DEFAULT 0 CHECK(is_synced IN (0, 1)),
      FOREIGN KEY (user_id) REFERENCES $tableUsers(id) ON DELETE CASCADE
    );
    ''',

    // 3. Caregivers
    '''
    CREATE TABLE $tableCaregivers (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      full_name TEXT NOT NULL,
      relationship_to_patient TEXT NOT NULL,
      phone TEXT NOT NULL,
      alert_notifications_enabled INTEGER DEFAULT 1 CHECK(alert_notifications_enabled IN (0, 1)),
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      is_synced INTEGER DEFAULT 0 CHECK(is_synced IN (0, 1)),
      FOREIGN KEY (user_id) REFERENCES $tableUsers(id) ON DELETE CASCADE
    );
    ''',

    // 4. Caregiver-Patient Relationships
    '''
    CREATE TABLE $tableCaregiverPatientRelationships (
      id TEXT PRIMARY KEY,
      patient_id TEXT NOT NULL,
      caregiver_id TEXT NOT NULL,
      access_role TEXT CHECK(access_role IN ('PRIMARY', 'SECONDARY', 'VIEWER')) DEFAULT 'PRIMARY',
      is_active INTEGER DEFAULT 1 CHECK(is_active IN (0, 1)),
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      is_synced INTEGER DEFAULT 0 CHECK(is_synced IN (0, 1)),
      FOREIGN KEY (patient_id) REFERENCES $tablePatients(id) ON DELETE CASCADE,
      FOREIGN KEY (caregiver_id) REFERENCES $tableCaregivers(id) ON DELETE CASCADE,
      CONSTRAINT unq_patient_caregiver UNIQUE(patient_id, caregiver_id)
    );
    ''',

    // 5. Game Sessions
    '''
    CREATE TABLE $tableGameSessions (
      id TEXT PRIMARY KEY,
      patient_id TEXT NOT NULL,
      game_type TEXT CHECK(game_type IN ('FAMILY_FACE_MATCH', 'PATTERN_COMPLETION', 'ACTIVITY_SEQUENCE', 'OBJECT_SORTING')) NOT NULL,
      start_time TEXT NOT NULL,
      end_time TEXT,
      difficulty_level INTEGER CHECK(difficulty_level BETWEEN 1 AND 5) NOT NULL,
      is_completed INTEGER DEFAULT 0 CHECK(is_completed IN (0, 1)),
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      is_synced INTEGER DEFAULT 0 CHECK(is_synced IN (0, 1)),
      FOREIGN KEY (patient_id) REFERENCES $tablePatients(id) ON DELETE CASCADE
    );
    ''',

    // 6. Game Results
    '''
    CREATE TABLE $tableGameResults (
      id TEXT PRIMARY KEY,
      session_id TEXT NOT NULL,
      game_type TEXT NOT NULL,
      score INTEGER NOT NULL CHECK(score >= 0),
      max_possible_score INTEGER NOT NULL CHECK(max_possible_score > 0),
      accuracy_percentage REAL NOT NULL CHECK(accuracy_percentage BETWEEN 0.0 AND 100.0),
      total_trials INTEGER NOT NULL CHECK(total_trials >= 0),
      correct_trials INTEGER NOT NULL CHECK(correct_trials >= 0),
      error_count INTEGER NOT NULL CHECK(error_count >= 0),
      avg_response_time_ms REAL NOT NULL CHECK(avg_response_time_ms >= 0),
      total_hesitation_pause_ms REAL NOT NULL CHECK(total_hesitation_pause_ms >= 0),
      completed_at TEXT NOT NULL,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      is_synced INTEGER DEFAULT 0 CHECK(is_synced IN (0, 1)),
      FOREIGN KEY (session_id) REFERENCES $tableGameSessions(id) ON DELETE CASCADE
    );
    ''',

    // 7. Performance Metrics
    '''
    CREATE TABLE $tablePerformanceMetrics (
      id TEXT PRIMARY KEY,
      session_id TEXT NOT NULL,
      trial_number INTEGER NOT NULL CHECK(trial_number >= 0),
      stimulus_id TEXT NOT NULL,
      user_response TEXT NOT NULL,
      is_correct INTEGER NOT NULL CHECK(is_correct IN (0, 1)),
      response_time_ms INTEGER NOT NULL CHECK(response_time_ms >= 0),
      hesitation_duration_ms INTEGER NOT NULL CHECK(hesitation_duration_ms >= 0),
      recorded_at TEXT NOT NULL,
      is_synced INTEGER DEFAULT 0 CHECK(is_synced IN (0, 1)),
      FOREIGN KEY (session_id) REFERENCES $tableGameSessions(id) ON DELETE CASCADE
    );
    ''',

    // 8. Difficulty History
    '''
    CREATE TABLE $tableDifficultyHistory (
      id TEXT PRIMARY KEY,
      patient_id TEXT NOT NULL,
      game_type TEXT NOT NULL,
      previous_difficulty INTEGER NOT NULL CHECK(previous_difficulty BETWEEN 1 AND 5),
      new_difficulty INTEGER NOT NULL CHECK(new_difficulty BETWEEN 1 AND 5),
      reason TEXT NOT NULL,
      calculated_performance_score REAL NOT NULL CHECK(calculated_performance_score BETWEEN 0.0 AND 1.0),
      calculated_at TEXT NOT NULL,
      is_synced INTEGER DEFAULT 0 CHECK(is_synced IN (0, 1)),
      FOREIGN KEY (patient_id) REFERENCES $tablePatients(id) ON DELETE CASCADE
    );
    ''',

    // 9. Medications
    '''
    CREATE TABLE $tableMedications (
      id TEXT PRIMARY KEY,
      patient_id TEXT NOT NULL,
      name TEXT NOT NULL,
      dosage_description TEXT NOT NULL,
      visual_color_code TEXT DEFAULT '#3B82F6',
      instructions TEXT,
      is_active INTEGER DEFAULT 1 CHECK(is_active IN (0, 1)),
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      is_synced INTEGER DEFAULT 0 CHECK(is_synced IN (0, 1)),
      FOREIGN KEY (patient_id) REFERENCES $tablePatients(id) ON DELETE CASCADE
    );
    ''',

    // 10. Medication Schedules
    '''
    CREATE TABLE $tableMedicationSchedules (
      id TEXT PRIMARY KEY,
      medication_id TEXT NOT NULL,
      time_of_day TEXT NOT NULL,
      meal_relation TEXT CHECK(meal_relation IN ('BEFORE_MEAL', 'AFTER_MEAL', 'WITH_MEAL', 'ANYTIME')) DEFAULT 'AFTER_MEAL',
      days_of_week TEXT DEFAULT '1,2,3,4,5,6,7',
      is_active INTEGER DEFAULT 1 CHECK(is_active IN (0, 1)),
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      is_synced INTEGER DEFAULT 0 CHECK(is_synced IN (0, 1)),
      FOREIGN KEY (medication_id) REFERENCES $tableMedications(id) ON DELETE CASCADE
    );
    ''',

    // 11. Medication Logs
    '''
    CREATE TABLE $tableMedicationLogs (
      id TEXT PRIMARY KEY,
      schedule_id TEXT NOT NULL,
      scheduled_time TEXT NOT NULL,
      status TEXT CHECK(status IN ('TAKEN', 'MISSED', 'SNOOZED', 'SKIPPED')) NOT NULL,
      action_timestamp TEXT NOT NULL,
      confirmed_by_role TEXT CHECK(confirmed_by_role IN ('PATIENT', 'CAREGIVER')) NOT NULL,
      notes TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      is_synced INTEGER DEFAULT 0 CHECK(is_synced IN (0, 1)),
      FOREIGN KEY (schedule_id) REFERENCES $tableMedicationSchedules(id) ON DELETE CASCADE
    );
    ''',

    // 12. Sync Queue
    '''
    CREATE TABLE $tableSyncQueue (
      operation_id TEXT PRIMARY KEY,
      entity_id TEXT NOT NULL,
      entity_type TEXT NOT NULL,
      operation_type TEXT CHECK(operation_type IN ('INSERT', 'UPDATE', 'DELETE')) NOT NULL,
      payload_json TEXT NOT NULL,
      timestamp TEXT NOT NULL,
      retry_count INTEGER DEFAULT 0 CHECK(retry_count >= 0),
      sync_status TEXT CHECK(sync_status IN ('PENDING', 'IN_PROGRESS', 'FAILED', 'COMPLETED')) DEFAULT 'PENDING',
      last_error TEXT
    );
    ''',

    // 13. Audit Logs
    '''
    CREATE TABLE $tableAuditLogs (
      id TEXT PRIMARY KEY,
      actor_id TEXT NOT NULL,
      actor_role TEXT NOT NULL,
      action TEXT NOT NULL,
      resource_type TEXT NOT NULL,
      resource_id TEXT NOT NULL,
      details_json TEXT,
      timestamp TEXT NOT NULL,
      is_synced INTEGER DEFAULT 0 CHECK(is_synced IN (0, 1))
    );
    ''',

    // 14. App Settings
    '''
    CREATE TABLE $tableAppSettings (
      setting_key TEXT PRIMARY KEY,
      setting_value TEXT NOT NULL,
      updated_at TEXT NOT NULL
    );
    ''',

    // Indexes
    'CREATE INDEX idx_game_sessions_patient ON $tableGameSessions(patient_id, start_time);',
    'CREATE INDEX idx_game_results_session ON $tableGameResults(session_id);',
    'CREATE INDEX idx_perf_metrics_session ON $tablePerformanceMetrics(session_id, trial_number);',
    'CREATE INDEX idx_med_logs_schedule ON $tableMedicationLogs(schedule_id, scheduled_time);',
    'CREATE INDEX idx_sync_queue_status ON $tableSyncQueue(sync_status, retry_count);',
    'CREATE INDEX idx_audit_timestamp ON $tableAuditLogs(timestamp);',
    'CREATE INDEX idx_rel_patient_caregiver ON $tableCaregiverPatientRelationships(patient_id, caregiver_id);',
    'CREATE INDEX idx_medications_patient ON $tableMedications(patient_id);',
    'CREATE INDEX idx_med_schedules_med ON $tableMedicationSchedules(medication_id);',
    'CREATE INDEX idx_diff_history_patient_game ON $tableDifficultyHistory(patient_id, game_type);',
    'CREATE INDEX idx_game_results_completed ON $tableGameResults(completed_at);',
  ];

  static List<String> get createTablesQueries => v1SchemaQueries;
}
