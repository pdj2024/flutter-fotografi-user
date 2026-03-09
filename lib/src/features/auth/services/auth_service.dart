// lib/src/core/services/auth_service.dart

import 'dart:async';
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
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

  /// ✅ Getter untuk data login terakhir (No_Id, Status, dll)
  Map<String, dynamic>? get lastLoginData => _lastLoginData;

  /// ✅ Clear setelah dipakai
  void clearLastLoginData() => _lastLoginData = null;

  // Refresh lock
  bool _isRefreshing = false;
  final List<Completer<String?>> _refreshQueue = [];

  // ═══════════════════════════════════════════════════════
  // 🔧 INIT
  // ═══════════════════════════════════════════════════════

  Future<void> initialize() async {
    try {
      print("🔧 [AuthService] Initializing...");
      if (Hive.isBoxOpen(_boxName)) await Hive.box(_boxName).close();
      _authBox = await Hive.openBox(_boxName);
      print("✅ [AuthService] Initialized");
    } catch (e) {
      print("❌ [AuthService] Init failed: $e");
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════
  // 🔄 RESTORE SESSION
  // ═══════════════════════════════════════════════════════

  Future<bool> restoreSession() async {
    try {
      print("🔄 [AuthService] Restoring session...");

      final wasLoggedIn =
          _authBox?.get(_keyIsLoggedIn, defaultValue: false) ?? false;
      if (!wasLoggedIn) {
        print("⚠️  No previous login found");
        return false;
      }

      // Cek access token di storage
      final accessToken = await tokenStorage.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        print("❌ No access token in storage");
        await _clearLoginState();
        return false;
      }

      // Restore Google user silently (untuk UI/display name dll)
      _currentUser = await _googleSignIn.signInSilently();

      print("✅ Session restored");
      return true;
    } catch (e) {
      print("❌ Restore session error: $e");
      await _clearLoginState();
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════
  // 🔑 SIGN IN
  // ═══════════════════════════════════════════════════════

  /// Login Google → ambil ID token Google → kirim ke backend → simpan access+refresh token
  Future<String?> signIn() async {
    try {
      print("🔑 [AuthService] Starting sign-in...");

      _currentUser = await _googleSignIn.signIn();
      if (_currentUser == null) {
        print("⚠️  Sign-in cancelled");
        return null;
      }

      final googleAuth = await _currentUser!.authentication;
      final googleIdToken = googleAuth.idToken;
      if (googleIdToken == null) {
        print("❌ Google ID token null");
        return null;
      }

      final deviceToken = await _getDeviceToken();

      final result = await _checkLoginBackend(
        googleIdToken: googleIdToken,
        deviceToken: deviceToken ?? '',
      );

      if (result == null) return null;

      final accessToken = result['token'] as String;
      final refreshToken = result['refreshToken'] as String;
      final backendDeviceToken = result['deviceToken'] as String?;

      await tokenStorage.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );

      if (backendDeviceToken != null && backendDeviceToken.isNotEmpty) {
        await tokenStorage.saveDeviceToken(backendDeviceToken);
      } else if (deviceToken != null) {
        await tokenStorage.saveDeviceToken(deviceToken);
      }

      // ✅ Simpan seluruh data response untuk diakses UserProvider
      _lastLoginData = result;

      await _saveLoginState();

      print("✅ Sign-in complete");
      return accessToken;
    } catch (e) {
      print("❌ Sign-in error: $e");
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════
  // 🎫 GET ACCESS TOKEN (untuk Authorization Bearer)
  // ═══════════════════════════════════════════════════════

  /// Return access_token dari storage.
  /// Jika null/expired → coba refresh otomatis.
  Future<String?> getIdToken({bool forceRefresh = false}) async {
    // Jika sedang refresh, tunggu
    if (_isRefreshing) {
      return await _waitForRefresh();
    }

    if (!forceRefresh) {
      final stored = await tokenStorage.getAccessToken();
      if (stored != null && stored.isNotEmpty) {
        return stored;
      }
    }

    // Access token kosong atau forceRefresh → refresh
    return await _doRefreshAccessToken();
  }

  Future<bool> hasValidToken() async {
    final token = await tokenStorage.getAccessToken();
    return token != null && token.isNotEmpty;
  }

  /// Ambil token dari storage tanpa refresh
  Future<String?> getStoredToken() async {
    return await tokenStorage.getAccessToken();
  }
  // ═══════════════════════════════════════════════════════
  // 🔄 REFRESH ACCESS TOKEN
  // ═══════════════════════════════════════════════════════

  Future<String?> _doRefreshAccessToken() async {
    if (_isRefreshing) return await _waitForRefresh();

    _isRefreshing = true;

    try {
      print("🔄 [AuthService] Refreshing access token...");

      final refreshToken = await tokenStorage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        print("❌ No refresh token, force logout...");
        _notifyRefreshQueue(null);
        await _forceLogout();
        return null;
      }

      print("📊 [Refresh] refreshToken: $refreshToken");

      final uri = Uri.parse('$_baseUrl/auth/refresh');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'X-Jenis-User': Constants.customer,
        },
        body: jsonEncode({'refreshToken': refreshToken}),
      );

      print("📊 [Refresh] Status: ${response.statusCode}");
      print("📊 [Refresh] Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newAccessToken = data['token'] as String?;
        final newRefreshToken = data['refreshToken'] as String?;

        if (newAccessToken == null) {
          print("❌ token null dari response refresh");
          _notifyRefreshQueue(null);
          await _forceLogout();
          return null;
        }

        await tokenStorage.saveAccessToken(newAccessToken);
        if (newRefreshToken != null) {
          await tokenStorage.saveRefreshToken(newRefreshToken);
        }

        print("✅ Access token refreshed");
        _notifyRefreshQueue(newAccessToken);
        return newAccessToken;
      } else {
        print("❌ Refresh failed: ${response.statusCode}, force logout...");
        _notifyRefreshQueue(null);
        await _forceLogout();
        return null;
      }
    } catch (e) {
      print("❌ Refresh error: $e");
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
      print("🚪 [AuthService] Force logout...");
      await tokenStorage.clearAll();
      await _googleSignIn.disconnect();
      await _clearLoginState();
      _currentUser = null;
      print("✅ [AuthService] Force logout complete");
      onSessionExpired?.call();
    } catch (e) {
      print("❌ [AuthService] Force logout error: $e");
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

      print("📊 [checkLoginBackend] Status: ${response.statusCode}");
      print("📦 Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        // Validasi field yang dibutuhkan
        if (data['token'] == null || data['refreshToken'] == null) {
          print("❌ Response tidak mengandung token / refreshToken");
          return null;
        }

        return data;
      }

      return null;
    } catch (e) {
      print("❌ _checkLoginBackend error: $e");
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════
  // 📱 DEVICE TOKEN (FCM)
  // ═══════════════════════════════════════════════════════

  Future<String?> _getDeviceToken() async {
    try {
      final fcm = FirebaseMessaging.instance;
      final token = await fcm.getToken();
      print("📱 [AuthService] FCM token: ${token}");
      return token;
    } catch (e) {
      print("⚠️  FCM token error: $e");
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════
  // 🚪 SIGN OUT
  // ═══════════════════════════════════════════════════════

  Future<void> signOut() async {
    try {
      print("🚪 [AuthService] Signing out...");

      // Hapus token dari storage (sesuai requirement)
      await tokenStorage.clearAuthTokens();

      // Sign out Google juga (biar picker muncul lagi saat login berikutnya)
      await _googleSignIn.signOut();
      await _clearLoginState();
      _currentUser = null;

      print("✅ Sign-out complete");
    } catch (e) {
      print("❌ Sign-out error: $e");
      await tokenStorage.clearAuthTokens();
      await _clearLoginState();
      _currentUser = null;
    }
  }

  Future<void> disconnect() async {
    try {
      await tokenStorage.clearAll();
      await _googleSignIn.disconnect();
      await _clearLoginState();
      _currentUser = null;
    } catch (e) {
      await signOut();
    }
  }

  Future<void> logoutAndRevoke() async => await disconnect();
  Future<void> logout() async => await signOut();

  // ═══════════════════════════════════════════════════════
  // 📊 STATE
  // ═══════════════════════════════════════════════════════

  bool get isLoggedIn => _currentUser != null;
  GoogleSignInAccount? get currentUser => _currentUser;
  String? get email => _currentUser?.email;
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
