import 'dart:convert';

import 'package:mpjnew/src/data/models/room_chat_model.dart';

class RoomChatEntity {
  int id = 0;

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

  bool get hasUnread => countStatusReceived > 0;

  int get actualUnreadCount => countStatusReceived;

  String get displayName => usernameLawan ?? 'Unknown';

  String get previewMessage {
    if (lastMessage.isEmpty) return 'Belum ada pesan';
    if (lastMessage.length > 50) return '${lastMessage.substring(0, 50)}...';
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
  // SQFLITE SERIALIZATION
  // =========================================

  Map<String, dynamic> toMap() => {
        'room_id': roomId,
        'room_type': roomType,
        'username_lawan': usernameLawan,
        'id_lawan': idLawan,
        'id_media_lawan': idMediaLawan,
        'tipe_user_lawan': tipeUserLawan,
        'last_message_at': lastMessageAt.millisecondsSinceEpoch,
        'last_message': lastMessage,
        'unread': unread,
        'user_ids': jsonEncode(userIds),
        'count_status_sent': countStatusSent,
        'list_id_message_sent': jsonEncode(listIdMessageSent),
        'count_status_received': countStatusReceived,
        'list_id_message_received': jsonEncode(listIdMessageReceived),
      };

  factory RoomChatEntity.fromMap(Map<String, dynamic> map) {
    return RoomChatEntity()
      ..id = (map['id'] as int?) ?? 0
      ..roomId = map['room_id'] as String
      ..roomType = map['room_type'] as String
      ..usernameLawan = map['username_lawan'] as String?
      ..idLawan = map['id_lawan'] as String
      ..idMediaLawan = map['id_media_lawan'] as String?
      ..tipeUserLawan = map['tipe_user_lawan'] as String?
      ..lastMessageAt = DateTime.fromMillisecondsSinceEpoch(
          map['last_message_at'] as int)
      ..lastMessage = map['last_message'] as String
      ..unread = (map['unread'] as int?) ?? 0
      ..userIds = map['user_ids'] != null
          ? List<String>.from(jsonDecode(map['user_ids'] as String))
          : []
      ..countStatusSent = (map['count_status_sent'] as int?) ?? 0
      ..listIdMessageSent = map['list_id_message_sent'] != null
          ? List<String>.from(
              jsonDecode(map['list_id_message_sent'] as String))
          : []
      ..countStatusReceived = (map['count_status_received'] as int?) ?? 0
      ..listIdMessageReceived = map['list_id_message_received'] != null
          ? List<String>.from(
              jsonDecode(map['list_id_message_received'] as String))
          : [];
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

  RoomChatEntity copyWith({
    String? roomType,
    String? usernameLawan,
    String? idLawan,
    String? idMediaLawan,
    String? tipeUserLawan,
    List<String>? userIds,
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
