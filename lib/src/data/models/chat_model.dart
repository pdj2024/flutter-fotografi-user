class ChatModel {
  final String messageId;
  final String roomId;
  final String senderId;
  final String tipeUser;
  final String message;
  final String jenisPesan;
  final String? idPaket;
  final String? noInvoice;
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
    required this.idPaket,
    required this.noInvoice,
    required this.sentAt,
    required this.editedAt,
    required this.userIds,
  });

  /// COPY WITH
  ChatModel copyWith({
    String? messageId,
    String? roomId,
    String? senderId,
    String? tipeUser,
    String? message,
    String? jenisPesan,
    String? idPaket,
    String? noInvoice,
    DateTime? sentAt,
    DateTime? editedAt,
    List<String>? userIds,
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
      sentAt: sentAt ?? this.sentAt,
      editedAt: editedAt ?? this.editedAt,
      userIds: userIds ?? List<String>.from(this.userIds),
    );
  }

  /// FROM JSON
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
      sentAt: DateTime.parse(json["Sent_At"]),
      editedAt:
          json["Edited_At"] != null ? DateTime.parse(json["Edited_At"]) : null,
      userIds:
          json["User_Ids"] != null ? List<String>.from(json["User_Ids"]) : [],
    );
  }

  /// TO JSON
  Map<String, dynamic> toJson() {
    return {
      "Message_Id": messageId,
      "Room_Id": roomId,
      "Sender_Id": senderId,
      "Tipe_User": tipeUser,
      "Message": message,
      "Jenis_Pesan": jenisPesan,
      "Id_Paket": idPaket,
      "No_Invoice": noInvoice,
      "Sent_At": sentAt.toIso8601String(),
      "Edited_At": editedAt?.toIso8601String(),
      "User_Ids": userIds,
    };
  }
}
