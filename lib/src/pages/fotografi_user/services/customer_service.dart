import 'dart:convert';

import 'package:mpjnew/src/pages/fotografi_user/models/customer_model.dart';
import 'package:mpjnew/src/pages/core/api_client.dart';
import 'package:mpjnew/src/pages/core/api_singleton.dart';

class CustomerService {
  final String entity = 'Customer';
  final String controller = 'customer';
  final ApiClient _client = apiClient;

 

  /// Check login via Google
  Future<CustomerModel?> checkGoogleLogin() async {
    try {
      final response = await _client.post('/auth/cek-login-google');

      print("==== SERVICE RESPONSE: " + response.body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return CustomerModel.fromJson(data);
      } else if (response.statusCode == 401) {
        return null; // Token invalid / belum login
      } else {
        throw Exception('Gagal cek login Google (${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Error saat cek login Google: $e');
    }
  }

  /// GET ALL
  Future<List<CustomerModel>> getAll({
    String? no_id,
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
          if (nama_display != null) 'nama_display': nama_display,
          if (kota != null) 'kota': kota,
          if (status != null) 'status': status,
          if (orderBy != null) 'orderby': orderBy,
          if (orderDir != null) 'orderdir': orderDir,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => CustomerModel.fromJson(e)).toList();
      } else {
        throw Exception('Gagal load $entity (${response.statusCode})');
      }
    } catch (e) {
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
  Future<void> update(CustomerModel model) async {
    final response = await _client.put(
      '/$controller/update',
      queryParameters: {'no_id': model.no_id},
      body: _client.toJsonSafe(model.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception('Gagal mengupdate $entity');
    }
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
