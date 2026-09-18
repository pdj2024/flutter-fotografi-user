// Kebutuhan Local Storage Sqflite
class ComplainExistence {
  final String noComplain;
  final String status;

  const ComplainExistence({
    required this.noComplain,
    required this.status,
  });

  bool get isClosed => status.toLowerCase() == 'selesai';

  factory ComplainExistence.fromComplain(ComplainModel complain) =>
      ComplainExistence(
        noComplain: complain.noComplain,
        status: complain.status,
      );

  factory ComplainExistence.fromMap(Map map) => ComplainExistence(
        noComplain: map['noComplain']?.toString() ?? '',
        status: map['status']?.toString() ?? "",
      );

  Map<String, dynamic> toMap() => {'noComplain': noComplain, 'status': status};
}

class ComplainModel {
  final String noComplain;
  final String noOrder;
  final String? noTrackingPesanan;
  // Nomor tracking complain itu sendiri (beda dari noTrackingPesanan yang
  // punya order-nya). Nullable dan sengaja tidak di-default '' seperti di
  // ComplainHeaderModel -- belum dikonfirmasi apakah get-group (endpoint
  // yang mengisi model ini) benar-benar mengirim field ini, jadi UI cuma
  // menampilkan kalau ada; kalau backend tidak kirim, cukup disembunyikan.
  final String? noTrackingKomplain;
  final String idVendor;
  final String idCustomer;
  final String judul;
  final String status;
  final DateTime? tglClosed;
  final int totalMessages;
  final List<ComplainMessageModel> details;

  const ComplainModel({
    required this.noComplain,
    required this.noOrder,
    this.noTrackingPesanan,
    this.noTrackingKomplain,
    required this.idVendor,
    required this.idCustomer,
    required this.judul,
    required this.status,
    this.tglClosed,
    required this.totalMessages,
    required this.details,
  });

  bool get isClosed => status.toLowerCase() == 'selesai';

  factory ComplainModel.fromJson(Map<String, dynamic> json) {
    final rawDetails = json['Details'] as List<dynamic>? ?? [];
    final details = rawDetails
        .map((e) => ComplainMessageModel.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.tglCreated.compareTo(b.tglCreated));

    return ComplainModel(
      noComplain: json['No_Complain'] ?? '',
      noOrder: json['No_Order'] ?? '',
      noTrackingPesanan: json['No_Tracking_Pesanan'],
      noTrackingKomplain: json['No_Tracking_Komplain']?.toString(),
      idVendor: json['Id_Vendor'] ?? '',
      idCustomer: json['Id_Customer'] ?? '',
      judul: json['Judul'] ?? '',
      status: json['Status'] ?? '',
      tglClosed: json['Tgl_Closed'] != null
          ? DateTime.tryParse(json['Tgl_Closed'].toString())
          : null,
      totalMessages: json['Total_Messages'] is int
          ? json['Total_Messages']
          : int.tryParse(json['Total_Messages']?.toString() ?? '') ??
              details.length,
      details: details,
    );
  }

  ComplainModel copyWith({
    String? noComplain,
    String? noOrder,
    String? noTrackingPesanan,
    String? noTrackingKomplain,
    String? idVendor,
    String? idCustomer,
    String? judul,
    String? status,
    DateTime? tglClosed,
    int? totalMessages,
    List<ComplainMessageModel>? details,
  }) {
    return ComplainModel(
      noComplain: noComplain ?? this.noComplain,
      noOrder: noOrder ?? this.noOrder,
      noTrackingPesanan: noTrackingPesanan ?? this.noTrackingPesanan,
      noTrackingKomplain: noTrackingKomplain ?? this.noTrackingKomplain,
      idVendor: idVendor ?? this.idVendor,
      idCustomer: idCustomer ?? this.idCustomer,
      judul: judul ?? this.judul,
      status: status ?? this.status,
      tglClosed: tglClosed ?? this.tglClosed,
      totalMessages: totalMessages ?? this.totalMessages,
      details: details ?? this.details,
    );
  }
}

/// Satu lampiran di dalam pesan Complain. Catatan penting soal naming dari
/// backend: field `id_media` di sini isinya bukan id — itu URL signed yang
/// SUDAH bisa langsung dipakai buat nampilin gambar (sudah di-embed
/// server-side di response get-group, tidak perlu resolve terpisah lewat
/// /mediacloud/read-url-batch). Id media yang sebenarnya ada di `no_id_media`.
class ComplainAttachmentModel {
  final String url;
  final String noIdMedia;

  const ComplainAttachmentModel({required this.url, required this.noIdMedia});

  factory ComplainAttachmentModel.fromJson(Map<String, dynamic> json) {
    return ComplainAttachmentModel(
      url: json['id_media']?.toString() ?? '',
      noIdMedia: json['no_id_media']?.toString() ?? '',
    );
  }
}

class ComplainMessageModel {
  final String noId;
  final String senderId;
  final String senderNama;
  final String tipeUser;
  final String message;
  final DateTime tglCreated;
  final String sendStatus;
  final List<ComplainAttachmentModel> attachments;

  const ComplainMessageModel({
    required this.noId,
    required this.senderId,
    required this.senderNama,
    required this.tipeUser,
    required this.message,
    required this.tglCreated,
    required this.sendStatus,
    required this.attachments,
  });

  bool get isLocalEcho => noId.startsWith('local-');
  bool get isPending => isLocalEcho || sendStatus == 'pending';
  bool get isFailed => sendStatus == 'failed';
  bool get isAdmin => tipeUser.toLowerCase() == 'admin';

  factory ComplainMessageModel.fromJson(Map<String, dynamic> json) {
    return ComplainMessageModel(
      noId: json['No_Id'] ?? '',
      senderId: json['Sender_Id'] ?? '',
      senderNama: json['Sender_Nama'] ?? '',
      tipeUser: json['Tipe_User'] ?? '',
      message: json['Message'] ?? '',
      tglCreated:
          DateTime.tryParse(json['Tgl_Created']?.toString() ?? '') ??
              DateTime.now(),
      sendStatus: json['Send_Status'] ?? 'sent',
      attachments: _parseAttachments(json['Id_Media']),
    );
  }

  static List<ComplainAttachmentModel> _parseAttachments(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) =>
              ComplainAttachmentModel.fromJson(Map<String, dynamic>.from(e)))
          .where((a) => a.url.isNotEmpty)
          .toList();
    }
    return [];
  }
}

/// Ringkasan satu Complain untuk tampilan list (mis. menu "Complain" di
/// halaman Setting) — dari GET /complain/get-header. Beda dari
/// [ComplainModel]: tidak bawa Details (isi pesan), tapi bawa metadata
/// tambahan (No_Tracking_Komplain, Prioritas, Assigned_To, dll) yang
/// tidak ada di response get-group.
class ComplainHeaderModel {
  final String noComplain;
  final String noTrackingKomplain;
  final String noOrder;
  final String? noTrackingPesanan;
  final String idVendor;
  final String idCustomer;
  final String judul;
  final String status;
  final DateTime? tglClosed;
  final DateTime? tglCreated;
  final DateTime? lastUpdated;
  final String senderId;
  final String senderNama;
  final String tipeUser;
  final int totalMessages;
  final DateTime? batasWaktu;
  final String prioritas;
  final String assignedTo;
  final String hasilAkhir;

  const ComplainHeaderModel({
    required this.noComplain,
    required this.noTrackingKomplain,
    required this.noOrder,
    this.noTrackingPesanan,
    required this.idVendor,
    required this.idCustomer,
    required this.judul,
    required this.status,
    this.tglClosed,
    this.tglCreated,
    this.lastUpdated,
    required this.senderId,
    required this.senderNama,
    required this.tipeUser,
    required this.totalMessages,
    this.batasWaktu,
    this.prioritas = '',
    this.assignedTo = '',
    this.hasilAkhir = '',
  });

  bool get isClosed => status.toLowerCase() == 'selesai';

  factory ComplainHeaderModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) =>
        v == null ? null : DateTime.tryParse(v.toString());

    return ComplainHeaderModel(
      noComplain: json['No_Complain'] ?? '',
      noTrackingKomplain: json['No_Tracking_Komplain'] ?? '',
      noOrder: json['No_Order'] ?? '',
      noTrackingPesanan: json['No_Tracking_Pesanan'],
      idVendor: json['Id_Vendor'] ?? '',
      idCustomer: json['Id_Customer'] ?? '',
      judul: json['Judul'] ?? '',
      status: json['Status'] ?? '',
      tglClosed: parseDate(json['Tgl_Closed']),
      tglCreated: parseDate(json['Tgl_Created']),
      lastUpdated: parseDate(json['Last_Updated']),
      senderId: json['Sender_Id'] ?? '',
      senderNama: json['Sender_Nama'] ?? '',
      tipeUser: json['Tipe_User'] ?? '',
      totalMessages: json['Total_Messages'] is int
          ? json['Total_Messages']
          : int.tryParse(json['Total_Messages']?.toString() ?? '') ?? 0,
      batasWaktu: parseDate(json['Batas_Waktu']),
      prioritas: json['Prioritas'] ?? '',
      assignedTo: json['Assigned_To'] ?? '',
      hasilAkhir: json['Hasil_Akhir'] ?? '',
    );
  }
}
