class MetodePembayaranModel {
  final String caraBayar;
  final String display;
  final String deskripsi;
  final int fee;
  final String provider;
  final String status;

  MetodePembayaranModel({
    required this.caraBayar,
    required this.display,
    required this.deskripsi,
    required this.fee,
    required this.provider,
    required this.status,
  });

  /// =======================
  /// FROM JSON
  /// =======================
  factory MetodePembayaranModel.fromJson(Map<String, dynamic> json) {
    return MetodePembayaranModel(
      caraBayar: json['Cara_Bayar'] ?? '',
      display: json['Display'] ?? '',
      deskripsi: json['Deskripsi'] ?? '',
      fee: json['Fee'] is int
          ? json['Fee']
          : int.tryParse(json['Fee'].toString()) ?? 0,
      provider: json['Provider'] ?? '',
      status: json['Status'] ?? '',
    );
  }

  /// =======================
  /// TO JSON
  /// =======================
  Map<String, dynamic> toJson() {
    return {
      'Cara_Bayar': caraBayar,
      'Display': display,
      'Deskripsi': deskripsi,
      'Fee': fee,
      'Provider': provider,
      'Status': status,
    };
  }

  /// =======================
  /// COPY WITH
  /// =======================
  MetodePembayaranModel copyWith({
    String? caraBayar,
    String? display,
    String? deskripsi,
    int? fee,
    String? provider,
    String? status,
  }) {
    return MetodePembayaranModel(
      caraBayar: caraBayar ?? this.caraBayar,
      display: display ?? this.display,
      deskripsi: deskripsi ?? this.deskripsi,
      fee: fee ?? this.fee,
      provider: provider ?? this.provider,
      status: status ?? this.status,
    );
  }
}
