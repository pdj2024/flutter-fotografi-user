// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_message_entity.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ChatMessageEntityAdapter extends TypeAdapter<ChatMessageEntity> {
  @override
  final int typeId = 0;

  @override
  ChatMessageEntity read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ChatMessageEntity(
      messageId: fields[0] as String,
      roomId: fields[1] as String,
      senderId: fields[2] as String,
      message: fields[3] as String,
      sendStatus: fields[4] as String,
      sentAt: fields[5] as DateTime,
      localId: fields[6] as String?,
      jenisPesan: fields[7] as String?,
      paket: fields[8] as PaketModel?,
      penawaran: fields[9] as PenawaranModel?,
      pesanan: fields[10] as PesananModel?,
      readAt: fields[11] as DateTime?,
      deliveredAt: fields[12] as DateTime?,
      receiverIds: (fields[13] as List?)?.cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, ChatMessageEntity obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.messageId)
      ..writeByte(1)
      ..write(obj.roomId)
      ..writeByte(2)
      ..write(obj.senderId)
      ..writeByte(3)
      ..write(obj.message)
      ..writeByte(4)
      ..write(obj.sendStatus)
      ..writeByte(5)
      ..write(obj.sentAt)
      ..writeByte(6)
      ..write(obj.localId)
      ..writeByte(7)
      ..write(obj.jenisPesan)
      ..writeByte(8)
      ..write(obj.paket)
      ..writeByte(9)
      ..write(obj.penawaran)
      ..writeByte(10)
      ..write(obj.pesanan)
      ..writeByte(11)
      ..write(obj.readAt)
      ..writeByte(12)
      ..write(obj.deliveredAt)
      ..writeByte(13)
      ..write(obj.receiverIds);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatMessageEntityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
