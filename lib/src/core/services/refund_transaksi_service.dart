import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:mpjnew/src/core/services/api_client.dart';
import 'package:mpjnew/src/core/services/api_singleton.dart';
import 'package:mpjnew/src/data/models/refund_transaksi_model.dart';

class RefundTransaksiService {
  final String entity = 'Transaksi Refund';
  final String controller = 'TransaksiRefund';
  final ApiClient _client = apiClient;

  /// Berbeda dengan service lain di app ini, [getAll] TIDAK melempar saat
  /// gagal — hasilnya hanya pelengkap halaman detail pesanan, jadi daftar
  /// kosong adalah jawaban aman yang tidak boleh menjatuhkan halaman.
  Future<List<RefundTransaksiModel>> getAll({required String idPesanan}) async {
    try {
      final response = await _client.get(
        '/$controller/getAll',
        queryParameters: {'id_pesanan': idPesanan},
      );

      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body)['Data'];
      if (data is! List) return [];

      return data
          .whereType<Map<String, dynamic>>()
          .map(RefundTransaksiModel.fromJson)
          // Backend bisa ikut mengembalikan baris pesanan lain.
          .where((t) => t.idPesanan == idPesanan)
          .toList();
    } catch (e) {
      debugPrint('[RefundTransaksiService] ⚠️ Gagal load $entity: $e');
      return [];
    }
  }
}
