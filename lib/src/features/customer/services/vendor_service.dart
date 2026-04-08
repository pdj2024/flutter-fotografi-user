import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:mpjnew/src/data/models/vendor_model.dart';
import '../../../core/services/api_client.dart';
import 'package:mpjnew/src/core/services/api_singleton.dart';

class VendorService {
  final String entity = 'Vendor';
  final String controller = 'vendor';
  final ApiClient _client = apiClient; // ← pakai nama beda

  /// GET ALL dengan parameter opsional
  Future<List<VendorModel>> getAll({
    String? no_id,
    String? namaDisplay,
    String? username,
    String? id_media,
    String? status,
    String? orderBy,
    String? orderDir,
  }) async {
    try {
      final response = await apiClient.get(
        '/$controller/getAll',
        queryParameters: {
          if (no_id != null) 'no_id': no_id,
          if (namaDisplay != null) 'Nama_Display': namaDisplay,
          if (username != null) 'username': username,
          if (id_media != null) 'id_media': id_media,
          if (status != null) 'status': status,
          if (orderBy != null) 'orderby': orderBy,
          if (orderDir != null) 'orderdir': orderDir,
        },
      );

      debugPrint('==============================');
      debugPrint('Response Body: ${response.body}');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('==============================');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        final List<dynamic> data = json['Data'];

        return data.map((e) => VendorModel.fromJson(e)).toList();
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

  Future<List<VendorModel>> searchVendor({
    String? no_id,
    String? filter,
    String? namaDisplay,
    String? username,
    String? id_media,
    String? status,
    String? orderBy,
    String? orderDir,
  }) async {
    try {
      final response = await apiClient.get(
        '/$controller/getAll/search',
        queryParameters: {
          if (no_id != null) 'no_id': no_id,
          if (filter != null) 'filter': filter,
          if (id_media != null) 'id_media': id_media,
          if (status != null) 'status': status,
          if (orderBy != null) 'orderby': orderBy,
          if (orderDir != null) 'orderdir': orderDir,
        },
      );

      debugPrint('==============================');
      debugPrint('Response Body: ${response.body}');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('==============================');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        final List<dynamic> data = json['Data'];

        return data.map((e) => VendorModel.fromJson(e)).toList();
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
  Future<void> create(VendorModel model) async {
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
  Future<void> update(VendorModel model) async {
    final response = await apiClient.put(
      '/$controller/update',
      queryParameters: {
        'no_id': model.noId
      }, // Asumsinya noId adalah string di VendorModel
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
