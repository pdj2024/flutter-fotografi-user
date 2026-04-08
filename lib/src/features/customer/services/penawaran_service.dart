import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:mpjnew/src/core/services/api_client.dart';
import 'package:mpjnew/src/core/services/api_singleton.dart';
import 'package:mpjnew/src/data/hive_entity/penawaran_model.dart';

class PenawaranService {
  final String entity = 'Penawaran';
  final String controller = 'Penawaran';

  final ApiClient _client = apiClient; // ← pakai nama beda

  /// GET ALL
  Future<List<PenawaranModel>> getAll({
    String? noId,
    String? idCustomer,
    String? idVendor,
    String? namaPaket,
    int? hargaMin,
    int? hargaMax,
    String? status,
    String? orderBy,
    String? orderDir,
    String? kota,
    List<String>? idList,
  }) async {
    try {
      final response = await _client.get(
        '/$controller/getAll',
        queryParameters: {
          if (noId != null) 'no_id': noId,
          if (idCustomer != null) 'id_customer': idCustomer,
          if (idVendor != null) 'id_vendor': idVendor,
          if (namaPaket != null) 'nama_paket': namaPaket,
          if (hargaMin != null) 'harga_min': hargaMin.toString(),
          if (hargaMax != null) 'harga_max': hargaMax.toString(),
          if (status != null) 'status': status,
          if (orderBy != null) 'orderby': orderBy,
          if (orderDir != null) 'orderdir': orderDir,
          if (kota != null) 'kota': kota,
          if (idList != null && idList.isNotEmpty)
            'idList': idList, // dio otomatis jadi idList=a&idList=b
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
              .map((item) => PenawaranModel.fromJson(item))
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
}
