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
      noId: json['no_id'] ?? '',
      noOrder: json['no_order'] ?? '',
      tglProgress: DateTime.parse(json['tgl_progress']),
      deskripsi: json['deskripsi'] ?? '',
      senderId: json['sender_id'] ?? '',
      tipeUser: json['tipe_user'] ?? '',
      namaSender: json['Nama_Sender'] ?? '',
      status: json['status'] ?? '',
      statusProgressPesanan: json['status_progress_pesanan'] ?? '',
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
