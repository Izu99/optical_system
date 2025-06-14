import 'package:sqflite/sqflite.dart';
import '../models/prescription.dart';
import 'customer_helper.dart'; // Import this to use DatabaseHelper

class PrescriptionHelper {
  static final PrescriptionHelper instance = PrescriptionHelper._init();
  PrescriptionHelper._init();

  Future<Database> get database async {
    // Use the same database as DatabaseHelper
    return await DatabaseHelper.instance.database;
  }

  Future<int> createPrescription(Prescription prescription) async {
    final db = await database;
    return await db.insert('prescriptions', prescription.toMap());
  }

  Future<List<Prescription>> getAllPrescriptions() async {
    final db = await database;
    final result = await db.query('prescriptions');
    return result.map((e) => Prescription.fromMap(e)).toList();
  }

  Future<int> updatePrescription(Prescription prescription) async {
    final db = await database;
    return await db.update(
      'prescriptions',
      prescription.toMap(),
      where: 'prescription_id = ?',
      whereArgs: [prescription.prescriptionId],
    );
  }

  Future<int> deletePrescription(int id) async {
    final db = await database;
    return await db.delete('prescriptions', where: 'prescription_id = ?', whereArgs: [id]);
  }
}
