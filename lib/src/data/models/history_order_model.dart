class HistoryOrderModel {
  final String noId;
  final String noOrder;
  final DateTime tglProgress;
  final String deskripsi;
  final String senderId;
  final String tipeUser;
  final String namaSender;
  final String status;

  HistoryOrderModel({
    required this.noId,
    required this.noOrder,
    required this.tglProgress,
    required this.deskripsi,
    required this.senderId,
    required this.tipeUser,
    required this.namaSender,
    required this.status,
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
    );
  }
}
