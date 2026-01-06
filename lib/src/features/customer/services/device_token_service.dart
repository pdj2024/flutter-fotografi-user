import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:mpjnew/src/core/services/api_client.dart';
import 'package:mpjnew/src/core/services/api_singleton.dart';

class DeviceTokenService {
  final String controller = 'auth';
  final ApiClient _client = apiClient;

  // =========================
  // GET DEVICE TOKEN
  // =========================
  Future<String> _getDeviceToken() async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Gagal mendapatkan device token dari Firebase');
    }
    return token;
  }

  // =========================
  // REQUEST BODY
  // =========================
  Map<String, dynamic> _buildBody({
    required String userId,
    required String action,
    required String deviceToken,
  }) {
    return {
      "No_Id": userId,
      "Action": action, // add | remove
      "Device_Token": deviceToken,
    };
  }

  // =========================
  // ADD DEVICE TOKEN (LOGIN)
  // =========================
  Future<void> addDeviceToken(String userId) async {
    final deviceToken = await _getDeviceToken();

    final response = await _client.post(
      '/$controller/device-token',
      body: jsonEncode(
        _buildBody(
          userId: userId,
          action: 'add',
          deviceToken: deviceToken,
        ),
      ),
      headers: {'Content-Type': 'application/json'},
    );

    _logResponse(response);

    if (response.statusCode == 200) {
      // sukses normal
      return;
    }

    if (response.statusCode == 400) {
      final body = jsonDecode(response.body);

      if (body["Message"] == "Device token sudah ada.") {
        // ⬅️ anggap sukses
        return;
      }
    }

    throw Exception('Gagal menambahkan device token');
  }

  // =========================
  // REMOVE DEVICE TOKEN (LOGOUT)
  // =========================
  Future<void> removeDeviceToken(String userId) async {
    final deviceToken = await _getDeviceToken();

    final response = await _client.post(
      '/$controller/device-token',
      body: jsonEncode(
        _buildBody(
          userId: userId,
          action: 'remove',
          deviceToken: deviceToken,
        ),
      ),
      headers: {'Content-Type': 'application/json'},
    );

    _logResponse(response);

    if (response.statusCode != 200) {
      throw Exception('Gagal menghapus device token');
    }
  }

  // =========================
  // LOGGER
  // =========================
  void _logResponse(dynamic response) {
    print('==============================');
    print('URL: ${response.request?.url}');
    print('Status Code: ${response.statusCode}');
    print('Body: ${response.body}');
    print('==============================');
  }
}
