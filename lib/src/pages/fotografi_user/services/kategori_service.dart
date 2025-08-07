import 'dart:convert';

import '../../core/api_client.dart';
import '../models/kategori_model.dart';
import 'package:mpjnew/src/pages/core/api_client.dart';
import 'package:mpjnew/src/pages/core/api_singleton.dart';

class KategoriService {


  final String entity = 'Kategori';
  final String controller = 'kategori';
 final ApiClient _client = apiClient; // ← pakai nama beda
 

  /// GET ALL
  Future<List<KategoriModel>> getAll({
    String? noId,
    String? namaKategori,
    String? idMedia,
    String? status,
    String? orderBy,
    String? orderDir,
  }) async {
    try {
      final response = await apiClient.get(
        
        '/$controller/getAll',
        queryParameters: {
          if (noId != null) 'no_id': noId,
          if (namaKategori != null) 'nama_kategori': namaKategori,
          if (idMedia != null) 'id_media': idMedia,
          if (status != null) 'status': status,
          if (orderBy != null) 'orderby': orderBy,
          if (orderDir != null) 'orderdir': orderDir,
        },
      );
print('==============================');
  print('Response Body: ${response.body}');
  print('Status Code: ${response.statusCode}');
  print('==============================');

      
  // print('==============================');
  // print('Response Body: ${response.body}');
  // print('Status Code: ${response.statusCode}');
  // print('==============================');


      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        final List<dynamic> data = json['Data'];
        return data.map((e) => KategoriModel.fromJson(e)).toList();
      } else {
        throw Exception('Gagal load $entity (${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Error saat mengambil $entity: $e');
    }
  }

  /// CREATE
  Future<void> create(KategoriModel model) async {
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
  Future<void> update(KategoriModel model) async {
    final response = await apiClient.put(
      '/$controller/update',
      queryParameters: {'no_id': model.no_id},
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
