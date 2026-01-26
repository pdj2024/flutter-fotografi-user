/// Enum untuk status pengiriman pesan
enum SendStatus {
  pending('pending'),
  sending('sending'),
  sent('sent'),
  delivered('delivered'),
  read('read'),
  failed('failed');

  final String value;
  const SendStatus(this.value);

  static SendStatus fromString(String? status) {
    if (status == null || status.isEmpty) return SendStatus.pending;
    return SendStatus.values.firstWhere(
      (e) => e.value.toLowerCase() == status.toLowerCase(),
      orElse: () => SendStatus.pending,
    );
  }

  bool get isPending => this == SendStatus.pending;
  bool get isSending => this == SendStatus.sending;
  bool get isSent => index >= SendStatus.sent.index;
  bool get isDelivered => index >= SendStatus.delivered.index;
  bool get isRead => this == SendStatus.read;
  bool get isUnread => index < SendStatus.read.index;
  bool get isFailed => this == SendStatus.failed;
}

/// Enum untuk jenis pesan
enum JenisPesan {
  text('text'),
  paket('paket'),
  penawaran('penawaran'),
  pesanan('pesanan'),
  image('image'),
  system('system');

  final String value;
  const JenisPesan(this.value);

  static JenisPesan fromString(String? type) {
    if (type == null || type.isEmpty) return JenisPesan.text;
    return JenisPesan.values.firstWhere(
      (e) => e.value.toLowerCase() == type.toLowerCase(),
      orElse: () => JenisPesan.text,
    );
  }
}

class ChatModel {
  final String messageId;
  final String roomId;
  final String senderId;
  final String tipeUser;
  final String message;
  final String jenisPesan;
  final String? idPaket;
  final String? noInvoice; // No Pesanan (jika penawaran sudah jadi pesanan)
  final String? noPenawaran;
  final String status;
  final String sendStatus;
  final String roomType;
  final DateTime sentAt;
  final DateTime? editedAt;
  final DateTime? deliveredAt;
  final DateTime? readAt;
  final List<String> userIds;
  final List<String> receiverIds;

  // Local tracking
  final String? localId;

  ChatModel({
    required this.messageId,
    required this.roomId,
    required this.senderId,
    required this.tipeUser,
    required this.message,
    required this.jenisPesan,
    this.idPaket,
    this.noInvoice,
    this.noPenawaran,
    required this.status,
    required this.sendStatus,
    required this.roomType,
    required this.sentAt,
    this.editedAt,
    this.deliveredAt,
    this.readAt,
    required this.userIds,
    required this.receiverIds,
    this.localId,
  });

  // =========================================
  // HELPER GETTERS
  // =========================================

  /// Cek apakah ini local echo (belum dikirim ke server)
  bool get isLocalEcho => localId != null && localId!.startsWith('local-');

  /// Cek apakah pesan memiliki paket
  bool get hasPaket => idPaket != null && idPaket!.isNotEmpty;

  /// Cek apakah pesan memiliki penawaran
  bool get hasPenawaran => noPenawaran != null && noPenawaran!.isNotEmpty;

  /// Cek apakah pesan memiliki pesanan (penawaran yang sudah dibayar)
  bool get hasPesanan => noInvoice != null && noInvoice!.isNotEmpty;

  /// Cek apakah penawaran sudah konversi ke pesanan
  bool get isPenawaranConverted => hasPenawaran && hasPesanan;

  /// Get send status enum
  SendStatus get sendStatusEnum => SendStatus.fromString(sendStatus);

  /// Get jenis pesan enum
  JenisPesan get jenisPesanEnum => JenisPesan.fromString(jenisPesan);

  /// Determine tipe konten yang harus ditampilkan
  /// Prioritas: Pesanan > Penawaran > Paket > Text
  JenisPesan get resolvedJenisPesan {
    // Jika penawaran sudah jadi pesanan, tampilkan sebagai pesanan
    if (hasPesanan) return JenisPesan.pesanan;
    if (hasPenawaran) return JenisPesan.penawaran;
    if (hasPaket) return JenisPesan.paket;
    return jenisPesanEnum;
  }

  /// Cek apakah pesan dari user tertentu
  bool isFromUser(String userId) => senderId == userId;

  // =========================================
  // FROM JSON (REST API)
  // =========================================
  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      messageId:
          json["Message_Id"]?.toString() ?? json["messageId"]?.toString() ?? "",
      roomId: json["Room_Id"]?.toString() ?? json["roomId"]?.toString() ?? "",
      senderId: json["Sender_Id"]?.toString() ??
          json["senderId"]?.toString() ??
          json["sender"]?.toString() ??
          "",
      tipeUser:
          json["Tipe_User"]?.toString() ?? json["tipeUser"]?.toString() ?? "",
      message: json["Message"]?.toString() ?? json["message"]?.toString() ?? "",
      jenisPesan: json["Jenis_Pesan"]?.toString() ??
          json["jenisPesan"]?.toString() ??
          "text",
      idPaket: json["Id_Paket"]?.toString() ?? json["idPaket"]?.toString(),
      noInvoice: json["No_Pesanan"]?.toString() ??
          json["No_Invoice"]?.toString() ??
          json["noPesanan"]?.toString(),
      noPenawaran:
          json["No_Penawaran"]?.toString() ?? json["noPenawaran"]?.toString(),
      status:
          json["Status"]?.toString() ?? json["status"]?.toString() ?? "aktif",
      sendStatus: json["Send_Status"]?.toString() ??
          json["sendStatus"]?.toString() ??
          "pending",
      roomType: json["Room_Type"]?.toString() ??
          json["roomType"]?.toString() ??
          "direct",
      sentAt: _parseDateTime(json["Sent_At"] ?? json["sentAt"]),
      editedAt: json["Edited_At"] != null || json["editedAt"] != null
          ? _parseDateTime(json["Edited_At"] ?? json["editedAt"])
          : null,
      deliveredAt: json["Delivered_At"] != null || json["deliveredAt"] != null
          ? _parseDateTime(json["Delivered_At"] ?? json["deliveredAt"])
          : null,
      readAt: json["Read_At"] != null || json["readAt"] != null
          ? _parseDateTime(json["Read_At"] ?? json["readAt"])
          : null,
      userIds: _parseUserIds(
          json["User_Ids"] ?? json["userIds"] ?? json["user_Ids"]),
      receiverIds: _parseUserIds(
          json["Receiver_Ids"]),
      localId: json["Local_Id"]?.toString() ?? json["localId"]?.toString(),
    );
  }

  /// FROM SignalR event data
  factory ChatModel.fromSignalR(
      Map<String, dynamic> json, String currentUserId) {
    return ChatModel(
      messageId: json["messageId"]?.toString() ?? "",
      roomId: json["roomId"]?.toString() ?? "",
      senderId:
          json["senderId"]?.toString() ?? json["sender"]?.toString() ?? "",
      tipeUser: json["tipeUser"]?.toString() ?? "",
      message: json["message"]?.toString() ?? "",
      jenisPesan: json["jenisPesan"]?.toString() ?? "text",
      idPaket: json["idPaket"]?.toString(),
      noInvoice: json["noInvoice"]?.toString() ?? json["noPesanan"]?.toString(),
      noPenawaran: json["noPenawaran"]?.toString(),
      status: json["status"]?.toString() ?? "aktif",
      sendStatus: json["sendStatus"]?.toString() ?? "sent",
      roomType: json["roomType"]?.toString() ?? "direct",
      sentAt: _parseDateTime(json["sentAt"]),
      editedAt:
          json["editedAt"] != null ? _parseDateTime(json["editedAt"]) : null,
      deliveredAt: json["deliveredAt"] != null
          ? _parseDateTime(json["deliveredAt"])
          : null,
      readAt: json["readAt"] != null ? _parseDateTime(json["readAt"]) : null,
      userIds: _parseUserIds(json["userIds"]),
      receiverIds: _parseUserIds(json["receiverIds"]),
      localId: json["localId"]?.toString(),
    );
  }

  // =========================================
  // TO JSON
  // =========================================

  /// TO JSON (REST API)
  Map<String, dynamic> toJson() {
    return {
      "message_Id": messageId,
      "room_Id": roomId,
      "sender_Id": senderId,
      "tipe_User": tipeUser,
      "message": message,
      "jenis_Pesan": jenisPesan,
      "id_Paket": idPaket,
      "no_pesanan": noInvoice,
      "no_penawaran": noPenawaran,
      "status": status,
      "send_status": sendStatus,
      "room_type": roomType,
      "Sent_At": sentAt.toUtc().toIso8601String(),
      "Edited_At": editedAt?.toUtc().toIso8601String(),
      "user_Ids": userIds,
      "receiver_Ids": receiverIds,
    };
  }

  /// TO JSON (SignalR)
  Map<String, dynamic> toSignalRJson() {
    return {
      "messageId": messageId,
      "roomId": roomId,
      "sender": senderId,
      "senderId": senderId,
      "message": message,
      "sentAt": sentAt.toUtc().toIso8601String(),
      "editedAt": editedAt?.toUtc().toIso8601String(),
      "tipeUser": tipeUser,
      "noInvoice": noInvoice,
      "noPenawaran": noPenawaran,
      "idPaket": idPaket,
      "status": status,
      "jenisPesan": jenisPesan,
      "sendStatus": sendStatus,
      "roomType": roomType,
      "localId": localId,
    };
  }

  // =========================================
  // COPY WITH
  // =========================================
  ChatModel copyWith({
    String? messageId,
    String? roomId,
    String? senderId,
    String? tipeUser,
    String? message,
    String? jenisPesan,
    String? idPaket,
    String? noInvoice,
    String? noPenawaran,
    String? status,
    String? sendStatus,
    String? roomType,
    DateTime? sentAt,
    DateTime? editedAt,
    DateTime? deliveredAt,
    DateTime? readAt,
    List<String>? userIds,
    List<String>? receiverIds,
    String? localId,
  }) {
    return ChatModel(
      messageId: messageId ?? this.messageId,
      roomId: roomId ?? this.roomId,
      senderId: senderId ?? this.senderId,
      tipeUser: tipeUser ?? this.tipeUser,
      message: message ?? this.message,
      jenisPesan: jenisPesan ?? this.jenisPesan,
      idPaket: idPaket ?? this.idPaket,
      noInvoice: noInvoice ?? this.noInvoice,
      noPenawaran: noPenawaran ?? this.noPenawaran,
      status: status ?? this.status,
      sendStatus: sendStatus ?? this.sendStatus,
      roomType: roomType ?? this.roomType,
      sentAt: sentAt ?? this.sentAt,
      editedAt: editedAt ?? this.editedAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      readAt: readAt ?? this.readAt,
      userIds: userIds ?? this.userIds,
      receiverIds: receiverIds ?? this.receiverIds,
      localId: localId ?? this.localId,
    );
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
    return 'ChatModel(id: $messageId, room: $roomId, sender: $senderId, '
        'status: $sendStatus, jenis: ${resolvedJenisPesan.value}, '
        'msg: ${message.length > 20 ? '${message.substring(0, 20)}...' : message})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatModel &&
        other.messageId == messageId &&
        other.roomId == roomId;
  }

  @override
  int get hashCode => messageId.hashCode ^ roomId.hashCode;
}
