class HistoryOrderModel {
  final String noId;
  final String noOrder;
  final DateTime tglProgress;
  final String deskripsi;
  final String senderId;
  final String tipeUser;
  final String namaSender;
  final String status;
  final String statusProgressPesanan;

  HistoryOrderModel({
    required this.noId,
    required this.noOrder,
    required this.tglProgress,
    required this.deskripsi,
    required this.senderId,
    required this.tipeUser,
    required this.namaSender,
    required this.status,
    required this.statusProgressPesanan,
  });

  // =====================================================
  // 🔄 FROM JSON
  // =====================================================
  factory HistoryOrderModel.fromJson(Map<String, dynamic> json) {
    return HistoryOrderModel(
      noId: json['No_Id'] ?? '',
      noOrder: json['No_Order'] ?? '',
      tglProgress: DateTime.parse(json['Tgl_Progress']),
      deskripsi: json['Deskripsi'] ?? '',
      senderId: json['Sender_Id'] ?? '',
      tipeUser: json['Tipe_User'] ?? '',
      namaSender: json['Nama_Sender'] ?? '',
      status: json['Status'] ?? '',
      statusProgressPesanan: json['Status_Progress_Pesanan'] ?? '',
    );
  }

  factory HistoryOrderModel.fromFCM(Map<String, dynamic> json) {
    return HistoryOrderModel(
      noId: json['no_id']?.toString() ?? '',
      noOrder: json['no_order']?.toString() ?? '',
      tglProgress: json['tgl_progress'] != null
          ? DateTime.tryParse(json['tgl_progress'].toString()) ?? DateTime.now()
          : DateTime.now(),
      deskripsi: json['deskripsi']?.toString() ?? '',
      senderId: json['sender_id']?.toString() ?? '',
      tipeUser: json['tipe_user']?.toString() ?? '',
      namaSender: json['nama_sender']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      statusProgressPesanan: json['status_progress_pesanan']?.toString() ?? '',
    );
  }

  // =====================================================
  // 🔁 TO JSON
  // =====================================================
  Map<String, dynamic> toJson() {
    return {
      'No_Id': noId,
      'No_Order': noOrder,
      'Tgl_Progress': tglProgress.toIso8601String(),
      'Deskripsi': deskripsi,
      'Sender_Id': senderId,
      'Tipe_User': tipeUser,
      'Nama_Sender': namaSender,
      'Status': status,
      'Status_Progress_Pesanan': statusProgressPesanan,
    };
  }

  Map<String, dynamic> toJsonCreate() {
    return {
      'no_order': noOrder,
      'deskripsi': deskripsi,
      'sender_Id': senderId,
      'status': status,
      'status_Progress_Pesanan': statusProgressPesanan,
    };
  }

  // =====================================================
  // ✏️ COPY WITH
  // =====================================================

  HistoryOrderModel copyWith({
    String? noId,
    String? noOrder,
    DateTime? tglProgress,
    String? deskripsi,
    String? senderId,
    String? tipeUser,
    String? namaSender,
    String? status,
    String? statusProgressPesanan,
  }) {
    return HistoryOrderModel(
      noId: noId ?? this.noId,
      noOrder: noOrder ?? this.noOrder,
      tglProgress: tglProgress ?? this.tglProgress,
      deskripsi: deskripsi ?? this.deskripsi,
      senderId: senderId ?? this.senderId,
      tipeUser: tipeUser ?? this.tipeUser,
      namaSender: namaSender ?? this.namaSender,
      status: status ?? this.status,
      statusProgressPesanan:
          statusProgressPesanan ?? this.statusProgressPesanan,
    );
  }
}

/// Progress Status Enum untuk mapping status pesanan
enum OrderProgressStatus {
  menungguBayar,
  persiapan,
  proses,
  review,
  revisi,
  selesai,
  dibatalkan,
  unknown;

  static OrderProgressStatus fromString(String? status) {
    switch (status?.toLowerCase()) {
      case 'menunggu bayar':
      case 'menunggu_bayar':
      case 'pending':
        return OrderProgressStatus.menungguBayar;
      case 'persiapan':
      case 'preparation':
        return OrderProgressStatus.persiapan;
      case 'proses':
      case 'processing':
      case 'dikerjakan':
        return OrderProgressStatus.proses;
      case 'review':
      case 'ulasan':
        return OrderProgressStatus.review;
      case 'revisi':
      case 'revision':
        return OrderProgressStatus.revisi;
      case 'selesai':
      case 'completed':
      case 'done':
        return OrderProgressStatus.selesai;
      case 'dibatalkan':
      case 'cancelled':
      case 'batal':
        return OrderProgressStatus.dibatalkan;
      default:
        return OrderProgressStatus.unknown;
    }
  }

  String get emoji {
    switch (this) {
      case OrderProgressStatus.menungguBayar:
        return '💳';
      case OrderProgressStatus.persiapan:
        return '📦';
      case OrderProgressStatus.proses:
        return '⚙️';
      case OrderProgressStatus.review:
        return '⭐';
      case OrderProgressStatus.revisi:
        return '🔧';
      case OrderProgressStatus.selesai:
        return '🎉';
      case OrderProgressStatus.dibatalkan:
        return '❌';
      default:
        return '📋';
    }
  }

  String get title {
    switch (this) {
      case OrderProgressStatus.menungguBayar:
        return 'Menunggu Pembayaran';
      case OrderProgressStatus.persiapan:
        return 'Persiapan Pesanan';
      case OrderProgressStatus.proses:
        return 'Sedang Diproses';
      case OrderProgressStatus.review:
        return 'Berikan Ulasan';
      case OrderProgressStatus.revisi:
        return 'Dalam Revisi';
      case OrderProgressStatus.selesai:
        return 'Pesanan Selesai';
      case OrderProgressStatus.dibatalkan:
        return 'Pesanan Dibatalkan';
      default:
        return 'Update Pesanan';
    }
  }

  String get description {
    switch (this) {
      case OrderProgressStatus.menungguBayar:
        return 'Pesanan berhasil dibuat. Silakan selesaikan pembayaran.';
      case OrderProgressStatus.persiapan:
        return 'Pembayaran diterima. Vendor sedang menyiapkan pesanan Anda.';
      case OrderProgressStatus.proses:
        return 'Pesanan sedang dikerjakan oleh vendor.';
      case OrderProgressStatus.review:
        return 'Pesanan selesai dikerjakan. Mohon berikan ulasan Anda.';
      case OrderProgressStatus.revisi:
        return 'Vendor sedang melakukan revisi sesuai permintaan Anda.';
      case OrderProgressStatus.selesai:
        return 'Pesanan telah selesai. Terima kasih!';
      case OrderProgressStatus.dibatalkan:
        return 'Pesanan telah dibatalkan.';
      default:
        return 'Status tidak diketahui';
    }
  }

  String get tipeUser {
    switch (this) {
      case OrderProgressStatus.menungguBayar:
      case OrderProgressStatus.review:
      case OrderProgressStatus.selesai:
      case OrderProgressStatus.dibatalkan:
        return 'Customer';
      case OrderProgressStatus.persiapan:
      case OrderProgressStatus.proses:
      case OrderProgressStatus.revisi:
        return 'Vendor';
      default:
        return 'Unknown';
    }
  }
}
