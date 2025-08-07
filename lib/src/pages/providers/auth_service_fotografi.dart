import 'dart:convert';

import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  GoogleSignInAccount? _currentUser;
  String? _cachedIdToken;
  DateTime? _tokenExpiry;

  static const _tokenLifespan = Duration(minutes: 60);

  /// 🔹 Cek apakah user sudah login (Google Account tersimpan)
  bool get isLoggedIn => _currentUser != null;

  /// 🔹 Ambil email & nama user
  String? get email => _currentUser?.email;
  String? get displayName => _currentUser?.displayName;

  /// 🔹 Login ke Google → return Google ID Token


Future<String?> login({bool silent = false}) async {
  try {
    _currentUser = silent
        ? await _googleSignIn.signInSilently()
        : await _googleSignIn.signIn();

    if (_currentUser == null) {
      print("🔸 Login dibatalkan atau silent login gagal.");
      return null;
    }

    final auth = await _currentUser!.authentication;

    _cachedIdToken = auth.idToken;
    _tokenExpiry = DateTime.now().add(_tokenLifespan);

    print("✅ Login berhasil: ${_currentUser!.email}");

    // 🔍 Debug isi JWT ID Token
    if (_cachedIdToken != null) {
      try {
        final parts = _cachedIdToken!.split('.');
        if (parts.length != 3) {
          print("❌ Format JWT tidak valid.");
        } else {
          final payloadBase64 = base64Url.normalize(parts[1]);
          final payloadString = utf8.decode(base64Url.decode(payloadBase64));
          print("📦 DECODED JWT PAYLOAD:");
          print(payloadString);
        }
      } catch (e) {
        print("❌ Gagal decode JWT: $e");
      }
    }

    return _cachedIdToken;
  } catch (e) {
    print("❌ Login error: $e");
    return null;
  }
}


  /// 🔹 Ambil ID Token (cached kalau belum expired)
  Future<String?> getIdToken({bool forceRefresh = false}) async {
    final now = DateTime.now();

    if (!forceRefresh &&
        _cachedIdToken != null &&
        _tokenExpiry != null &&
        now.isBefore(_tokenExpiry!)) {
      return _cachedIdToken;
    }

    try {
      final account = _currentUser ?? await _googleSignIn.signInSilently();
      if (account == null) return null;

      _currentUser = account;
      final auth = await account.authentication;

      _cachedIdToken = auth.idToken;
      _tokenExpiry = now.add(_tokenLifespan);

      return _cachedIdToken;
    } catch (e) {
      print("❌ Gagal ambil ID token: $e");
      return null;
    }
  }

  /// 🔹 Logout dari Google
  Future<void> logout() async {
    try {
      await _googleSignIn.signOut();
      _currentUser = null;
      _cachedIdToken = null;
      _tokenExpiry = null;
      print("✅ Logout berhasil.");
    } catch (e) {
      print("❌ Logout error: $e");
    }
  }
}
