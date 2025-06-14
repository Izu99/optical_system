import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/customer.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('pos_system.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        phoneNumber TEXT NOT NULL,
        address TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  // Customer CRUD operations
  Future<int> createCustomer(Customer customer) async {
    final db = await instance.database;
    return await db.insert('customers', customer.toMap());
  }

  Future<List<Customer>> getAllCustomers() async {
    final db = await instance.database;
    final result = await db.query('customers', orderBy: 'createdAt DESC');
    return result.map((json) => Customer.fromMap(json)).toList();
  }

  Future<Customer?> getCustomer(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Customer.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateCustomer(Customer customer) async {
    final db = await instance.database;
    return await db.update(
      'customers',
      customer.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  Future<int> deleteCustomer(int id) async {
    final db = await instance.database;
    return await db.delete(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Customer>> searchCustomers(String query) async {
    final db = await instance.database;
    final result = await db.query(
      'customers',
      where: 'name LIKE ? OR email LIKE ? OR phoneNumber LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'createdAt DESC',
    );
    return result.map((json) => Customer.fromMap(json)).toList();
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}