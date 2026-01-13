import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/features/auth/services/auth_service.dart';

class ApiClient {
  final AuthService _authService = AuthService();
  static const String baseUrl = '${Constants.baseUrl}/api';
  String? _role;

  // 🔒 Lock untuk mencegah multiple refresh bersamaan
  bool _isRefreshing = false;

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

      Object? finalBody = body;
      if (body is Map) {
        finalBody = jsonEncode(body);
        mergedHeaders.putIfAbsent(
          'Content-Type',
          () => 'application/json',
        );
      }

      print("📤 [PUT] $uri");
      print("📄 Headers: $mergedHeaders");
      print("📦 Body: $finalBody");

      return http.put(uri, headers: mergedHeaders, body: finalBody);
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

  /// 🔄 Handle request dengan auto retry jika token invalid
  Future<http.Response> _handleWithAuthRetry(
    Future<http.Response> Function() request, {
    int retryCount = 0,
    int maxRetries = 5,
  }) async {
    try {
      final response = await request();

      print("📊 Status Code: ${response.statusCode}");
      print("📊 Body: ${response.body}");

      // ✅ Request berhasil
      if (response.statusCode != 401) {
        return response;
      }

      // ❌ Token invalid dan sudah mencoba retry
      if (retryCount >= maxRetries) {
        print("❌ Max retry tercapai, kembalikan response 401");
        return response;
      }

      // 🔍 Cek apakah error karena token invalid
      final isTokenError = response.body.contains("Invalid Token") ||
          response.body.contains("invalid_token") ||
          response.body.contains("Token expired") ||
          response.body.contains("Unauthorized");

      if (!isTokenError) {
        print("⚠️ 401 tapi bukan token error");
        return response;
      }

      // 🔄 Refresh token
      print("🔄 Token invalid, mencoba refresh token...");

      final refreshed = await _refreshToken();

      if (!refreshed) {
        print("❌ Refresh token gagal, user perlu login ulang");
        // Optional: trigger logout atau navigasi ke login
        // await _authService.logout();
        return response;
      }

      print("✅ Token berhasil di-refresh, retry request...");

      // Retry request dengan token baru
      return _handleWithAuthRetry(
        request,
        retryCount: retryCount + 1,
        maxRetries: maxRetries,
      );
    } catch (e) {
      print("❌ Error dalam request: $e");
      rethrow;
    }
  }

  /// 🔄 Refresh token menggunakan silent login
  Future<bool> _refreshToken() async {
    // 🔒 Cegah multiple refresh bersamaan
    if (_isRefreshing) {
      print("⏳ Sedang refresh token, tunggu...");
      // Tunggu sampai refresh selesai (max 5 detik)
      int waitCount = 0;
      while (_isRefreshing && waitCount < 50) {
        await Future.delayed(const Duration(milliseconds: 100));
        waitCount++;
      }
      return !_isRefreshing; // Return true jika refresh sudah selesai
    }

    _isRefreshing = true;

    try {
      print("🔄 Mulai refresh token...");

      // Coba silent login untuk mendapat token baru
      final newToken = await _authService.login(silent: true);

      if (newToken == null || newToken.isEmpty) {
        print("❌ Silent login gagal, tidak dapat token baru");
        return false;
      }

      print("✅ Token baru berhasil didapat");
      return true;
    } catch (e) {
      print("❌ Error saat refresh token: $e");
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  /// Ambil header standar (opsional token & role)
  Future<Map<String, String>> _headers() async {
    // 🔄 Selalu cek token fresh (dengan cache jika belum expired)
    final token = await _authService.getIdToken(forceRefresh: false);

    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
      'X-Jenis-User': Constants.customer,
      if (_role != null) 'X-User-Role': _role!,
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

  /// 🧪 Helper untuk test apakah user masih terautentikasi
  Future<bool> isAuthenticated() async {
    final token = await _authService.getIdToken(forceRefresh: false);
    return token != null && token.isNotEmpty;
  }

  /// 🚪 Logout dan clear semua data
  Future<void> logout() async {
    await _authService.logout();
    clearRole();
  }
}
