import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/branch.dart';

class BranchHelper {
  static final BranchHelper instance = BranchHelper._init();
  static Database? _database;

  BranchHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('pos_system.db');
    // Ensure the branches table exists every time the database is opened
    await _ensureBranchesTable(_database!);
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(
      path,
      version: 1,
      // Don't need to do anything in onCreate, shop_helper handles its own table
    );
  }

  Future<void> _ensureBranchesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS branches (
        branch_id INTEGER PRIMARY KEY AUTOINCREMENT,
        branch_name TEXT NOT NULL,
        contact_number TEXT NOT NULL,
        branch_code TEXT NOT NULL,
        shop_id INTEGER NOT NULL,
        FOREIGN KEY (shop_id) REFERENCES shops (shop_id) ON DELETE CASCADE
      )
    ''');
  }

  Future<int> createBranch(Branch branch) async {
    final db = await instance.database;
    return await db.insert('branches', branch.toMap());
  }

  Future<List<Branch>> getAllBranches() async {
    final db = await instance.database;
    final result = await db.query('branches', orderBy: 'branch_id DESC');
    return result.map((json) => Branch.fromMap(json)).toList();
  }

  Future<List<Branch>> getBranchesByShopId(int shopId) async {
    final db = await instance.database;
    final result = await db.query(
      'branches',
      where: 'shop_id = ?',
      whereArgs: [shopId],
      orderBy: 'branch_id DESC',
    );
    return result.map((json) => Branch.fromMap(json)).toList();
  }

  Future<Branch?> getBranch(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      'branches',
      where: 'branch_id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Branch.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateBranch(Branch branch) async {
    final db = await instance.database;
    return await db.update(
      'branches',
      branch.toMap(),
      where: 'branch_id = ?',
      whereArgs: [branch.branchId],
    );
  }

  Future<int> deleteBranch(int id) async {
    final db = await instance.database;
    return await db.delete(
      'branches',
      where: 'branch_id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Branch>> searchBranches(String query) async {
    final db = await instance.database;
    final result = await db.query(
      'branches',
      where: 'branch_name LIKE ? OR branch_code LIKE ? OR contact_number LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'branch_id DESC',
    );
    return result.map((json) => Branch.fromMap(json)).toList();
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
