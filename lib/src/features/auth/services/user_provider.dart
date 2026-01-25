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
/// 👤 UserProvider - FIXED VERSION
/// ============================================
/// Improvements:
/// 1. Hive storage untuk user data persistence
/// 2. Better session restore logic
/// 3. Auto-refresh expired tokens
/// 4. Cleaner state management
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
      _userBox = await Hive.openBox(_userBoxName);
      print("✅ [UserProvider] Hive box opened");
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

      print("💾 [UserProvider] Customer data saved");
      print("👤 User: ${_customer!.namaDisplay}");
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
        _customer = null;
      }

      // Load role
      final savedRole = _userBox?.get(_keyRole);
      if (savedRole != null && savedRole.isNotEmpty) {
        _role = savedRole;
        apiClient.setRole(_role);
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
      print("🗑️ [UserProvider] User data cleared");
    } catch (e) {
      print("❌ [UserProvider] Clear error: $e");
    }
  }

  // =========================================================
  // 🔐 AUTHENTICATION
  // =========================================================
  
  Future<GoogleLoginStatus> checkLoginGoogle({
    required String role,
    bool silent = false,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      print("🔐 [UserProvider] checkLoginGoogle | role: $role, silent: $silent");

      // 1️⃣ Login to Google
      final idToken = await authService.login(silent: silent);

      if (idToken == null) {
        print("❌ [UserProvider] Login failed, token null");
        if (!silent) {
          await _clearUserData();
          clear();
        }
        return GoogleLoginStatus.tokenInvalid;
      }

      print("✅ [UserProvider] Token obtained, checking backend status...");

      // 2️⃣ Check status on backend
      final result = await _customerService.checkGoogleLogin();

      // 3️⃣ Handle CREATED status
      if (result.status == GoogleLoginStatus.created) {
        setRole(role);
        _customer = result.customer;
        await _saveCustomerData();
        notifyListeners();
        return GoogleLoginStatus.created;
      }

      // 4️⃣ Handle AKTIF status
      if (result.status == GoogleLoginStatus.aktif && result.customer != null) {
        _customer = result.customer!;
        await _saveCustomerData();

        // Register device token
        try {
          await deviceTokenService.addDeviceToken(_customer!.noId);
        } catch (e) {
          print("⚠️ [UserProvider] Device token registration failed: $e");
        }

        setRole(role);
        print("✅ [UserProvider] User active: ${_customer!.namaDisplay}");
        notifyListeners();
        return GoogleLoginStatus.aktif;
      }

      print("⚠️ [UserProvider] Status: ${result.status}");
      return result.status;
      
    } catch (e, stackTrace) {
      _error = "Login gagal: $e";
      print("❌ [UserProvider] checkLoginGoogle error: $e");
      print(stackTrace);
      notifyListeners();
      return GoogleLoginStatus.error;
    } finally {
      _setLoading(false);
    }
  }

  // =========================================================
  // 🔄 SESSION RESTORE
  // =========================================================
  
  Future<bool> restoreSession() async {
    try {
      print("🔄 [UserProvider] Restoring session...");

      // 1️⃣ Restore auth session
      final sessionRestored = await authService.restoreSession();

      if (!sessionRestored) {
        print("❌ [UserProvider] Auth session restore failed");
        _customer = null;
        _isInitialized = true;
        notifyListeners();
        return false;
      }

      // 2️⃣ Load user data from storage
      await loadUserData();

      // 3️⃣ If no customer data, try to fetch from backend
      if (_customer == null) {
        print("⚠️ [UserProvider] No local customer data, fetching from backend...");
        return await _refreshCustomerFromBackend();
      }

      // 4️⃣ Check if data is stale (older than 24 hours)
      final lastSync = _userBox?.get(_keyLastSync);
      if (lastSync != null) {
        final lastSyncDate = DateTime.parse(lastSync);
        final hoursSinceSync = DateTime.now().difference(lastSyncDate).inHours;
        
        if (hoursSinceSync > 24) {
          print("⚠️ [UserProvider] Data stale (${hoursSinceSync}h old), refreshing...");
          await _refreshCustomerFromBackend();
        }
      }

      print("✅ [UserProvider] Session restored: ${_customer!.namaDisplay}");
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
  Future<bool> _refreshCustomerFromBackend() async {
    try {
      final result = await _customerService.checkGoogleLogin();
      
      if (result.customer != null) {
        _customer = result.customer;
        await _saveCustomerData();
        notifyListeners();
        print("✅ [UserProvider] Customer data refreshed: ${_customer!.namaDisplay}");
        return true;
      }
      
      print("❌ [UserProvider] Failed to get customer from backend");
      return false;
      
    } catch (e) {
      print("❌ [UserProvider] Backend refresh error: $e");
      return false;
    }
  }

  // =========================================================
  // 🚪 LOGOUT
  // =========================================================
  
  Future<void> logout() async {
    try {
      print("🚪 [UserProvider] Logging out...");

      // 1️⃣ Remove device token
      if (_customer != null) {
        try {
          await deviceTokenService.removeDeviceToken(_customer!.noId);
        } catch (e) {
          print("⚠️ [UserProvider] Device token removal failed: $e");
        }
      }

      // 2️⃣ Logout from AuthService
      await authService.logout();

      // 3️⃣ Clear all data
      await _clearUserData();
      clear();
      apiClient.clearRole();

      print("✅ [UserProvider] Logout complete");
      notifyListeners();
    } catch (e) {
      print("❌ [UserProvider] Logout error: $e");
      clear();
      notifyListeners();
    }
  }

  Future<void> logoutAndSwitchAccount() async {
    try {
      print("🔄 [UserProvider] Switching account...");

      if (_customer != null) {
        try {
          await deviceTokenService.removeDeviceToken(_customer!.noId);
        } catch (e) {
          print("⚠️ [UserProvider] Device token removal failed: $e");
        }
      }

      await authService.logoutAndRevoke();
      await _clearUserData();
      clear();
      apiClient.clearRole();

      print("✅ [UserProvider] Account switch complete");
      notifyListeners();
    } catch (e) {
      print("❌ [UserProvider] Switch account error: $e");
      clear();
      notifyListeners();
    }
  }

  // =========================================================
  // 🛠️ UTILITIES
  // =========================================================
  
  void setRole(String role) {
    _role = role;
    apiClient.setRole(role);
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
  Future<void> refreshUserData() async {
    await _refreshCustomerFromBackend();
  }
}