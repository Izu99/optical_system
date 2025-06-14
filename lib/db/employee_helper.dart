import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/employee.dart';

class EmployeeHelper {
  static final EmployeeHelper instance = EmployeeHelper._init();
  static Database? _database;

  EmployeeHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('pos_system.db');
    await _ensureEmployeeTable(_database!);
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1);
  }

  Future<void> _ensureEmployeeTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        user_id INTEGER PRIMARY KEY AUTOINCREMENT,
        role TEXT NOT NULL,
        branch_id INTEGER NOT NULL,
        email TEXT NOT NULL,
        name TEXT,
        phone TEXT,
        address TEXT,
        image_path TEXT
      )
    ''');
  }

  Future<int> createEmployee(Employee employee) async {
    final db = await instance.database;
    return await db.insert('users', employee.toMap());
  }

  Future<List<Employee>> getAllEmployees() async {
    final db = await instance.database;
    final result = await db.query('users', orderBy: 'user_id DESC');
    return result.map((json) => Employee.fromMap(json)).toList();
  }

  Future<List<Employee>> searchEmployees(String query) async {
    final db = await instance.database;
    final result = await db.query(
      'users',
      where: 'name LIKE ? OR email LIKE ? OR phone LIKE ? OR address LIKE ?',
      whereArgs: List.filled(4, '%$query%'),
      orderBy: 'user_id DESC',
    );
    return result.map((json) => Employee.fromMap(json)).toList();
  }

  Future<int> updateEmployee(Employee employee) async {
    final db = await instance.database;
    return await db.update(
      'users',
      employee.toMap(),
      where: 'user_id = ?',
      whereArgs: [employee.userId],
    );
  }

  Future<int> deleteEmployee(int userId) async {
    final db = await instance.database;
    return await db.delete(
      'users',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  Future<Employee?> getManagerForBranch(int branchId) async {
    final db = await instance.database;
    final result = await db.query(
      'users',
      where: 'branch_id = ? AND role = ?',
      whereArgs: [branchId, 'manager'],
      limit: 1,
    );
    if (result.isNotEmpty) {
      return Employee.fromMap(result.first);
    }
    return null;
  }
}
