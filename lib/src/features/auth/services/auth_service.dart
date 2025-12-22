import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
  );

  GoogleSignInAccount? _currentUser;
  String? _cachedIdToken;

  /// 🔹 Status login
  bool get isLoggedIn => _currentUser != null;

  String? get email => _currentUser?.email;
  String? get displayName => _currentUser?.displayName;
  String? get photoUrl => _currentUser?.photoUrl;

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
        return null;
      }

      // ❗ PAKSA REFRESH TOKEN
      final auth = await _currentUser!.authentication;

      if (auth.idToken == null) {
        print("❌ ID Token null");
        return null;
      }

      _cachedIdToken = auth.idToken;

      print("✅ Login sukses: ${_currentUser!.email}");
      _debugJwt(_cachedIdToken!);

      return _cachedIdToken;
    } catch (e) {
      print("❌ Login error: $e");
      return null;
    }
  }

  // =========================================================
  // 🔄 AMBIL TOKEN → SELALU FRESH
  // =========================================================
  Future<String?> getIdToken({bool forceRefresh = true}) async {
    try {
      if (_currentUser == null) {
        _currentUser = await _googleSignIn.signInSilently(
          reAuthenticate: true,
        );
      }

      if (_currentUser == null) return null;

      final auth = await _currentUser!.authentication;
      _cachedIdToken = auth.idToken;

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

      print("✅ Logout total berhasil");
    } catch (e) {
      print("❌ Logout error: $e");
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
      print("📦 JWT PAYLOAD:");
      print(payloadString);
    } catch (e) {
      print("❌ Decode JWT gagal: $e");
    }
  }
}
