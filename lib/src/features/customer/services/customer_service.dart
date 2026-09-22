import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:mpjnew/src/core/services/api_client.dart';
import 'package:mpjnew/src/core/services/api_singleton.dart';
import 'package:mpjnew/src/data/models/customer_model.dart';

class CustomerService {
  final String entity = 'Customer';
  final String controller = 'customer';
  final ApiClient _client = apiClient;

  /// GET ALL
  Future<List<CustomerModel>> getAll({
    String? no_id,
    String? username,
    String? email,
    String? nama_display,
    String? kota,
    String? status,
    String? orderBy,
    String? orderDir,
  }) async {
    try {
      final response = await _client.get(
        '/$controller/getAll',
        queryParameters: {
          if (no_id != null) 'no_id': no_id,
          if (username != null) 'username': username,
          if (email != null) 'email': email,
          if (nama_display != null) 'nama_display': nama_display,
          if (kota != null) 'kota': kota,
          if (status != null) 'status': status,
          if (orderBy != null) 'orderby': orderBy,
          if (orderDir != null) 'orderdir': orderDir,
        },
      );

      debugPrint('📊 [CustomerService.getAll] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final dynamic data = body['Data'];

        if (data == null) return [];

        List<Map<String, dynamic>> list = [];

        if (data is List) {
          list = data.whereType<Map<String, dynamic>>().toList();
        } else if (data is Map<String, dynamic>) {
          list = [data];
        } else {
          throw Exception("Format Data tidak dikenali: ${data.runtimeType}");
        }

        return list.map((e) => CustomerModel.fromJson(e)).toList();
      } else if (response.statusCode == 204) {
        return [];
      } else {
        throw Exception('Gagal load $entity (${response.statusCode})');
      }
    } catch (e, st) {
      debugPrint("❌ [CustomerService.getAll] Error: $e");
      debugPrint(st.toString());
      throw Exception('Error saat mengambil $entity: $e');
    }
  }

  // Get username for checking availability
  Future<List<CustomerModel>> getByUsername({
    String? username,
  }) async {
    try {
      final response = await _client.get(
        '/$controller/get-byUsername',
        queryParameters: {
          if (username != null) 'username': username,
        },
      );

      debugPrint('📊 [CustomerService.getAll] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final dynamic data = body['Data'];

        if (data == null) return [];

        List<Map<String, dynamic>> list = [];

        if (data is List) {
          list = data.whereType<Map<String, dynamic>>().toList();
        } else if (data is Map<String, dynamic>) {
          list = [data];
        } else {
          throw Exception("Format Data tidak dikenali: ${data.runtimeType}");
        }

        return list.map((e) => CustomerModel.fromJson(e)).toList();
      } else if (response.statusCode == 204) {
        return [];
      } else {
        throw Exception('Gagal load $entity (${response.statusCode})');
      }
    } catch (e, st) {
      debugPrint("❌ [CustomerService.getAll] Error: $e");
      debugPrint(st.toString());
      throw Exception('Error saat mengambil $entity: $e');
    }
  }

  /// CREATE
  Future<void> create(CustomerModel model) async {
    final response = await _client.post(
      '/$controller/create',
      body: model.toJson(),
    );

    if (response.statusCode != 200) {
      throw Exception('Gagal menambahkan $entity');
    }
  }

  /// UPDATE
  Future<Map<String, dynamic>> update(CustomerModel model) async {
    final response = await _client.put(
      '/$controller/update',
      queryParameters: {'no_id': model.noId},
      body: jsonEncode(model.toJsonUpdate()),
    );

    debugPrint('📊 [CustomerService.update] Status: ${response.statusCode}');
    debugPrint('📦 Body: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Gagal mengupdate $entity');
    }

    return jsonDecode(response.body);
  }

  /// DELETE
  Future<void> delete(String noId) async {
    final response = await _client.delete(
      '/$controller/delete',
      queryParameters: {'no_id': noId},
    );

    if (response.statusCode != 200) {
      throw Exception('Gagal menghapus $entity');
    }
  }
}
