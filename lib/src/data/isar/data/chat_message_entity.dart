import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:mpjnew/src/data/hive_entity/paket_model.dart';
import 'package:mpjnew/src/data/hive_entity/penawaran_model.dart';
import 'package:mpjnew/src/data/hive_entity/pesanan_model.dart';
import 'package:mpjnew/src/data/models/chat_model.dart';

// ═══════════════════════════════════════════════════════════════════════════
// EMBEDDED: PAKET
// Mirror dari PaketModel — semua field sama, tidak ada yang dihilangkan
// ═══════════════════════════════════════════════════════════════════════════

class EmbeddedPaket {
  String noId = '';
  String namaPaket = '';
  String idVendor = '';
  int harga = 0;
  String rincian = '';
  String status = '';

  EmbeddedPaket();

  factory EmbeddedPaket.fromModel(PaketModel m) => EmbeddedPaket()
    ..noId = m.no_id
    ..namaPaket = m.nama_paket
    ..idVendor = m.id_vendor
    ..harga = m.harga
    ..rincian = m.rincian
    ..status = m.status;

  factory EmbeddedPaket.fromJson(Map<String, dynamic> json) => EmbeddedPaket()
    ..noId = (json['noId'] as String?) ?? ''
    ..namaPaket = (json['namaPaket'] as String?) ?? ''
    ..idVendor = (json['idVendor'] as String?) ?? ''
    ..harga = (json['harga'] as int?) ?? 0
    ..rincian = (json['rincian'] as String?) ?? ''
    ..status = (json['status'] as String?) ?? '';

  Map<String, dynamic> toJson() => {
        'noId': noId,
        'namaPaket': namaPaket,
        'idVendor': idVendor,
        'harga': harga,
        'rincian': rincian,
        'status': status,
      };

  PaketModel toModel() => PaketModel(
        no_id: noId,
        nama_paket: namaPaket,
        id_vendor: idVendor,
        harga: harga,
        rincian: rincian,
        status: status,
      );

  bool get isNotEmpty => noId.isNotEmpty;
}

// ═══════════════════════════════════════════════════════════════════════════
// EMBEDDED: PENAWARAN
// Mirror dari PenawaranModel — semua field sama
// ═══════════════════════════════════════════════════════════════════════════

class EmbeddedPenawaran {
  String noId = '';
  String noTrackingPenawaran = '';
  String noPesanan = '';
  String idVendor = '';
  String namaVendor = '';
  String idCustomer = '';
  String namaCustomer = '';
  String idPaket = '';
  String namaPaket = '';
  int harga = 0;
  String status = '';
  String lokasi = '';
  String kota = '';
  String namaKota = '';
  String deskripsi = '';
  DateTime tglRealisasi = DateTime.now();
  DateTime createdAt = DateTime.now();
  DateTime? updatedAt;
  int estimasiPengerjaan = 0;
  DateTime? expiredAt;

  EmbeddedPenawaran();

  factory EmbeddedPenawaran.fromModel(PenawaranModel m) => EmbeddedPenawaran()
    ..noId = m.noId
    ..noTrackingPenawaran = m.noTrackingPenawaran
    ..noPesanan = m.noPesanan
    ..idVendor = m.idVendor
    ..namaVendor = m.namaVendor
    ..idCustomer = m.idCustomer
    ..namaCustomer = m.namaCustomer
    ..idPaket = m.idPaket
    ..namaPaket = m.namaPaket
    ..harga = m.harga
    ..status = m.status
    ..lokasi = m.lokasi
    ..kota = m.kota
    ..namaKota = m.namaKota
    ..deskripsi = m.deskripsi
    ..tglRealisasi = m.tglRealisasi
    ..createdAt = m.createdAt
    ..updatedAt = m.updatedAt
    ..estimasiPengerjaan = m.estimasiPengerjaan
    ..expiredAt = m.expiredAt;

  factory EmbeddedPenawaran.fromJson(Map<String, dynamic> json) =>
      EmbeddedPenawaran()
        ..noId = (json['noId'] as String?) ?? ''
        ..noTrackingPenawaran = (json['noTrackingPenawaran'] as String?) ?? ''
        ..noPesanan = (json['noPesanan'] as String?) ?? ''
        ..idVendor = (json['idVendor'] as String?) ?? ''
        ..namaVendor = (json['namaVendor'] as String?) ?? ''
        ..idCustomer = (json['idCustomer'] as String?) ?? ''
        ..namaCustomer = (json['namaCustomer'] as String?) ?? ''
        ..idPaket = (json['idPaket'] as String?) ?? ''
        ..namaPaket = (json['namaPaket'] as String?) ?? ''
        ..harga = (json['harga'] as int?) ?? 0
        ..status = (json['status'] as String?) ?? ''
        ..lokasi = (json['lokasi'] as String?) ?? ''
        ..kota = (json['kota'] as String?) ?? ''
        ..namaKota = (json['namaKota'] as String?) ?? ''
        ..deskripsi = (json['deskripsi'] as String?) ?? ''
        ..tglRealisasi = json['tglRealisasi'] != null
            ? DateTime.fromMillisecondsSinceEpoch(json['tglRealisasi'] as int)
            : DateTime.now()
        ..createdAt = json['createdAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int)
            : DateTime.now()
        ..updatedAt = json['updatedAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(json['updatedAt'] as int)
            : null
        ..estimasiPengerjaan = (json['estimasiPengerjaan'] as int?) ?? 0
        ..expiredAt = json['expiredAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(json['expiredAt'] as int)
            : null;

  Map<String, dynamic> toJson() => {
        'noId': noId,
        'noTrackingPenawaran': noTrackingPenawaran,
        'noPesanan': noPesanan,
        'idVendor': idVendor,
        'namaVendor': namaVendor,
        'idCustomer': idCustomer,
        'namaCustomer': namaCustomer,
        'idPaket': idPaket,
        'namaPaket': namaPaket,
        'harga': harga,
        'status': status,
        'lokasi': lokasi,
        'kota': kota,
        'namaKota': namaKota,
        'deskripsi': deskripsi,
        'tglRealisasi': tglRealisasi.millisecondsSinceEpoch,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'updatedAt': updatedAt?.millisecondsSinceEpoch,
        'estimasiPengerjaan': estimasiPengerjaan,
        'expiredAt': expiredAt?.millisecondsSinceEpoch,
      };

  PenawaranModel toModel() => PenawaranModel(
        noId: noId,
        noTrackingPenawaran: noTrackingPenawaran,
        noPesanan: noPesanan,
        idVendor: idVendor,
        namaVendor: namaVendor,
        idCustomer: idCustomer,
        namaCustomer: namaCustomer,
        idPaket: idPaket,
        namaPaket: namaPaket,
        harga: harga,
        status: status,
        lokasi: lokasi,
        kota: kota,
        namaKota: namaKota,
        deskripsi: deskripsi,
        tglRealisasi: tglRealisasi,
        createdAt: createdAt,
        updatedAt: updatedAt,
        estimasiPengerjaan: estimasiPengerjaan,
        expiredAt: expiredAt,
      );

  bool get isNotEmpty => noId.isNotEmpty;

  /// ✅ Penawaran sudah jadi pesanan jika noPesanan tidak kosong
  bool get sudahJadiPesanan => noPesanan.isNotEmpty;
}

// ═══════════════════════════════════════════════════════════════════════════
// EMBEDDED: PESANAN
// Mirror dari PesananModel — semua field sama
// ═══════════════════════════════════════════════════════════════════════════

class EmbeddedPesanan {
  String noBukti = '';
  String? noTrackingPesanan;
  String? status;
  String? statusProgresPesanan;
  String? deskripsiProgresPesanan;
  String? noPenawaran;
  String idVendor = '';
  String? namaVendor;
  String? idMediaVendor;
  String idCustomer = '';
  String? namaCustomer;
  String idPaket = '';
  String namaPaket = '';
  int harga = 0;
  String lokasi = '';
  String kota = '';
  String? namaKota;
  DateTime tglRealisasi = DateTime.now();
  String? metodeBayar;
  String? statusBayar;
  String? idPaymentGateway;
  String? orderIdMidtrans;
  DateTime? expiryTime;
  String? paymentNumber1;
  String? paymentNumber2;
  String? linkSnap;
  String? linkUrl;
  int subtotal = 0;
  double? totDpp;
  int? ppn;
  bool? inclPpn;
  int? totPpn;
  int grandTotal = 0;
  int estimasiPengerjaan = 0;
  DateTime? tglPengerjaanMax;
  DateTime? createdAt;
  DateTime? updatedAt;

  EmbeddedPesanan();

  factory EmbeddedPesanan.fromModel(PesananModel m) => EmbeddedPesanan()
    ..noBukti = m.noBukti
    ..noTrackingPesanan = m.noTrackingPesanan
    ..status = m.status
    ..statusProgresPesanan = m.statusProgresPesanan
    ..deskripsiProgresPesanan = m.deskripsiProgresPesanan
    ..noPenawaran = m.noPenawaran
    ..idVendor = m.idVendor
    ..namaVendor = m.namaVendor
    ..idMediaVendor = m.idMediaVendor
    ..idCustomer = m.idCustomer
    ..namaCustomer = m.namaCustomer
    ..idPaket = m.idPaket
    ..namaPaket = m.namaPaket
    ..harga = m.harga
    ..lokasi = m.lokasi
    ..kota = m.kota
    ..namaKota = m.namaKota
    ..tglRealisasi = m.tglRealisasi
    ..metodeBayar = m.metodeBayar
    ..statusBayar = m.statusBayar
    ..idPaymentGateway = m.idPaymentGateway
    ..orderIdMidtrans = m.orderIdMidtrans
    ..expiryTime = m.expiryTime
    ..paymentNumber1 = m.paymentNumber1
    ..paymentNumber2 = m.paymentNumber2
    ..linkSnap = m.linkSnap
    ..linkUrl = m.linkUrl
    ..subtotal = m.subtotal
    ..totDpp = m.totDpp
    ..ppn = m.ppn
    ..inclPpn = m.inclPpn
    ..totPpn = m.totPpn
    ..grandTotal = m.grandTotal
    ..estimasiPengerjaan = m.estimasiPengerjaan
    ..tglPengerjaanMax = m.tglPengerjaanMax
    ..createdAt = m.createdAt
    ..updatedAt = m.updatedAt;

  factory EmbeddedPesanan.fromJson(Map<String, dynamic> json) =>
      EmbeddedPesanan()
        ..noBukti = (json['noBukti'] as String?) ?? ''
        ..noTrackingPesanan = json['noTrackingPesanan'] as String?
        ..status = json['status'] as String?
        ..statusProgresPesanan = json['statusProgresPesanan'] as String?
        ..deskripsiProgresPesanan = json['deskripsiProgresPesanan'] as String?
        ..noPenawaran = json['noPenawaran'] as String?
        ..idVendor = (json['idVendor'] as String?) ?? ''
        ..namaVendor = json['namaVendor'] as String?
        ..idMediaVendor = json['idMediaVendor'] as String?
        ..idCustomer = (json['idCustomer'] as String?) ?? ''
        ..namaCustomer = json['namaCustomer'] as String?
        ..idPaket = (json['idPaket'] as String?) ?? ''
        ..namaPaket = (json['namaPaket'] as String?) ?? ''
        ..harga = (json['harga'] as int?) ?? 0
        ..lokasi = (json['lokasi'] as String?) ?? ''
        ..kota = (json['kota'] as String?) ?? ''
        ..namaKota = json['namaKota'] as String?
        ..tglRealisasi = json['tglRealisasi'] != null
            ? DateTime.fromMillisecondsSinceEpoch(json['tglRealisasi'] as int)
            : DateTime.now()
        ..metodeBayar = json['metodeBayar'] as String?
        ..statusBayar = json['statusBayar'] as String?
        ..idPaymentGateway = json['idPaymentGateway'] as String?
        ..orderIdMidtrans = json['orderIdMidtrans'] as String?
        ..expiryTime = json['expiryTime'] != null
            ? DateTime.fromMillisecondsSinceEpoch(json['expiryTime'] as int)
            : null
        ..paymentNumber1 = json['paymentNumber1'] as String?
        ..paymentNumber2 = json['paymentNumber2'] as String?
        ..linkSnap = json['linkSnap'] as String?
        ..linkUrl = json['linkUrl'] as String?
        ..subtotal = (json['subtotal'] as int?) ?? 0
        ..totDpp = (json['totDpp'] as num?)?.toDouble()
        ..ppn = json['ppn'] as int?
        ..inclPpn = json['inclPpn'] as bool?
        ..totPpn = json['totPpn'] as int?
        ..grandTotal = (json['grandTotal'] as int?) ?? 0
        ..estimasiPengerjaan = (json['estimasiPengerjaan'] as int?) ?? 0
        ..tglPengerjaanMax = json['tglPengerjaanMax'] != null
            ? DateTime.fromMillisecondsSinceEpoch(json['tglPengerjaanMax'] as int)
            : null
        ..createdAt = json['createdAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int)
            : null
        ..updatedAt = json['updatedAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(json['updatedAt'] as int)
            : null;

  Map<String, dynamic> toJson() => {
        'noBukti': noBukti,
        'noTrackingPesanan': noTrackingPesanan,
        'status': status,
        'statusProgresPesanan': statusProgresPesanan,
        'deskripsiProgresPesanan': deskripsiProgresPesanan,
        'noPenawaran': noPenawaran,
        'idVendor': idVendor,
        'namaVendor': namaVendor,
        'idMediaVendor': idMediaVendor,
        'idCustomer': idCustomer,
        'namaCustomer': namaCustomer,
        'idPaket': idPaket,
        'namaPaket': namaPaket,
        'harga': harga,
        'lokasi': lokasi,
        'kota': kota,
        'namaKota': namaKota,
        'tglRealisasi': tglRealisasi.millisecondsSinceEpoch,
        'metodeBayar': metodeBayar,
        'statusBayar': statusBayar,
        'idPaymentGateway': idPaymentGateway,
        'orderIdMidtrans': orderIdMidtrans,
        'expiryTime': expiryTime?.millisecondsSinceEpoch,
        'paymentNumber1': paymentNumber1,
        'paymentNumber2': paymentNumber2,
        'linkSnap': linkSnap,
        'linkUrl': linkUrl,
        'subtotal': subtotal,
        'totDpp': totDpp,
        'ppn': ppn,
        'inclPpn': inclPpn,
        'totPpn': totPpn,
        'grandTotal': grandTotal,
        'estimasiPengerjaan': estimasiPengerjaan,
        'tglPengerjaanMax': tglPengerjaanMax?.millisecondsSinceEpoch,
        'createdAt': createdAt?.millisecondsSinceEpoch,
        'updatedAt': updatedAt?.millisecondsSinceEpoch,
      };

  PesananModel toModel() => PesananModel(
        noBukti: noBukti,
        noTrackingPesanan: noTrackingPesanan,
        status: status,
        statusProgresPesanan: statusProgresPesanan,
        deskripsiProgresPesanan: deskripsiProgresPesanan,
        noPenawaran: noPenawaran,
        idVendor: idVendor,
        namaVendor: namaVendor,
        idMediaVendor: idMediaVendor,
        idCustomer: idCustomer,
        namaCustomer: namaCustomer,
        idPaket: idPaket,
        namaPaket: namaPaket,
        harga: harga,
        lokasi: lokasi,
        kota: kota,
        namaKota: namaKota,
        tglRealisasi: tglRealisasi,
        metodeBayar: metodeBayar,
        statusBayar: statusBayar,
        idPaymentGateway: idPaymentGateway,
        orderIdMidtrans: orderIdMidtrans,
        expiryTime: expiryTime,
        paymentNumber1: paymentNumber1,
        paymentNumber2: paymentNumber2,
        linkSnap: linkSnap,
        linkUrl: linkUrl,
        subtotal: subtotal,
        totDpp: totDpp,
        ppn: ppn,
        inclPpn: inclPpn,
        totPpn: totPpn,
        grandTotal: grandTotal,
        estimasiPengerjaan: estimasiPengerjaan,
        tglPengerjaanMax: tglPengerjaanMax,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  bool get isNotEmpty => noBukti.isNotEmpty;
}

// ═══════════════════════════════════════════════════════════════════════════
// CHAT MESSAGE ENTITY
// ═══════════════════════════════════════════════════════════════════════════

class ChatMessageEntity {
  int id = 0;

  late String messageId;
  late String roomId;
  late String senderId;
  late String message;
  late String sendStatus;
  late DateTime sentAt;

  String? localId;
  String? jenisPesan;

  // ── Reference IDs — disimpan agar enrich bisa berjalan ──────────────────
  String? idPaket;
  String? noPenawaran;
  String? noInvoice; // = noBukti pesanan

  // ── Embedded objects — full model tersimpan sebagai JSON ─────────────────
  EmbeddedPaket? paket;
  EmbeddedPenawaran? penawaran;
  EmbeddedPesanan? pesanan;

  DateTime? readAt;
  DateTime? receivedAt;
  List<String> receiverIds = [];

  // =========================================
  // HELPER GETTERS
  // =========================================

  bool get isLocalEcho => localId != null && messageId.startsWith('local-');

  bool get hasPaket => paket != null && paket!.isNotEmpty;

  bool get hasPenawaran => penawaran != null && penawaran!.isNotEmpty;

  bool get hasPesanan => pesanan != null && pesanan!.isNotEmpty;

  bool get isPending => sendStatus == 'pending';

  bool get isFailed => sendStatus == 'failed';

  bool get isRead => sendStatus == 'read';

  /// Jenis pesan resolved — prioritas: pesanan > penawaran > paket > text
  String get resolvedJenisPesan {
    if (hasPesanan) return 'pesanan';
    if (hasPenawaran) return 'penawaran';
    if (hasPaket) return 'paket';
    // Fallback: cek dari ID jika embedded belum di-enrich
    if (noInvoice?.isNotEmpty == true) return 'pesanan';
    if (noPenawaran?.isNotEmpty == true) return 'penawaran';
    if (idPaket?.isNotEmpty == true) return 'paket';
    return jenisPesan ?? 'text';
  }

  /// ✅ Cek apakah penawaran sudah berubah jadi pesanan
  bool get penawaranSudahJadiPesanan =>
      hasPenawaran && penawaran!.sudahJadiPesanan;

  // ── Reconstruct model ────────────────────────────────────────────────────

  PaketModel? get paketModel => hasPaket ? paket!.toModel() : null;

  PenawaranModel? get penawaranModel =>
      hasPenawaran ? penawaran!.toModel() : null;

  PesananModel? get pesananModel => hasPesanan ? pesanan!.toModel() : null;

  // =========================================
  // CONSTRUCTORS
  // =========================================

  ChatMessageEntity();

  /// Dari ChatModel saja — embedded null, ID tersimpan untuk enrich nanti
  factory ChatMessageEntity.fromChatModel(ChatModel model) {
    return ChatMessageEntity()
      ..messageId = model.messageId
      ..roomId = model.roomId
      ..senderId = model.senderId
      ..message = model.message
      ..sendStatus = model.sendStatus
      ..sentAt = model.sentAt
      ..localId = model.localId
      ..jenisPesan = model.jenisPesan
      ..readAt = model.readAt
      ..receivedAt = model.receivedAt
      ..receiverIds = List<String>.from(model.receiverIds)
      // ✅ Simpan reference ID agar enrich bisa berjalan setelah save
      ..idPaket = model.idPaket
      ..noPenawaran = model.noPenawaran
      ..noInvoice = model.noInvoice;
  }

  /// Dari ChatModel + data yang sudah di-fetch — embedded langsung terisi
  factory ChatMessageEntity.fromChatModelWithData(
    ChatModel model, {
    PaketModel? paket,
    PenawaranModel? penawaran,
    PesananModel? pesanan,
  }) {
    return ChatMessageEntity()
      ..messageId = model.messageId
      ..roomId = model.roomId
      ..senderId = model.senderId
      ..message = model.message
      ..sendStatus = model.sendStatus
      ..sentAt = model.sentAt
      ..localId = model.localId
      ..jenisPesan = model.jenisPesan
      ..readAt = model.readAt
      ..receivedAt = model.receivedAt
      ..receiverIds = List<String>.from(model.receiverIds)
      ..idPaket = model.idPaket
      ..noPenawaran = model.noPenawaran
      ..noInvoice = model.noInvoice
      ..paket = paket != null ? EmbeddedPaket.fromModel(paket) : null
      ..penawaran =
          penawaran != null ? EmbeddedPenawaran.fromModel(penawaran) : null
      ..pesanan = pesanan != null ? EmbeddedPesanan.fromModel(pesanan) : null;
  }

  // =========================================
  // SQFLITE SERIALIZATION
  // =========================================

  Map<String, dynamic> toMap() => {
        'message_id': messageId,
        'room_id': roomId,
        'sender_id': senderId,
        'message': message,
        'send_status': sendStatus,
        'sent_at': sentAt.millisecondsSinceEpoch,
        'local_id': localId,
        'jenis_pesan': jenisPesan,
        'id_paket': idPaket,
        'no_penawaran': noPenawaran,
        'no_invoice': noInvoice,
        'paket': paket != null ? jsonEncode(paket!.toJson()) : null,
        'penawaran':
            penawaran != null ? jsonEncode(penawaran!.toJson()) : null,
        'pesanan': pesanan != null ? jsonEncode(pesanan!.toJson()) : null,
        'read_at': readAt?.millisecondsSinceEpoch,
        'received_at': receivedAt?.millisecondsSinceEpoch,
        'receiver_ids': jsonEncode(receiverIds),
      };

  factory ChatMessageEntity.fromMap(Map<String, dynamic> map) {
    final entity = ChatMessageEntity()
      ..id = (map['id'] as int?) ?? 0
      ..messageId = map['message_id'] as String
      ..roomId = map['room_id'] as String
      ..senderId = map['sender_id'] as String
      ..message = map['message'] as String
      ..sendStatus = map['send_status'] as String
      ..sentAt =
          DateTime.fromMillisecondsSinceEpoch(map['sent_at'] as int)
      ..localId = map['local_id'] as String?
      ..jenisPesan = map['jenis_pesan'] as String?
      ..idPaket = map['id_paket'] as String?
      ..noPenawaran = map['no_penawaran'] as String?
      ..noInvoice = map['no_invoice'] as String?
      ..readAt = map['read_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['read_at'] as int)
          : null
      ..receivedAt = map['received_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['received_at'] as int)
          : null
      ..receiverIds = map['receiver_ids'] != null
          ? List<String>.from(jsonDecode(map['receiver_ids'] as String))
          : [];

    try {
      if (map['paket'] != null) {
        entity.paket =
            EmbeddedPaket.fromJson(jsonDecode(map['paket'] as String));
      }
      if (map['penawaran'] != null) {
        entity.penawaran = EmbeddedPenawaran.fromJson(
            jsonDecode(map['penawaran'] as String));
      }
      if (map['pesanan'] != null) {
        entity.pesanan =
            EmbeddedPesanan.fromJson(jsonDecode(map['pesanan'] as String));
      }
    } catch (e) {
      debugPrint('[ChatMessageEntity] ⚠️ fromMap embedded parse error: $e');
    }

    return entity;
  }

  // =========================================
  // CONVERTERS
  // =========================================

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
      // ✅ Prioritas: embedded data jika ada, fallback ke ID
      idPaket: paket?.noId ?? idPaket,
      noInvoice: pesanan?.noBukti ?? noInvoice,
      noPenawaran: penawaran?.noId ?? noPenawaran,
      status: 'aktif',
      sendStatus: sendStatus,
      roomType: roomType,
      sentAt: sentAt,
      editedAt: null,
      receivedAt: receivedAt,
      readAt: readAt,
      userIds: userIds,
      receiverIds: receiverIds,
      localId: localId,
    );
  }

  // =========================================
  // COPY WITH
  // =========================================

  ChatMessageEntity copyWith({
    String? messageId,
    String? sendStatus,
    String? message,
    String? jenisPesan,
    String? idPaket,
    String? noPenawaran,
    String? noInvoice,
    EmbeddedPaket? paket,
    EmbeddedPenawaran? penawaran,
    EmbeddedPesanan? pesanan,
    DateTime? readAt,
    DateTime? receivedAt,
    List<String>? receiverIds,
  }) {
    return ChatMessageEntity()
      ..id = id
      ..messageId = messageId ?? this.messageId
      ..roomId = roomId
      ..senderId = senderId
      ..message = message ?? this.message
      ..sendStatus = sendStatus ?? this.sendStatus
      ..sentAt = sentAt
      ..localId = localId
      ..jenisPesan = jenisPesan ?? this.jenisPesan
      ..idPaket = idPaket ?? this.idPaket
      ..noPenawaran = noPenawaran ?? this.noPenawaran
      ..noInvoice = noInvoice ?? this.noInvoice
      ..paket = paket ?? this.paket
      ..penawaran = penawaran ?? this.penawaran
      ..pesanan = pesanan ?? this.pesanan
      ..readAt = readAt ?? this.readAt
      ..receivedAt = receivedAt ?? this.receivedAt
      ..receiverIds = receiverIds ?? List<String>.from(this.receiverIds);
  }

  @override
  String toString() =>
      'ChatMessageEntity(messageId: $messageId, room: $roomId, '
      'status: $sendStatus, jenis: $resolvedJenisPesan, '
      'hasPaket: $hasPaket, hasPenawaran: $hasPenawaran, hasPesanan: $hasPesanan)';
}
