import 'dart:async';
import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// ============================================
/// 🔐 AuthService - BEST PRACTICE VERSION
/// ============================================
/// ✅ NO manual token storage
/// ✅ NO manual expiry validation  
/// ✅ Trust Google SDK for token lifecycle
/// ✅ User stays logged in across app restarts
/// ============================================

class AuthService {
  // Singleton
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // ✅ Google Sign-In SDK (NO forceCodeForRefreshToken needed)
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  // Local storage (ONLY for login state, NOT for tokens)
  static const String _boxName = 'auth_box';
  Box? _authBox;

  // Keys
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyUserEmail = 'user_email';

  // In-memory user state
  GoogleSignInAccount? _currentUser;

  // Token refresh lock (prevent concurrent refresh)
  bool _isRefreshing = false;
  final List<Completer<String?>> _refreshQueue = [];

  // =========================================================
  // 🔧 INITIALIZATION
  // =========================================================
  
  Future<void> initialize() async {
    try {
      print("🔧 [AuthService] Initializing...");
      
      if (Hive.isBoxOpen(_boxName)) {
        await Hive.box(_boxName).close();
      }
      
      _authBox = await Hive.openBox(_boxName);
      
      print("✅ [AuthService] Initialized");
    } catch (e) {
      print("❌ [AuthService] Init failed: $e");
      rethrow;
    }
  }

  // =========================================================
  // 🔄 RESTORE SESSION
  // =========================================================
  
  /// Restore user session from Google SDK
  /// ✅ NO token validation needed - SDK handles it
  Future<bool> restoreSession() async {
    try {
      print("═══════════════════════════════════════");
      print("🔄 [AuthService] Restoring session...");

      // Check if user was logged in before
      final wasLoggedIn = _authBox?.get(_keyIsLoggedIn, defaultValue: false) ?? false;
      
      if (!wasLoggedIn) {
        print("⚠️  No previous login found");
        return false;
      }

      // ✅ MAGIC: signInSilently() checks Google's refresh token
      // If refresh token valid → auto refresh ID token → return user
      // If refresh token expired → return null
      _currentUser = await _googleSignIn.signInSilently();

      if (_currentUser == null) {
        print("❌ Silent sign-in failed (refresh token expired)");
        await _clearLoginState();
        return false;
      }

      print("✅ Session restored successfully");
      print("   Email: ${_currentUser!.email}");
      print("═══════════════════════════════════════");
      
      return true;
    } catch (e) {
      print("❌ Restore session error: $e");
      await _clearLoginState();
      return false;
    }
  }

  // =========================================================
  // 🔑 SIGN IN
  // =========================================================
  
  /// Interactive sign-in with Google account picker
  Future<String?> signIn() async {
    try {
      print("═══════════════════════════════════════");
      print("🔑 [AuthService] Starting sign-in...");

      // Show Google account picker
      _currentUser = await _googleSignIn.signIn();

      if (_currentUser == null) {
        print("⚠️  Sign-in cancelled by user");
        return null;
      }

      print("✅ Sign-in successful");
      print("   Email: ${_currentUser!.email}");

      // ✅ Save ONLY login state (NOT token!)
      await _saveLoginState();

      // Get initial token
      final token = await getIdToken();
      
      print("═══════════════════════════════════════");
      return token;
    } catch (e) {
      print("❌ Sign-in error: $e");
      return null;
    }
  }

  // =========================================================
  // 🎫 GET ID TOKEN - ALWAYS FRESH
  // =========================================================
  
  /// Get fresh ID token for backend API calls
  /// ✅ SDK auto-refreshes if expired
  /// ✅ NO manual validation needed
  Future<String?> getIdToken({bool forceRefresh = false}) async {
    try {
      // Prevent concurrent refresh
      if (_isRefreshing) {
        print("⏳ [AuthService] Token refresh in progress, waiting...");
        return await _waitForRefresh();
      }

      // Ensure we have a user
      if (_currentUser == null) {
        print("🔄 [AuthService] No user, attempting silent sign-in...");
        _currentUser = await _googleSignIn.signInSilently();
        
        if (_currentUser == null) {
          print("❌ No authenticated user");
          return null;
        }
      }

      _isRefreshing = true;

      // ✅ MAGIC: This ALWAYS returns fresh token
      // SDK checks expiry → if expired, auto-refresh → return new token
      final auth = await _currentUser!.authentication;
      final token = auth.idToken;

      _notifyRefreshQueue(token);

      if (token != null) {
        print("✅ [AuthService] ID token obtained (${token.length} chars)");
      } else {
        print("⚠️  [AuthService] ID token is null");
      }

      return token;
      
    } catch (e) {
      print("❌ [AuthService] Get token error: $e");
      _notifyRefreshQueue(null);
      return null;
    } finally {
      _isRefreshing = false;
    }
  }

  // =========================================================
  // 📊 STATE QUERIES
  // =========================================================
  
  /// Check if user is logged in
  /// ✅ Based on Google SDK state, NOT token expiry
  bool get isLoggedIn => _currentUser != null;

  /// Get current user
  GoogleSignInAccount? get currentUser => _currentUser;

  /// Get user email
  String? get email => _currentUser?.email;

  /// Get display name
  String? get displayName => _currentUser?.displayName;

  /// Get photo URL
  String? get photoUrl => _currentUser?.photoUrl;

  /// Get user ID
  String? get userId => _currentUser?.id;

  // =========================================================
  // 🚪 SIGN OUT
  // =========================================================
  
  /// Sign out current user
  Future<void> signOut() async {
    try {
      print("🚪 [AuthService] Signing out...");

      await _googleSignIn.signOut();
      await _clearLoginState();
      _currentUser = null;

      print("✅ Sign-out successful");
    } catch (e) {
      print("❌ Sign-out error: $e");
      // Force clear even if Google sign-out fails
      await _clearLoginState();
      _currentUser = null;
    }
  }

  /// Disconnect account (revoke access)
  /// Use when user wants to switch account
  Future<void> disconnect() async {
    try {
      print("🔌 [AuthService] Disconnecting account...");

      await _googleSignIn.disconnect();
      await _clearLoginState();
      _currentUser = null;

      print("✅ Account disconnected");
    } catch (e) {
      print("❌ Disconnect error: $e");
      // Fallback to signOut
      await signOut();
    }
  }

  /// Logout and switch to different account
  Future<void> logoutAndRevoke() async {
    await disconnect();
  }

  // =========================================================
  // 💾 STORAGE HELPERS
  // =========================================================
  
  /// Save login state to Hive
  /// ✅ ONLY stores flag, NOT token
  Future<void> _saveLoginState() async {
    if (_authBox == null || _currentUser == null) return;

    await _authBox!.put(_keyIsLoggedIn, true);
    await _authBox!.put(_keyUserEmail, _currentUser!.email);
    await _authBox!.flush();

    print("💾 [AuthService] Login state saved");
  }

  /// Clear login state from Hive
  Future<void> _clearLoginState() async {
    if (_authBox == null) return;

    await _authBox!.clear();
    await _authBox!.flush();

    print("🗑️  [AuthService] Login state cleared");
  }

  // =========================================================
  // 🔄 REFRESH QUEUE MANAGEMENT
  // =========================================================
  
  /// Wait for ongoing token refresh
  Future<String?> _waitForRefresh() async {
    final completer = Completer<String?>();
    _refreshQueue.add(completer);
    return completer.future;
  }

  /// Notify all waiting requests
  void _notifyRefreshQueue(String? token) {
    for (final completer in _refreshQueue) {
      if (!completer.isCompleted) {
        completer.complete(token);
      }
    }
    _refreshQueue.clear();
  }

  // =========================================================
  // 🧪 DEBUG UTILITIES
  // =========================================================
  
  /// Print current auth state
  void printDebugState() {
    print("═══ AuthService State ═══");
    print("User: ${_currentUser?.email ?? 'null'}");
    print("Is logged in: $isLoggedIn");
    print("Refreshing: $_isRefreshing");
    print("Queue length: ${_refreshQueue.length}");
    
    if (_authBox != null) {
      print("Storage:");
      print("  Was logged in: ${_authBox!.get(_keyIsLoggedIn)}");
      print("  Saved email: ${_authBox!.get(_keyUserEmail)}");
    }
    
    print("═══════════════════════════");
  }

  /// Debug JWT token (for development only)
  void debugJwt(String token) {
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
        print("   Valid for: ${exp.difference(DateTime.now()).inMinutes} minutes");
      }
    } catch (e) {
      print("❌ JWT decode error: $e");
    }
  }

  // =========================================================
  // 🔧 LEGACY COMPATIBILITY (for migration)
  // =========================================================
  
  /// Alias for signIn() - for backward compatibility
  Future<String?> login({bool silent = false}) async {
    if (silent) {
      final restored = await restoreSession();
      return restored ? await getIdToken() : null;
    }
    return await signIn();
  }

  /// Alias for signOut() - for backward compatibility
  Future<void> logout() async {
    await signOut();
  }

  /// Get current user async - for backward compatibility
  Future<GoogleSignInAccount?> getCurrentUserAsync() async {
    if (_currentUser != null) return _currentUser;
    _currentUser = await _googleSignIn.signInSilently();
    return _currentUser;
  }
}