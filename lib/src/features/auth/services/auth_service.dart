// lib/src/core/services/auth_service.dart

import 'dart:async';
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/services/token_storage_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  Map<String, dynamic>? _lastLoginData;
  Function()? onSessionExpired;

  static const String _baseUrl = '${Constants.baseUrl}/api';

  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  // Hive — hanya untuk flag login state
  static const String _boxName = 'auth_box';
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyUserEmail = 'user_email';
  Box? _authBox;

  GoogleSignInAccount? _currentUser;

  /// Getter untuk data login terakhir (No_Id, Status, dll)
  Map<String, dynamic>? get lastLoginData => _lastLoginData;

  /// Clear setelah dipakai
  void clearLastLoginData() => _lastLoginData = null;

  // Session state
  bool _hasValidTokenSession = false;

  // Refresh lock
  bool _isRefreshing = false;
  final List<Completer<String?>> _refreshQueue = [];

  // ═══════════════════════════════════════════════════════
  // 🔧 INIT
  // ═══════════════════════════════════════════════════════

  Future<void> initialize() async {
    try {
      debugPrint("🔧 [AuthService] Initializing...");
      if (Hive.isBoxOpen(_boxName)) await Hive.box(_boxName).close();
      _authBox = await Hive.openBox(_boxName);
      debugPrint("✅ [AuthService] Initialized");
    } catch (e) {
      debugPrint("❌ [AuthService] Init failed: $e");
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════
  // 🔄 RESTORE SESSION
  // ═══════════════════════════════════════════════════════

  Future<bool> restoreSession() async {
    try {
      debugPrint("🔄 [AuthService] Restoring session...");

      final wasLoggedIn =
          _authBox?.get(_keyIsLoggedIn, defaultValue: false) ?? false;
      if (!wasLoggedIn) {
        debugPrint("⚠️  No previous login found");
        return false;
      }

      final accessToken = await tokenStorage.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        debugPrint("❌ No access token in storage");
        await _clearLoginState();
        return false;
      }

      _currentUser = await _googleSignIn.signInSilently();

      if (_currentUser == null) {
        debugPrint("⚠️  Silent sign-in failed, validating refresh token...");
        final tokenValid = await _validateAndRefreshToken();
        if (!tokenValid) {
          debugPrint("❌ Refresh token invalid, clearing session");
          await _clearLoginState();
          await tokenStorage.clearAll();
          return false;
        }
        debugPrint("✅ Refresh token valid, session restorable from token");
        _hasValidTokenSession = true;
      }

      debugPrint("✅ Session restored");
      return true;
    } catch (e) {
      debugPrint("❌ Restore session error: $e");
      await _clearLoginState();
      return false;
    }
  }

  /// Validasi refresh token dengan hit endpoint /auth/refresh.
  /// Dipakai saat signInSilently() gagal — tidak memanggil onSessionExpired.
  Future<bool> _validateAndRefreshToken() async {
    try {
      final refreshToken = await tokenStorage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        debugPrint("❌ [AuthService] No refresh token in storage");
        return false;
      }

      final uri = Uri.parse('$_baseUrl/auth/refresh');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'X-Jenis-User': Constants.customer,
        },
        body: jsonEncode({'refreshToken': refreshToken}),
      );

      debugPrint("📊 [ValidateRefresh] Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newAccessToken = data['token'] as String?;
        final newRefreshToken = data['refreshToken'] as String?;

        if (newAccessToken == null) return false;

        await tokenStorage.saveAccessToken(newAccessToken);
        if (newRefreshToken != null) {
          await tokenStorage.saveRefreshToken(newRefreshToken);
        }
        debugPrint("✅ [AuthService] Token refreshed during restore");
        return true;
      }

      return false;
    } catch (e) {
      debugPrint("❌ [AuthService] _validateAndRefreshToken error: $e");
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════
  // 🔑 SIGN IN
  // ═══════════════════════════════════════════════════════

  Future<String?> signIn() async {
    try {
      debugPrint("🔑 [AuthService] Starting sign-in...");

      _currentUser = await _googleSignIn.signIn();
      if (_currentUser == null) {
        debugPrint("⚠️  Sign-in cancelled");
        return null;
      }

      final googleAuth = await _currentUser!.authentication;
      final googleIdToken = googleAuth.idToken;
      if (googleIdToken == null) {
        debugPrint("❌ Google ID token null");
        return null;
      }

      final deviceToken = await _getDeviceToken();

      final result = await _checkLoginBackend(
        googleIdToken: googleIdToken,
        deviceToken: deviceToken ?? '',
      );

      if (result == null) return null;

      final accessToken        = result['token']        as String;
      final refreshToken       = result['refreshToken'] as String;
      final backendDeviceToken = result['deviceToken']  as String?;
      final idSession          = result['id_session']   as String?;
      // No_Id tidak disimpan di storage — tersedia via CustomerModel / UserProvider

      // ── Simpan sekaligus ke secure storage ────────────────────────────
      await tokenStorage.saveLoginData(
        accessToken:  accessToken,
        refreshToken: refreshToken,
        deviceToken:  backendDeviceToken?.isNotEmpty == true
            ? backendDeviceToken
            : deviceToken,
        idSession: idSession,
      );

      debugPrint("💾 [AuthService] Login data saved | id_session: $idSession");

      // ── Simpan seluruh data response untuk diakses UserProvider ───────
      _lastLoginData = result;

      await _saveLoginState();

      debugPrint("✅ Sign-in complete");
      return accessToken;
    } catch (e) {
      debugPrint("❌ Sign-in error: $e");
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════
  // 🎫 GET ACCESS TOKEN
  // ═══════════════════════════════════════════════════════

  Future<String?> getIdToken({bool forceRefresh = false}) async {
    if (_isRefreshing) return await _waitForRefresh();

    if (!forceRefresh) {
      final stored = await tokenStorage.getAccessToken();
      if (stored != null && stored.isNotEmpty) return stored;
    }

    return await _doRefreshAccessToken();
  }

  Future<bool> hasValidToken() async {
    final token = await tokenStorage.getAccessToken();
    return token != null && token.isNotEmpty;
  }

  Future<String?> getStoredToken() async => await tokenStorage.getAccessToken();

  // ═══════════════════════════════════════════════════════
  // 🔄 REFRESH ACCESS TOKEN
  // ═══════════════════════════════════════════════════════

  Future<String?> _doRefreshAccessToken() async {
    if (_isRefreshing) return await _waitForRefresh();

    _isRefreshing = true;

    try {
      debugPrint("🔄 [AuthService] Refreshing access token...");

      final refreshToken = await tokenStorage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        debugPrint("❌ No refresh token, force logout...");
        _notifyRefreshQueue(null);
        await _forceLogout();
        return null;
      }

      final uri = Uri.parse('$_baseUrl/auth/refresh');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'X-Jenis-User': Constants.customer,
        },
        body: jsonEncode({'refreshToken': refreshToken}),
      );

      debugPrint("📊 [Refresh] Status: ${response.statusCode}");
      debugPrint("📊 [Refresh] Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newAccessToken  = data['token']        as String?;
        final newRefreshToken = data['refreshToken'] as String?;

        if (newAccessToken == null) {
          debugPrint("❌ token null dari response refresh");
          _notifyRefreshQueue(null);
          await _forceLogout();
          return null;
        }

        await tokenStorage.saveAccessToken(newAccessToken);
        if (newRefreshToken != null) {
          await tokenStorage.saveRefreshToken(newRefreshToken);
        }

        debugPrint("✅ Access token refreshed");
        _notifyRefreshQueue(newAccessToken);
        return newAccessToken;
      } else {
        debugPrint("❌ Refresh failed: ${response.statusCode}, force logout...");
        _notifyRefreshQueue(null);
        await _forceLogout();
        return null;
      }
    } catch (e) {
      debugPrint("❌ Refresh error: $e");
      _notifyRefreshQueue(null);
      await _forceLogout();
      return null;
    } finally {
      _isRefreshing = false;
    }
  }

  /// Force logout — hapus semua token + disconnect Google
  Future<void> _forceLogout() async {
    try {
      debugPrint("🚪 [AuthService] Force logout...");
      // Coba hapus session di backend sebelum clear lokal
      await _deleteUserSession();
      await tokenStorage.clearAll();
      // Guest/sudah signed-out → disconnect() melempar PlatformException;
      // jangan sampai membatalkan pembersihan state di bawahnya.
      try {
        await _googleSignIn.disconnect();
      } catch (e) {
        debugPrint("⚠️ [AuthService] Google disconnect dilewati: $e");
      }
      await _clearLoginState();
      _currentUser = null;
      _hasValidTokenSession = false;
      debugPrint("✅ [AuthService] Force logout complete");
      onSessionExpired?.call();
    } catch (e) {
      debugPrint("❌ [AuthService] Force logout error: $e");
      _hasValidTokenSession = false;
      onSessionExpired?.call();
    }
  }

  // ═══════════════════════════════════════════════════════
  // 🌐 BACKEND CALL — CHECK LOGIN
  // ═══════════════════════════════════════════════════════

  Future<Map<String, dynamic>?> _checkLoginBackend({
    required String googleIdToken,
    required String deviceToken,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/auth/cek-login-google');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $googleIdToken',
          'X-Jenis-User': Constants.customer,
          'Device-Token': deviceToken,
        },
      );

      debugPrint("📊 [checkLoginBackend] Status: ${response.statusCode}");
      debugPrint("📦 Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        if (data['token'] == null || data['refreshToken'] == null) {
          debugPrint("❌ Response tidak mengandung token / refreshToken");
          return null;
        }

        return data;
      }

      return null;
    } catch (e) {
      debugPrint("❌ _checkLoginBackend error: $e");
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════
  // 🗑️ BACKEND CALL — DELETE USER SESSION (LOGOUT)
  // ═══════════════════════════════════════════════════════

  /// Hapus session di backend menggunakan id_session yang disimpan saat login.
  /// Endpoint: DELETE /api/usersession/delete?no_id={id_session}
  /// Non-fatal: jika gagal, proses logout lokal tetap berjalan.
  Future<void> _deleteUserSession() async {
    try {
      // ✅ no_id di query param diisi dengan nilai id_session (bukan No_Id)
      final idSession = await tokenStorage.getIdSession();
      if (idSession == null || idSession.isEmpty) {
        debugPrint("⚠️  [AuthService] No id_session found, skip delete session");
        return;
      }

      debugPrint("🗑️  [AuthService] Deleting session for id_session: $idSession");

      final uri = Uri.parse('$_baseUrl/usersession/delete').replace(
        queryParameters: {'no_id': idSession}, // ✅ id_session → no_id param
      );

      final accessToken = await tokenStorage.getAccessToken();
      final response = await http.delete(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'X-Jenis-User': Constants.customer,
          if (accessToken != null) 'Authorization': 'Bearer $accessToken',
        },
      );

      debugPrint("📊 [deleteSession] Status: ${response.statusCode}");
      debugPrint("📊 [deleteSession] Body: ${response.body}");

      if (response.statusCode == 200) {
        debugPrint("✅ [AuthService] Session deleted from backend");
      } else {
        debugPrint("⚠️  [AuthService] Delete session returned ${response.statusCode} (non-fatal)");
      }
    } catch (e) {
      // Non-fatal — tetap lanjut logout lokal
      debugPrint("⚠️  [AuthService] _deleteUserSession error (non-fatal): $e");
    }
  }

  // ═══════════════════════════════════════════════════════
  // 📱 DEVICE TOKEN (FCM)
  // ═══════════════════════════════════════════════════════

  Future<String?> _getDeviceToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      debugPrint("📱 [AuthService] FCM token: $token");
      return token;
    } catch (e) {
      debugPrint("⚠️  FCM token error: $e");
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════
  // 🚪 SIGN OUT
  // ═══════════════════════════════════════════════════════

  Future<void> signOut() async {
    try {
      debugPrint("🚪 [AuthService] Signing out...");

      // ── 1. Hapus session di backend ────────────────────────────────────
      await _deleteUserSession();

      // ── 2. Hapus token dari storage ────────────────────────────────────
      await tokenStorage.clearAll();

      // ── 3. Sign out Google ─────────────────────────────────────────────
      await _googleSignIn.signOut();
      await _clearLoginState();
      _currentUser = null;
      _hasValidTokenSession = false;

      debugPrint("✅ Sign-out complete");
    } catch (e) {
      debugPrint("❌ Sign-out error: $e");
      await tokenStorage.clearAll();
      await _clearLoginState();
      _currentUser = null;
      _hasValidTokenSession = false;
    }
  }

  Future<void> disconnect() async {
    try {
      await _deleteUserSession();
      await tokenStorage.clearAll();
      await _googleSignIn.disconnect();
      await _clearLoginState();
      _currentUser = null;
      _hasValidTokenSession = false;
    } catch (e) {
      await signOut();
    }
  }

  Future<void> logoutAndRevoke() async => await disconnect();
  Future<void> logout() async => await signOut();

  // ═══════════════════════════════════════════════════════
  // 📊 STATE
  // ═══════════════════════════════════════════════════════

  bool get isLoggedIn => _currentUser != null || _hasValidTokenSession;
  GoogleSignInAccount? get currentUser => _currentUser;
  String? get email => _currentUser?.email;
  String? get storedEmail => _authBox?.get(_keyUserEmail) as String?;
  String? get displayName => _currentUser?.displayName;
  String? get photoUrl => _currentUser?.photoUrl;
  String? get userId => _currentUser?.id;

  // ═══════════════════════════════════════════════════════
  // 💾 STORAGE HELPERS
  // ═══════════════════════════════════════════════════════

  Future<void> _saveLoginState() async {
    if (_authBox == null || _currentUser == null) return;
    await _authBox!.put(_keyIsLoggedIn, true);
    await _authBox!.put(_keyUserEmail, _currentUser!.email);
    await _authBox!.flush();
  }

  Future<void> _clearLoginState() async {
    if (_authBox == null) return;
    await _authBox!.clear();
    await _authBox!.flush();
  }

  // ═══════════════════════════════════════════════════════
  // 🔄 REFRESH QUEUE
  // ═══════════════════════════════════════════════════════

  Future<String?> _waitForRefresh() async {
    final completer = Completer<String?>();
    _refreshQueue.add(completer);
    return completer.future;
  }

  void _notifyRefreshQueue(String? token) {
    for (final c in _refreshQueue) {
      if (!c.isCompleted) c.complete(token);
    }
    _refreshQueue.clear();
  }

  // ── Legacy compat ──
  Future<String?> login({bool silent = false}) async {
    if (silent) {
      final restored = await restoreSession();
      return restored ? await getIdToken() : null;
    }
    return await signIn();
  }

  Future<GoogleSignInAccount?> getCurrentUserAsync() async {
    if (_currentUser != null) return _currentUser;
    _currentUser = await _googleSignIn.signInSilently();
    return _currentUser;
  }
}