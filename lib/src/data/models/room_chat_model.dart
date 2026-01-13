import 'chat_model.dart';

class RoomChatModel {
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
  });

  // =========================================
  // HELPER GETTERS
  // =========================================

  /// Cek apakah ada unread messages
  bool get hasUnread => (unread ?? 0) > 0;

  /// Get display name
  String get displayName => usernameLawan ?? 'Unknown';

  /// Get preview message
  String get previewMessage {
    if (lastMessage.isEmpty) return 'Belum ada pesan';
    return lastMessage;
  }

  /// Get partner ID (alias untuk idLawan)
  String get partnerId => idLawan;

  /// Get partner ID dari userIds jika idLawan tidak ada
  String? getPartnerId(String currentUserId) {
    if (idLawan.isNotEmpty) return idLawan;
    try {
      return userIds.firstWhere((id) => id != currentUserId);
    } catch (_) {
      return null;
    }
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
    );
  }

  /// Update dengan pesan baru
  RoomChatModel withNewMessage(ChatModel message, {bool incrementUnread = false}) {
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

  /// Clear unread count
  RoomChatModel clearUnread() {
    return copyWith(unread: 0);
  }

  // =========================================
  // FROM JSON
  // =========================================
  factory RoomChatModel.fromJson(Map<String, dynamic> json) {
    return RoomChatModel(
      roomId: json["Room_Id"]?.toString() ?? json["roomId"]?.toString() ?? "",
      roomType: json["Room_Type"]?.toString() ?? json["roomType"]?.toString() ?? "direct",
      usernameLawan: json["Username_Lawan"]?.toString() ?? json["usernameLawan"]?.toString(),
      idLawan: json["Id_Lawan"]?.toString() ?? json["idLawan"]?.toString() ?? "",
      idMediaLawan: json["Id_Media_Lawan"]?.toString() ?? json["idMediaLawan"]?.toString(),
      tipeUserLawan: json["Tipe_User_Lawan"]?.toString() ?? json["tipeUserLawan"]?.toString(),
      lastMessageAt: _parseDateTime(json["Last_Message_At"] ?? json["lastMessageAt"]),
      lastMessage: json["Last_Message"]?.toString() ?? json["lastMessage"]?.toString() ?? "",
      status: json["Status"]?.toString() ?? json["status"]?.toString() ?? "aktif",
      unread: int.tryParse(json["Unread"]?.toString() ?? json["unread"]?.toString() ?? "0"),
      userIds: _parseUserIds(json["User_Ids"] ?? json["userIds"]),
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

  @override
  String toString() {
    return 'RoomChatModel(id: $roomId, partner: $usernameLawan, unread: $unread)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RoomChatModel && other.roomId == roomId;
  }

  @override
  int get hashCode => roomId.hashCode;
}