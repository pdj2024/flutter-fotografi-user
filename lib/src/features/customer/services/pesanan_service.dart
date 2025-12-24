import 'dart:convert';

import 'package:mpjnew/src/core/services/api_client.dart';
import 'package:mpjnew/src/core/services/api_singleton.dart';
import 'package:mpjnew/src/data/models/create_pesanan_result.dart';
import 'package:mpjnew/src/data/models/pesanan_model.dart';

class PesananService {
  final String entity = 'Order';
  final String controller = 'order';

  final ApiClient _client = apiClient;

  Future<List<PesananModel>> getAll({
    String? noBukti,
    String? idCustomer,
    String? status,
    String? statusBayar,
    String? statusProgresPesanan,
    String? idPayment,
    String? orderBy,
    String? orderDir,
  }) async {
    try {
      final response = await _client.get(
        '/$controller/getAll',
        queryParameters: {
          if (noBukti != null) 'no_bukti': noBukti,
          if (idCustomer != null) 'id_customer': idCustomer,
          if (status != null) 'status': status,
          if (statusBayar != null) 'status_bayar': statusBayar,
          if (statusProgresPesanan != null)
            'status_bayar': statusProgresPesanan,
          if (idPayment != null) 'id_payment_gateway': idPayment,
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
              .map((item) => PesananModel.fromJson(item))
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

  Future<CreatePesananResult> create(PesananModel model) async {
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

    final decoded = jsonDecode(response.body);

    final buatPesanan = decoded['BuatPesanan'];

    if (buatPesanan == null || buatPesanan['StatusCode'] != 200) {
      throw Exception(buatPesanan?['Message'] ?? 'Create pesanan gagal');
    }

    return CreatePesananResult.fromJson(decoded);
  }

  /// UPDATE
  Future<void> update(PesananModel model) async {
    final response = await apiClient.put(
      '/$controller/updateHeader',
      queryParameters: {'no_bukti': model.noBukti},
      body: jsonEncode(model.toJsonUpdate()),
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
