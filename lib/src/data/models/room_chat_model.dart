import 'package:equatable/equatable.dart';

import 'chat_model.dart';

class RoomChatModel extends Equatable {
  final String roomId;
  final String roomType;
  final String? usernameLawan;
  final String idLawan;
  final String? idMediaLawan;
  final String? tipeUserLawan;
  final DateTime lastMessageAt;
  final String lastMessage;
  final String status;
  final int? unread;
  final List<String> userIds;
  
  // ✅ NEW FIELDS untuk tracking message status
  final int countStatusSent;
  final List<String> listIdMessageSent;
  final int countStatusReceived;
  final List<String> listIdMessageReceived;

  RoomChatModel({
    required this.roomId,
    required this.roomType,
    this.usernameLawan,
    required this.idLawan,
    this.idMediaLawan,
    this.tipeUserLawan,
    required this.lastMessageAt,
    required this.lastMessage,
    required this.status,
    this.unread,
    required this.userIds,
    this.countStatusSent = 0,
    this.listIdMessageSent = const [],
    this.countStatusReceived = 0,
    this.listIdMessageReceived = const [],
  });

  // =========================================
  // EQUATABLE
  // =========================================

  @override
  List<Object?> get props => [roomId];

  @override
  bool get stringify => true;

  // =========================================
  // HELPER GETTERS
  // =========================================

  /// ✅ IMPROVED: Cek unread berdasarkan received messages
  /// Untuk customer: pesan dengan status "received" adalah pesan yang belum dibaca
  bool get hasUnread => countStatusReceived > 0;

  /// ✅ IMPROVED: Get actual unread count
  int get actualUnreadCount => countStatusReceived;

  /// Get display name
  String get displayName => usernameLawan ?? 'Unknown';

  String get previewMessage {
    if (lastMessage.isEmpty) return 'Belum ada pesan';
    if (lastMessage.length > 50) {
      return '${lastMessage.substring(0, 50)}...';
    }
    return lastMessage;
  }

  /// Get partner ID (alias untuk idLawan)
  String get partnerId => idLawan;

  /// Get partner ID dari room (untuk direct chat)
  String getPartnerId(String currentUserId) {
    if (userIds.length != 2) return '';
    return userIds.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
  }

  // =========================================
  // COPY WITH
  // =========================================
  RoomChatModel copyWith({
    String? roomId,
    String? roomType,
    String? usernameLawan,
    String? idLawan,
    String? idMediaLawan,
    String? tipeUserLawan,
    DateTime? lastMessageAt,
    String? lastMessage,
    String? status,
    int? unread,
    List<String>? userIds,
    int? countStatusSent,
    List<String>? listIdMessageSent,
    int? countStatusReceived,
    List<String>? listIdMessageReceived,
  }) {
    return RoomChatModel(
      roomId: roomId ?? this.roomId,
      roomType: roomType ?? this.roomType,
      usernameLawan: usernameLawan ?? this.usernameLawan,
      idLawan: idLawan ?? this.idLawan,
      idMediaLawan: idMediaLawan ?? this.idMediaLawan,
      tipeUserLawan: tipeUserLawan ?? this.tipeUserLawan,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastMessage: lastMessage ?? this.lastMessage,
      status: status ?? this.status,
      unread: unread ?? this.unread,
      userIds: userIds ?? List<String>.from(this.userIds),
      countStatusSent: countStatusSent ?? this.countStatusSent,
      listIdMessageSent: listIdMessageSent ?? List<String>.from(this.listIdMessageSent),
      countStatusReceived: countStatusReceived ?? this.countStatusReceived,
      listIdMessageReceived: listIdMessageReceived ?? List<String>.from(this.listIdMessageReceived),
    );
  }

  /// Update dengan pesan baru
  RoomChatModel withNewMessage(ChatModel message,
      {bool incrementUnread = false}) {
    String preview = message.message;

    // Set preview berdasarkan jenis pesan
    if (message.message.isEmpty) {
      switch (message.resolvedJenisPesan) {
        case JenisPesan.paket:
          preview = '📦 Paket ditawarkan';
          break;
        case JenisPesan.penawaran:
          preview = '💰 Penawaran baru';
          break;
        case JenisPesan.pesanan:
          preview = '🧾 Detail pesanan';
          break;
        default:
          preview = 'Pesan baru';
      }
    }

    return copyWith(
      lastMessage: preview,
      lastMessageAt: message.sentAt,
      unread: incrementUnread ? (unread ?? 0) + 1 : unread,
    );
  }

  /// ✅ NEW: Clear unread by clearing received messages
  RoomChatModel clearUnread() {
    return copyWith(
      unread: 0,
      countStatusReceived: 0,
      listIdMessageReceived: [],
    );
  }

  // =========================================
  // FROM JSON
  // =========================================
  factory RoomChatModel.fromJson(Map<String, dynamic> json) {
    return RoomChatModel(
      roomId: json["Room_Id"]?.toString() ?? json["roomId"]?.toString() ?? "",
      roomType: json["Room_Type"]?.toString() ??
          json["roomType"]?.toString() ??
          "direct",
      usernameLawan: json["Username_Lawan"]?.toString() ??
          json["usernameLawan"]?.toString(),
      idLawan:
          json["Id_Lawan"]?.toString() ?? json["idLawan"]?.toString() ?? "",
      idMediaLawan: json["Id_Media_Lawan"]?.toString() ??
          json["idMediaLawan"]?.toString(),
      tipeUserLawan: json["Tipe_User_Lawan"]?.toString() ??
          json["tipeUserLawan"]?.toString(),
      lastMessageAt:
          _parseDateTime(json["Last_Message_At"] ?? json["lastMessageAt"]),
      lastMessage: json["Last_Message"]?.toString() ??
          json["lastMessage"]?.toString() ??
          "",
      status:
          json["Status"]?.toString() ?? json["status"]?.toString() ?? "aktif",
      unread: int.tryParse(
          json["Unread"]?.toString() ?? json["unread"]?.toString() ?? "0"),
      userIds: _parseUserIds(json["User_Ids"] ?? json["userIds"]),
      // ✅ NEW FIELDS
      countStatusSent: int.tryParse(
          json["Count_Status_Sent"]?.toString() ?? 
          json["countStatusSent"]?.toString() ?? "0") ?? 0,
      listIdMessageSent: _parseStringList(
          json["List_Id_Message_Sent"] ?? json["listIdMessageSent"]),
      countStatusReceived: int.tryParse(
          json["Count_Status_Received"]?.toString() ?? 
          json["countStatusReceived"]?.toString() ?? "0") ?? 0,
      listIdMessageReceived: _parseStringList(
          json["List_Id_Message_Received"] ?? json["listIdMessageReceived"]),
    );
  }

  /// FROM SignalR RoomCreated event
  factory RoomChatModel.fromSignalR(Map<String, dynamic> json) {
    return RoomChatModel(
      roomId: json["roomId"]?.toString() ?? "",
      roomType: json["roomType"]?.toString() ?? "direct",
      usernameLawan: json["usernameLawan"]?.toString(),
      idLawan: json["idLawan"]?.toString() ?? "",
      idMediaLawan: json["idMediaLawan"]?.toString(),
      tipeUserLawan: json["tipeUserLawan"]?.toString(),
      lastMessageAt: _parseDateTime(json["createdAt"] ?? json["lastMessageAt"]),
      lastMessage: json["lastMessage"]?.toString() ?? "",
      status: json["status"]?.toString() ?? "aktif",
      unread: 0,
      userIds: _parseUserIds(json["userIds"]),
      countStatusSent: 0,
      listIdMessageSent: [],
      countStatusReceived: 0,
      listIdMessageReceived: [],
    );
  }

  // =========================================
  // TO JSON
  // =========================================
  Map<String, dynamic> toJson() {
    return {
      "Room_Id": roomId,
      "Room_Type": roomType,
      "Username_Lawan": usernameLawan,
      "Id_Lawan": idLawan,
      "Id_Media_Lawan": idMediaLawan,
      "Tipe_User_Lawan": tipeUserLawan,
      "Last_Message_At": lastMessageAt.toUtc().toIso8601String(),
      "Last_Message": lastMessage,
      "Status": status,
      "Unread": unread,
      "User_Ids": userIds,
      "Count_Status_Sent": countStatusSent,
      "List_Id_Message_Sent": listIdMessageSent,
      "Count_Status_Received": countStatusReceived,
      "List_Id_Message_Received": listIdMessageReceived,
    };
  }

  // =========================================
  // UTILITIES
  // =========================================
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value.toLocal();
    try {
      return DateTime.parse(value.toString()).toLocal();
    } catch (_) {
      return DateTime.now();
    }
  }

  static List<String> _parseUserIds(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [];
  }

  /// ✅ NEW: Parse string list helper
  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [];
  }

  @override
  String toString() {
    return 'RoomChatModel(id: $roomId, partner: $usernameLawan, unread: $actualUnreadCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RoomChatModel && other.roomId == roomId;
  }

  @override
  int get hashCode => roomId.hashCode;
}