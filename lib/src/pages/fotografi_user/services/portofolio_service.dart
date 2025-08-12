import 'dart:convert';

import '../../core/api_client.dart';
import '../models/portofolio_model.dart';
import 'package:mpjnew/src/pages/core/api_client.dart';
import 'package:mpjnew/src/pages/core/api_singleton.dart';

class PortofolioService {
  final String entity = 'Portofolio';
  final String controller = 'portofolio';


   final ApiClient _client = apiClient; // ← pakai nama beda

  /// GET ALL
  Future<List<PortofolioModel>> getAll({
    String? noId,
     String? status,
    String? id_customer,
    String? idVendor,
    String? idMedia,
    String? idKategori,
    String? namaVendor,
    double? ratingVendorMin,
    double? ratingVendorMax,
    int? jumlahPaketMin,
    int? jumlahPaketMax,
    String? jenisMedia,
    String? username,
     String? nama_vendor,
      String? untuk_keperluan,
    String? orderBy,
    String? orderDir,
  }) async {
    try {
      final response = await apiClient.get(
        '/$controller/getAll',
        queryParameters: {
          if (noId != null) 'no_id': noId,
           if (status != null) 'status': status,
          if (id_customer != null) 'id_customer': id_customer,
          if (idVendor != null) 'id_vendor': idVendor,
          if (idMedia != null) 'id_media': idMedia,
          if (idKategori != null) 'id_kategori': idKategori,
          if (namaVendor != null) 'nama_vendor': namaVendor,
          if (ratingVendorMin != null) 'rating_vendor_min': ratingVendorMin.toString(),
          if (ratingVendorMax != null) 'rating_vendor_max': ratingVendorMax.toString(),
          if (jumlahPaketMin != null) 'jumlah_paket_min': jumlahPaketMin.toString(),
          if (jumlahPaketMax != null) 'jumlah_paket_max': jumlahPaketMax.toString(),
          if (jenisMedia != null) 'jenis_media': jenisMedia,
          if (username != null) 'username_vendor': username,
           if (nama_vendor != null) 'nama_vendor': nama_vendor,
            if (untuk_keperluan != null) 'untuk_keperluan': untuk_keperluan,
          if (orderBy != null) 'orderBy': orderBy,
          if (orderDir != null) 'orderDir': orderDir,
        },
      );
print('==============================');
  print('Response Body: ${response.body}');
  print('Status Code: ${response.statusCode}');
  print('==============================');


      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        final List<dynamic> data = json['Data'];
        return data.map((e) => PortofolioModel.fromJson(e)).toList();
      } else if (response.statusCode == 204) {
        // Tidak ada data
        return [];
      } else {
        throw Exception('Gagal load $entity (${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Error saat mengambil $entity: $e');
    }
  }

/// CREATE
  Future<void> create(PortofolioModel model) async {
    final response = await apiClient.post(
      '/$controller/create',
      body: jsonEncode(model.toJson()),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('Gagal menambahkan $entity');
    }
  }

  /// UPDATE
  Future<void> update(PortofolioModel model) async {
    final response = await apiClient.put(
      '/$controller/update',
      queryParameters: {'no_id': model.noId},
      body: jsonEncode(apiClient.toJsonSafe(model.toJson())),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('Gagal mengupdate $entity');
    }
  }

  /// DELETE
  Future<void> delete(String noId) async {
    final response = await apiClient.delete(
      '/$controller/delete',
      queryParameters: {'no_id': noId},
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('Gagal menghapus $entity');
    }
  }
}
