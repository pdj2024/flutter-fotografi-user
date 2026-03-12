// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'portofolio_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PortofolioModelAdapter extends TypeAdapter<PortofolioModel> {
  @override
  final int typeId = 6;

  @override
  PortofolioModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PortofolioModel(
      noId: fields[0] as String,
      idVendor: fields[1] as String,
      idMedia: (fields[2] as List).cast<String>(),
      idMediaVendor: fields[3] as String?,
      idKategori: fields[4] as String?,
      namaKategori: fields[5] as String?,
      jenisMedia: fields[6] as String?,
      usernameVendor: fields[7] as String?,
      namaVendor: fields[8] as String?,
      kota: fields[9] as String?,
      namaKota: fields[10] as String?,
      caption: fields[11] as String?,
      idPaket: (fields[12] as List).cast<String>(),
      paket: fields[13] as dynamic,
      tglCreated: fields[14] as DateTime,
      jumlahPaket: fields[15] as int?,
      status: fields[16] as String,
      ratingVendor: fields[17] as double?,
      hargaMinPaket: fields[18] as int?,
      hargaMaxPaket: fields[19] as int?,
      jumlahPortofolio: fields[20] as int?,
      likes: fields[21] as int,
      saves: fields[22] as int,
      matchKota: fields[23] as int?,
      fromSavedVendor: fields[24] as int?,
      isSaved: fields[25] as bool?,
      isLiked: fields[26] as bool?,
      skorTotal: fields[27] as double?,
      mediaUrls: (fields[28] as List).cast<MediaUrlModel>(),
      lastUpdated: fields[29] as DateTime?,
      lastSynced: fields[30] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, PortofolioModel obj) {
    writer
      ..writeByte(31)
      ..writeByte(0)
      ..write(obj.noId)
      ..writeByte(1)
      ..write(obj.idVendor)
      ..writeByte(2)
      ..write(obj.idMedia)
      ..writeByte(3)
      ..write(obj.idMediaVendor)
      ..writeByte(4)
      ..write(obj.idKategori)
      ..writeByte(5)
      ..write(obj.namaKategori)
      ..writeByte(6)
      ..write(obj.jenisMedia)
      ..writeByte(7)
      ..write(obj.usernameVendor)
      ..writeByte(8)
      ..write(obj.namaVendor)
      ..writeByte(9)
      ..write(obj.kota)
      ..writeByte(10)
      ..write(obj.namaKota)
      ..writeByte(11)
      ..write(obj.caption)
      ..writeByte(12)
      ..write(obj.idPaket)
      ..writeByte(13)
      ..write(obj.paket)
      ..writeByte(14)
      ..write(obj.tglCreated)
      ..writeByte(15)
      ..write(obj.jumlahPaket)
      ..writeByte(16)
      ..write(obj.status)
      ..writeByte(17)
      ..write(obj.ratingVendor)
      ..writeByte(18)
      ..write(obj.hargaMinPaket)
      ..writeByte(19)
      ..write(obj.hargaMaxPaket)
      ..writeByte(20)
      ..write(obj.jumlahPortofolio)
      ..writeByte(21)
      ..write(obj.likes)
      ..writeByte(22)
      ..write(obj.saves)
      ..writeByte(23)
      ..write(obj.matchKota)
      ..writeByte(24)
      ..write(obj.fromSavedVendor)
      ..writeByte(25)
      ..write(obj.isSaved)
      ..writeByte(26)
      ..write(obj.isLiked)
      ..writeByte(27)
      ..write(obj.skorTotal)
      ..writeByte(28)
      ..write(obj.mediaUrls)
      ..writeByte(29)
      ..write(obj.lastUpdated)
      ..writeByte(30)
      ..write(obj.lastSynced);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PortofolioModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
