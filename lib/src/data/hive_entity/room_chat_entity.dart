import 'package:hive/hive.dart';
import 'package:mpjnew/src/data/models/room_chat_model.dart';

part 'room_chat_entity.g.dart';

/// Hive entity untuk room chat
/// Field minimal untuk hemat storage
@HiveType(typeId: 7)
class RoomChatEntity extends HiveObject {
  @HiveField(0)
  String roomId;

  @HiveField(1)
  String roomType; // direct, group

  @HiveField(2)
  String? usernameLawan;

  @HiveField(3)
  String idLawan;

  @HiveField(4)
  String? idMediaLawan;

  @HiveField(5)
  DateTime lastMessageAt;

  @HiveField(6)
  String lastMessage;

  @HiveField(7)
  int unread;

  @HiveField(8)
  List<String> userIds;

  // ✅ NEW FIELDS untuk tracking message status
  @HiveField(9)
  int countStatusSent;

  @HiveField(10)
  List<String> listIdMessageSent;

  @HiveField(11)
  int countStatusReceived;

  @HiveField(12)
  List<String> listIdMessageReceived;

  RoomChatEntity({
    required this.roomId,
    required this.roomType,
    this.usernameLawan,
    required this.idLawan,
    this.idMediaLawan,
    required this.lastMessageAt,
    required this.lastMessage,
    this.unread = 0,
    required this.userIds,
    this.countStatusSent = 0,
    this.listIdMessageSent = const [],
    this.countStatusReceived = 0,
    this.listIdMessageReceived = const [],
  });

  // =========================================
  // HELPER GETTERS
  // =========================================

  /// ✅ IMPROVED: hasUnread berdasarkan received count
  bool get hasUnread => countStatusReceived > 0;
  
  /// ✅ IMPROVED: actualUnreadCount dari received messages
  int get actualUnreadCount => countStatusReceived;
  
  String get displayName => usernameLawan ?? 'Unknown';

  String get previewMessage {
    if (lastMessage.isEmpty) return 'Belum ada pesan';
    if (lastMessage.length > 50) {
      return '${lastMessage.substring(0, 50)}...';
    }
    return lastMessage;
  }

  String getPartnerId(String currentUserId) {
    if (userIds.length != 2) return '';
    return userIds.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
  }

  // =========================================
  // CONVERTERS
  // =========================================

  /// Convert dari RoomChatModel (existing model)
  factory RoomChatEntity.fromRoomChatModel(RoomChatModel model) {
    return RoomChatEntity(
      roomId: model.roomId,
      roomType: model.roomType,
      usernameLawan: model.usernameLawan,
      idLawan: model.idLawan,
      idMediaLawan: model.idMediaLawan,
      lastMessageAt: model.lastMessageAt,
      lastMessage: model.lastMessage,
      unread: model.unread ?? 0,
      userIds: model.userIds,
      // ✅ NEW FIELDS
      countStatusSent: model.countStatusSent,
      listIdMessageSent: List<String>.from(model.listIdMessageSent),
      countStatusReceived: model.countStatusReceived,
      listIdMessageReceived: List<String>.from(model.listIdMessageReceived),
    );
  }

  /// Convert ke RoomChatModel (untuk kompatibilitas UI)
  RoomChatModel toRoomChatModel() {
    return RoomChatModel(
      roomId: roomId,
      roomType: roomType,
      usernameLawan: usernameLawan,
      idLawan: idLawan,
      idMediaLawan: idMediaLawan,
      lastMessageAt: lastMessageAt,
      lastMessage: lastMessage,
      status: 'aktif',
      unread: unread,
      userIds: userIds,
      // ✅ NEW FIELDS
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
    return RoomChatEntity(
      roomId: roomId,
      roomType: roomType,
      usernameLawan: usernameLawan,
      idLawan: idLawan,
      idMediaLawan: idMediaLawan,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastMessage: lastMessage ?? this.lastMessage,
      unread: unread ?? this.unread,
      userIds: userIds,
      countStatusSent: countStatusSent ?? this.countStatusSent,
      listIdMessageSent: listIdMessageSent ?? this.listIdMessageSent,
      countStatusReceived: countStatusReceived ?? this.countStatusReceived,
      listIdMessageReceived: listIdMessageReceived ?? this.listIdMessageReceived,
    );
  }

  @override
  String toString() {
    return 'RoomChatEntity(id: $roomId, partner: $usernameLawan, unread: $actualUnreadCount, received: $countStatusReceived)';
  }
}