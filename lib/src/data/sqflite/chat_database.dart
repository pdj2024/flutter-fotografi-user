import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// Low-level sqflite database helper.
/// Bertanggung jawab HANYA untuk inisialisasi dan pembuatan tabel.
class ChatDatabase {
  static final ChatDatabase instance = ChatDatabase._();
  ChatDatabase._();

  Database? _db;

  Future<Database> get db async {
    _db ??= await _init();
    return _db!;
  }

  Future<Database> _init() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, 'chat_db.sqlite');
    debugPrint('[ChatDatabase] 📂 Opening database at $path');
    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    debugPrint('[ChatDatabase] 🏗️ Creating tables (v$version)');

    await db.execute('''
      CREATE TABLE rooms (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        room_id TEXT UNIQUE NOT NULL,
        room_type TEXT NOT NULL,
        username_lawan TEXT,
        id_lawan TEXT NOT NULL,
        id_media_lawan TEXT,
        tipe_user_lawan TEXT,
        last_message_at INTEGER NOT NULL,
        last_message TEXT NOT NULL,
        unread INTEGER NOT NULL DEFAULT 0,
        user_ids TEXT NOT NULL DEFAULT '[]',
        count_status_sent INTEGER NOT NULL DEFAULT 0,
        list_id_message_sent TEXT NOT NULL DEFAULT '[]',
        count_status_received INTEGER NOT NULL DEFAULT 0,
        list_id_message_received TEXT NOT NULL DEFAULT '[]'
      )
    ''');

    await db.execute('''
      CREATE TABLE messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        message_id TEXT UNIQUE NOT NULL,
        room_id TEXT NOT NULL,
        sender_id TEXT NOT NULL,
        message TEXT NOT NULL,
        send_status TEXT NOT NULL,
        sent_at INTEGER NOT NULL,
        local_id TEXT,
        jenis_pesan TEXT,
        id_paket TEXT,
        no_penawaran TEXT,
        no_invoice TEXT,
        paket TEXT,
        penawaran TEXT,
        pesanan TEXT,
        read_at INTEGER,
        received_at INTEGER,
        receiver_ids TEXT NOT NULL DEFAULT '[]'
      )
    ''');

    await db.execute(
        'CREATE INDEX idx_messages_room_id ON messages(room_id)');
    await db.execute(
        'CREATE INDEX idx_messages_send_status ON messages(send_status)');
    await db.execute(
        'CREATE INDEX idx_messages_local_id ON messages(local_id)');
    await db.execute(
        'CREATE INDEX idx_rooms_last_message_at ON rooms(last_message_at DESC)');

    debugPrint('[ChatDatabase] ✅ Tables created');
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
    debugPrint('[ChatDatabase] 🔒 Database closed');
  }
}
