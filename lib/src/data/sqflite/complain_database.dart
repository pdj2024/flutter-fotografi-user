import 'package:flutter/foundation.dart';
import 'package:mpjnew/src/data/models/complain_model.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// Low-level sqflite database untuk cache "apakah order ini punya Complain".
/// Hanya menyimpan no_order + no_complain + status — BUKAN isi pesan.
class ComplainDatabase {
  static final ComplainDatabase instance = ComplainDatabase._();
  ComplainDatabase._();

  Database? _db;

  Future<Database> get db async {
    _db ??= await _init();
    return _db!;
  }

  Future<Database> _init() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, 'complain_exists_db.sqlite');
    debugPrint('[ComplainDatabase] 📂 Opening database at $path');
    return openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE complain_exists (
        no_order TEXT PRIMARY KEY,
        no_complain TEXT NOT NULL,
        status TEXT NOT NULL
      )
    ''');
  }

  Future<ComplainExistence?> get(String noOrder) async {
    final database = await db;
    final rows = await database.query(
      'complain_exists',
      where: 'no_order = ?',
      whereArgs: [noOrder],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ComplainExistence(
      noComplain: rows.first['no_complain'] as String,
      status: rows.first['status'] as String,
    );
  }

  Future<void> put(String noOrder, ComplainExistence value) async {
    final database = await db;
    await database.insert(
      'complain_exists',
      {
        'no_order': noOrder,
        'no_complain': value.noComplain,
        'status': value.status,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> remove(String noOrder) async {
    final database = await db;
    await database.delete('complain_exists', where: 'no_order = ?', whereArgs: [noOrder]);
  }
}
