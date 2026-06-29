// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'penawaran_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PenawaranModelAdapter extends TypeAdapter<PenawaranModel> {
  @override
  final int typeId = 4;

  @override
  PenawaranModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PenawaranModel(
      noId: fields[0] as String,
      noTrackingPenawaran: fields[1] as String,
      noPesanan: fields[2] as String,
      idVendor: fields[3] as String,
      namaVendor: fields[4] as String,
      idCustomer: fields[5] as String,
      namaCustomer: fields[6] as String,
      idPaket: fields[7] as String,
      namaPaket: fields[8] as String,
      harga: fields[9] as int,
      status: fields[10] as String,
      lokasi: fields[11] as String,
      kota: fields[13] as String,
      namaKota: fields[12] as String,
      deskripsi: fields[14] as String,
      tglRealisasi: fields[15] as DateTime,
      createdAt: fields[16] as DateTime,
      updatedAt: fields[17] as DateTime?,
      revisi: (fields[18] as int?) ?? 0,
    );
  }

  @override
  void write(BinaryWriter writer, PenawaranModel obj) {
    writer
      ..writeByte(19)
      ..writeByte(0)
      ..write(obj.noId)
      ..writeByte(1)
      ..write(obj.noTrackingPenawaran)
      ..writeByte(2)
      ..write(obj.noPesanan)
      ..writeByte(3)
      ..write(obj.idVendor)
      ..writeByte(4)
      ..write(obj.namaVendor)
      ..writeByte(5)
      ..write(obj.idCustomer)
      ..writeByte(6)
      ..write(obj.namaCustomer)
      ..writeByte(7)
      ..write(obj.idPaket)
      ..writeByte(8)
      ..write(obj.namaPaket)
      ..writeByte(9)
      ..write(obj.harga)
      ..writeByte(10)
      ..write(obj.status)
      ..writeByte(11)
      ..write(obj.lokasi)
      ..writeByte(12)
      ..write(obj.namaKota)
      ..writeByte(13)
      ..write(obj.kota)
      ..writeByte(14)
      ..write(obj.deskripsi)
      ..writeByte(15)
      ..write(obj.tglRealisasi)
      ..writeByte(16)
      ..write(obj.createdAt)
      ..writeByte(17)
      ..write(obj.updatedAt)
      ..writeByte(18)
      ..write(obj.revisi);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PenawaranModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
