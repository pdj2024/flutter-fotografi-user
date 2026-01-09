import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  // ✅ SINGLETON PATTERN
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
  );

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  GoogleSignInAccount? _currentUser;
  String? _cachedIdToken;
  
  // ✅ Gunakan storage untuk persist flag
  static const String _keyJustLoggedOut = 'just_logged_out';

  // Storage Keys
  static const String _keyIdToken = 'id_token';
  static const String _keyEmail = 'user_email';
  static const String _keyDisplayName = 'user_display_name';
  static const String _keyPhotoUrl = 'user_photo_url';
  static const String _keyUserId = 'user_id';
  static const String _keyTokenExpiry = 'token_expiry';

  // ✅ Getter untuk status login yang akurat
  bool get isLoggedIn => _currentUser != null && _cachedIdToken != null;
  String? get email => _currentUser?.email;
  String? get displayName => _currentUser?.displayName;
  String? get photoUrl => _currentUser?.photoUrl;
  String? get userId => _currentUser?.id;
  String? get cachedToken => _cachedIdToken;

  // =========================================================
  // 🔄 CHECK JUST LOGGED OUT (dari storage)
  // =========================================================
  Future<bool> _isJustLoggedOut() async {
    final value = await _storage.read(key: _keyJustLoggedOut);
    return value == 'true';
  }

  Future<void> _setJustLoggedOut(bool value) async {
    if (value) {
      await _storage.write(key: _keyJustLoggedOut, value: 'true');
    } else {
      await _storage.delete(key: _keyJustLoggedOut);
    }
  }

  // =========================================================
  // 🔄 RESTORE SESSION
  // =========================================================
  Future<bool> restoreSession() async {
    try {
      print("🔄 [AuthService] Mencoba restore session...");

      // Cek apakah baru logout
      if (await _isJustLoggedOut()) {
        print("⚠️ [AuthService] Baru logout, skip restore");
        return false;
      }

      final savedToken = await _storage.read(key: _keyIdToken);
      final savedEmail = await _storage.read(key: _keyEmail);

      if (savedToken == null || savedEmail == null) {
        print("⚠️ [AuthService] Tidak ada session tersimpan");
        _clearMemoryState();
        return false;
      }

      // Cek expiry
      final expiryStr = await _storage.read(key: _keyTokenExpiry);
      if (expiryStr != null) {
        final expiry = DateTime.parse(expiryStr);
        if (DateTime.now().isAfter(expiry)) {
          print("⚠️ [AuthService] Token expired");
          await _clearAllData();
          return false;
        }
      }

      // Silent sign in
      _currentUser = await _googleSignIn.signInSilently();

      if (_currentUser != null) {
        _cachedIdToken = savedToken;
        print("✅ [AuthService] Session restored: $savedEmail");
        return true;
      }

      print("⚠️ [AuthService] Silent sign in gagal");
      await _clearAllData();
      return false;
    } catch (e) {
      print("❌ [AuthService] Restore session error: $e");
      await _clearAllData();
      return false;
    }
  }

  // =========================================================
  // 💾 SIMPAN DATA USER
  // =========================================================
  Future<void> _saveUserData(String idToken) async {
    try {
      if (_currentUser == null) return;

      await _storage.write(key: _keyIdToken, value: idToken);
      await _storage.write(key: _keyEmail, value: _currentUser!.email);
      await _storage.write(
          key: _keyDisplayName, value: _currentUser!.displayName ?? '');
      await _storage.write(
          key: _keyPhotoUrl, value: _currentUser!.photoUrl ?? '');
      await _storage.write(key: _keyUserId, value: _currentUser!.id);

      final expiry = DateTime.now().add(const Duration(minutes: 55));
      await _storage.write(
          key: _keyTokenExpiry, value: expiry.toIso8601String());

      // Clear flag just logged out
      await _setJustLoggedOut(false);

      print("💾 [AuthService] User data tersimpan");
    } catch (e) {
      print("❌ [AuthService] Gagal simpan user data: $e");
    }
  }

  // =========================================================
  // 🗑️ CLEAR DATA
  // =========================================================
  void _clearMemoryState() {
    _currentUser = null;
    _cachedIdToken = null;
  }

  Future<void> _clearAllData() async {
    try {
      _clearMemoryState();
      
      await _storage.delete(key: _keyIdToken);
      await _storage.delete(key: _keyEmail);
      await _storage.delete(key: _keyDisplayName);
      await _storage.delete(key: _keyPhotoUrl);
      await _storage.delete(key: _keyUserId);
      await _storage.delete(key: _keyTokenExpiry);
      
      print("🗑️ [AuthService] Semua data terhapus");
    } catch (e) {
      print("❌ [AuthService] Gagal hapus data: $e");
    }
  }

  // =========================================================
  // 🔐 LOGIN
  // =========================================================
  Future<String?> login({bool silent = false}) async {
    try {
      print("🔑 [AuthService] Login ${silent ? 'SILENT' : 'INTERACTIVE'}");

      _cachedIdToken = null;

      // Cek flag just logged out untuk silent login
      if (silent && await _isJustLoggedOut()) {
        print("⚠️ [AuthService] Skip silent login setelah logout");
        return null;
      }

      if (silent) {
        _currentUser = await _googleSignIn.signInSilently();
      } else {
        // Clear flag sebelum interactive login
        await _setJustLoggedOut(false);
        _currentUser = await _googleSignIn.signIn();
      }

      if (_currentUser == null) {
        print("⚠️ [AuthService] Login dibatalkan / gagal");
        return null;
      }

      // Get token dengan error handling
      String? idToken;
      try {
        final auth = await _currentUser!.authentication;
        idToken = auth.idToken;
      } catch (authError) {
        print("⚠️ [AuthService] Auth error: $authError");

        if (authError.toString().contains('NEED_REMOTE_CONSENT') ||
            authError.toString().contains('SIGN_IN_REQUIRED')) {
          print("🔄 [AuthService] Mencoba ulang setelah clear cache...");

          await _googleSignIn.signOut();
          _currentUser = await _googleSignIn.signIn();

          if (_currentUser != null) {
            final retryAuth = await _currentUser!.authentication;
            idToken = retryAuth.idToken;
          }
        } else {
          rethrow;
        }
      }

      if (idToken == null) {
        print("❌ [AuthService] ID Token null");
        await _clearAllData();
        return null;
      }

      _cachedIdToken = idToken;
      await _saveUserData(_cachedIdToken!);

      print("✅ [AuthService] Login sukses: ${_currentUser!.email}");
      _debugJwt(_cachedIdToken!);

      return _cachedIdToken;
    } catch (e) {
      print("❌ [AuthService] Login error: $e");
      await _clearAllData();
      return null;
    }
  }

  // =========================================================
  // 🔄 GET ID TOKEN
  // =========================================================
  Future<String?> getIdToken({bool forceRefresh = false}) async {
    try {
      // Cek flag just logged out
      if (await _isJustLoggedOut()) {
        print("⚠️ [AuthService] Baru logout, perlu login manual");
        return null;
      }

      // Cek cached token
      if (!forceRefresh && _cachedIdToken != null) {
        final expiryStr = await _storage.read(key: _keyTokenExpiry);
        if (expiryStr != null) {
          final expiry = DateTime.parse(expiryStr);
          final bufferTime = DateTime.now().add(const Duration(minutes: 5));
          if (bufferTime.isBefore(expiry)) {
            print("✅ [AuthService] Menggunakan cached token");
            return _cachedIdToken;
          }
        }
      }

      // Refresh token
      _currentUser ??= await _googleSignIn.signInSilently();

      if (_currentUser == null) {
        print("⚠️ [AuthService] Tidak ada user, perlu login");
        await _clearAllData();
        return null;
      }

      try {
        final auth = await _currentUser!.authentication;
        _cachedIdToken = auth.idToken;

        if (_cachedIdToken != null) {
          await _saveUserData(_cachedIdToken!);
        }

        return _cachedIdToken;
      } catch (authError) {
        print("⚠️ [AuthService] getIdToken auth error: $authError");
        _clearMemoryState();
        return null;
      }
    } catch (e) {
      print("❌ [AuthService] getIdToken error: $e");
      return null;
    }
  }

  // =========================================================
  // 🚪 LOGOUT
  // =========================================================
  Future<void> logout() async {
    try {
      print("🚪 [AuthService] Memulai logout...");

      // Set flag SEBELUM clear data
      await _setJustLoggedOut(true);

      try {
        await _googleSignIn.signOut();
        print("✅ [AuthService] Google signOut berhasil");
      } catch (e) {
        print("⚠️ [AuthService] SignOut error (diabaikan): $e");
      }

      await _clearAllData();
      
      // Set flag lagi setelah clear (untuk memastikan)
      await _setJustLoggedOut(true);

      print("✅ [AuthService] Logout berhasil");
    } catch (e) {
      print("❌ [AuthService] Logout error: $e");
      _clearMemoryState();
      await _setJustLoggedOut(true);
    }
  }

  // =========================================================
  // 🔄 LOGOUT DAN REVOKE (untuk ganti akun)
  // =========================================================
  Future<void> logoutAndRevoke() async {
    try {
      print("🚪 [AuthService] Logout dengan revoke...");

      await _setJustLoggedOut(true);

      try {
        await _googleSignIn.disconnect();
        print("✅ [AuthService] Google disconnect berhasil");
      } catch (e) {
        print("⚠️ [AuthService] Disconnect error: $e");
        await _googleSignIn.signOut();
      }

      await _clearAllData();
      await _setJustLoggedOut(true);

      print("✅ [AuthService] Logout dan revoke berhasil");
    } catch (e) {
      print("❌ [AuthService] logoutAndRevoke error: $e");
      _clearMemoryState();
      await _setJustLoggedOut(true);
    }
  }

  // =========================================================
  // 🔄 LOGIN DENGAN AKUN BERBEDA
  // =========================================================
  Future<String?> loginWithDifferentAccount() async {
    try {
      print("🔄 [AuthService] Login dengan akun berbeda...");

      await logoutAndRevoke();
      await Future.delayed(const Duration(milliseconds: 500));
      await _setJustLoggedOut(false);

      return await login(silent: false);
    } catch (e) {
      print("❌ [AuthService] loginWithDifferentAccount error: $e");
      return null;
    }
  }

  // =========================================================
  // 🧪 DEBUG JWT
  // =========================================================
  void _debugJwt(String token) {
    try {
      final parts = token.split('.');
      final payloadBase64 = base64Url.normalize(parts[1]);
      final payloadString = utf8.decode(base64Url.decode(payloadBase64));
      print("📦 [AuthService] JWT PAYLOAD: $payloadString");
    } catch (e) {
      print("❌ [AuthService] Decode JWT gagal: $e");
    }
  }
}