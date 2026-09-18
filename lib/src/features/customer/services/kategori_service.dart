import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../core/services/api_client.dart';
import '../../../data/models/kategori_model.dart';
import 'package:mpjnew/src/core/services/api_singleton.dart';

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
    String? canSearch,
  }) async {
    try {
      final response = await apiClient.get(
        '/$controller/getAll',
        // Kategori dibaca guest juga (dipanggil dari splash untuk SEMUA
        // user termasuk yang belum login). Tanpa ini, guest tanpa token
        // dapat 401 → dianggap sesi kedaluwarsa → force-logout ke halaman
        // login walau tidak pernah login sama sekali.
        requireAuth: false,
        queryParameters: {
          if (noId != null) 'no_id': noId,
          if (namaKategori != null) 'nama_kategori': namaKategori,
          if (idMedia != null) 'id_media': idMedia,
          if (status != null) 'status': status,
          if (orderBy != null) 'orderby': orderBy,
          if (orderDir != null) 'orderdir': orderDir,
          if (canSearch != null) 'can_search': canSearch,
        },
      );
      debugPrint('[KategoriService] getAll → ${response.statusCode} '
          '(${response.body.length} bytes)');

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        final List<dynamic> data = json['Data'];
        return data.map((e) => KategoriModel.fromJson(e)).toList();
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
