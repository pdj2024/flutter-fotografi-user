import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mpjnew/src/core/constants/constants.dart';

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
    final headers = await _headers();

    print("📥 [GET] $uri");
    print("📄 Headers: $headers");

    return await http.get(uri, headers: headers);
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
    final mergedHeaders = await _mergedHeaders(headers);

    Object? finalBody = body;
    if (body is Map) {
      finalBody = jsonEncode(body);
      mergedHeaders.putIfAbsent('Content-Type', () => 'application/json');
    }

    print("📤 [POST] $uri");
    print("📄 Headers: $mergedHeaders");
    print("📦 Body: $finalBody");

    return await http.post(uri, headers: mergedHeaders, body: finalBody);
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
    final mergedHeaders = await _mergedHeaders(headers);

    print("📤 [PUT] $uri");
    print("📄 Headers: $mergedHeaders");
    print("📦 Body: $body");

    return await http.put(uri, headers: mergedHeaders, body: body);
  }

  /// DELETE request
  Future<http.Response> delete(
    String path, {
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final uri =
        Uri.parse('$baseUrl$path').replace(queryParameters: queryParameters);
    final mergedHeaders = await _mergedHeaders(headers);

    print("❌ [DELETE] $uri");
    print("📄 Headers: $mergedHeaders");

    return await http.delete(uri, headers: mergedHeaders);
  }

  /// Ambil header standar (opsional token & role)
  Future<Map<String, String>> _headers() async {
    final token = await _authService.getIdToken(); // nullable token

    // debugPrint('======= MY TOKEN: $token', wrapWidth: 1024);

    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
      if (_role != null) 'X-Jenis-User': _role!,
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
