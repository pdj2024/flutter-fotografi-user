import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:mpjnew/src/core/services/api_client.dart';
import 'package:mpjnew/src/core/services/api_singleton.dart';

class DeviceTokenService {
  final String controller = 'auth';
  final ApiClient _client = apiClient;

  // =========================
  // GET DEVICE TOKEN
  // =========================
  Future<String> _getDeviceToken() async {
    try {
      debugPrint('[DeviceTokenService] 📱 Getting FCM token...');

      final token = await FirebaseMessaging.instance.getToken();

      if (token == null || token.isEmpty) {
        debugPrint('[DeviceTokenService] ❌ Token is null or empty');
        throw Exception('Gagal mendapatkan device token dari Firebase');
      }

      debugPrint(
          '[DeviceTokenService] ✅ Token obtained (length: ${token.length})');
      debugPrint(
          '[DeviceTokenService] Token preview: ${token.substring(0, 20)}...');

      return token;
    } catch (e) {
      debugPrint('[DeviceTokenService] ❌ Error getting token: $e');
      rethrow;
    }
  }

  // =========================
  // REQUEST BODY
  // =========================
  Map<String, dynamic> _buildBody({
    required String userId,
    required String action,
    required String deviceToken,
  }) {
    final body = {
      "No_Id": userId,
      "Action": action, // add | remove
      "Device_Token": deviceToken,
    };

    debugPrint('[DeviceTokenService] 📦 Request body:');
    debugPrint('  - User ID: $userId');
    debugPrint('  - Action: $action');
    debugPrint('  - Token: ${deviceToken.substring(0, 20)}...');

    return body;
  }

  // =========================
  // ADD DEVICE TOKEN (LOGIN)
  // =========================
  Future<void> addDeviceToken(String userId, String? token) async {
    try {
      debugPrint(
          '[DeviceTokenService] ➕ Adding device token for user: $userId');

      final deviceToken = token ?? await _getDeviceToken();

      if (deviceToken.contains(":APA")) {
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

        _logResponse(response, 'ADD');

        if (response.statusCode == 200) {
          debugPrint('[DeviceTokenService] ✅ Token added successfully');
          return;
        }

        if (response.statusCode == 400) {
          final body = jsonDecode(response.body);

          if (body["Message"] == "Device token sudah ada.") {
            debugPrint(
                '[DeviceTokenService] ℹ️ Token already exists (treating as success)');
            return;
          }
        }
      }

      debugPrint('[DeviceTokenService] ❌ Failed to add token');
      throw Exception('Gagal menambahkan device token');
    } catch (e) {
      debugPrint('[DeviceTokenService] ❌ Add token error: $e');
      rethrow;
    }
  }

  // =========================
  // REMOVE DEVICE TOKEN (LOGOUT)
  // =========================
  Future<void> removeDeviceToken(String userId, String? token) async {
    try {
      debugPrint(
          '[DeviceTokenService] ➖ Removing device token for user: $userId');

      final deviceToken = token ?? await _getDeviceToken();

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

      _logResponse(response, 'REMOVE');

      if (response.statusCode == 200) {
        debugPrint('[DeviceTokenService] ✅ Token removed successfully');
        return;
      }

      debugPrint('[DeviceTokenService] ❌ Failed to remove token');
      throw Exception('Gagal menghapus device token');
    } catch (e) {
      debugPrint('[DeviceTokenService] ❌ Remove token error: $e');
      rethrow;
    }
  }

  // =========================
  // LOGGER
  // =========================
  void _logResponse(dynamic response, String operation) {
    debugPrint('==============================');
    debugPrint('[$operation] Device Token API Response');
    debugPrint('URL: ${response.request?.url}');
    debugPrint('Status Code: ${response.statusCode}');
    debugPrint('Body: ${response.body}');
    debugPrint('==============================');
  }
}
