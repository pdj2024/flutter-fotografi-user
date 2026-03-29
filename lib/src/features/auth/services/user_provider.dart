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

class UserProvider with ChangeNotifier {
  final CustomerService _customerService;

  UserProvider({
    required CustomerService customerService,
    required VendorService vendorService,
  }) : _customerService = customerService;

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

      print("💾 [UserProvider] Customer data saved: ${_customer!.namaDisplay}");
    } catch (e) {
      print("❌ [UserProvider] Save error: $e");
    }
  }

  Future<void> loadUserData() async {
    try {
      print("🔄 [UserProvider] Loading user data...");

      if (_userBox == null) await initialize();

      final customerJson = _userBox?.get(_keyCustomer);

      if (customerJson != null && customerJson.isNotEmpty) {
        try {
          _customer = CustomerModel.fromJson(jsonDecode(customerJson));
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

  void updateCustomerLocally(CustomerModel updatedCustomer) {
    _customer = updatedCustomer;
    _saveCustomerData(); // persist ke Hive
    notifyListeners();
    debugPrint(
        "✅ [UserProvider] Customer updated locally: ${updatedCustomer.namaDisplay}");
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

  Future<GoogleLoginStatus> checkLoginGoogle({
    required String role,
    bool silent = false,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      print(
          "🔐 [UserProvider] checkLoginGoogle | Role: $role | Silent: $silent");

      if (silent) {
        // ── SILENT: restore dari storage ─────────────────
        final restored = await authService.restoreSession();
        if (!restored) {
          print("❌ Silent restore failed");
          return GoogleLoginStatus.tokenInvalid;
        }

        await loadUserData();

        if (_customer == null) {
          print("❌ No customer data after restore");
          return GoogleLoginStatus.tokenInvalid;
        }

        setRole(role);
        print("✅ Silent restore success");
        return GoogleLoginStatus.aktif;
      } else {
        // ── INTERACTIVE: Google sign-in ───────────────────
        // signIn() sudah hit backend & simpan token — tidak perlu hit lagi
        final accessToken = await authService.signIn();

        if (accessToken == null) {
          print("❌ Sign-in failed");
          await _clearUserData();
          clear();
          return GoogleLoginStatus.tokenInvalid;
        }

        // ✅ Ambil data dari lastLoginData — tidak hit backend lagi
        final loginData = authService.lastLoginData;
        authService.clearLastLoginData();

        if (loginData == null) {
          print("❌ No login data");
          return GoogleLoginStatus.error;
        }

        final status =
            (loginData['Status'] as String?)?.toLowerCase() ?? 'error';
        final noId = loginData['No_Id'] as String?;

        print("📊 Status: $status, No_Id: $noId");

        // Fetch customer detail pakai access_token yang sudah tersimpan
        if (noId != null) {
          try {
            final customers = await _customerService.getAll(no_id: noId);
            if (customers.isNotEmpty) {
              _customer = customers.first;
              await _saveCustomerData();
            }
          } catch (e) {
            print("⚠️ Fetch customer detail error: $e");
          }
        }

        setRole(role);
        notifyListeners();

        // ✅ Customer hanya ada 2 status
        switch (status) {
          case 'aktif':
            return GoogleLoginStatus.aktif;
          case 'created':
            return GoogleLoginStatus.created;
          default:
            return GoogleLoginStatus.error;
        }
      }
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

      final sessionRestored = await authService.restoreSession();

      if (!sessionRestored) {
        print("❌ Auth session restore failed");
        _customer = null;
        _isInitialized = true;
        notifyListeners();
        return false;
      }

      print("✅ Auth session restored | Email: ${authService.email}");

      await loadUserData();

      if (_customer == null) {
        print("⚠️ No local customer data, fetching from backend...");
        final fetched = await _refreshCustomerFromBackend();
        if (!fetched) {
          print("❌ Failed to fetch customer data");
          await authService.signOut();
          return false;
        }
      }

      final lastSync = _userBox?.get(_keyLastSync);
      if (lastSync != null) {
        try {
          final hoursSinceSync =
              DateTime.now().difference(DateTime.parse(lastSync)).inHours;
          print("ℹ️ Last sync: ${hoursSinceSync}h ago");
          if (hoursSinceSync > 24) {
            print("🔄 Data stale, refreshing...");
            await _refreshCustomerFromBackend();
          }
        } catch (e) {
          print("⚠️ Last sync parse error: $e");
        }
      }

      // ── Refresh device token saat session restore ──────────────────────
      // FCM token bisa berubah setelah app restart atau reinstall
      // addDeviceToken sudah handle duplikat (status 400 "sudah ada" = success)
      final userId = _customer?.noId;
      if (userId != null && userId.isNotEmpty) {
        try {
          final deviceTokenService = DeviceTokenService();
          await deviceTokenService.addDeviceToken(userId, null);
          print("✅ [UserProvider] Device token refreshed for: $userId");
        } catch (e) {
          // Non-fatal — notifikasi mungkin tidak jalan tapi app tetap bisa dipakai
          print("⚠️ [UserProvider] Device token refresh failed: $e");
        }
      }

      print("✅ Session restored: ${_customer!.namaDisplay}");
      return true;
    } catch (e, stackTrace) {
      print("❌ [UserProvider] Restore error: $e");
      print(stackTrace);
      _isInitialized = true;
      notifyListeners();
      return false;
    }
  }

  Future<bool> _refreshCustomerFromBackend() async {
    try {
      print("🔄 [UserProvider] Refreshing customer from backend...");

      final token = await authService.getIdToken();
      if (token == null) {
        print("❌ No valid token");
        return false;
      }

      // Gunakan getAll dengan email dari authService jika tersedia
      final email = authService.email;
      if (email == null) {
        print("❌ No email available");
        return false;
      }

      final customers = await _customerService.getAll(email: email);
      if (customers.isNotEmpty) {
        _customer = customers.first;
        await _saveCustomerData();
        notifyListeners();
        print("✅ Customer refreshed: ${_customer!.namaDisplay}");
        return true;
      }

      print("❌ No customer data from backend");
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

      // Hapus token dari storage + disconnect Google
      await authService.signOut();
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

      // disconnect → user HARUS pilih akun lagi
      await authService.disconnect();
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

  Future<void> refreshUserData() async {
    print("🔄 [UserProvider] Force refresh...");
    await _refreshCustomerFromBackend();
  }

  void printDebugState() {
    print("═══ UserProvider State ═══");
    print("Customer: ${_customer?.namaDisplay ?? 'null'}");
    print("Role: $_role");
    print("Is logged in: $isLoggedIn");
    print("Is loading: $_isLoading");
    print("Error: $_error");
    print("Initialized: $_isInitialized");
    if (_userBox != null) {
      print("Storage - Is logged in: ${_userBox!.get(_keyIsLoggedIn)}");
      print("Storage - Role: ${_userBox!.get(_keyRole)}");
      print("Storage - Last sync: ${_userBox!.get(_keyLastSync)}");
    }
    print("═══════════════════════════");
  }
}
