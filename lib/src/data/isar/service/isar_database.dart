import 'package:isar/isar.dart';
import 'package:mpjnew/src/data/isar/data/chat_message_entity.dart';
import 'package:mpjnew/src/data/isar/data/room_chat_entity.dart';
import 'package:path_provider/path_provider.dart';

/// Helper untuk inisialisasi Isar dan contoh query umum.
///
/// Tambahkan dependency di pubspec.yaml:
/// ```yaml
/// dependencies:
///   isar: ^3.1.0+1
///   isar_flutter_libs: ^3.1.0+1  # include native binaries
///   path_provider: ^2.0.0
///
/// dev_dependencies:
///   isar_generator: ^3.1.0+1
///   build_runner: ^2.4.0
/// ```
///
/// Lalu jalankan code generation:
/// ```bash
/// dart run build_runner build --delete-conflicting-outputs
/// ```
class IsarDatabase {
  static Isar? _instance;

  static Future<Isar> getInstance() async {
    if (_instance != null && _instance!.isOpen) return _instance!;

    final dir = await getApplicationDocumentsDirectory();

    _instance = await Isar.open(
      [
        ChatMessageEntitySchema,
        RoomChatEntitySchema,
      ],
      directory: dir.path,
      name: 'chat_db', // Nama database — bisa diganti
    );

    return _instance!;
  }

  static Future<void> close() async {
    await _instance?.close();
    _instance = null;
  }
}

// =========================================
// CONTOH QUERY UMUM
// =========================================

/// Contoh repository pattern untuk ChatMessageEntity
class ChatMessageIsarRepo {
  final Isar isar;
  ChatMessageIsarRepo(this.isar);

  // --- READ ---

  /// Ambil semua pesan berdasarkan roomId, diurutkan dari terlama
  Future<List<ChatMessageEntity>> getByRoom(String roomId) async {
    return isar.chatMessageEntitys
        .filter()
        .roomIdEqualTo(roomId)
        .sortBySentAt()
        .findAll();
  }

  /// Ambil pesan by messageId (business key)
  Future<ChatMessageEntity?> getByMessageId(String messageId) async {
    return isar.chatMessageEntitys
        .filter()
        .messageIdEqualTo(messageId)
        .findFirst();
  }

  /// Ambil pesan pending yang belum terkirim
  Future<List<ChatMessageEntity>> getPendingMessages(String roomId) async {
    return isar.chatMessageEntitys
        .filter()
        .roomIdEqualTo(roomId)
        .sendStatusEqualTo('pending')
        .findAll();
  }

  // --- WRITE ---

  /// Simpan atau update satu pesan (upsert by messageId karena @Index unique+replace)
  Future<void> save(ChatMessageEntity entity) async {
    await isar.writeTxn(() async {
      await isar.chatMessageEntitys.put(entity);
    });
  }

  /// Simpan banyak pesan sekaligus
  Future<void> saveAll(List<ChatMessageEntity> entities) async {
    await isar.writeTxn(() async {
      await isar.chatMessageEntitys.putAll(entities);
    });
  }

  /// Update sendStatus pesan by messageId
  Future<void> updateStatus(String messageId, String newStatus) async {
    final entity = await getByMessageId(messageId);
    if (entity == null) return;

    await isar.writeTxn(() async {
      entity.sendStatus = newStatus;
      await isar.chatMessageEntitys.put(entity);
    });
  }

  /// Hapus pesan by messageId
  Future<void> deleteByMessageId(String messageId) async {
    final entity = await getByMessageId(messageId);
    if (entity == null) return;

    await isar.writeTxn(() async {
      await isar.chatMessageEntitys.delete(entity.id);
    });
  }

  /// Hapus semua pesan di room tertentu
  Future<void> deleteByRoom(String roomId) async {
    await isar.writeTxn(() async {
      await isar.chatMessageEntitys
          .filter()
          .roomIdEqualTo(roomId)
          .deleteAll();
    });
  }

  // --- STREAM (realtime) ---

  /// Watch perubahan pesan di room tertentu (untuk update UI otomatis)
  Stream<List<ChatMessageEntity>> watchRoom(String roomId) {
    return isar.chatMessageEntitys
        .filter()
        .roomIdEqualTo(roomId)
        .sortBySentAt()
        .watch(fireImmediately: true);
  }
}

/// Contoh repository pattern untuk RoomChatEntity
class RoomChatIsarRepo {
  final Isar isar;
  RoomChatIsarRepo(this.isar);

  // --- READ ---

  /// Ambil semua room, urutkan dari yang paling baru ada pesan
  Future<List<RoomChatEntity>> getAllRooms() async {
    return isar.roomChatEntitys
        .where()
        .sortByLastMessageAtDesc()
        .findAll();
  }

  /// Ambil room by roomId (business key)
  Future<RoomChatEntity?> getByRoomId(String roomId) async {
    return isar.roomChatEntitys
        .filter()
        .roomIdEqualTo(roomId)
        .findFirst();
  }

  /// Ambil room yang punya unread messages
  Future<List<RoomChatEntity>> getRoomsWithUnread() async {
    return isar.roomChatEntitys
        .filter()
        .countStatusReceivedGreaterThan(0)
        .findAll();
  }

  // --- WRITE ---

  /// Simpan atau update room
  Future<void> save(RoomChatEntity entity) async {
    await isar.writeTxn(() async {
      await isar.roomChatEntitys.put(entity);
    });
  }

  /// Update last message dan timestamp
  Future<void> updateLastMessage(
    String roomId,
    String message,
    DateTime sentAt,
  ) async {
    final entity = await getByRoomId(roomId);
    if (entity == null) return;

    await isar.writeTxn(() async {
      entity.lastMessage = message;
      entity.lastMessageAt = sentAt;
      await isar.roomChatEntitys.put(entity);
    });
  }

  /// Clear unread count untuk room
  Future<void> clearUnread(String roomId) async {
    final entity = await getByRoomId(roomId);
    if (entity == null) return;

    await isar.writeTxn(() async {
      entity.unread = 0;
      entity.countStatusReceived = 0;
      entity.listIdMessageReceived = [];
      await isar.roomChatEntitys.put(entity);
    });
  }

  // --- STREAM ---

  /// Watch semua room (untuk update list UI otomatis)
  Stream<List<RoomChatEntity>> watchAllRooms() {
    return isar.roomChatEntitys
        .where()
        .sortByLastMessageAtDesc()
        .watch(fireImmediately: true);
  }
}