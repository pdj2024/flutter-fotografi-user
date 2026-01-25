import 'dart:async';
import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// ============================================
/// 🔐 AuthService - SIMPLE & CORRECT VERSION
/// ============================================
/// ✅ NO excessive signOut/signIn
/// ✅ Let Google SDK handle token refresh
/// ✅ Simple, stable, predictable
/// ============================================

class AuthService {
  // ✅ SINGLETON PATTERN
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);

  // ✅ Hive boxes
  static const String _boxName = 'auth_box';
  static const String _userBoxName = 'user_box';
  Box? _authBox;
  Box? _userBox;

  // ✅ In-memory state
  GoogleSignInAccount? _currentUser;
  String? _cachedIdToken;
  DateTime? _tokenExpiry;

  // ✅ Token refresh queue management
  bool _isRefreshing = false;
  final List<Completer<String?>> _refreshQueue = [];

  // ✅ Hive keys
  static const String _keyIdToken = 'id_token';
  static const String _keyEmail = 'user_email';
  static const String _keyDisplayName = 'user_display_name';
  static const String _keyPhotoUrl = 'user_photo_url';
  static const String _keyUserId = 'user_id';
  static const String _keyTokenExpiry = 'token_expiry';
  static const String _keyJustLoggedOut = 'just_logged_out';

  // ✅ Getters
  bool get isLoggedIn => _currentUser != null && _cachedIdToken != null;
  String? get email => _currentUser?.email;
  String? get displayName => _currentUser?.displayName;
  String? get photoUrl => _currentUser?.photoUrl;
  String? get userId => _currentUser?.id;
  String? get cachedToken => _cachedIdToken;

  // =========================================================
  // 🔧 INITIALIZATION
  // =========================================================
  Future<void> initialize() async {
    try {
      print("🔧 [AuthService] Initializing...");

      // Close if already open
      if (Hive.isBoxOpen(_boxName)) {
        await Hive.box(_boxName).close();
      }
      if (Hive.isBoxOpen(_userBoxName)) {
        await Hive.box(_userBoxName).close();
      }

      // Open boxes
      _authBox = await Hive.openBox(_boxName);
      _userBox = await Hive.openBox(_userBoxName);

      print("✅ [AuthService] Initialized");
      print("   Auth box: ${_authBox!.length} items");
      print("   User box: ${_userBox!.length} items");
    } catch (e, st) {
      print("❌ [AuthService] Init failed: $e");
      print("Stack: $st");
      rethrow;
    }
  }

  // =========================================================
  // 💾 STORAGE OPERATIONS
  // =========================================================

  /// Save user data to Hive
  Future<void> _saveUserData(String idToken) async {
    try {
      if (_currentUser == null || _authBox == null) {
        print("❌ [AuthService] Cannot save: no user or box");
        return;
      }

      _cachedIdToken = idToken;
      _tokenExpiry = DateTime.now().add(const Duration(minutes: 55));

      print("💾 [AuthService] Saving to Hive...");

      // Save data
      await _authBox!.put(_keyIdToken, idToken);
      await _authBox!.put(_keyEmail, _currentUser!.email);
      await _authBox!.put(_keyDisplayName, _currentUser!.displayName ?? '');
      await _authBox!.put(_keyPhotoUrl, _currentUser!.photoUrl ?? '');
      await _authBox!.put(_keyUserId, _currentUser!.id);
      await _authBox!.put(_keyTokenExpiry, _tokenExpiry!.toIso8601String());

      // ✅ CRITICAL: Flush to disk
      await _authBox!.flush();

      // Clear logout flag
      await _authBox!.delete(_keyJustLoggedOut);

      print("✅ [AuthService] Data saved");

      // Verify
      final saved = _authBox!.get(_keyEmail);
      print("   Email in Hive: $saved");
    } catch (e, st) {
      print("❌ [AuthService] Save error: $e");
      print("Stack: $st");
    }
  }

  /// Check if user just logged out
  Future<bool> _isJustLoggedOut() async {
    if (_authBox == null) return false;
    return _authBox!.get(_keyJustLoggedOut, defaultValue: false) ?? false;
  }

  /// Set logout flag
  Future<void> _setJustLoggedOut(bool value) async {
    if (_authBox == null) return;
    await _authBox!.put(_keyJustLoggedOut, value);
    await _authBox!.flush();
  }

  /// Clear in-memory state
  void _clearMemoryState() {
    _currentUser = null;
    _cachedIdToken = null;
    _tokenExpiry = null;
  }

  /// Clear all data
  Future<void> _clearAllData() async {
    try {
      print("🗑️ [AuthService] Clearing data...");

      _clearMemoryState();

      if (_authBox != null) {
        await _authBox!.clear();
        await _authBox!.flush();
      }

      if (_userBox != null) {
        await _userBox!.clear();
        await _userBox!.flush();
      }

      print("✅ [AuthService] Data cleared");
    } catch (e) {
      print("❌ [AuthService] Clear error: $e");
    }
  }

  // =========================================================
  // 🔄 RESTORE SESSION
  // =========================================================
  Future<bool> restoreSession() async {
    try {
      print("═══════════════════════════════════════");
      print("🔄 [AuthService] Restoring session...");

      // Check if box initialized
      if (_authBox == null) {
        print("❌ Auth box not initialized");
        return false;
      }

      // Check logout flag
      if (await _isJustLoggedOut()) {
        print("⚠️ Just logged out, skip restore");
        return false;
      }

      // Get saved data
      final savedToken = _authBox!.get(_keyIdToken);
      final savedEmail = _authBox!.get(_keyEmail);

      print("📦 Saved data:");
      print("   Token: ${savedToken != null ? 'exists' : 'null'}");
      print("   Email: $savedEmail");

      if (savedToken == null || savedEmail == null) {
        print("⚠️ No saved session");
        _clearMemoryState();
        return false;
      }

      // Check token expiry
      final expiryStr = _authBox!.get(_keyTokenExpiry);
      if (expiryStr != null) {
        _tokenExpiry = DateTime.parse(expiryStr.toString());
        print("⏰ Expiry: $_tokenExpiry");
      }

      // ✅ Try silent sign in
      print("🔄 Attempting silent sign-in...");
      _currentUser = await _googleSignIn.signInSilently();

      if (_currentUser == null) {
        print("⚠️ Silent sign-in failed");
        await _clearAllData();
        return false;
      }

      print("✅ Silent sign-in successful");
      print("   Email: ${_currentUser!.email}");

      // Verify email matches
      if (_currentUser!.email != savedEmail) {
        print("⚠️ Email mismatch!");
        print("   Saved: $savedEmail");
        print("   Current: ${_currentUser!.email}");
        await _clearAllData();
        return false;
      }

      // Check if token needs refresh
      if (_tokenExpiry == null ||
          DateTime.now()
              .add(const Duration(minutes: 5))
              .isAfter(_tokenExpiry!)) {
        print("🔄 Token expired/expiring, refreshing...");
        final newToken = await _refreshToken();
        if (newToken != null) {
          _cachedIdToken = newToken;
          await _saveUserData(newToken);
        } else {
          // Use saved token if refresh fails
          _cachedIdToken = savedToken.toString();
        }
      } else {
        _cachedIdToken = savedToken.toString();
      }

      print("✅ Session restored successfully");
      print("═══════════════════════════════════════");
      return true;
    } catch (e, st) {
      print("❌ Restore error: $e");
      print("Stack: $st");
      await _clearAllData();
      return false;
    }
  }

  // =========================================================
  // 🔐 LOGIN
  // =========================================================
  Future<String?> login({bool silent = false}) async {
    try {
      print("═══════════════════════════════════════");
      print("🔑 [AuthService] Login ${silent ? 'SILENT' : 'INTERACTIVE'}");

      // Clear cached data
      _cachedIdToken = null;
      _tokenExpiry = null;

      // Check logout flag
      if (silent && await _isJustLoggedOut()) {
        print("⚠️ Skip silent login after logout");
        return null;
      }

      // Clear logout flag for interactive login
      if (!silent) {
        await _setJustLoggedOut(false);
      }

      // Sign in
      _currentUser = silent
          ? await _googleSignIn.signInSilently()
          : await _googleSignIn.signIn();

      if (_currentUser == null) {
        print("⚠️ Login cancelled/failed");
        return null;
      }

      print("✅ Login successful");
      print("   Email: ${_currentUser!.email}");

      // Get token
      final token = await _getToken();

      if (token == null) {
        print("❌ Failed to get token");
        await _clearAllData();
        return null;
      }

      // Save to Hive
      await _saveUserData(token);

      print("✅ Login complete");
      print("═══════════════════════════════════════");
      return _cachedIdToken;
    } catch (e, st) {
      print("❌ Login error: $e");
      print("Stack: $st");
      await _clearAllData();
      return null;
    }
  }

  // =========================================================
  // 🔄 GET ID TOKEN - SIMPLE VERSION
  // =========================================================
  Future<String?> getIdToken({bool forceRefresh = false}) async {
    try {
      print("🔑 [AuthService] getIdToken (forceRefresh: $forceRefresh)");

      // Check logout flag
      if (await _isJustLoggedOut()) {
        print("⚠️ Just logged out");
        return null;
      }

      // Restore user if null
      if (_currentUser == null) {
        print("🔄 No current user, trying silent sign-in...");
        _currentUser = await _googleSignIn.signInSilently();

        if (_currentUser == null) {
          print("❌ Silent sign-in failed");
          return null;
        }

        print("✅ User restored: ${_currentUser!.email}");
      }

      // Return cached token if valid
      if (!forceRefresh && _isTokenValid()) {
        print("✅ Using cached token");
        return _cachedIdToken;
      }

      // Need to refresh
      print("🔄 Token needs refresh");

      // ✅ Queue system: wait if already refreshing
      if (_isRefreshing) {
        print("⏳ Refresh in progress, queuing...");
        return await _waitForRefresh();
      }

      // Start refresh
      return await _refreshTokenWithQueue();
    } catch (e, st) {
      print("❌ getIdToken error: $e");
      print("Stack: $st");
      return null;
    }
  }

  // =========================================================
  // 🔄 TOKEN REFRESH - SIMPLE & CORRECT
  // =========================================================

  /// Refresh token with queue management
  Future<String?> _refreshTokenWithQueue() async {
    if (_isRefreshing) {
      return await _waitForRefresh();
    }

    _isRefreshing = true;

    try {
      print("🔄 [AuthService] Refreshing token...");

      // Ensure we have user
      if (_currentUser == null) {
        print("🔄 Trying silent sign-in...");
        _currentUser = await _googleSignIn.signInSilently();
      }

      if (_currentUser == null) {
        print("❌ No user, cannot refresh");
        _notifyRefreshQueue(null);
        return null;
      }

      // Get fresh token
      final newToken = await _refreshToken();

      if (newToken != null) {
        await _saveUserData(newToken);
        print("✅ Token refreshed");
      } else {
        print("❌ Refresh failed");
      }

      // Notify waiting requests
      _notifyRefreshQueue(newToken);
      return newToken;
    } catch (e) {
      print("❌ Refresh error: $e");
      _notifyRefreshQueue(null);
      return null;
    } finally {
      _isRefreshing = false;
    }
  }

  /// ✅ SIMPLE: Refresh token (NO signOut!)
  Future<String?> _refreshToken() async {
    try {
      if (_currentUser == null) {
        print("❌ No current user");
        return null;
      }

      // ✅ SIMPLE: Just get authentication
      // Google SDK handles refresh automatically!
      final auth = await _currentUser!.authentication;
      final token = auth.idToken;

      if (token != null) {
        print("✅ Token obtained (length: ${token.length})");

        if (token != _cachedIdToken) {
          print("   → NEW token");
        } else {
          print("   → Same token (not expired yet)");
        }

        return token;
      }

      print("⚠️ Token is null");
      return null;
    } catch (e) {
      print("❌ Refresh error: $e");
      return null;
    }
  }

  /// ✅ SIMPLE: Get token (NO retry with signOut!)
  Future<String?> _getToken() async {
    try {
      if (_currentUser == null) {
        print("❌ No current user");
        return null;
      }

      // ✅ SIMPLE: Just get the token
      final auth = await _currentUser!.authentication;
      final token = auth.idToken;

      if (token != null) {
        print("✅ Token obtained (length: ${token.length})");
      } else {
        print("⚠️ Token is null");
      }

      return token;
    } catch (e) {
      print("❌ Get token error: $e");
      // ✅ NO RETRY - just return null
      return null;
    }
  }

  /// Wait for ongoing refresh
  Future<String?> _waitForRefresh() async {
    final completer = Completer<String?>();
    _refreshQueue.add(completer);
    return completer.future;
  }

  /// Notify all waiting requests
  void _notifyRefreshQueue(String? token) {
    for (final completer in _refreshQueue) {
      completer.complete(token);
    }
    _refreshQueue.clear();
  }

  // =========================================================
  // ✅ TOKEN VALIDATION
  // =========================================================
  bool _isTokenValid() {
    if (_cachedIdToken == null || _tokenExpiry == null) {
      return false;
    }

    // Valid if expires in more than 5 minutes
    final bufferTime = DateTime.now().add(const Duration(minutes: 5));
    return bufferTime.isBefore(_tokenExpiry!);
  }

  // =========================================================
  // 🚪 LOGOUT - ONLY WHEN USER ACTUALLY WANTS TO LOGOUT
  // =========================================================

  /// Normal logout
  Future<void> logout() async {
    try {
      print("🚪 [AuthService] Logging out...");

      await _setJustLoggedOut(true);

      // ✅ SignOut is OK here - user wants to logout
      try {
        await _googleSignIn.signOut();
        print("✅ Google sign-out success");
      } catch (e) {
        print("⚠️ Sign-out error: $e");
      }

      await _clearAllData();
      await _setJustLoggedOut(true);

      print("✅ Logout complete");
    } catch (e) {
      print("❌ Logout error: $e");
      _clearMemoryState();
      await _setJustLoggedOut(true);
    }
  }

  /// Logout and revoke (stronger)
  Future<void> logoutAndRevoke() async {
    try {
      print("🚪 [AuthService] Logout with revoke...");

      await _setJustLoggedOut(true);

      // ✅ Disconnect is OK here - user wants to switch account
      try {
        await _googleSignIn.disconnect();
        print("✅ Google disconnect success");
      } catch (e) {
        print("⚠️ Disconnect error: $e");
        await _googleSignIn.signOut();
      }

      await _clearAllData();
      await _setJustLoggedOut(true);

      print("✅ Logout and revoke complete");
    } catch (e) {
      print("❌ Logout/revoke error: $e");
      _clearMemoryState();
      await _setJustLoggedOut(true);
    }
  }

  /// Login with different account
  Future<String?> loginWithDifferentAccount() async {
    try {
      print("🔄 [AuthService] Switching account...");

      // ✅ Revoke is OK here - switching account
      await logoutAndRevoke();
      await Future.delayed(const Duration(milliseconds: 500));
      await _setJustLoggedOut(false);

      return await login(silent: false);
    } catch (e) {
      print("❌ Switch account error: $e");
      return null;
    }
  }

  // =========================================================
  // 🧪 UTILITIES
  // =========================================================

  GoogleSignInAccount? getCurrentUser() => _currentUser;

  Future<GoogleSignInAccount?> getCurrentUserAsync() async {
    if (_currentUser != null) return _currentUser;
    _currentUser = await _googleSignIn.signInSilently();
    return _currentUser;
  }

  void _debugJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length < 2) return;

      final payloadBase64 = base64Url.normalize(parts[1]);
      final payloadString = utf8.decode(base64Url.decode(payloadBase64));
      final payload = jsonDecode(payloadString);

      print("📦 JWT:");
      print("   Email: ${payload['email']}");
      print("   Name: ${payload['name']}");
      if (payload['exp'] != null) {
        final exp = DateTime.fromMillisecondsSinceEpoch(payload['exp'] * 1000);
        print("   Expires: $exp");
      }
    } catch (e) {
      print("❌ JWT decode error: $e");
    }
  }

  Future<void> updateCachedToken(String newToken) async {
    await _saveUserData(newToken);
  }

  void printDebugState() {
    print("═══ AuthService State ═══");
    print("Current user: ${_currentUser?.email ?? 'null'}");
    print("Cached token: ${_cachedIdToken != null ? 'exists' : 'null'}");
    print("Token expiry: $_tokenExpiry");
    print("Token valid: ${_isTokenValid()}");
    print("Is refreshing: $_isRefreshing");
    print("Queue length: ${_refreshQueue.length}");

    if (_authBox != null) {
      print("Hive data:");
      print("  Email: ${_authBox!.get(_keyEmail)}");
      print("  User ID: ${_authBox!.get(_keyUserId)}");
      print(
          "  Token: ${_authBox!.get(_keyIdToken) != null ? 'exists' : 'null'}");
    }

    print("═══════════════════════");
  }
}
