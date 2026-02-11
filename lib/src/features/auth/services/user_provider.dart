import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/constants/login_status.dart';
import 'package:mpjnew/src/core/services/api_singleton.dart';
import 'package:mpjnew/src/core/services/auth_service_instance.dart';
import 'package:mpjnew/src/data/models/customer_model.dart';
import 'package:mpjnew/src/features/customer/services/customer_service.dart';
import 'package:mpjnew/src/features/customer/services/device_token_service.dart';
import 'package:mpjnew/src/features/customer/services/vendor_service.dart';

/// ============================================
/// 👤 UserProvider - COMPATIBLE WITH NEW AuthService
/// ============================================
/// Changes:
/// 1. ✅ Use authService.signIn() instead of login()
/// 2. ✅ Use authService.getIdToken() without forceRefresh by default
/// 3. ✅ Use authService.signOut() instead of logout()
/// 4. ✅ Use authService.disconnect() for account switching
/// 5. ✅ Remove all token caching logic
/// ============================================

class UserProvider with ChangeNotifier {
  final CustomerService _customerService;

  UserProvider({
    required CustomerService customerService,
    required VendorService vendorService,
  }) : _customerService = customerService;

  DeviceTokenService get deviceTokenService => DeviceTokenService();

  // ✅ Hive box
  static const String _userBoxName = 'user_box';
  Box? _userBox;

  // 🔑 Hive keys
  static const String _keyRole = 'user_role';
  static const String _keyCustomer = 'user_customer_data';
  static const String _keyIsLoggedIn = 'user_is_logged_in';
  static const String _keyLastSync = 'user_last_sync';

  // State
  String _role = Constants.customer;
  String? _photoUrl;
  CustomerModel? _customer;
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  // Getters
  String? get role => _role;
  String? get photoUrl => _photoUrl;
  CustomerModel? get customer => _customer;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInitialized => _isInitialized;
  bool get isLoggedIn => _customer != null && authService.isLoggedIn;
  String? get userId => _customer?.noId;
  String get displayName => _customer?.namaDisplay ?? '';

  // =========================================================
  // 🔧 INITIALIZATION
  // =========================================================
  
  Future<void> initialize() async {
    try {
      print("🔧 [UserProvider] Initializing...");
      
      if (Hive.isBoxOpen(_userBoxName)) {
        await Hive.box(_userBoxName).close();
      }
      
      _userBox = await Hive.openBox(_userBoxName);
      print("✅ [UserProvider] Hive box opened");
      
      // Load user data immediately
      await loadUserData();
    } catch (e) {
      print("❌ [UserProvider] Hive init error: $e");
    }
  }

  // =========================================================
  // 💾 STORAGE OPERATIONS
  // =========================================================
  
  Future<void> _saveCustomerData() async {
    try {
      if (_customer == null || _userBox == null) return;

      final customerJson = jsonEncode(_customer!.toJson());
      
      await _userBox!.putAll({
        _keyCustomer: customerJson,
        _keyRole: _role,
        _keyIsLoggedIn: true,
        _keyLastSync: DateTime.now().toIso8601String(),
      });

      await _userBox!.flush();

      print("💾 [UserProvider] Customer data saved");
      print("   User: ${_customer!.namaDisplay}");
      print("   Role: $_role");
    } catch (e) {
      print("❌ [UserProvider] Save error: $e");
    }
  }

  Future<void> loadUserData() async {
    try {
      print("🔄 [UserProvider] Loading user data...");

      if (_userBox == null) {
        await initialize();
      }

      // Load customer data
      final customerJson = _userBox?.get(_keyCustomer);
      
      if (customerJson != null && customerJson.isNotEmpty) {
        try {
          final customerMap = jsonDecode(customerJson);
          _customer = CustomerModel.fromJson(customerMap);
          print("✅ [UserProvider] Customer loaded: ${_customer?.namaDisplay}");
        } catch (e) {
          print("❌ [UserProvider] Parse error: $e");
          await _userBox?.delete(_keyCustomer);
          _customer = null;
        }
      } else {
        print("ℹ️  [UserProvider] No customer data in storage");
        _customer = null;
      }

      // Load role
      final savedRole = _userBox?.get(_keyRole);
      if (savedRole != null && savedRole.isNotEmpty) {
        _role = savedRole;
        apiClient.setRole(_role);
        print("✅ [UserProvider] Role loaded: $_role");
      }

      _isInitialized = true;
      notifyListeners();
    } catch (e, stackTrace) {
      print("❌ [UserProvider] Load error: $e");
      print(stackTrace);
      _customer = null;
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> _clearUserData() async {
    try {
      await _userBox?.clear();
      await _userBox?.flush();
      print("🗑️  [UserProvider] User data cleared");
    } catch (e) {
      print("❌ [UserProvider] Clear error: $e");
    }
  }

  // =========================================================
  // 🔐 AUTHENTICATION
  // =========================================================
  
  /// Login with Google
  /// ✅ Uses new AuthService.signIn()
  Future<GoogleLoginStatus> checkLoginGoogle({
    required String role,
    bool silent = false,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      print("═══════════════════════════════════════");
      print("🔐 [UserProvider] checkLoginGoogle");
      print("   Role: $role");
      print("   Silent: $silent");
      print("═══════════════════════════════════════");

      // 1️⃣ Sign in with Google
      String? idToken;
      
      if (silent) {
        // Try silent restore
        final restored = await authService.restoreSession();
        if (restored) {
          idToken = await authService.getIdToken();
        }
      } else {
        // Interactive sign-in
        idToken = await authService.signIn();
      }

      if (idToken == null) {
        print("❌ [UserProvider] Sign-in failed, token null");
        if (!silent) {
          await _clearUserData();
          clear();
        }
        return GoogleLoginStatus.tokenInvalid;
      }

      print("✅ [UserProvider] Token obtained (${idToken.length} chars)");
      print("🔄 [UserProvider] Checking backend status...");

      // 2️⃣ Check status on backend
      final result = await _customerService.checkGoogleLogin();

      print("📊 [UserProvider] Backend response: ${result.status}");

      // 3️⃣ Handle CREATED status (new user)
      if (result.status == GoogleLoginStatus.created) {
        print("✅ [UserProvider] New user created");
        setRole(role);
        _customer = result.customer;
        await _saveCustomerData();
        notifyListeners();
        return GoogleLoginStatus.created;
      }

      // 4️⃣ Handle AKTIF status (existing user)
      if (result.status == GoogleLoginStatus.aktif && result.customer != null) {
        _customer = result.customer!;
        print("✅ [UserProvider] User active: ${_customer!.namaDisplay}");
        
        await _saveCustomerData();

        // Register device token
        try {
          await deviceTokenService.addDeviceToken(_customer!.noId, null);
          print("✅ [UserProvider] Device token registered");
        } catch (e) {
          print("⚠️  [UserProvider] Device token registration failed: $e");
        }

        setRole(role);
        notifyListeners();
        return GoogleLoginStatus.aktif;
      }

      // 5️⃣ Other statuses
      print("⚠️  [UserProvider] Status: ${result.status}");
      return result.status;
      
    } catch (e, stackTrace) {
      _error = "Login gagal: $e";
      print("❌ [UserProvider] checkLoginGoogle error: $e");
      print(stackTrace);
      notifyListeners();
      return GoogleLoginStatus.error;
    } finally {
      _setLoading(false);
      print("═══════════════════════════════════════");
    }
  }

  // =========================================================
  // 🔄 SESSION RESTORE
  // =========================================================
  
  /// Restore user session
  /// ✅ Uses new AuthService.restoreSession()
  Future<bool> restoreSession() async {
    try {
      print("═══════════════════════════════════════");
      print("🔄 [UserProvider] Restoring session...");

      // 1️⃣ Restore auth session (Google Sign-In)
      final sessionRestored = await authService.restoreSession();

      if (!sessionRestored) {
        print("❌ [UserProvider] Auth session restore failed");
        _customer = null;
        _isInitialized = true;
        notifyListeners();
        return false;
      }

      print("✅ [UserProvider] Auth session restored");
      print("   Email: ${authService.email}");

      // 2️⃣ Load user data from local storage
      await loadUserData();

      // 3️⃣ If no customer data, fetch from backend
      if (_customer == null) {
        print("⚠️  [UserProvider] No local customer data");
        print("🔄 [UserProvider] Fetching from backend...");
        
        final fetched = await _refreshCustomerFromBackend();
        
        if (!fetched) {
          print("❌ [UserProvider] Failed to fetch customer data");
          await authService.signOut();
          return false;
        }
      }

      // 4️⃣ Check if data is stale (older than 24 hours)
      final lastSync = _userBox?.get(_keyLastSync);
      if (lastSync != null) {
        try {
          final lastSyncDate = DateTime.parse(lastSync);
          final hoursSinceSync = DateTime.now().difference(lastSyncDate).inHours;
          
          print("ℹ️  [UserProvider] Last sync: ${hoursSinceSync}h ago");
          
          if (hoursSinceSync > 24) {
            print("🔄 [UserProvider] Data stale, refreshing...");
            await _refreshCustomerFromBackend();
          }
        } catch (e) {
          print("⚠️  [UserProvider] Last sync parse error: $e");
        }
      }

      print("✅ [UserProvider] Session restored successfully");
      print("   User: ${_customer!.namaDisplay}");
      print("   Role: $_role");
      print("═══════════════════════════════════════");
      
      return true;
      
    } catch (e, stackTrace) {
      print("❌ [UserProvider] Restore error: $e");
      print(stackTrace);
      _isInitialized = true;
      notifyListeners();
      return false;
    }
  }

  /// Refresh customer data from backend
  /// ✅ Uses fresh token from AuthService
  Future<bool> _refreshCustomerFromBackend() async {
    try {
      print("🔄 [UserProvider] Refreshing customer from backend...");
      
      // Verify token is valid
      final token = await authService.getIdToken();
      if (token == null) {
        print("❌ [UserProvider] No valid token");
        return false;
      }

      final result = await _customerService.checkGoogleLogin();
      
      if (result.customer != null) {
        _customer = result.customer;
        await _saveCustomerData();
        notifyListeners();
        print("✅ [UserProvider] Customer refreshed: ${_customer!.namaDisplay}");
        return true;
      }
      
      print("❌ [UserProvider] No customer data from backend");
      return false;
      
    } catch (e) {
      print("❌ [UserProvider] Backend refresh error: $e");
      return false;
    }
  }

  // =========================================================
  // 🚪 LOGOUT
  // =========================================================
  
  /// Normal logout
  /// ✅ Uses new AuthService.signOut()
  Future<void> logout() async {
    try {
      print("═══════════════════════════════════════");
      print("🚪 [UserProvider] Logging out...");

      // 1️⃣ Remove device token
      if (_customer != null) {
        try {
          await deviceTokenService.removeDeviceToken(_customer!.noId, null);
          print("✅ [UserProvider] Device token removed");
        } catch (e) {
          print("⚠️  [UserProvider] Device token removal failed: $e");
        }
      }

      // 2️⃣ Sign out from Google
      await authService.signOut();
      print("✅ [UserProvider] Google sign-out complete");

      // 3️⃣ Clear all local data
      await _clearUserData();
      clear();
      apiClient.clearRole();

      print("✅ [UserProvider] Logout complete");
      print("═══════════════════════════════════════");
      
      notifyListeners();
    } catch (e) {
      print("❌ [UserProvider] Logout error: $e");
      clear();
      notifyListeners();
    }
  }

  /// Logout and switch account
  /// ✅ Uses new AuthService.disconnect()
  Future<void> logoutAndSwitchAccount() async {
    try {
      print("═══════════════════════════════════════");
      print("🔄 [UserProvider] Switching account...");

      // 1️⃣ Remove device token
      if (_customer != null) {
        try {
          await deviceTokenService.removeDeviceToken(_customer!.noId, null);
          print("✅ [UserProvider] Device token removed");
        } catch (e) {
          print("⚠️  [UserProvider] Device token removal failed: $e");
        }
      }

      // 2️⃣ Disconnect Google account (revoke access)
      await authService.disconnect();
      print("✅ [UserProvider] Google account disconnected");

      // 3️⃣ Clear all local data
      await _clearUserData();
      clear();
      apiClient.clearRole();

      print("✅ [UserProvider] Account switch complete");
      print("═══════════════════════════════════════");
      
      notifyListeners();
    } catch (e) {
      print("❌ [UserProvider] Switch account error: $e");
      clear();
      notifyListeners();
    }
  }

  // =========================================================
  // 🛠️  UTILITIES
  // =========================================================
  
  void setRole(String role) {
    _role = role;
    apiClient.setRole(role);
    _userBox?.put(_keyRole, role);
    print("✅ [UserProvider] Role set: $role");
    notifyListeners();
  }

  void setPhotoUrl(String photoUrl) {
    _photoUrl = photoUrl;
    notifyListeners();
  }

  void clear() {
    _customer = null;
    _role = Constants.customer;
    _error = null;
    _isLoading = false;
    _photoUrl = null;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Force refresh user data from backend
  /// ✅ Uses fresh token from AuthService
  Future<void> refreshUserData() async {
    print("🔄 [UserProvider] Force refresh user data...");
    await _refreshCustomerFromBackend();
  }

  /// Get current auth state
  void printDebugState() {
    print("═══ UserProvider State ═══");
    print("Customer: ${_customer?.namaDisplay ?? 'null'}");
    print("Role: $_role");
    print("Is logged in: $isLoggedIn");
    print("Is loading: $_isLoading");
    print("Error: $_error");
    print("Initialized: $_isInitialized");
    
    if (_userBox != null) {
      print("Storage:");
      print("  Is logged in: ${_userBox!.get(_keyIsLoggedIn)}");
      print("  Role: ${_userBox!.get(_keyRole)}");
      print("  Last sync: ${_userBox!.get(_keyLastSync)}");
    }
    
    print("═══════════════════════════");
    
    // Also print auth state
    authService.printDebugState();
  }
}