import 'dart:convert';

import '../../../core/services/api_client.dart';
import '../../../data/models/portofolio_model.dart';
import 'package:mpjnew/src/core/services/api_singleton.dart';

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
    int? hargaPaketMin,
    int? hargaPaketMax,
    String? jenisMedia,
    String? username,
    String? nama_vendor,
    String? untuk_keperluan,
    String? kota,
    String? orderBy,
    String? orderDir,
  }) async {
    try {
      print("============= PORTO GETT MIN: " + hargaPaketMin.toString());

      final response = await apiClient.get(
        '/$controller/getAll',
        queryParameters: {
          if (noId != null && noId.toString().isNotEmpty) 'no_id': noId,
          if (status != null && status.toString().isNotEmpty) 'status': status,
          if (id_customer != null && id_customer.toString().isNotEmpty)
            'id_customer': id_customer,
          if (idVendor != null && idVendor.toString().isNotEmpty)
            'id_vendor': idVendor,
          if (idMedia != null && idMedia.toString().isNotEmpty)
            'id_media': idMedia,
          if (idKategori != null && idKategori.toString().isNotEmpty)
            'id_kategori': idKategori,
          if (namaVendor != null && namaVendor.toString().isNotEmpty)
            'nama_vendor': namaVendor,
          if (ratingVendorMin != null)
            'rating_vendor_min': ratingVendorMin.toString(),
          if (ratingVendorMax != null)
            'rating_vendor_max': ratingVendorMax.toString(),
          if (jumlahPaketMin != null)
            'jumlah_paket_min': jumlahPaketMin.toString(),
          if (jumlahPaketMax != null)
            'jumlah_paket_max': jumlahPaketMax.toString(),
          if (hargaPaketMin != null) 'harga_min': hargaPaketMin.toString(),
          if (hargaPaketMax != null) 'harga_max': hargaPaketMax.toString(),
          if (jenisMedia != null && jenisMedia.toString().isNotEmpty)
            'jenis_media': jenisMedia,
          if (username != null && username.toString().isNotEmpty)
            'username_vendor': username,
          if (nama_vendor != null && nama_vendor.toString().isNotEmpty)
            'nama_vendor': nama_vendor,
          if (untuk_keperluan != null && untuk_keperluan.toString().isNotEmpty)
            'untuk_keperluan': untuk_keperluan,
          if (kota != null && kota.toString().isNotEmpty) 'kota': kota,
          if (orderBy != null && orderBy.toString().isNotEmpty)
            'orderBy': orderBy,
          if (orderDir != null && orderDir.toString().isNotEmpty)
            'orderDir': orderDir,
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

// ACTION
  Future<void> action({
    required String no_id,
    required String id_portofolio,
    required String action_type, // like, unlike, save, unsave
  }) async {
    final body = {
      "no_id": no_id,
      "id_portofolio": id_portofolio,
      "action_type": action_type,
    };

    final response = await apiClient.post(
      '/$controller/action',
      body: jsonEncode(body),
      headers: {'Content-Type': 'application/json'},
    );

    print('==============================');
    print('Response Body: ${response.body}');
    print('Status Code: ${response.statusCode}');
    print('==============================');

    if (response.statusCode != 200) {
      throw Exception('Gagal melakukan aksi $action_type');
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
