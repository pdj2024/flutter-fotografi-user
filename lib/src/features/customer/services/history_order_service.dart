import 'dart:convert';

import 'package:mpjnew/src/core/services/api_client.dart';
import 'package:mpjnew/src/core/services/api_singleton.dart';
import 'package:mpjnew/src/data/models/history_order_model.dart';

class HistoryOrderService {
  final String entity = 'Orderprogress';
  final String controller = 'orderprogress';

  final ApiClient _client = apiClient;

  Future<List<HistoryOrderModel>> getAll({
    String? noid,
    String? senderId,
    String? deskripsi,
    String? noOrder,
    String? status,
    String? orderBy,
    String? orderDir,
  }) async {
    try {
      final response = await _client.get(
        '/$controller/getAll',
        queryParameters: {
          if (noid != null) 'no_id': noid,
          if (senderId != null) 'sender_id': senderId,
          if (status != null) 'status': status,
          if (noOrder != null) 'no_order': noOrder,
          if (deskripsi != null) 'deskripsi': deskripsi,
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
          final penawaranList = (data as List? ?? [])
              .map((item) => HistoryOrderModel.fromJson(item))
              .toList();

          return penawaranList;
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

  Future<void> create(HistoryOrderModel model) async {
    final response = await apiClient.post(
      '/$controller/create',
      body: jsonEncode(model.toJson()),
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
  Future<void> update(HistoryOrderModel model) async {
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
