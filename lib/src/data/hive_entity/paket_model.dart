import 'package:hive/hive.dart';

part 'paket_model.g.dart';

@HiveType(typeId: 3)
class PaketModel {
  @HiveField(0)
  final String no_id;
  
  @HiveField(1)
  final String nama_paket;
  
  @HiveField(2)
  final String id_vendor;
  
  @HiveField(3)
  final int harga;
  
  @HiveField(4)
  final String rincian;
  
  @HiveField(5)
  final String status;

  @HiveField(6)
  final int revisi;

  PaketModel({
    required this.no_id,
    required this.nama_paket,
    required this.id_vendor,
    required this.harga,
    required this.rincian,
    required this.status,
    this.revisi = 0,
  });

  factory PaketModel.fromJson(Map<String, dynamic> json) {
    return PaketModel(
      no_id: json['No_Id'] ?? '',
      nama_paket: json['Nama_Paket'] ?? '',
      id_vendor: json['Id_Vendor'] ?? '',
      harga: json['Harga'] ?? 0,
      rincian: json['Rincian'] ?? '',
      status: json['Status'] ?? "",
      revisi: json['Revisi'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'No_Id': no_id,
      'nama_paket': nama_paket,
      'id_vendor': id_vendor,
      'harga': harga,
      'rincian': rincian,
      'status': status,
      'Revisi': revisi,
    };
  }

  PaketModel copyWith({
    String? no_id,
    String? nama_paket,
    String? id_vendor,
    int? harga,
    String? rincian,
    String? status,
    int? revisi,
  }) {
    return PaketModel(
      no_id: no_id ?? this.no_id,
      nama_paket: nama_paket ?? this.nama_paket,
      id_vendor: id_vendor ?? this.id_vendor,
      harga: harga ?? this.harga,
      rincian: rincian ?? this.rincian,
      status: status ?? this.status,
      revisi: revisi ?? this.revisi,
    );
  }

  /// Tambahkan ini untuk CREATE
  Map<String, dynamic> toJsonAPI() => {
        "nama_paket": nama_paket,
        "id_vendor": id_vendor,
        "harga": harga,
        "rincian": rincian,
        "status": status,
      };
}