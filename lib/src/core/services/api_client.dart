import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/services/api_singleton.dart';

import '../../features/auth/services/auth_service.dart';

class ApiClient {
  final AuthService _authService;
  static const String baseUrl = '${Constants.baseUrl}/api';
  String? _role;

  ApiClient(this._authService);

  void setRole(String role) => _role = role;
  void clearRole() => _role = null;
  String? getRole() => _role;
  Future<String?> getIdToken() async {
    return await _authService.getIdToken();
  }

  Future<Map<String, String>> getHeaders() => _headers();

  /// GET request
  Future<http.Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final uri =
        Uri.parse('$baseUrl$path').replace(queryParameters: queryParameters);

    return _handleWithAuthRetry(() async {
      final headers = await _headers();

      print("📥 [GET] $uri");
      print("📄 Headers: $headers");

      return http.get(uri, headers: headers);
    });
  }

  /// POST request
  Future<http.Response> post(
    String path, {
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
    Object? body,
  }) async {
    final uri =
        Uri.parse('$baseUrl$path').replace(queryParameters: queryParameters);

    return _handleWithAuthRetry(() async {
      final mergedHeaders = await _mergedHeaders(headers);

      Object? finalBody = body;
      if (body is Map) {
        finalBody = jsonEncode(body);
        mergedHeaders.putIfAbsent(
          'Content-Type',
          () => 'application/json',
        );
      }

      print("📤 [POST] $uri");
      print("📄 Headers: $mergedHeaders");
      print("📦 Body: $finalBody");

      return http.post(uri, headers: mergedHeaders, body: finalBody);
    });
  }

  /// PUT request
  Future<http.Response> put(
    String path, {
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
    Object? body,
  }) async {
    final uri =
        Uri.parse('$baseUrl$path').replace(queryParameters: queryParameters);

    return _handleWithAuthRetry(() async {
      final mergedHeaders = await _mergedHeaders(headers);

      print("📤 [PUT] $uri");
      print("📄 Headers: $mergedHeaders");
      print("📦 Body: $body");

      return http.put(uri, headers: mergedHeaders, body: body);
    });
  }

  /// DELETE request
  Future<http.Response> delete(
    String path, {
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final uri =
        Uri.parse('$baseUrl$path').replace(queryParameters: queryParameters);

    return _handleWithAuthRetry(() async {
      final mergedHeaders = await _mergedHeaders(headers);

      print("❌ [DELETE] $uri");
      print("📄 Headers: $mergedHeaders");

      return http.delete(uri, headers: mergedHeaders);
    });
  }

  Future<http.Response> _handleWithAuthRetry(
    Future<http.Response> Function() request, {
    bool retry = true,
  }) async {
    final response = await request();

    print("📤 Status Code: ${response.statusCode}");
    print("📤 Body: ${response.body}");

    if (response.statusCode == 401 &&
        response.body.contains("Invalid Token") &&
        retry) {
      print("🔄 Token invalid, mencoba silent login...");

      final newToken = await _authService.login(silent: true);

      if (newToken == null) {
        print("❌ Silent login gagal");
        return response;
      }

      print("✅ Silent login berhasil, retry request");
      return _handleWithAuthRetry(request, retry: false);
    }

    return response;
  }

  /// Ambil header standar (opsional token & role)
  Future<Map<String, String>> _headers() async {
    final token = await _authService.getIdToken(); // selalu fresh

    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
      'X-Jenis-User': Constants.customer,
    };
  }

  /// Merge header tambahan dengan default
  Future<Map<String, String>> _mergedHeaders(Map<String, String>? extra) async {
    final headers = await _headers();
    return {
      ...headers,
      if (extra != null) ...extra,
    };
  }

  /// Optional: untuk konversi null jadi string kosong
  Map<String, dynamic> toJsonSafe(Map<String, dynamic> original) {
    return original.map((key, value) => MapEntry(key, value ?? ""));
  }
}
