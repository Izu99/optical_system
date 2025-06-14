import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/shop.dart';

class ShopHelper {
  static final ShopHelper instance = ShopHelper._init();
  static Database? _database;

  ShopHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('pos_system.db');
    // Ensure the shops table exists every time the database is opened
    await _ensureShopsTable(_database!);
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(
      path,
      version: 1,
      // Don't need to do anything in onCreate, customer_helper handles its own table
    );
  }

  Future<void> _ensureShopsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS shops (
        shop_id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        contact_number TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        headoffice_address TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS frames (
        frame_id INTEGER PRIMARY KEY AUTOINCREMENT,
        brand TEXT NOT NULL,
        size TEXT NOT NULL,
        whole_sale_price REAL NOT NULL,
        color TEXT NOT NULL,
        model TEXT NOT NULL,
        selling_price REAL NOT NULL,
        stock INTEGER NOT NULL,
        branch_id INTEGER NOT NULL,
        shop_id INTEGER NOT NULL,
        image_path TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS lenses (
        lens_id INTEGER PRIMARY KEY AUTOINCREMENT,
        power TEXT NOT NULL,
        coating TEXT NOT NULL,
        category TEXT NOT NULL,
        cost REAL NOT NULL,
        stock INTEGER NOT NULL,
        selling_price REAL NOT NULL,
        branch_id INTEGER NOT NULL,
        shop_id INTEGER NOT NULL
      )
    ''');
  }

  Future<bool> isShopNameUnique(String shopName) async {
    final db = await instance.database;
    final result = await db.query(
      'shops',
      where: 'name = ?',
      whereArgs: [shopName],
    );
    return result.isEmpty;
  }

  Future<int> createShop(Shop shop) async {
    final db = await instance.database;
    final isUnique = await isShopNameUnique(shop.name);
    if (!isUnique) {
      throw Exception('Shop name already exists');
    }
    return await db.insert('shops', {
      'name': shop.name,
      'contact_number': shop.contactNumber,
      'email': shop.email,
      'headoffice_address': shop.headofficeAddress,
    });
  }

  Future<List<Shop>> getAllShops() async {
    final db = await instance.database;
    final result = await db.query('shops', orderBy: 'shop_id DESC');
    return result.map((json) => Shop.fromMap(json)).toList();
  }

  Future<Shop?> getShop(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      'shops',
      where: 'shop_id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Shop.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateShop(Shop shop) async {
    final db = await instance.database;
    return await db.update(
      'shops',
      shop.toMap(),
      where: 'shop_id = ?',
      whereArgs: [shop.shopId],
    );
  }

  Future<int> deleteShop(int id) async {
    final db = await instance.database;
    return await db.delete(
      'shops',
      where: 'shop_id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Shop>> searchShops(String query) async {
    final db = await instance.database;
    final result = await db.query(
      'shops',
      where: 'name LIKE ? OR email LIKE ? OR contact_number LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'shop_id DESC',
    );
    return result.map((json) => Shop.fromMap(json)).toList();
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
