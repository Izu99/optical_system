import 'package:sqflite/sqflite.dart';
import '../models/frame.dart';
import 'shop_helper.dart';

class FrameHelper {
  static final FrameHelper instance = FrameHelper._init();
  static Database? _database;
  FrameHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await ShopHelper.instance.database;
    return _database!;
  }

  Future<int> createFrame(Frame frame) async {
    final db = await instance.database;
    return await db.insert('frames', frame.toMap());
  }

  Future<List<Frame>> getAllFrames() async {
    final db = await instance.database;
    final result = await db.query('frames', orderBy: 'frame_id DESC');
    return result.map((json) => Frame.fromMap(json)).toList();
  }

  Future<int> updateFrame(Frame frame) async {
    final db = await instance.database;
    return await db.update(
      'frames',
      frame.toMap(),
      where: 'frame_id = ?',
      whereArgs: [frame.frameId],
    );
  }

  Future<int> deleteFrame(int id) async {
    final db = await instance.database;
    return await db.delete(
      'frames',
      where: 'frame_id = ?',
      whereArgs: [id],
    );
  }

  // Add: Get frame by ID
  Future<Frame?> getFrameById(int id) async {
    final db = await instance.database;
    final result = await db.query('frames', where: 'frame_id = ?', whereArgs: [id]);
    if (result.isNotEmpty) {
      return Frame.fromMap(result.first);
    }
    return null;
  }
}
