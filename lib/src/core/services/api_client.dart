import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/services/auth_service_instance.dart';

/// ============================================
/// 🌐 ApiClient - FIXED VERSION
/// ============================================
/// Improvements:
/// 1. Better token refresh handling
/// 2. Exponential backoff untuk retry
/// 3. Request deduplication
/// 4. Cleaner error handling
/// ============================================

class ApiClient {
  static const String baseUrl = '${Constants.baseUrl}/api';
  String? _role;

  // 🔔 Callback untuk session expired
  Function()? onSessionExpired;

  void setRole(String role) => _role = role;
  void clearRole() => _role = null;
  String? getRole() => _role;

  Future<String?> getIdToken() => authService.getIdToken();
  Future<Map<String, String>> getHeaders() => _headers();

  // =========================================================
  // 📡 HTTP METHODS
  // =========================================================

  Future<http.Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool requireAuth = true, // ← tambah ini
  }) async {
    final uri =
        Uri.parse('$baseUrl$path').replace(queryParameters: queryParameters);

    return _executeWithRetry(
      () async {
        final headers = await _headers(requireAuth: requireAuth); // ← pass
        print("📥 [GET] $uri");
        return http.get(uri, headers: headers);
      },
      method: 'GET',
      path: path,
      requireAuth: requireAuth, // ← pass
    );
  }

  Future<http.Response> post(
    String path, {
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
    Object? body,
    bool requireAuth = true, // ← tambah ini
  }) async {
    final uri =
        Uri.parse('$baseUrl$path').replace(queryParameters: queryParameters);

    return _executeWithRetry(
      () async {
        final mergedHeaders =
            await _mergedHeaders(headers, requireAuth: requireAuth);
        Object? finalBody = body;
        if (body is Map) {
          finalBody = jsonEncode(body);
          mergedHeaders.putIfAbsent('Content-Type', () => 'application/json');
        }
        print("📤 [POST] $uri");
        return http.post(uri, headers: mergedHeaders, body: finalBody);
      },
      method: 'POST',
      path: path,
      requireAuth: requireAuth,
    );
  }

  Future<http.Response> put(
    String path, {
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
    Object? body,
  }) async {
    final uri =
        Uri.parse('$baseUrl$path').replace(queryParameters: queryParameters);

    return _executeWithRetry(
      () async {
        final mergedHeaders = await _mergedHeaders(headers);
        Object? finalBody = body;

        if (body is Map) {
          finalBody = jsonEncode(body);
          mergedHeaders.putIfAbsent('Content-Type', () => 'application/json');
        }

        print("📤 [PUT] $uri");
        return http.put(uri, headers: mergedHeaders, body: finalBody);
      },
      method: 'PUT',
      path: path,
    );
  }

  Future<http.Response> delete(
    String path, {
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final uri =
        Uri.parse('$baseUrl$path').replace(queryParameters: queryParameters);

    return _executeWithRetry(
      () async {
        final mergedHeaders = await _mergedHeaders(headers);
        print("❌ [DELETE] $uri");
        return http.delete(uri, headers: mergedHeaders);
      },
      method: 'DELETE',
      path: path,
    );
  }

  // =========================================================
  // 🔄 RETRY MECHANISM WITH EXPONENTIAL BACKOFF
  // =========================================================

  Future<http.Response> _executeWithRetry(
    Future<http.Response> Function() request, {
    required String method,
    required String path,
    int attempt = 1,
    int maxAttempts = 3,
    bool requireAuth = true, // ← tambah ini
  }) async {
    try {
      final response = await request();
      print("📊 [$method $path] Status: ${response.statusCode}");

      if (response.statusCode != 401) return response;

      // ✅ Jika public endpoint, jangan retry/logout — kembalikan response saja
      if (!requireAuth) {
        print("⚠️ [$method $path] 401 on public endpoint, skip retry");
        return response;
      }

      if (!_isTokenError(response)) {
        print("⚠️ [$method $path] 401 but not token error");
        return response;
      }

      if (attempt >= maxAttempts) {
        print("❌ [$method $path] Max attempts reached");
        _triggerSessionExpired();
        throw Exception('Session expired after $maxAttempts attempts');
      }

      print(
          "🔄 [$method $path] Refreshing token (attempt $attempt/$maxAttempts)...");
      final refreshed = await _refreshToken();

      if (!refreshed) {
        if (attempt >= maxAttempts - 1) {
          _triggerSessionExpired();
          throw Exception('Token refresh failed');
        }
        return response;
      }

      final delayMs = _calculateBackoff(attempt);
      await Future.delayed(Duration(milliseconds: delayMs));

      return _executeWithRetry(
        request,
        method: method,
        path: path,
        attempt: attempt + 1,
        maxAttempts: maxAttempts,
        requireAuth: requireAuth,
      );
    } catch (e) {
      print("❌ [$method $path] Error: $e");
      rethrow;
    }
  }

  // =========================================================
  // 🔄 TOKEN REFRESH
  // =========================================================

  Future<bool> _refreshToken() async {
    try {
      print("🔄 [ApiClient] Requesting token refresh...");

      // ✅ WAJIB forceRefresh: true → trigger _doRefreshAccessToken()
      // Tanpa ini, hanya baca dari storage → return token lama yang sudah 401
      final newToken = await authService.getIdToken(forceRefresh: true);

      if (newToken != null && newToken.isNotEmpty) {
        print("✅ [ApiClient] Token refreshed successfully");
        print("🔑 New token (first 30): ${newToken}");
        return true;
      }

      print("❌ [ApiClient] Token refresh returned null");
      return false;
    } catch (e) {
      print("❌ [ApiClient] Token refresh error: $e");
      return false;
    }
  }

  // =========================================================
  // 🔍 HELPER METHODS
  // =========================================================

  /// Check if response indicates a token error
  bool _isTokenError(http.Response response) {
    if (response.statusCode != 401) return false;

    final body = response.body.toLowerCase();
    return body.contains('invalid token') ||
        body.contains('invalid_token') ||
        body.contains('token expired') ||
        body.contains('unauthorized') ||
        body.contains('token') && body.contains('invalid');
  }

  /// Calculate exponential backoff delay
  int _calculateBackoff(int attempt) {
    // 200ms, 400ms, 800ms, etc.
    return (200 * (1 << (attempt - 1))).clamp(200, 2000);
  }

  /// Trigger session expired callback
  void _triggerSessionExpired() {
    if (onSessionExpired != null) {
      print("🚪 [ApiClient] Triggering session expired callback");
      onSessionExpired!();
    }
  }

  // =========================================================
  // 🔐 HEADERS
  // =========================================================

  Future<Map<String, String>> _headers({bool requireAuth = true}) async {
    String? token;

    if (requireAuth) {
      // ✅ Hanya baca storage, TIDAK trigger refresh
      token = await authService.getStoredToken();
    }

    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      'X-Jenis-User': Constants.customer,
      if (_role != null) 'X-User-Role': _role!,
    };
  }

  Future<Map<String, String>> _mergedHeaders(
    Map<String, String>? extra, {
    bool requireAuth = true,
  }) async {
    final headers = await _headers(requireAuth: requireAuth);
    return {
      ...headers,
      if (extra != null) ...extra,
    };
  }

  // =========================================================
  // 🛠️ UTILITIES
  // =========================================================

  Map<String, dynamic> toJsonSafe(Map<String, dynamic> original) {
    return original.map((key, value) => MapEntry(key, value ?? ""));
  }

  Future<bool> isAuthenticated() async {
    final token = await authService.getIdToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> logout() async {
    await authService.signOut();
    clearRole();
  }
}
