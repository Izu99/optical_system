import 'package:sqflite/sqflite.dart';
import '../models/lens.dart';
import 'shop_helper.dart';

class LensHelper {
  LensHelper._privateConstructor();
  static final LensHelper instance = LensHelper._privateConstructor();

  Future<Database> get database async => await ShopHelper.instance.database;

  Future<int> createLens(Lens lens) async {
    final db = await database;
    return await db.insert('lenses', lens.toMap());
  }

  Future<List<Lens>> getAllLenses() async {
    final db = await database;
    final result = await db.query('lenses', orderBy: 'lens_id DESC');
    return result.map((json) => Lens.fromMap(json)).toList();
  }

  Future<int> updateLens(Lens lens) async {
    final db = await database;
    return await db.update('lenses', lens.toMap(), where: 'lens_id = ?', whereArgs: [lens.lensId]);
  }

  Future<int> deleteLens(int id) async {
    final db = await database;
    return await db.delete('lenses', where: 'lens_id = ?', whereArgs: [id]);
  }

  // Add: Get lens by ID
  Future<Lens?> getLensById(int id) async {
    final db = await database;
    final result = await db.query('lenses', where: 'lens_id = ?', whereArgs: [id]);
    if (result.isNotEmpty) {
      return Lens.fromMap(result.first);
    }
    return null;
  }
}
