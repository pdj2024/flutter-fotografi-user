class PesananModel {
  // =======================
  // IDENTITAS
  // =======================
  final String noBukti;
  final String? noTrackingPesanan;
  final String? status;
  final String? statusProgresPesanan;
  final String? noPenawaran;

  // =======================
  // VENDOR & CUSTOMER
  // =======================
  final String idVendor;
  final String? namaVendor;

  final String idCustomer;
  final String? namaCustomer;

  // =======================
  // PAKET
  // =======================
  final String idPaket;
  final String namaPaket;
  final int harga;

  // =======================
  // LOKASI & WAKTU
  // =======================
  final String lokasi;
  final String kota;
  final String? namaKota;
  final DateTime tglRealisasi;

  // =======================
  // PEMBAYARAN
  // =======================
  final String? metodeBayar;
  final String? statusBayar;
  final String? idPaymentGateway;
  final String? orderIdMidtrans;

  final DateTime? expiryTime;
  final String? paymentNumber1;
  final String? paymentNumber2;

  // =======================
  // TIMESTAMP
  // =======================
  final String? linkUrl;

  // =======================
  // TOTAL & PAJAK
  // =======================
  final int subtotal;
  final double? totDpp;
  final int? ppn;
  final bool? inclPpn;
  final int? totPpn;
  final int grandTotal;

  // =======================
  // TIMESTAMP
  // =======================
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PesananModel({
    required this.noBukti,
    this.noTrackingPesanan,
    this.status,
    this.statusProgresPesanan,
    this.noPenawaran,
    required this.idVendor,
    this.namaVendor,
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
    return PesananModel(
      noBukti: json['No_Bukti'],
      noTrackingPesanan: json['No_Tracking_Pesanan'],
      status: json['Status'],
      statusProgresPesanan: json['Status_Progress_Pesanan'],
      noPenawaran: json['No_Penawaran'],
      idVendor: json['Id_Vendor'],
      namaVendor: json['Nama_Vendor'],
      idCustomer: json['Id_Customer'],
      namaCustomer: json['Nama_Customer'],
      idPaket: json['Id_Paket'],
      namaPaket: json['Nama_Paket'],
      harga: json['Harga'] ?? 0,
      lokasi: json['Lokasi'],
      kota: json['Kota'],
      namaKota: json['Nama_Kota'],
      tglRealisasi: DateTime.parse(json['Tgl_Realisasi']),
      metodeBayar: json['Metode_Bayar'],
      statusBayar: json['Status_Bayar'],
      idPaymentGateway: json['Id_Payment_Gateway'],
      orderIdMidtrans: json['Order_Id_Midtrans'],
      expiryTime: json['Expiry_Time'] != null
          ? DateTime.parse(json['Expiry_Time'])
          : null,
      paymentNumber1: json['Payment_Number_1'],
      paymentNumber2: json['Payment_Number_2'],
      linkUrl: json['Link_Url'],
      subtotal: json['Subtotal'] ?? 0,
      totDpp: json['Tot_DPP'] != null
          ? double.tryParse(json['Tot_DPP'].toString())
          : null,
      ppn: json['PPN'],
      inclPpn: json['Incl_PPN'],
      totPpn: json['Tot_PPN'],
      grandTotal: json['Grand_Total'] ?? 0,
      createdAt: json['Created_At'] != null
          ? DateTime.parse(json['Created_At'])
          : null,
      updatedAt: json['Updated_At'] != null
          ? DateTime.parse(json['Updated_At'])
          : null,
    );
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
    String? noPenawaran,
    String? idVendor,
    String? namaVendor,
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
    );
  }
}
