import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'database_constants.dart';
import 'migrations/migration_runner.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;
  final MigrationRunner _migrationRunner;
  final String? _customPath;

  DatabaseHelper._internal({MigrationRunner? migrationRunner, String? customPath})
      : _migrationRunner = migrationRunner ?? MigrationRunner(),
        _customPath = customPath;

  factory DatabaseHelper.forCustomPath(String path, {MigrationRunner? migrationRunner}) {
    return DatabaseHelper._internal(
      customPath: path,
      migrationRunner: migrationRunner,
    );
  }

  Future<Database> get database async {
    if (_database != null && _database!.isOpen) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final String path;
    final custom = _customPath;
    if (custom != null) {
      path = custom;
    } else if (kIsWeb) {
      path = DatabaseConstants.databaseName;
    } else {
      final String databasesPath = await getDatabasesPath();
      path = p.join(databasesPath, DatabaseConstants.databaseName);
    }

    return await openDatabase(
      path,
      version: DatabaseConstants.databaseVersion,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onConfigure(Database db) async {
    // Crucial: enforce foreign keys on every connection
    await db.execute('PRAGMA foreign_keys = ON;');
  }

  Future<void> _onCreate(Database db, int version) async {
    final Batch batch = db.batch();
    for (final String query in DatabaseConstants.v1SchemaQueries) {
      batch.execute(query);
    }
    await batch.commit(noResult: true);

    // If version > 1, execute remaining migrations
    if (version > 1) {
      await _migrationRunner.runMigrations(db, 1, version);
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    await _migrationRunner.runMigrations(db, oldVersion, newVersion);
  }

  Future<void> close() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
      _database = null;
    }
  }
}
