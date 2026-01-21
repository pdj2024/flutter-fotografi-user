import 'package:hive/hive.dart';

part 'pesanan_model.g.dart';

@HiveType(typeId: 4)
class PesananModel {
  // =======================
  // IDENTITAS
  // =======================
  @HiveField(0)
  final String noBukti;
  
  @HiveField(1)
  final String? noTrackingPesanan;
  
  @HiveField(2)
  final String? status;
  
  @HiveField(3)
  final String? statusProgresPesanan;
  
  @HiveField(4)
  final String? deskripsiProgresPesanan;
  
  @HiveField(5)
  final String? noPenawaran;

  // =======================
  // VENDOR & CUSTOMER
  // =======================
  @HiveField(6)
  final String idVendor;
  
  @HiveField(7)
  final String? namaVendor;
  
  @HiveField(8)
  final String? idMediaVendor;

  @HiveField(9)
  final String idCustomer;
  
  @HiveField(10)
  final String? namaCustomer;

  // =======================
  // PAKET
  // =======================
  @HiveField(11)
  final String idPaket;
  
  @HiveField(12)
  final String namaPaket;
  
  @HiveField(13)
  final int harga;

  // =======================
  // LOKASI & WAKTU
  // =======================
  @HiveField(14)
  final String lokasi;
  
  @HiveField(15)
  final String kota;
  
  @HiveField(16)
  final String? namaKota;
  
  @HiveField(17)
  final DateTime tglRealisasi;

  // =======================
  // PEMBAYARAN
  // =======================
  @HiveField(18)
  final String? metodeBayar;
  
  @HiveField(19)
  final String? statusBayar;
  
  @HiveField(20)
  final String? idPaymentGateway;
  
  @HiveField(21)
  final String? orderIdMidtrans;

  @HiveField(22)
  final DateTime? expiryTime;
  
  @HiveField(23)
  final String? paymentNumber1;
  
  @HiveField(24)
  final String? paymentNumber2;

  // =======================
  // HASIL
  // =======================
  @HiveField(25)
  final String? linkUrl;

  // =======================
  // TOTAL & PAJAK
  // =======================
  @HiveField(26)
  final int subtotal;
  
  @HiveField(27)
  final double? totDpp;
  
  @HiveField(28)
  final int? ppn;
  
  @HiveField(29)
  final bool? inclPpn;
  
  @HiveField(30)
  final int? totPpn;
  
  @HiveField(31)
  final int grandTotal;

  // =======================
  // TIMESTAMP
  // =======================
  @HiveField(32)
  final DateTime? createdAt;
  
  @HiveField(33)
  final DateTime? updatedAt;

  PesananModel({
    required this.noBukti,
    this.noTrackingPesanan,
    this.status,
    this.statusProgresPesanan,
    this.deskripsiProgresPesanan,
    this.noPenawaran,
    required this.idVendor,
    this.namaVendor,
    this.idMediaVendor,
    required this.idCustomer,
    this.namaCustomer,
    required this.idPaket,
    required this.namaPaket,
    required this.harga,
    required this.lokasi,
    required this.kota,
    this.namaKota,
    required this.tglRealisasi,
    this.metodeBayar,
    this.statusBayar,
    this.idPaymentGateway,
    this.orderIdMidtrans,
    this.expiryTime,
    this.paymentNumber1,
    this.paymentNumber2,
    this.linkUrl,
    required this.subtotal,
    this.totDpp,
    this.ppn,
    this.inclPpn,
    this.totPpn,
    required this.grandTotal,
    this.createdAt,
    this.updatedAt,
  });

  // =======================
  // FROM JSON (RESPONSE API)
  // =======================
  factory PesananModel.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic v) =>
        v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;

    double? parseDouble(dynamic v) =>
        v == null ? null : double.tryParse(v.toString());

    DateTime? parseDate(dynamic v) => (v == null || v.toString().isEmpty)
        ? null
        : DateTime.tryParse(v.toString());

    bool? parseBool(dynamic v) {
      if (v == null) return null;
      if (v is bool) return v;
      if (v is int) return v == 1;
      if (v is String) return v.toLowerCase() == 'true';
      return null;
    }

    return PesananModel(
      noBukti: json['No_Bukti'] ?? '',
      noTrackingPesanan: json['No_Tracking_Pesanan'],
      status: json['Status'],
      statusProgresPesanan: json['Status_Progress_Pesanan'],
      deskripsiProgresPesanan: json['Deskripsi_Progress_Pesanan'],
      noPenawaran: json['No_Penawaran'],
      idVendor: json['Id_Vendor'] ?? '',
      namaVendor: json['Nama_Vendor'],
      idMediaVendor: json['Id_Media_Vendor'],
      idCustomer: json['Id_Customer'] ?? '',
      namaCustomer: json['Nama_Customer'],
      idPaket: json['Id_Paket'] ?? '',
      namaPaket: json['Nama_Paket'] ?? '',
      harga: parseInt(json['Harga']),
      lokasi: json['Lokasi'] ?? '',
      kota: json['Kota'] ?? '',
      namaKota: json['Nama_Kota'],
      tglRealisasi: parseDate(json['Tgl_Realisasi']) ?? DateTime.now(),
      metodeBayar: json['Metode_Bayar'],
      statusBayar: json['Status_Bayar'],
      idPaymentGateway: json['Id_Payment_Gateway'],
      orderIdMidtrans: json['Order_Id_Midtrans'],
      expiryTime: parseDate(json['Expiry_Time']),
      paymentNumber1: json['Payment_Number_1'],
      paymentNumber2: json['Payment_Number_2'],
      linkUrl: (json['Link_Url'] as String?)?.isNotEmpty == true
          ? json['Link_Url']
          : null,
      subtotal: parseInt(json['Subtotal']),
      totDpp: parseDouble(json['Tot_DPP']),
      ppn: parseInt(json['PPN']),
      inclPpn: parseBool(json['Incl_PPN']),
      totPpn: parseInt(json['Tot_PPN']),
      grandTotal: parseInt(json['Grand_Total']),
      createdAt: parseDate(json['Created_At']),
      updatedAt: parseDate(json['Updated_At']),
    );
  }

  // =======================
  // TO JSON (FULL)
  // =======================
  Map<String, dynamic> toJson() {
    return {
      'No_Bukti': noBukti,
      'No_Tracking_Pesanan': noTrackingPesanan,
      'Status': status,
      'Status_Progress_Pesanan': statusProgresPesanan,
      'Deskripsi_Progress_Pesanan': deskripsiProgresPesanan,
      'No_Penawaran': noPenawaran,
      'Id_Vendor': idVendor,
      'Nama_Vendor': namaVendor,
      'Id_Media_Vendor': idMediaVendor,
      'Id_Customer': idCustomer,
      'Nama_Customer': namaCustomer,
      'Id_Paket': idPaket,
      'Nama_Paket': namaPaket,
      'Harga': harga,
      'Lokasi': lokasi,
      'Kota': kota,
      'Nama_Kota': namaKota,
      'Tgl_Realisasi': tglRealisasi.toIso8601String(),
      'Metode_Bayar': metodeBayar,
      'Status_Bayar': statusBayar,
      'Id_Payment_Gateway': idPaymentGateway,
      'Order_Id_Midtrans': orderIdMidtrans,
      'Expiry_Time': expiryTime?.toIso8601String(),
      'Payment_Number_1': paymentNumber1,
      'Payment_Number_2': paymentNumber2,
      'Link_Url': linkUrl,
      'Subtotal': subtotal,
      'Tot_DPP': totDpp,
      'PPN': ppn,
      'Incl_PPN': inclPpn,
      'Tot_PPN': totPpn,
      'Grand_Total': grandTotal,
      'Created_At': createdAt?.toIso8601String(),
      'Updated_At': updatedAt?.toIso8601String(),
    };
  }

  // =======================
  // TO JSON (CREATE)
  // =======================
  Map<String, dynamic> toJsonCreate() {
    return {
      'no_penawaran': noPenawaran,
      'id_vendor': idVendor,
      'id_customer': idCustomer,
      'id_paket': idPaket,
      'nama_paket': namaPaket,
      'kota': kota,
      'harga': harga,
      'lokasi': lokasi,
      'tgl_realisasi': tglRealisasi.toUtc().toIso8601String(),
      'status': status,
      'status_bayar': statusBayar,
      'payment_type': metodeBayar,
      'id_payment_gateway': idPaymentGateway,
    };
  }

  // =======================
  // TO JSON (UPDATE)
  // =======================
  Map<String, dynamic> toJsonUpdate() {
    return {
      'id_paket': idPaket,
      'nama_paket': namaPaket,
      'kota': kota,
      'harga': harga,
      'lokasi': lokasi,
      'link_url': linkUrl,
      'tgl_realisasi': tglRealisasi.toUtc().toIso8601String(),
      'status': status,
    };
  }

  // =======================
  // COPY WITH
  // =======================
  PesananModel copyWith({
    String? noBukti,
    String? noTrackingPesanan,
    String? status,
    String? statusProgresPesanan,
    String? deskripsiProgresPesanan,
    String? noPenawaran,
    String? idVendor,
    String? namaVendor,
    String? idMediaVendor,
    String? idCustomer,
    String? namaCustomer,
    String? idPaket,
    String? namaPaket,
    int? harga,
    String? lokasi,
    String? kota,
    String? namaKota,
    DateTime? tglRealisasi,
    String? metodeBayar,
    String? statusBayar,
    String? idPaymentGateway,
    String? orderIdMidtrans,
    DateTime? expiryTime,
    String? paymentNumber1,
    String? paymentNumber2,
    String? linkUrl,
    int? subtotal,
    double? totDpp,
    int? ppn,
    bool? inclPpn,
    int? totPpn,
    int? grandTotal,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PesananModel(
      noBukti: noBukti ?? this.noBukti,
      noTrackingPesanan: noTrackingPesanan ?? this.noTrackingPesanan,
      status: status ?? this.status,
      statusProgresPesanan: statusProgresPesanan ?? this.statusProgresPesanan,
      deskripsiProgresPesanan:
          deskripsiProgresPesanan ?? this.deskripsiProgresPesanan,
      noPenawaran: noPenawaran ?? this.noPenawaran,
      idVendor: idVendor ?? this.idVendor,
      namaVendor: namaVendor ?? this.namaVendor,
      idCustomer: idCustomer ?? this.idCustomer,
      namaCustomer: namaCustomer ?? this.namaCustomer,
      idPaket: idPaket ?? this.idPaket,
      namaPaket: namaPaket ?? this.namaPaket,
      harga: harga ?? this.harga,
      lokasi: lokasi ?? this.lokasi,
      kota: kota ?? this.kota,
      namaKota: namaKota ?? this.namaKota,
      tglRealisasi: tglRealisasi ?? this.tglRealisasi,
      metodeBayar: metodeBayar ?? this.metodeBayar,
      statusBayar: statusBayar ?? this.statusBayar,
      idPaymentGateway: idPaymentGateway ?? this.idPaymentGateway,
      orderIdMidtrans: orderIdMidtrans ?? this.orderIdMidtrans,
      expiryTime: expiryTime ?? this.expiryTime,
      paymentNumber1: paymentNumber1 ?? this.paymentNumber1,
      paymentNumber2: paymentNumber2 ?? this.paymentNumber2,
      linkUrl: linkUrl ?? this.linkUrl,
      subtotal: subtotal ?? this.subtotal,
      totDpp: totDpp ?? this.totDpp,
      ppn: ppn ?? this.ppn,
      inclPpn: inclPpn ?? this.inclPpn,
      totPpn: totPpn ?? this.totPpn,
      grandTotal: grandTotal ?? this.grandTotal,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      idMediaVendor: idMediaVendor ?? this.idMediaVendor,
    );
  }
}