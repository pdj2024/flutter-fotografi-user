import 'package:isar/isar.dart';
import 'package:mpjnew/src/data/models/room_chat_model.dart';

// Jalankan: dart run build_runner build
part 'room_chat_entity.g.dart';

/// Isar collection untuk room chat.
///
/// Migrasi dari Hive (typeId: 7) ke Isar.
/// Perubahan utama:
/// - `id` (int, auto-increment) sebagai primary key Isar
/// - `roomId` (String) sebagai unique business key
/// - `tipeUserLawan` ditambahkan (ada di RoomChatModel tapi tidak di Hive entity sebelumnya)
@collection
class RoomChatEntity {
  /// Primary key Isar (auto-increment). Tidak perlu di-set manual.
  Id id = Isar.autoIncrement;

  /// Business key unik — gunakan ini untuk lookup by room ID.
  @Index(unique: true, replace: true)
  late String roomId;

  late String roomType; // direct | group

  String? usernameLawan;

  late String idLawan;

  String? idMediaLawan;

  /// ✅ Field ini ada di RoomChatModel tapi hilang di Hive entity lama — ditambahkan kembali
  String? tipeUserLawan;

  late DateTime lastMessageAt;

  late String lastMessage;

  int unread = 0;

  List<String> userIds = [];

  // ✅ Tracking message status (sama seperti Hive entity lama)
  int countStatusSent = 0;
  List<String> listIdMessageSent = [];
  int countStatusReceived = 0;
  List<String> listIdMessageReceived = [];

  // =========================================
  // HELPER GETTERS
  // =========================================

  @ignore
  bool get hasUnread => countStatusReceived > 0;

  @ignore
  int get actualUnreadCount => countStatusReceived;

  @ignore
  String get displayName => usernameLawan ?? 'Unknown';

  @ignore
  String get previewMessage {
    if (lastMessage.isEmpty) return 'Belum ada pesan';
    if (lastMessage.length > 50) {
      return '${lastMessage.substring(0, 50)}...';
    }
    return lastMessage;
  }

  @ignore
  String getPartnerId(String currentUserId) {
    if (userIds.length != 2) return '';
    return userIds.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
  }

  // =========================================
  // FACTORY CONSTRUCTORS
  // =========================================

  RoomChatEntity();

  /// Buat dari RoomChatModel
  factory RoomChatEntity.fromRoomChatModel(RoomChatModel model) {
    return RoomChatEntity()
      ..roomId = model.roomId
      ..roomType = model.roomType
      ..usernameLawan = model.usernameLawan
      ..idLawan = model.idLawan
      ..idMediaLawan = model.idMediaLawan
      ..tipeUserLawan = model.tipeUserLawan
      ..lastMessageAt = model.lastMessageAt
      ..lastMessage = model.lastMessage
      ..unread = model.unread ?? 0
      ..userIds = List<String>.from(model.userIds)
      ..countStatusSent = model.countStatusSent
      ..listIdMessageSent = List<String>.from(model.listIdMessageSent)
      ..countStatusReceived = model.countStatusReceived
      ..listIdMessageReceived = List<String>.from(model.listIdMessageReceived);
  }

  // =========================================
  // CONVERTERS
  // =========================================

  /// Convert ke RoomChatModel untuk kompatibilitas UI/BLoC
  RoomChatModel toRoomChatModel() {
    return RoomChatModel(
      roomId: roomId,
      roomType: roomType,
      usernameLawan: usernameLawan,
      idLawan: idLawan,
      idMediaLawan: idMediaLawan,
      tipeUserLawan: tipeUserLawan,
      lastMessageAt: lastMessageAt,
      lastMessage: lastMessage,
      status: 'aktif',
      unread: unread,
      userIds: userIds,
      countStatusSent: countStatusSent,
      listIdMessageSent: listIdMessageSent,
      countStatusReceived: countStatusReceived,
      listIdMessageReceived: listIdMessageReceived,
    );
  }

  /// Copy with
  RoomChatEntity copyWith({
    String? lastMessage,
    DateTime? lastMessageAt,
    int? unread,
    int? countStatusSent,
    List<String>? listIdMessageSent,
    int? countStatusReceived,
    List<String>? listIdMessageReceived,
  }) {
    return RoomChatEntity()
      ..id = id
      ..roomId = roomId
      ..roomType = roomType
      ..usernameLawan = usernameLawan
      ..idLawan = idLawan
      ..idMediaLawan = idMediaLawan
      ..tipeUserLawan = tipeUserLawan
      ..lastMessageAt = lastMessageAt ?? this.lastMessageAt
      ..lastMessage = lastMessage ?? this.lastMessage
      ..unread = unread ?? this.unread
      ..userIds = List<String>.from(userIds)
      ..countStatusSent = countStatusSent ?? this.countStatusSent
      ..listIdMessageSent =
          listIdMessageSent ?? List<String>.from(this.listIdMessageSent)
      ..countStatusReceived = countStatusReceived ?? this.countStatusReceived
      ..listIdMessageReceived = listIdMessageReceived ??
          List<String>.from(this.listIdMessageReceived);
  }

  @override
  String toString() {
    return 'RoomChatEntity(id: $id, roomId: $roomId, partner: $usernameLawan, '
        'unread: $actualUnreadCount, received: $countStatusReceived)';
  }
}