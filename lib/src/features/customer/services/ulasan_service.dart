import 'dart:convert';

import 'package:mpjnew/src/core/services/api_client.dart';
import 'package:mpjnew/src/core/services/api_singleton.dart';
import 'package:mpjnew/src/data/models/ulasan_model.dart';

class UlasanService {
  final String entity = 'Ulasan';
  final String controller = 'ulasan';

  final ApiClient _client = apiClient;

Future<List<UlasanModel>> getAll({
    String? noOrder,
    String? minRating,
    String? maxRating,
    String? tglUlasan,
    String? isiUlasan,
    String? status,
    String? orderBy,
    String? orderDir,
  }) async {
    try {
      final response = await _client.get(
        '/$controller/getAll',
        queryParameters: {
          if (noOrder != null) 'no_order': noOrder,
          if (minRating != null) 'min_rating': minRating,
          if (maxRating != null) 'max_rating': maxRating,
          if (isiUlasan != null) 'isi_ulasan': isiUlasan,
          if (tglUlasan != null) 'tgl_ulasan_1': tglUlasan,
          if (status != null) 'status': status,
          if (orderBy != null) 'orderby': orderBy,
          if (orderDir != null) 'orderdir': orderDir,
        },
      );

      print('==============================');
      print('URL: ${response.request?.url}');
      print('Status Code: ${response.statusCode}');
      print('Body: ${response.body}');
      print('==============================');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final data = decoded['Data'];

        if (data is List) {
          final ulasanList = (data as List? ?? [])
              .map((item) => UlasanModel.fromJson(item))
              .toList();

          return ulasanList;
        } else {
          return [];
        }
      } else if (response.statusCode == 204) {
        return [];
      } else {
        throw Exception('Gagal load $entity (${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Error saat mengambil $entity: $e');
    }
  }

  Future<void> create(UlasanModel model) async {
    final response = await apiClient.post(
      '/$controller/create',
      body: jsonEncode(model.toJsonCreate()),
      headers: {'Content-Type': 'application/json'},
    );

    print('==============================');
    print('URL: ${response.request?.url}');
    print('Status Code: ${response.statusCode}');
    print('Body: ${response.body}');
    print('==============================');

    if (response.statusCode != 200) {
      throw Exception('Gagal membuat pesanan');
    }
  }

  /// UPDATE
  Future<void> update(UlasanModel model) async {
    final response = await apiClient.put(
      '/$controller/update',
      queryParameters: {'no_id': model.noId},
      body: jsonEncode(model.toJson()),
      headers: {'Content-Type': 'application/json'},
    );

    print('==============================');
    print('URL: ${response.request?.url}');
    print('Status Code: ${response.statusCode}');
    print('Body: ${response.body}');
    print('==============================');

    if (response.statusCode != 200) {
      throw Exception('Gagal mengupdate $entity');
    }
  }

  /// DELETE
  Future<void> delete(UlasanModel model) async {
    final response = await apiClient.put(
      '/$controller/update',
      queryParameters: {'no_id': model.noId},
      body: jsonEncode(model.toJson()),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('Gagal menghapus $entity');
    }
  }
}