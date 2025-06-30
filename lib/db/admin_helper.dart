// db/admin_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/admin.dart';


// AdminHelper implementation with SQLite logic for admin registration and login
class AdminHelper {
  static final AdminHelper instance = AdminHelper._init();
  static Database? _database;
  AdminHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('pos_system.db');
    await _ensureAdminTable(_database!);
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);
    return await openDatabase(path, version: 1);
  }

  Future<void> _ensureAdminTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS admins (
        adminId INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        email TEXT NOT NULL,
        password TEXT NOT NULL
      )
    ''');
  }

  Future<Admin?> getAdmin(String username, String password) async {
    final db = await instance.database;
    final result = await db.query(
      'admins',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
      limit: 1,
    );
    if (result.isNotEmpty) {
      final map = result.first;
      return Admin(
        adminId: map['adminId'] as int?,
        username: map['username'] as String,
        email: map['email'] as String,
        password: map['password'] as String,
      );
    }
    return null;
  }

  Future<Admin?> getAdminByEmail(String email, String password) async {
    final db = await instance.database;
    final result = await db.query(
      'admins',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
      limit: 1,
    );
    if (result.isNotEmpty) {
      final map = result.first;
      return Admin(
        adminId: map['adminId'] as int?,
        username: map['username'] as String,
        email: map['email'] as String,
        password: map['password'] as String,
      );
    }
    return null;
  }

  Future<Admin?> getAdminById(int adminId) async {
    final db = await instance.database;
    final result = await db.query(
      'admins',
      where: 'adminId = ?',
      whereArgs: [adminId],
      limit: 1,
    );
    if (result.isNotEmpty) {
      final map = result.first;
      return Admin(
        adminId: map['adminId'] as int?,
        username: map['username'] as String,
        email: map['email'] as String,
        password: map['password'] as String,
      );
    }
    return null;
  }

  Future<bool> isUsernameUnique(String username) async {
    final db = await instance.database;
    final result = await db.query(
      'admins',
      where: 'username = ?',
      whereArgs: [username],
      limit: 1,
    );
    return result.isEmpty;
  }

  Future<void> createAdmin(Admin admin) async {
    final db = await instance.database;
    await db.insert('admins', {
      'username': admin.username,
      'email': admin.email,
      'password': admin.password,
    });
  }

  Future<void> updateAdmin(Admin admin) async {
    final db = await instance.database;
    await db.update(
      'admins',
      {
        'username': admin.username,
        'email': admin.email,
        'password': admin.password,
      },
      where: 'adminId = ?',
      whereArgs: [admin.adminId],
    );
  }
}