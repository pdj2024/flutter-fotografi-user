import 'dart:convert';

import 'package:mpjnew/src/core/constants/login_status.dart';
import 'package:mpjnew/src/core/services/google_login_result.dart';
import 'package:mpjnew/src/data/models/customer_model.dart';
import 'package:mpjnew/src/core/services/api_client.dart';
import 'package:mpjnew/src/core/services/api_singleton.dart';

class CustomerService {
  final String entity = 'Customer';
  final String controller = 'customer';
  final ApiClient _client = apiClient;

  /// Check login via Google
  Future<GoogleLoginResult> checkGoogleLogin() async {
    try {
      print("==== SERVICE: checkGoogleLogin() dipanggil");

      final response = await _client.post('/auth/cek-login-google');

      print("==== SERVICE RESPONSE (${response.statusCode}): ${response.body}");

      // ------------------------
      // HANDLE RESPONSE 200
      // ------------------------
      if (response.statusCode == 200) {
        Map<String, dynamic> data;

        try {
          data = jsonDecode(response.body);
        } catch (jsonError) {
          print("❌ JSON parsing error: $jsonError");
          return GoogleLoginResult(GoogleLoginStatus.error);
        }

        print("isi dari data =====> $data");

        final status = data['Status'];
        final noId = data['No_Id'];

        print("isi dari status =====> $status");
        print("isi dari noId =====> $noId");

        // Ambil data customer
        try {
          final user = await getAll(no_id: noId);

          switch (status) {
            case 'aktif':
              return GoogleLoginResult(
                GoogleLoginStatus.aktif,
                customer: user.first,
              );

            case 'created':
              return GoogleLoginResult(GoogleLoginStatus.created);

            case 'tokenInvalid':
              return GoogleLoginResult(GoogleLoginStatus.tokenInvalid);

            case 'nonaktif':
              return GoogleLoginResult(GoogleLoginStatus.nonaktif);
          }
        } catch (e) {
          print("❌ Error saat mengambil user via getAll(): $e");
          return GoogleLoginResult(GoogleLoginStatus.error);
        }

        return GoogleLoginResult(GoogleLoginStatus.error);
      }

      // ------------------------
      // HANDLE RESPONSE 401
      // ------------------------
      if (response.statusCode == 401) {
        print("⚠️ Token invalid (401)");
        return GoogleLoginResult(GoogleLoginStatus.tokenInvalid);
      }

      // ------------------------
      // HANDLE EMAIL BELUM TERDAFTAR
      // ------------------------
      if (response.statusCode == 400 &&
          response.body.contains("Email belum terdaftar")) {
        print("⚠️ Email belum terdaftar");
        return GoogleLoginResult(GoogleLoginStatus.error);
      }

      // ------------------------
      // HANDLE RESPON DI LUAR EKSPETASI
      // ------------------------
      print("⚠️ Respon tidak dikenal (${response.statusCode})");
      return GoogleLoginResult(GoogleLoginStatus.error);
    }

    // ------------------------
    // CATCH ERROR UTAMA
    // ------------------------
    catch (e, stack) {
      print("❌ ERROR checkGoogleLogin(): $e");
      print("❌ STACKTRACE: $stack");
      return GoogleLoginResult(GoogleLoginStatus.error);
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

      if (response.statusCode != 200) {
        throw Exception('Gagal load $entity (${response.statusCode})');
      }

      final body = jsonDecode(response.body);
      dynamic data = body['Data'];

      // Log untuk debugging
      print("DEBUG getAll() Data type = ${data.runtimeType}");

      if (data == null) return [];

      List<Map<String, dynamic>> list = [];

      if (data is List) {
        // Data berupa list
        list = data.whereType<Map<String, dynamic>>().toList();
      } else if (data is Map<String, dynamic>) {
        // Data berupa single object
        list = [data];
      } else {
        throw Exception("Format Data tidak dikenali: ${data.runtimeType}");
      }

      return list.map((e) => CustomerModel.fromJson(e)).toList();
    } catch (e, st) {
      print("❌ Error saat mengambil $entity: $e");
      print(st);
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

    print('==============================');
    print('Response Body: ${response.body}');
    print('Status Code: ${response.statusCode}');
    print('==============================');

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
