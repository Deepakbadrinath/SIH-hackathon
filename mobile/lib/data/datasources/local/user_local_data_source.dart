import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_constants.dart';
import '../../../core/database/database_helper.dart';
import '../../../domain/models/user.dart';

abstract class UserLocalDataSource {
  Future<void> createUser(User user);
  Future<User?> getUserById(String id);
  Future<User?> getUserByPhoneOrEmail(String phoneOrEmail);
  Future<void> updateUser(User user);
  Future<void> deleteUser(String id);
  Future<List<User>> getAllUsers();
}

class UserLocalDataSourceImpl implements UserLocalDataSource {
  final DatabaseHelper _dbHelper;

  UserLocalDataSourceImpl({required DatabaseHelper dbHelper}) : _dbHelper = dbHelper;

  @override
  Future<void> createUser(User user) async {
    final db = await _dbHelper.database;
    await db.insert(
      DatabaseConstants.tableUsers,
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<User?> getUserById(String id) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      DatabaseConstants.tableUsers,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isNotEmpty) {
      return User.fromMap(results.first);
    }
    return null;
  }

  @override
  Future<User?> getUserByPhoneOrEmail(String phoneOrEmail) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      DatabaseConstants.tableUsers,
      where: 'phone_or_email = ?',
      whereArgs: [phoneOrEmail],
      limit: 1,
    );
    if (results.isNotEmpty) {
      return User.fromMap(results.first);
    }
    return null;
  }

  @override
  Future<void> updateUser(User user) async {
    final db = await _dbHelper.database;
    await db.update(
      DatabaseConstants.tableUsers,
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  @override
  Future<void> deleteUser(String id) async {
    final db = await _dbHelper.database;
    await db.delete(
      DatabaseConstants.tableUsers,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<List<User>> getAllUsers() async {
    final db = await _dbHelper.database;
    final results = await db.query(DatabaseConstants.tableUsers);
    return results.map((e) => User.fromMap(e)).toList();
  }
}
