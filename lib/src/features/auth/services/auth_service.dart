import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
  );
  
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  GoogleSignInAccount? _currentUser;
  String? _cachedIdToken;

  // Storage Keys
  static const String _keyIdToken = 'id_token';
  static const String _keyEmail = 'user_email';
  static const String _keyDisplayName = 'user_display_name';
  static const String _keyPhotoUrl = 'user_photo_url';
  static const String _keyUserId = 'user_id';
  static const String _keyTokenExpiry = 'token_expiry';

  /// 🔹 Status login
  bool get isLoggedIn => _currentUser != null;

  String? get email => _currentUser?.email;
  String? get displayName => _currentUser?.displayName;
  String? get photoUrl => _currentUser?.photoUrl;
  String? get userId => _currentUser?.id;

  // =========================================================
  // 🔄 RESTORE SESSION DARI STORAGE
  // =========================================================
  Future<bool>  restoreSession() async {
    try {
      print("🔄 Mencoba restore session...");
      
      final savedToken = await _storage.read(key: _keyIdToken);
      final savedEmail = await _storage.read(key: _keyEmail);
      
      if (savedToken == null || savedEmail == null) {
        print("⚠️ Tidak ada session tersimpan");
        return false;
      }

      // Cek apakah token expired
      final expiryStr = await _storage.read(key: _keyTokenExpiry);
      if (expiryStr != null) {
        final expiry = DateTime.parse(expiryStr);
        if (DateTime.now().isAfter(expiry)) {
          print("⚠️ Token expired, perlu login ulang");
          return await login(silent: true) != null;
        }
      }

      // Coba silent sign in
      _currentUser = await _googleSignIn.signInSilently(
        reAuthenticate: false,
      );

      if (_currentUser != null) {
        _cachedIdToken = savedToken;
        print("✅ Session restored: $savedEmail");
        return true;
      }

      print("⚠️ Silent sign in gagal");
      return false;
    } catch (e) {
      print("❌ Restore session error: $e");
      return false;
    }
  }

  // =========================================================
  // 💾 SIMPAN DATA USER KE STORAGE
  // =========================================================
  Future<void> _saveUserData(String idToken) async {
    try {
      if (_currentUser == null) return;

      // Simpan token dan data user
      await _storage.write(key: _keyIdToken, value: idToken);
      await _storage.write(key: _keyEmail, value: _currentUser!.email);
      await _storage.write(key: _keyDisplayName, value: _currentUser!.displayName ?? '');
      await _storage.write(key: _keyPhotoUrl, value: _currentUser!.photoUrl ?? '');
      await _storage.write(key: _keyUserId, value: _currentUser!.id);

      // Simpan waktu expired (JWT biasanya 1 jam)
      final expiry = DateTime.now().add(const Duration(minutes: 55));
      await _storage.write(key: _keyTokenExpiry, value: expiry.toIso8601String());

      print("💾 User data tersimpan");
    } catch (e) {
      print("❌ Gagal simpan user data: $e");
    }
  }

  // =========================================================
  // 🗑️ HAPUS DATA USER DARI STORAGE
  // =========================================================
  Future<void> _clearUserData() async {
    try {
      await _storage.delete(key: _keyIdToken);
      await _storage.delete(key: _keyEmail);
      await _storage.delete(key: _keyDisplayName);
      await _storage.delete(key: _keyPhotoUrl);
      await _storage.delete(key: _keyUserId);
      await _storage.delete(key: _keyTokenExpiry);

      print("🗑️ User data terhapus");
    } catch (e) {
      print("❌ Gagal hapus user data: $e");
    }
  }

  // =========================================================
  // 🔐 LOGIN → SELALU TOKEN BARU
  // =========================================================
  Future<String?> login({bool silent = false}) async {
    try {
      print("🔑 Login ${silent ? 'SILENT' : 'INTERACTIVE'}");

      // ❗ PAKSA BUANG TOKEN LAMA
      _cachedIdToken = null;

      // ambil account
      _currentUser = silent
          ? await _googleSignIn.signInSilently(reAuthenticate: true)
          : await _googleSignIn.signIn();

      if (_currentUser == null) {
        print("⚠️ Login dibatalkan / gagal");
        await _clearUserData(); // Hapus data jika login gagal
        return null;
      }

      // ❗ PAKSA REFRESH TOKEN
      final auth = await _currentUser!.authentication;

      if (auth.idToken == null) {
        print("❌ ID Token null");
        await _clearUserData();
        return null;
      }

      _cachedIdToken = auth.idToken;

      // 💾 SIMPAN DATA USER
      await _saveUserData(_cachedIdToken!);

      print("✅ Login sukses: ${_currentUser!.email}");
      _debugJwt(_cachedIdToken!);

      return _cachedIdToken;
    } catch (e) {
      print("❌ Login error: $e");
      await _clearUserData();
      return null;
    }
  }

  // =========================================================
  // 🔄 AMBIL TOKEN → SELALU FRESH
  // =========================================================
  Future<String?> getIdToken({bool forceRefresh = true}) async {
    try {
      // Cek apakah token di storage masih valid
      if (!forceRefresh && _cachedIdToken != null) {
        final expiryStr = await _storage.read(key: _keyTokenExpiry);
        if (expiryStr != null) {
          final expiry = DateTime.parse(expiryStr);
          if (DateTime.now().isBefore(expiry)) {
            print("✅ Menggunakan cached token");
            return _cachedIdToken;
          }
        }
      }

      if (_currentUser == null) {
        _currentUser = await _googleSignIn.signInSilently(
          reAuthenticate: true,
        );
      }

      if (_currentUser == null) {
        await _clearUserData();
        return null;
      }

      final auth = await _currentUser!.authentication;
      _cachedIdToken = auth.idToken;

      // 💾 UPDATE TOKEN DI STORAGE
      if (_cachedIdToken != null) {
        await _saveUserData(_cachedIdToken!);
      }

      return _cachedIdToken;
    } catch (e) {
      print("❌ getIdToken error: $e");
      return null;
    }
  }

  // =========================================================
  // 🚪 LOGOUT TOTAL
  // =========================================================
  Future<void> logout() async {
    try {
      await _googleSignIn.disconnect(); // ⬅️ penting
      await _googleSignIn.signOut();

      _currentUser = null;
      _cachedIdToken = null;

      // 🗑️ HAPUS SEMUA DATA USER
      await _clearUserData();

      print("✅ Logout total berhasil");
    } catch (e) {
      print("❌ Logout error: $e");
    }
  }

  // =========================================================
  // 📖 AMBIL DATA USER DARI STORAGE (optional helper)
  // =========================================================
  Future<Map<String, String?>> getSavedUserData() async {
    return {
      'email': await _storage.read(key: _keyEmail),
      'displayName': await _storage.read(key: _keyDisplayName),
      'photoUrl': await _storage.read(key: _keyPhotoUrl),
      'userId': await _storage.read(key: _keyUserId),
    };
  }

  // =========================================================
  // 🧪 DEBUG JWT
  // =========================================================
  void _debugJwt(String token) {
    try {
      final parts = token.split('.');
      final payloadBase64 = base64Url.normalize(parts[1]);
      final payloadString = utf8.decode(base64Url.decode(payloadBase64));
      print("📦 JWT PAYLOAD:");
      print(payloadString);
    } catch (e) {
      print("❌ Decode JWT gagal: $e");
    }
  }
}