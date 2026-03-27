import 'package:isar/isar.dart';
import 'package:mpjnew/src/data/models/room_chat_model.dart';

part 'room_chat_entity.g.dart';

@collection
class RoomChatEntity {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String roomId;

  late String roomType;

  String? usernameLawan;
  late String idLawan;
  String? idMediaLawan;
  String? tipeUserLawan;

  late DateTime lastMessageAt;
  late String lastMessage;

  int unread = 0;
  List<String> userIds = [];

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
    if (lastMessage.length > 50) return '${lastMessage.substring(0, 50)}...';
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

  /// ✅ FIX: copyWith support semua field.
  ///
  /// Field yang ditambahkan vs versi lama:
  ///   - usernameLawan, idMediaLawan: untuk update nama/avatar dari API
  ///   - userIds, idLawan, roomType, tipeUserLawan: data lengkap dari API
  ///
  /// Diperlukan saat drainPendingRoomFetch update minimal room
  /// (yang hanya punya roomId + idLawan + preview dari FCM)
  /// dengan data lengkap dari API response.
  RoomChatEntity copyWith({
    // Field dari API (sebelumnya tidak ada di copyWith)
    String? roomType,
    String? usernameLawan,
    String? idLawan,
    String? idMediaLawan,
    String? tipeUserLawan,
    List<String>? userIds,
    // Field yang sudah ada sebelumnya
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
      ..roomType = roomType ?? this.roomType
      ..usernameLawan = usernameLawan ?? this.usernameLawan
      ..idLawan = idLawan ?? this.idLawan
      ..idMediaLawan = idMediaLawan ?? this.idMediaLawan
      ..tipeUserLawan = tipeUserLawan ?? this.tipeUserLawan
      ..lastMessageAt = lastMessageAt ?? this.lastMessageAt
      ..lastMessage = lastMessage ?? this.lastMessage
      ..unread = unread ?? this.unread
      ..userIds = userIds ?? List<String>.from(this.userIds)
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