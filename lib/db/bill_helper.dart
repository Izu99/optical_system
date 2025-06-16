import 'package:sqflite/sqflite.dart';
import '../models/bill.dart';
import '../models/bill_item.dart';
import 'customer_helper.dart';

class BillHelper {
  BillHelper._privateConstructor();
  static final BillHelper instance = BillHelper._privateConstructor();

  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await DatabaseHelper.instance.database;
    return _database!;
  }

  Future<int> createBill(Bill bill) async {
    final db = await database;
    return await db.insert('billings', bill.toMap());
  }

  Future<int> updateBill(Bill bill) async {
    final db = await database;
    return await db.update('billings', bill.toMap(), where: 'billing_id = ?', whereArgs: [bill.billingId]);
  }

  Future<int> deleteBill(int billingId) async {
    final db = await database;
    await db.delete('billing_items', where: 'billing_id = ?', whereArgs: [billingId]);
    return await db.delete('billings', where: 'billing_id = ?', whereArgs: [billingId]);
  }

  Future<List<Bill>> getAllBills() async {
    final db = await database;
    final maps = await db.query('billings', orderBy: 'invoice_date DESC');
    return maps.map((e) => Bill.fromMap(e)).toList();
  }

  Future<List<BillItem>> getBillItems(int billingId) async {
    final db = await database;
    final maps = await db.query('billing_items', where: 'billing_id = ?', whereArgs: [billingId]);
    return maps.map((e) => BillItem.fromMap(e)).toList();
  }

  Future<int> createBillItem(BillItem item) async {
    final db = await database;
    return await db.insert('billing_items', item.toMap());
  }

  Future<int> updateBillItem(BillItem item) async {
    final db = await database;
    return await db.update('billing_items', item.toMap(), where: 'billing_item_id = ?', whereArgs: [item.billingItemId]);
  }

  Future<int> deleteBillItem(int billingItemId) async {
    final db = await database;
    return await db.delete('billing_items', where: 'billing_item_id = ?', whereArgs: [billingItemId]);
  }
}
