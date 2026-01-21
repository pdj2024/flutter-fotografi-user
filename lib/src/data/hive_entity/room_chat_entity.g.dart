// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'room_chat_entity.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RoomChatEntityAdapter extends TypeAdapter<RoomChatEntity> {
  @override
  final int typeId = 1;

  @override
  RoomChatEntity read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RoomChatEntity(
      roomId: fields[0] as String,
      roomType: fields[1] as String,
      usernameLawan: fields[2] as String?,
      idLawan: fields[3] as String,
      idMediaLawan: fields[4] as String?,
      lastMessageAt: fields[5] as DateTime,
      lastMessage: fields[6] as String,
      unread: fields[7] as int,
      userIds: (fields[8] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, RoomChatEntity obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.roomId)
      ..writeByte(1)
      ..write(obj.roomType)
      ..writeByte(2)
      ..write(obj.usernameLawan)
      ..writeByte(3)
      ..write(obj.idLawan)
      ..writeByte(4)
      ..write(obj.idMediaLawan)
      ..writeByte(5)
      ..write(obj.lastMessageAt)
      ..writeByte(6)
      ..write(obj.lastMessage)
      ..writeByte(7)
      ..write(obj.unread)
      ..writeByte(8)
      ..write(obj.userIds);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoomChatEntityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
