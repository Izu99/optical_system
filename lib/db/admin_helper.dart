// db/shop_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/shop.dart';
import '../models/admin.dart';

class ShopHelper {
  static final ShopHelper instance = ShopHelper._init();
  static Database? _database;

  ShopHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('pos_system.db');
    await _ensureShopTable(_database!);
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);
    return await openDatabase(path, version: 1);
  }

  Future<void> _ensureShopTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS shop (
        shopId INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        contact_number TEXT NOT NULL,
        email TEXT NOT NULL,
        headoffice_address TEXT NOT NULL,
        createdAt TEXT,
        updatedAt TEXT
      )
    ''');
  }

  Future<int> createShop(Shop shop) async {
    final db = await instance.database;
    
    // Check if shop already exists
    final existing = await getShop();
    if (existing != null) {
      throw Exception('Shop already exists. Use update instead.');
    }
    
    final now = DateTime.now().toIso8601String();
    return await db.insert('shop', {
      'name': shop.name,
      'contact_number': shop.contactNumber,
      'email': shop.email,
      'headoffice_address': shop.headofficeAddress,
      'createdAt': now,
      'updatedAt': now,
    });
  }

  Future<Shop?> getShop() async {
    final db = await instance.database;
    final maps = await db.query('shop', limit: 1);
    
    if (maps.isNotEmpty) {
      return Shop.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateShop(Shop shop) async {
    final db = await instance.database;
    final now = DateTime.now().toIso8601String();
    
    return await db.update(
      'shop',
      {
        'name': shop.name,
        'contact_number': shop.contactNumber,
        'email': shop.email,
        'headoffice_address': shop.headofficeAddress,
        'updatedAt': now,
      },
      where: 'shopId = ?',
      whereArgs: [shop.shopId],
    );
  }

  Future<bool> shopExists() async {
    final shop = await getShop();
    return shop != null;
  }
}

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
}