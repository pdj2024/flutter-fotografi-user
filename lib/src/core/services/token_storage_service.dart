import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorageService {
  static const _keyAccessToken  = 'access_token';
  static const _keyRefreshToken = 'refresh_token';
  static const _keyDeviceToken  = 'device_token';
  static const _keyIdSession    = 'id_session'; 

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // ── Access Token ──────────────────────────────────────
  Future<void>    saveAccessToken(String token)  => _storage.write(key: _keyAccessToken,  value: token);
  Future<String?> getAccessToken()               => _storage.read(key: _keyAccessToken);
  Future<void>    deleteAccessToken()            => _storage.delete(key: _keyAccessToken);

  // ── Refresh Token ─────────────────────────────────────
  Future<void>    saveRefreshToken(String token) => _storage.write(key: _keyRefreshToken, value: token);
  Future<String?> getRefreshToken()              => _storage.read(key: _keyRefreshToken);
  Future<void>    deleteRefreshToken()           => _storage.delete(key: _keyRefreshToken);

  // ── Device Token ──────────────────────────────────────
  Future<void>    saveDeviceToken(String token)  => _storage.write(key: _keyDeviceToken,  value: token);
  Future<String?> getDeviceToken()               => _storage.read(key: _keyDeviceToken);
  Future<void>    deleteDeviceToken()            => _storage.delete(key: _keyDeviceToken);

  // ── Id Session ────────────────────────────────────────
  Future<void>    saveIdSession(String id)       => _storage.write(key: _keyIdSession,    value: id);
  Future<String?> getIdSession()                 => _storage.read(key: _keyIdSession);
  Future<void>    deleteIdSession()              => _storage.delete(key: _keyIdSession);

  // ── No Id (user identifier dari No_Id field, bukan id_session) ──────
  // Tidak disimpan — untuk kebutuhan display, ambil dari CustomerModel / UserProvider

  // ── Bulk ops ──────────────────────────────────────────

  /// Simpan semua data dari response cek-login-google sekaligus
  Future<void> saveLoginData({
    required String accessToken,
    required String refreshToken,
    String? deviceToken,
    String? idSession,
  }) async {
    await saveAccessToken(accessToken);
    await saveRefreshToken(refreshToken);
    if (deviceToken != null && deviceToken.isNotEmpty) {
      await saveDeviceToken(deviceToken);
    }
    if (idSession != null && idSession.isNotEmpty) {
      await saveIdSession(idSession);
    }
  }

  /// Simpan hanya token pair (access + refresh) — untuk keperluan refresh token
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await saveAccessToken(accessToken);
    await saveRefreshToken(refreshToken);
  }

  /// Hanya hapus access + refresh (device token & session tetap)
  Future<void> clearAuthTokens() async {
    await deleteAccessToken();
    await deleteRefreshToken();
  }

  /// Hapus semua — dipanggil saat logout tuntas
  Future<void> clearAll() async {
    await deleteAccessToken();
    await deleteRefreshToken();
    await deleteDeviceToken();
    await deleteIdSession();
  }
}

final tokenStorage = TokenStorageService();