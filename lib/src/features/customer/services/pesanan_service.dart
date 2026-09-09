import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:mpjnew/src/core/services/api_client.dart';
import 'package:mpjnew/src/core/services/api_singleton.dart';
import 'package:mpjnew/src/data/hive_entity/pesanan_model.dart';
import 'package:mpjnew/src/data/models/create_pesanan_result.dart';

class PesananService {
  final String entity = 'order';
  final String controller = 'order';

  final ApiClient _client = apiClient;

  /// GET ALL
  Future<List<PesananModel>> getAll({
    String? noBukti,
    String? idVendor,
    String? idCustomer,
    String? status,
    String? statusBayar,
    String? statusProgresPesanan,
    String? idPayment,
    String? orderBy,
    String? orderDir,
    String? tglCreated1,
    String? tglCreated2,
  }) async {
    try {
      final response = await _client.get(
        '/$controller/getAll',
        queryParameters: {
          if (noBukti != null) 'no_bukti': noBukti,
          if (idCustomer != null) 'id_customer': idCustomer,
          if (idVendor != null) 'id_vendor': idVendor,
          if (status != null) 'status': status,
          if (statusBayar != null) 'status_bayar': statusBayar,
          // Dulu salah ditulis ke key 'status_bayar' juga (bentrok dengan
          // param di atas), jadi filter ini efektif tidak pernah jalan.
          if (statusProgresPesanan != null)
            'status_progress_pesanan': statusProgresPesanan,
          if (idPayment != null) 'id_payment_gateway': idPayment,
          if (orderBy != null) 'orderby': orderBy,
          if (orderDir != null) 'orderdir': orderDir,
          if (tglCreated1 != null) 'tgl_created_1': tglCreated1,
          if (tglCreated2 != null) 'tgl_created_2': tglCreated2,
        },
      );

      debugPrint('==============================');
      debugPrint('URL: ${response.request?.url}');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Body: ${response.body}');
      debugPrint('==============================');

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
    } catch (e, stackTrace) {
      throw Exception('Error saat mengambil $entity: $e');
    }
  }

  /// CREATE
  Future<CreatePesananResult> create(PesananModel model) async {
    final response = await apiClient.post(
      '/$controller/create',
      body: jsonEncode(model.toJsonCreate()),
      headers: {'Content-Type': 'application/json'},
    );

    debugPrint('==============================');
    debugPrint('URL: ${response.request?.url}');
    debugPrint('Status Code: ${response.statusCode}');
    debugPrint('Body: ${response.body}');
    debugPrint('==============================');

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

  /// CHANGE PAYMENT
  Future<void> changePayment(String noBukti, String paymentType) async {
    final response = await apiClient.post(
      '/$controller/change-payment',
      body: jsonEncode({'No_Bukti': noBukti, 'Payment_Type': paymentType}),
      headers: {'Content-Type': 'application/json'},
    );

    debugPrint('==============================');
    debugPrint('URL: ${response.request?.url}');
    debugPrint('Status Code: ${response.statusCode}');
    debugPrint('Body: ${response.body}');
    debugPrint('==============================');

    if (response.statusCode != 200) {
      String errorMsg =
          'Gagal mengganti metode pembayaran (${response.statusCode})';
      try {
        final decoded = jsonDecode(response.body);
        if (decoded['Message'] != null) errorMsg = decoded['Message'] as String;
      } catch (_) {}
      throw Exception(errorMsg);
    }

    final decoded = jsonDecode(response.body);
    final cancelResult = decoded['CancelResult'];
    if (cancelResult != null && cancelResult['Status'] != 200) {
      throw Exception(
          cancelResult['Message'] ?? 'Gagal membatalkan pembayaran lama');
    }
  }

  /// UPDATE
  Future<void> update(PesananModel model) async {
    final response = await apiClient.put(
      '/$controller/updateHeader',
      queryParameters: {'no_bukti': model.noBukti},
      body: jsonEncode(model.toJsonUpdate()),
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

  /// BATAL — POST /order/batal/:no_bukti
  Future<void> batal(String noBukti) async {
    final response = await _client.post(
      '/$controller/batal/$noBukti',
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Gagal membatalkan pesanan (${response.statusCode})');
    }
  }
}
