/// Model data yang diterima dari FCM payload
/// Digunakan baik di foreground maupun background isolate
class FcmChatMessage {
  final String messageId;
  final String roomId;
  final String senderId;
  final String senderName;
  final String message;
  final String jenisPesan;
  final String sendStatus;
  final String tipeUser;
  final DateTime sentAt;

  // Optional fields
  final String? idPaket;
  final String? noPenawaran;
  final String? noInvoice;
  final List<String> userIds;
  final List<String> receiverIds;

  const FcmChatMessage({
    required this.messageId,
    required this.roomId,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.jenisPesan,
    required this.sendStatus,
    required this.tipeUser,
    required this.sentAt,
    this.idPaket,
    this.noPenawaran,
    this.noInvoice,
    this.userIds = const [],
    this.receiverIds = const [],
  });

  // =========================================
  // FACTORY: dari FCM data payload (Map<String, dynamic>)
  // Mendukung snake_case (dari FCM backend) maupun camelCase
  // =========================================
  factory FcmChatMessage.fromFcmPayload(Map<String, dynamic> data) {
    return FcmChatMessage(
      messageId: data['message_id']?.toString() ??
          data['messageId']?.toString() ??
          '',
      roomId:
          data['room_id']?.toString() ?? data['roomId']?.toString() ?? '',
      senderId: data['sender_id']?.toString() ??
          data['senderId']?.toString() ??
          data['sender']?.toString() ??
          '',
      senderName: data['sender_name']?.toString() ??
          data['senderName']?.toString() ??
          'Unknown',
      message: data['message']?.toString() ?? '',
      jenisPesan: data['jenis_pesan']?.toString() ??
          data['jenisPesan']?.toString() ??
          'text',
      sendStatus: data['send_status']?.toString() ??
          data['sendStatus']?.toString() ??
          'sent',
      tipeUser: data['tipe_user']?.toString() ??
          data['tipeUser']?.toString() ??
          '',
      sentAt: _parseDateTime(
          data['sent_at'] ?? data['sentAt'] ?? data['timestamp']),
      idPaket:
          data['id_paket']?.toString() ?? data['idPaket']?.toString(),
      noPenawaran: data['no_penawaran']?.toString() ??
          data['noPenawaran']?.toString(),
      noInvoice: data['no_invoice']?.toString() ??
          data['noInvoice']?.toString() ??
          data['no_pesanan']?.toString(),
      userIds: _parseList(data['user_ids'] ?? data['userIds']),
      receiverIds:
          _parseList(data['receiver_ids'] ?? data['receiverIds']),
    );
  }

  factory FcmChatMessage.fromJson(Map<String, dynamic> json) =>
      FcmChatMessage.fromFcmPayload(json);

  Map<String, dynamic> toJson() => {
        'message_id': messageId,
        'room_id': roomId,
        'sender_id': senderId,
        'sender_name': senderName,
        'message': message,
        'jenis_pesan': jenisPesan,
        'send_status': sendStatus,
        'tipe_user': tipeUser,
        'sent_at': sentAt.toUtc().toIso8601String(),
        'id_paket': idPaket,
        'no_penawaran': noPenawaran,
        'no_invoice': noInvoice,
        'user_ids': userIds,
        'receiver_ids': receiverIds,
      };

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

  static List<String> _parseList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.map((e) => e.toString()).toList();
    if (value is String) {
      // Kadang dikirim sebagai JSON string: "[\"id1\",\"id2\"]"
      try {
        final decoded = value.replaceAll('[', '').replaceAll(']', '');
        return decoded
            .split(',')
            .map((e) => e.trim().replaceAll('"', ''))
            .where((e) => e.isNotEmpty)
            .toList();
      } catch (_) {
        return [];
      }
    }
    return [];
  }

  bool get isTextMessage => jenisPesan == 'text';
  bool get isPaket => jenisPesan == 'paket' || (idPaket?.isNotEmpty ?? false);
  bool get isPenawaran =>
      jenisPesan == 'penawaran' || (noPenawaran?.isNotEmpty ?? false);
  bool get isPesanan =>
      jenisPesan == 'pesanan' || (noInvoice?.isNotEmpty ?? false);

  // =========================================
  // BRIDGE: FcmChatMessage → ChatModel (existing model)
  // Dipakai di main.dart untuk meneruskan pesan ke ChatProvider lama
  // =========================================

  /// Konversi ke Map yang compatible dengan ChatModel.fromJson().
  ///
  /// Contoh penggunaan di main.dart / vendor_bottom_nav.dart:
  ///   import 'package:mpjvendor/src/data/models/chat_model.dart';
  ///   final chatModel = ChatModel.fromJson(fcmMessage.toChatModelJson());
  ///   chatProvider.handleMessageFromFCM(chatModel);
  Map<String, dynamic> toChatModelJson() {
    return {
      'Message_Id': messageId,
      'Room_Id': roomId,
      'Sender_Id': senderId,
      'Tipe_User': tipeUser,
      'Message': message,
      'Jenis_Pesan': jenisPesan,
      'Id_Paket': idPaket,
      'No_Penawaran': noPenawaran,
      'No_Pesanan': noInvoice,
      'Status': 'aktif',
      'Send_Status': sendStatus,
      'Room_Type': 'direct',
      'Sent_At': sentAt.toUtc().toIso8601String(),
      'User_Ids': userIds,
      'Receiver_Ids': receiverIds,
    };
  }

  @override
  String toString() =>
      'FcmChatMessage(id: $messageId, room: $roomId, sender: $senderId, '
      'status: $sendStatus, msg: ${message.length > 30 ? '${message.substring(0, 30)}...' : message})';

  @override
  bool operator ==(Object other) =>
      other is FcmChatMessage && other.messageId == messageId;

  @override
  int get hashCode => messageId.hashCode;
}