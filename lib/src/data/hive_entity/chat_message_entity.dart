import 'package:hive/hive.dart';
import 'package:mpjnew/src/data/hive_entity/penawaran_model.dart';
import 'package:mpjnew/src/data/models/chat_model.dart';
import 'package:mpjnew/src/data/hive_entity/paket_model.dart';
import 'package:mpjnew/src/data/hive_entity/pesanan_model.dart';

part 'chat_message_entity.g.dart';

/// Hive entity untuk chat message
/// Field minimal untuk hemat storage
@HiveType(typeId: 0)
class ChatMessageEntity extends HiveObject {
  @HiveField(0)
  String messageId;

  @HiveField(1)
  String roomId;

  @HiveField(2)
  String senderId;

  @HiveField(3)
  String message;

  @HiveField(4)
  String sendStatus; // pending, sending, sent, delivered, read, failed

  @HiveField(5)
  DateTime sentAt;

  @HiveField(6)
  String? localId; // untuk optimistic UI

  // Optional fields
  @HiveField(7)
  String? jenisPesan; // text, paket, penawaran, pesanan

  @HiveField(8)
  PaketModel? paket;

  @HiveField(9)
  PenawaranModel? penawaran;

  @HiveField(10)
  PesananModel? pesanan;

  @HiveField(11)
  DateTime? readAt;

  @HiveField(12)
  DateTime? deliveredAt;

  @HiveField(13)
  List<String>? receiverIds;

  ChatMessageEntity({
    required this.messageId,
    required this.roomId,
    required this.senderId,
    required this.message,
    required this.sendStatus,
    required this.sentAt,
    this.localId,
    this.jenisPesan,
    this.paket,
    this.penawaran,
    this.pesanan,
    this.readAt,
    this.deliveredAt,
    this.receiverIds
  });

  // =========================================
  // HELPER GETTERS
  // =========================================

  bool get isLocalEcho => localId != null && localId!.startsWith('local-');
  bool get hasPaket => paket != null;
  bool get hasPenawaran => penawaran != null;
  bool get hasPesanan => pesanan != null;

  String get resolvedJenisPesan {
    if (hasPesanan) return 'pesanan';
    if (hasPenawaran) return 'penawaran';
    if (hasPaket) return 'paket';
    return jenisPesan ?? 'text';
  }

  // =========================================
  // CONVERTERS
  // =========================================

  /// Convert dari ChatModel (existing model)
  factory ChatMessageEntity.fromChatModel(ChatModel model,
      {PaketModel? paket, PenawaranModel? penawaran, PesananModel? pesanan}) {
    return ChatMessageEntity(
      messageId: model.messageId,
      roomId: model.roomId,
      senderId: model.senderId,
      message: model.message,
      sendStatus: model.sendStatus,
      sentAt: model.sentAt,
      localId: model.localId,
      jenisPesan: model.jenisPesan,
      paket: paket,
      penawaran: penawaran,
      pesanan: pesanan,
      readAt: model.readAt,
      deliveredAt: model.deliveredAt,
      receiverIds: model.receiverIds,
    );
  }

  /// Convert ke ChatModel (untuk kompatibilitas UI)
  ChatModel toChatModel({
    required String tipeUser,
    required String roomType,
    required List<String> userIds,
  }) {
    return ChatModel(
      messageId: messageId,
      roomId: roomId,
      senderId: senderId,
      tipeUser: tipeUser,
      message: message,
      jenisPesan: resolvedJenisPesan,
      idPaket: paket?.no_id ?? "",
      noInvoice: pesanan?.noBukti ?? "",
      noPenawaran: penawaran?.noId ?? "",
      status: 'aktif',
      sendStatus: sendStatus,
      roomType: roomType,
      sentAt: sentAt,
      editedAt: null,
      deliveredAt: deliveredAt,
      readAt: readAt,
      userIds: userIds,
      receiverIds: receiverIds ?? [],
      localId: localId,
    );
  }

  /// Copy with
  ChatMessageEntity copyWith({
    String? messageId,
    String? sendStatus,
    String? message,
    PaketModel? paket,
    PesananModel? pesanan,
    PenawaranModel? penawaran,
    DateTime? readAt,
    DateTime? deliveredAt,
  }) {
    return ChatMessageEntity(
      messageId: messageId ?? this.messageId,
      roomId: roomId,
      senderId: senderId,
      message: message ?? this.message,
      sendStatus: sendStatus ?? this.sendStatus,
      sentAt: sentAt,
      localId: localId,
      jenisPesan: resolvedJenisPesan,
      paket: paket ?? this.paket,
      pesanan: pesanan ?? this.pesanan,
      penawaran: penawaran ?? this.penawaran,
      readAt: readAt ?? this.readAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      receiverIds: receiverIds,
    );
  }

  @override
  String toString() {
    return 'ChatMessageEntity(id: $messageId, room: $roomId, '
        'status: $sendStatus, localId: $localId)';
  }
}
