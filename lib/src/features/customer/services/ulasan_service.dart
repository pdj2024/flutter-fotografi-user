import 'dart:convert';

import 'package:mpjnew/src/core/services/api_client.dart';
import 'package:mpjnew/src/core/services/api_singleton.dart';
import 'package:mpjnew/src/data/models/ulasan_model.dart';


class UlasanService {
  final String entity = 'Ulasan';
  final String controller = 'ulasan';

  final ApiClient _client = apiClient;

  Future<List<UlasanModel>> getAll({
  // ===== IDENTITAS =====
  String? noUlasan,
  String? noOrder,
  String? idVendor,
  String? idCustomer,
  String? idPaket,

  // ===== RATING & ISI =====
  int? minRating,
  int? maxRating,
  String? isiUlasan,
  bool? adaBalasan,

  // ===== TANGGAL ULASAN =====
  DateTime? tglUlasanFrom,
  DateTime? tglUlasanTo,

  // ===== TANGGAL BALASAN =====
  DateTime? tglBalasanFrom,
  DateTime? tglBalasanTo,

  // ===== STATUS =====
  String? status,

  // ===== SORT & PAGINATION =====
  String? orderBy,
  String? orderDir,
  int? limit,
  int? offset,
}) async {
  try {
    final response = await _client.get(
      '/$controller/getAll',
      queryParameters: {
        if (noUlasan != null) 'no_id': noUlasan,
        if (noOrder != null) 'no_order': noOrder,
        if (idVendor != null) 'id_vendor': idVendor,
        if (idCustomer != null) 'id_customer': idCustomer,
        if (idPaket != null) 'id_paket': idPaket,

        if (minRating != null) 'min_rating': minRating,
        if (maxRating != null) 'max_rating': maxRating,
        if (isiUlasan != null) 'isi_ulasan': isiUlasan,
        if (adaBalasan != null) 'ada_balasan': adaBalasan ? 1 : 0,

        if (tglUlasanFrom != null)
          'tgl_ulasan_from': tglUlasanFrom.toIso8601String(),
        if (tglUlasanTo != null)
          'tgl_ulasan_to': tglUlasanTo.toIso8601String(),

        if (tglBalasanFrom != null)
          'tgl_balasan_from': tglBalasanFrom.toIso8601String(),
        if (tglBalasanTo != null)
          'tgl_balasan_to': tglBalasanTo.toIso8601String(),

        if (status != null) 'status': status,

        if (orderBy != null) 'orderby': orderBy,
        if (orderDir != null) 'orderdir': orderDir,
        if (limit != null) 'limit': limit,
        if (offset != null) 'offset': offset,
      },
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final data = decoded['Data'];

      if (data is List) {
        return data.map((e) => UlasanModel.fromJson(e)).toList();
      }
      return [];
    }

    if (response.statusCode == 204) {
      return [];
    }

    throw Exception('Gagal load ulasan (${response.statusCode})');
  } catch (e, stackTrace) {
    print(e);
    print(stackTrace);
    rethrow;
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
      body: jsonEncode(model.toJsonUpdate()), // Gunakan toJsonUpdate
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
      body: jsonEncode(model.copyWith(status: "hapus").toJsonUpdate()),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('Gagal menghapus $entity');
    }
  }
}
