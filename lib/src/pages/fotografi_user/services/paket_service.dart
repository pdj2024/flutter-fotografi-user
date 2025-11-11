import 'dart:convert';

import '../../../core/services/api_client.dart';
import '../../../data/models/paket_model.dart';
import 'package:mpjnew/src/core/services/api_singleton.dart';

class PaketService {


  final String entity = 'Paket';
  final String controller = 'paket';

   final ApiClient _client = apiClient; // ← pakai nama beda

  /// GET ALL
  Future<List<PaketModel>> getAll({
  String? noId,
  String? namaPaket,
  String? idVendor,
  int? hargaMin,
  int? hargaMax,
  String? status,
  String? orderBy,
  String? orderDir,
  List<String>? idList, // ✅ Tambahkan ini
}) async {
  try {
    final response = await apiClient.get(
      '/$controller/getAll',
      queryParameters: {
        if (noId != null) 'no_id': noId,
        if (namaPaket != null) 'nama_paket': namaPaket,
        if (idVendor != null) 'id_vendor': idVendor,
        if (hargaMin != null) 'harga_min': hargaMin.toString(),
        if (hargaMax != null) 'harga_max': hargaMax.toString(),
        if (status != null) 'status': status,
        if (orderBy != null) 'orderBy': orderBy,
        if (orderDir != null) 'orderDir': orderDir,
        if (idList != null && idList.isNotEmpty)
          'idList': idList, // ✅ biarkan ini list, dio akan handle jadi idList=..&idList=..
      },
    );

    print('==============================');
  print('Response Body: ${response.body}');
  print('Status Code: ${response.statusCode}');
  print('==============================');


    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => PaketModel.fromJson(e)).toList();
    } 
    else if (response.statusCode == 204) {
        // Tidak ada data
        return [];
      }
    else {
      throw Exception('Gagal load $entity (${response.statusCode})');
    }
  } catch (e) {
    throw Exception('Error saat mengambil $entity: $e');
  }
}


  /// CREATE
  Future<void> create(PaketModel model) async {
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
  Future<void> update(PaketModel model) async {
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
