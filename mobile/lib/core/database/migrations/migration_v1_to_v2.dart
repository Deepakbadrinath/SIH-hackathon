import 'package:sqflite/sqflite.dart';
import '../database_constants.dart';
import 'migration.dart';

class MigrationV1ToV2 extends Migration {
  const MigrationV1ToV2() : super(fromVersion: 1, toVersion: 2);

  @override
  Future<void> migrate(Database db) async {
    // 1. Add device_client_id column to sync_queue for multi-device identification
    await db.execute('''
      ALTER TABLE ${DatabaseConstants.tableSyncQueue}
      ADD COLUMN device_client_id TEXT;
    ''');

    // 2. Add is_flagged column to game_results for caregiver attention markers
    await db.execute('''
      ALTER TABLE ${DatabaseConstants.tableGameResults}
      ADD COLUMN is_flagged INTEGER DEFAULT 0 CHECK(is_flagged IN (0, 1));
    ''');

    // 3. Add optimization index on medication_schedules
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_med_schedules_med
      ON ${DatabaseConstants.tableMedicationSchedules}(medication_id);
    ''');
  }
}
