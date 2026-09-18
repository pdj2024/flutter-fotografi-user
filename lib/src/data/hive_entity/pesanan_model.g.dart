// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pesanan_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PesananModelAdapter extends TypeAdapter<PesananModel> {
  @override
  final int typeId = 5;

  @override
  PesananModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PesananModel(
      noBukti: fields[0] as String,
      noTrackingPesanan: fields[1] as String?,
      status: fields[2] as String?,
      statusProgresPesanan: fields[3] as String?,
      deskripsiProgresPesanan: fields[4] as String?,
      noPenawaran: fields[5] as String?,
      idVendor: fields[6] as String,
      namaVendor: fields[7] as String?,
      idMediaVendor: fields[8] as String?,
      idCustomer: fields[9] as String,
      namaCustomer: fields[10] as String?,
      idPaket: fields[11] as String,
      namaPaket: fields[12] as String,
      harga: fields[13] as int,
      lokasi: fields[14] as String,
      kota: fields[15] as String,
      namaKota: fields[16] as String?,
      tglRealisasi: fields[17] as DateTime,
      metodeBayar: fields[18] as String?,
      statusBayar: fields[19] as String?,
      idPaymentGateway: fields[20] as String?,
      orderIdMidtrans: fields[21] as String?,
      expiryTime: fields[22] as DateTime?,
      paymentNumber1: fields[23] as String?,
      paymentNumber2: fields[24] as String?,
      linkSnap: fields[25] as String?,
      linkUrl: fields[26] as String?,
      subtotal: fields[27] as int,
      totDpp: fields[28] as double?,
      ppn: fields[29] as int?,
      inclPpn: fields[30] as bool?,
      totPpn: fields[31] as int?,
      grandTotal: fields[32] as int,
      createdAt: fields[33] as DateTime?,
      updatedAt: fields[34] as DateTime?,
      revisi: fields[35] == null ? 0 : fields[35] as int,
      estimasiPengerjaan: fields[36] == null ? 0 : fields[36] as int,
      tglPengerjaanMax: fields[37] as DateTime?,
      tglRefund: fields[38] as DateTime?,
      tglRefunded: fields[39] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, PesananModel obj) {
    writer
      ..writeByte(40)
      ..writeByte(0)
      ..write(obj.noBukti)
      ..writeByte(1)
      ..write(obj.noTrackingPesanan)
      ..writeByte(2)
      ..write(obj.status)
      ..writeByte(3)
      ..write(obj.statusProgresPesanan)
      ..writeByte(4)
      ..write(obj.deskripsiProgresPesanan)
      ..writeByte(5)
      ..write(obj.noPenawaran)
      ..writeByte(6)
      ..write(obj.idVendor)
      ..writeByte(7)
      ..write(obj.namaVendor)
      ..writeByte(8)
      ..write(obj.idMediaVendor)
      ..writeByte(9)
      ..write(obj.idCustomer)
      ..writeByte(10)
      ..write(obj.namaCustomer)
      ..writeByte(11)
      ..write(obj.idPaket)
      ..writeByte(12)
      ..write(obj.namaPaket)
      ..writeByte(13)
      ..write(obj.harga)
      ..writeByte(14)
      ..write(obj.lokasi)
      ..writeByte(15)
      ..write(obj.kota)
      ..writeByte(16)
      ..write(obj.namaKota)
      ..writeByte(17)
      ..write(obj.tglRealisasi)
      ..writeByte(18)
      ..write(obj.metodeBayar)
      ..writeByte(19)
      ..write(obj.statusBayar)
      ..writeByte(20)
      ..write(obj.idPaymentGateway)
      ..writeByte(21)
      ..write(obj.orderIdMidtrans)
      ..writeByte(22)
      ..write(obj.expiryTime)
      ..writeByte(23)
      ..write(obj.paymentNumber1)
      ..writeByte(24)
      ..write(obj.paymentNumber2)
      ..writeByte(25)
      ..write(obj.linkSnap)
      ..writeByte(26)
      ..write(obj.linkUrl)
      ..writeByte(27)
      ..write(obj.subtotal)
      ..writeByte(28)
      ..write(obj.totDpp)
      ..writeByte(29)
      ..write(obj.ppn)
      ..writeByte(30)
      ..write(obj.inclPpn)
      ..writeByte(31)
      ..write(obj.totPpn)
      ..writeByte(32)
      ..write(obj.grandTotal)
      ..writeByte(33)
      ..write(obj.createdAt)
      ..writeByte(34)
      ..write(obj.updatedAt)
      ..writeByte(35)
      ..write(obj.revisi)
      ..writeByte(36)
      ..write(obj.estimasiPengerjaan)
      ..writeByte(37)
      ..write(obj.tglPengerjaanMax)
      ..writeByte(38)
      ..write(obj.tglRefund)
      ..writeByte(39)
      ..write(obj.tglRefunded);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PesananModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
