import 'package:sqflite/sqflite.dart';
import '../models/payment.dart';
import 'bill_helper.dart';

class PaymentHelper {
  PaymentHelper._privateConstructor();
  static final PaymentHelper instance = PaymentHelper._privateConstructor();

  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await BillHelper.instance.database;
    return _database!;
  }

  Future<int> createPayment(Payment payment) async {
    final db = await database;
    return await db.insert('payments', payment.toMap());
  }

  Future<int> updatePayment(Payment payment) async {
    final db = await database;
    return await db.update('payments', payment.toMap(), where: 'payment_id = ?', whereArgs: [payment.paymentId]);
  }

  Future<int> deletePayment(int paymentId) async {
    final db = await database;
    return await db.delete('payments', where: 'payment_id = ?', whereArgs: [paymentId]);
  }

  Future<List<Payment>> getAllPayments() async {
    final db = await database;
    final maps = await db.query('payments', orderBy: 'payment_id DESC');
    return maps.map((e) => Payment.fromMap(e)).toList();
  }

  Future<Payment?> getPaymentByBillId(int billingId) async {
    final db = await database;
    final maps = await db.query('payments', where: 'billing_id = ?', whereArgs: [billingId]);
    if (maps.isNotEmpty) {
      return Payment.fromMap(maps.first);
    }
    return null;
  }
}
