/// ✅ FIXED: Enum untuk status pengiriman pesan
/// Status flow: pending → sent → received → read (or failed)
enum SendStatus {
  pending('pending'), // Local only, belum hit API
  sent('sent'), // Terkirim ke server
  received('received'), // ✅ Changed from 'delivered' - Diterima di device
  read('read'), // Dibaca oleh penerima
  failed('failed'); // Gagal terkirim

  final String value;
  const SendStatus(this.value);

  static SendStatus fromString(String? status) {
    if (status == null || status.isEmpty) return SendStatus.pending;

    // ✅ Handle backward compatibility for 'delivered'
    if (status.toLowerCase() == 'delivered') {
      return SendStatus.received;
    }

    return SendStatus.values.firstWhere(
      (e) => e.value.toLowerCase() == status.toLowerCase(),
      orElse: () => SendStatus.pending,
    );
  }

  // ✅ Updated getters
  bool get isPending => this == SendStatus.pending;
  bool get isSent => this == SendStatus.sent;
  bool get isReceived =>
      this == SendStatus.received; // ✅ Changed from isDelivered
  bool get isRead => this == SendStatus.read;
  bool get isFailed => this == SendStatus.failed;

  // ✅ Composite checks
  bool get isSuccessful => index >= SendStatus.sent.index && !isFailed;
  bool get isUnread => index < SendStatus.read.index && !isFailed;
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

/// Satu-satunya sumber teks preview "pesan terakhir" di room list.
///
/// [jenis] HARUS hasil `resolvedJenisPesan`, bukan field `jenis_pesan` mentah:
/// server sering mengirim "text" padahal tipe aslinya ada di no_penawaran /
/// no_invoice / id_paket. Pakai mentah → preview jatuh ke "Pesan baru".
String chatPreviewText({required JenisPesan jenis, String message = ''}) {
  if (message.isNotEmpty) return message;
  switch (jenis) {
    case JenisPesan.paket:
      return '📦 Paket ditawarkan';
    case JenisPesan.penawaran:
      return '💰 Penawaran baru';
    case JenisPesan.pesanan:
      return '🧾 Detail pesanan';
    case JenisPesan.image:
      return '🖼️ Gambar';
    case JenisPesan.text:
    case JenisPesan.system:
      return 'Pesan baru';
  }
}

/// ✅ FIXED: ChatModel with correct status field names
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
  final String sendStatus; // pending, sent, received, read, failed
  final String roomType;
  final DateTime sentAt;
  final DateTime? editedAt;
  final DateTime? receivedAt; // ✅ Changed from deliveredAt
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
    this.receivedAt, // ✅ Changed
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
      // ✅ Changed: Handle both receivedAt and deliveredAt for backward compatibility
      receivedAt: json["Received_At"] != null ||
              json["receivedAt"] != null ||
              json["Delivered_At"] != null ||
              json["deliveredAt"] != null
          ? _parseDateTime(json["Received_At"] ??
              json["receivedAt"] ??
              json["Delivered_At"] ??
              json["deliveredAt"])
          : null,
      readAt: json["Read_At"] != null || json["readAt"] != null
          ? _parseDateTime(json["Read_At"] ?? json["readAt"])
          : null,
      userIds: _parseUserIds(
          json["User_Ids"] ?? json["userIds"] ?? json["user_Ids"]),
      receiverIds: _parseUserIds(json["Receiver_Ids"]),
      localId: json["Local_Id"]?.toString() ?? json["localId"]?.toString(),
    );
  }

  /// FROM SignalR event data
  factory ChatModel.fromFCM(Map<String, dynamic> json, String currentUserId) {
    return ChatModel(
      messageId: json["message_id"]?.toString() ?? "",
      roomId: json["room_id"]?.toString() ?? "",
      senderId: json["sender_id"]?.toString() ?? "",
      tipeUser: json["tipe_user"]?.toString() ?? "",
      message: json["message"]?.toString() ?? "",
      jenisPesan: json["jenis_pesan"]?.toString() ?? "text",
      idPaket: json["id_paket"]?.toString(),
      noInvoice:
          json["no_invoice"]?.toString() ?? json["no_pesanan"]?.toString(),
      noPenawaran: json["no_penawaran"]?.toString(),
      status: json["status"]?.toString() ?? "aktif",
      sendStatus: json["send_status"]?.toString() ?? "sent",
      roomType: json["roomType"]?.toString() ?? "direct",
      sentAt: _parseDateTime(json["sent_at"]),
      editedAt:
          json["edited_at"] != null ? _parseDateTime(json["edited_at"]) : null,
      // ✅ Changed: Handle both receivedAt and deliveredAt
      receivedAt: json["receivedAt"] != null || json["deliveredAt"] != null
          ? _parseDateTime(json["receivedAt"] ?? json["deliveredAt"])
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
      "Received_At": receivedAt?.toUtc().toIso8601String(), // ✅ Changed
      "Read_At": readAt?.toUtc().toIso8601String(),
      "user_Ids": userIds,
      "receiver_Ids": receiverIds,
    };
  }

  Map<String, dynamic> toJsonUpdate() {
    return {
      "message": message,
      "status": status,
      "send_status": sendStatus,
      "id_Paket": idPaket,
      "no_invoice": noInvoice,
      "no_penawaran": noPenawaran,
      "receiver_Ids": receiverIds,
    };
  }

  Map<String, dynamic> toJsonQueue() {
    return {
      // ✅ Key sama persis dengan yang dibaca fromJson()
      "Message_Id": messageId,
      "Room_Id": roomId,
      "Sender_Id": senderId,
      "Tipe_User": tipeUser,
      "Message": message,
      "Jenis_Pesan": jenisPesan,
      "Id_Paket": idPaket,
      "No_Pesanan": noInvoice,
      "No_Penawaran": noPenawaran,
      "Status": status,
      "Send_Status": sendStatus,
      "Room_Type": roomType,
      "Sent_At": sentAt.toUtc().toIso8601String(),
      "Edited_At": editedAt?.toUtc().toIso8601String(),
      "Received_At": receivedAt?.toUtc().toIso8601String(),
      "Read_At": readAt?.toUtc().toIso8601String(),
      "User_Ids": userIds,
      "Receiver_Ids": receiverIds,
      "Local_Id": localId, // ✅ Wajib ada untuk offline queue tracking
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
    DateTime? receivedAt, // ✅ Changed
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
      receivedAt: receivedAt ?? this.receivedAt, // ✅ Changed
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

  // ✅ Backward compatibility getter
  @Deprecated('Use receivedAt instead')
  DateTime? get deliveredAt => receivedAt;
}
