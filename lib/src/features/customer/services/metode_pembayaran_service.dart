import 'dart:convert';

import 'package:mpjnew/src/core/services/api_client.dart';
import 'package:mpjnew/src/core/services/api_singleton.dart';
import 'package:mpjnew/src/data/models/metode_pembayaran_model.dart';

class MetodePembayaranService {
  final String entity = 'Payment';
  final String controller = 'payment';

  final ApiClient _client = apiClient; // ← pakai nama beda

  /// GET ALL
  Future<List<MetodePembayaranModel>> getAll({
    String? caraBayar,
    String? display,
    String? paymentSnap,
    String? deskripsi,
    int? minFee,
    int? maxFee,
    int? provider,
    String? status,
    String? orderBy,
    String? orderDir,
  }) async {
    try {
      final response = await _client.get(
        '/$controller/option',
        queryParameters: {
          if (caraBayar != null) 'cara_bayar': caraBayar,
          if (paymentSnap != null) 'payment_snap': paymentSnap,
          if (display != null) 'display': display,
          if (deskripsi != null) 'deskripsi': deskripsi,
          if (minFee != null) 'min_fee': minFee.toString(),
          if (maxFee != null) 'max_fee': maxFee.toString(),
          if (provider != null) 'provider': provider,
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
          final metodeList = (data as List? ?? [])
              .map((item) => MetodePembayaranModel.fromJson(item))
              .toList();

          return metodeList;
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
}
