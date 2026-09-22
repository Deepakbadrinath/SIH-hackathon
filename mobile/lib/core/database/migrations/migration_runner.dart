import 'package:sqflite/sqflite.dart';
import 'migration.dart';
import 'migration_v1_to_v2.dart';

class MigrationRunner {
  final List<Migration> _migrations;

  MigrationRunner({List<Migration>? migrations})
      : _migrations = migrations ?? [const MigrationV1ToV2()];

  Future<void> runMigrations(Database db, int oldVersion, int newVersion) async {
    for (int v = oldVersion; v < newVersion; v++) {
      final migration = _migrations.firstWhere(
        (m) => m.fromVersion == v && m.toVersion == v + 1,
        orElse: () => throw StateError('No migration registered from v$v to v${v + 1}'),
      );
      await migration.migrate(db);
    }
  }
}
