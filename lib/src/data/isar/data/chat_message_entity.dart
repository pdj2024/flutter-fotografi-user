import 'package:isar/isar.dart';
import 'package:mpjnew/src/data/hive_entity/paket_model.dart';
import 'package:mpjnew/src/data/hive_entity/penawaran_model.dart';
import 'package:mpjnew/src/data/hive_entity/pesanan_model.dart';
import 'package:mpjnew/src/data/models/chat_model.dart';

part 'chat_message_entity.g.dart';

// ═══════════════════════════════════════════════════════════════════════════
// EMBEDDED: PAKET
// Mirror dari PaketModel — semua field sama, tidak ada yang dihilangkan
// ═══════════════════════════════════════════════════════════════════════════

@embedded
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

  PaketModel toModel() => PaketModel(
        no_id: noId,
        nama_paket: namaPaket,
        id_vendor: idVendor,
        harga: harga,
        rincian: rincian,
        status: status,
      );

  @ignore
  bool get isNotEmpty => noId.isNotEmpty;
}

// ═══════════════════════════════════════════════════════════════════════════
// EMBEDDED: PENAWARAN
// Mirror dari PenawaranModel — semua field sama
// ═══════════════════════════════════════════════════════════════════════════

@embedded
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
    ..updatedAt = m.updatedAt;

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
      );

  @ignore
  bool get isNotEmpty => noId.isNotEmpty;

  /// ✅ Penawaran sudah jadi pesanan jika noPesanan tidak kosong
  @ignore
  bool get sudahJadiPesanan => noPesanan.isNotEmpty;
}

// ═══════════════════════════════════════════════════════════════════════════
// EMBEDDED: PESANAN
// Mirror dari PesananModel — semua field sama
// ═══════════════════════════════════════════════════════════════════════════

@embedded
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
    ..createdAt = m.createdAt
    ..updatedAt = m.updatedAt;

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
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  @ignore
  bool get isNotEmpty => noBukti.isNotEmpty;
}

// ═══════════════════════════════════════════════════════════════════════════
// CHAT MESSAGE ENTITY
// ═══════════════════════════════════════════════════════════════════════════

@collection
class ChatMessageEntity {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String messageId;

  @Index()
  late String roomId;

  late String senderId;
  late String message;

  @Index()
  late String sendStatus;

  late DateTime sentAt;

  String? localId;
  String? jenisPesan;

  // ── Reference IDs — disimpan agar enrich bisa berjalan ──────────────────
  // Penting: embedded data bisa null (belum di-enrich),
  // tapi ID selalu ada jika pesan memang punya paket/penawaran/pesanan
  String? idPaket;
  String? noPenawaran;
  String? noInvoice; // = noBukti pesanan

  // ── Embedded objects — full model tersimpan di Isar ───────────────────
  EmbeddedPaket? paket;
  EmbeddedPenawaran? penawaran;
  EmbeddedPesanan? pesanan;

  DateTime? readAt;
  DateTime? receivedAt;
  List<String> receiverIds = [];

  // =========================================
  // HELPER GETTERS
  // =========================================

  @ignore
  bool get isLocalEcho =>
      localId != null && messageId.startsWith('local-');

  @ignore
  bool get hasPaket => paket != null && paket!.isNotEmpty;

  @ignore
  bool get hasPenawaran => penawaran != null && penawaran!.isNotEmpty;

  @ignore
  bool get hasPesanan => pesanan != null && pesanan!.isNotEmpty;

  @ignore
  bool get isPending => sendStatus == 'pending';

  @ignore
  bool get isFailed => sendStatus == 'failed';

  @ignore
  bool get isRead => sendStatus == 'read';

  /// Jenis pesan resolved — prioritas: pesanan > penawaran > paket > text
  @ignore
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
  @ignore
  bool get penawaranSudahJadiPesanan =>
      hasPenawaran && penawaran!.sudahJadiPesanan;

  // ── Reconstruct model ────────────────────────────────────────────────────

  @ignore
  PaketModel? get paketModel => hasPaket ? paket!.toModel() : null;

  @ignore
  PenawaranModel? get penawaranModel =>
      hasPenawaran ? penawaran!.toModel() : null;

  @ignore
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