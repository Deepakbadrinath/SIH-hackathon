import 'package:sqflite/sqflite.dart';

abstract class Migration {
  final int fromVersion;
  final int toVersion;

  const Migration({
    required this.fromVersion,
    required this.toVersion,
  });

  Future<void> migrate(Database db);
}
