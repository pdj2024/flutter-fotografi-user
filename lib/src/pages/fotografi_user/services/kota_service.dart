import 'dart:convert';

import '../../core/api_client.dart';

import 'package:mpjnew/src/pages/core/api_client.dart';
import 'package:mpjnew/src/pages/core/api_singleton.dart';

import '../models/kota_model.dart';

class KotaService {


  final String entity = 'Kota';
  final String controller = 'kota';
 final ApiClient _client = apiClient; // ← pakai nama beda
 

  /// GET ALL
  Future<List<KotaModel>> getAll({
    String? noId,
    String? namaKota,
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
          if (namaKota != null) 'nama_kota': namaKota,
       
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
        return data.map((e) => KotaModel.fromJson(e)).toList();
      } else {
        throw Exception('Gagal load $entity (${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Error saat mengambil $entity: $e');
    }
  }

  /// CREATE
  Future<void> create(KotaModel model) async {
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
  Future<void> update(KotaModel model) async {
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
