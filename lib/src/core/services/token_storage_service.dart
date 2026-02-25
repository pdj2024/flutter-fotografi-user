import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorageService {
  static const _keyAccessToken  = 'access_token';
  static const _keyRefreshToken = 'refresh_token';
  static const _keyDeviceToken  = 'device_token';

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

  // ── Bulk ops ──────────────────────────────────────────
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await saveAccessToken(accessToken);
    await saveRefreshToken(refreshToken);
  }

  /// Hanya hapus access + refresh (device token tetap)
  Future<void> clearAuthTokens() async {
    await deleteAccessToken();
    await deleteRefreshToken();
  }

  /// Hapus semua
  Future<void> clearAll() async {
    await deleteAccessToken();
    await deleteRefreshToken();
    await deleteDeviceToken();
  }
}

final tokenStorage = TokenStorageService();