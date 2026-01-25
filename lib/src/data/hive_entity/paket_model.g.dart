// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'paket_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PaketModelAdapter extends TypeAdapter<PaketModel> {
  @override
  final int typeId = 2;

  @override
  PaketModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PaketModel(
      no_id: fields[0] as String,
      nama_paket: fields[1] as String,
      id_vendor: fields[2] as String,
      harga: fields[3] as int,
      rincian: fields[4] as String,
      status: fields[5] as String,
    );
  }

  @override
  void write(BinaryWriter writer, PaketModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.no_id)
      ..writeByte(1)
      ..write(obj.nama_paket)
      ..writeByte(2)
      ..write(obj.id_vendor)
      ..writeByte(3)
      ..write(obj.harga)
      ..writeByte(4)
      ..write(obj.rincian)
      ..writeByte(5)
      ..write(obj.status);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaketModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
