class ChatModel {
  final String messageId;
  final String roomId;
  final String senderId;
  final String tipeUser;
  final String message;
  final String jenisPesan;

  final String? idPaket;
  final String? noInvoice;
  final String? noPenawaran;

  final String status;
  final String sendStatus;
  final String roomType;

  final DateTime sentAt;
  final DateTime? editedAt;
  final List<String> userIds;

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
    required this.userIds,
  });

  /// FROM JSON (REST API)
  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      messageId: json["Message_Id"] ?? "",
      roomId: json["Room_Id"] ?? "",
      senderId: json["Sender_Id"] ?? "",
      tipeUser: json["Tipe_User"] ?? "",
      message: json["Message"] ?? "",
      jenisPesan: json["Jenis_Pesan"] ?? "",
      idPaket: json["Id_Paket"],
      noInvoice: json["No_Invoice"],
      noPenawaran: json["No_Penawaran"],
      status: json["Status"] ?? "aktif",
      sendStatus: json["Send_Status"] ?? "",
      roomType: json["Room_Type"] ?? "direct",
      sentAt: DateTime.parse(json["Sent_At"]),
      editedAt:
          json["Edited_At"] != null ? DateTime.parse(json["Edited_At"]) : null,
      userIds:
          json["User_Ids"] != null ? List<String>.from(json["User_Ids"]) : [],
    );
  }

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
      "Sent_At": sentAt.toIso8601String(),
      "Edited_At": editedAt?.toIso8601String(),
      "user_Ids": userIds,
    };
  }

  /// TO JSON (SignalR)
  Map<String, dynamic> toSignalRJson() {
    return {
      "messageId": messageId,
      "roomId": roomId,
      "sender": senderId,
      "message": message,
      "sentAt": sentAt.toIso8601String(),
      "editedAt": editedAt?.toIso8601String(),
      "tipeUser": tipeUser,
      "noInvoice": noInvoice,
      "noPenawaran": noPenawaran,
      "idPaket": idPaket,
      "status": status,
      "jenisPesan": jenisPesan,
      "sendStatus": sendStatus,
      "roomType": roomType,
    };
  }
}
