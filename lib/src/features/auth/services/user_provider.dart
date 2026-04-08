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
      debugPrint("🔧 [UserProvider] Initializing...");

      if (Hive.isBoxOpen(_userBoxName)) {
        await Hive.box(_userBoxName).close();
      }

      _userBox = await Hive.openBox(_userBoxName);
      debugPrint("✅ [UserProvider] Hive box opened");

      await loadUserData();
    } catch (e) {
      debugPrint("❌ [UserProvider] Hive init error: $e");
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

      debugPrint(
          "💾 [UserProvider] Customer data saved: ${_customer!.namaDisplay}");
    } catch (e) {
      debugPrint("❌ [UserProvider] Save error: $e");
    }
  }

  Future<void> loadUserData() async {
    try {
      debugPrint("🔄 [UserProvider] Loading user data...");

      if (_userBox == null) await initialize();

      final customerJson = _userBox?.get(_keyCustomer);

      if (customerJson != null && customerJson.isNotEmpty) {
        try {
          _customer = CustomerModel.fromJson(jsonDecode(customerJson));
          debugPrint(
              "✅ [UserProvider] Customer loaded: ${_customer?.namaDisplay}");
        } catch (e) {
          debugPrint("❌ [UserProvider] Parse error: $e");
          await _userBox?.delete(_keyCustomer);
          _customer = null;
        }
      } else {
        debugPrint("ℹ️  [UserProvider] No customer data in storage");
        _customer = null;
      }

      final savedRole = _userBox?.get(_keyRole);
      if (savedRole != null && savedRole.isNotEmpty) {
        _role = savedRole;
        apiClient.setRole(_role);
        debugPrint("✅ [UserProvider] Role loaded: $_role");
      }

      _isInitialized = true;
      notifyListeners();
    } catch (e, stackTrace) {
      debugPrint("❌ [UserProvider] Load error: $e");
      debugPrint(stackTrace.toString());
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
      debugPrint("🗑️  [UserProvider] User data cleared");
    } catch (e) {
      debugPrint("❌ [UserProvider] Clear error: $e");
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
      debugPrint(
          "🔐 [UserProvider] checkLoginGoogle | Role: $role | Silent: $silent");

      if (silent) {
        // ── SILENT: restore dari storage ─────────────────
        final restored = await authService.restoreSession();
        if (!restored) {
          debugPrint("❌ Silent restore failed");
          return GoogleLoginStatus.tokenInvalid;
        }

        await loadUserData();

        if (_customer == null) {
          debugPrint("❌ No customer data after restore");
          return GoogleLoginStatus.tokenInvalid;
        }

        setRole(role);
        debugPrint("✅ Silent restore success");
        return GoogleLoginStatus.aktif;
      } else {
        // ── INTERACTIVE: Google sign-in ───────────────────
        // signIn() sudah hit backend & simpan token — tidak perlu hit lagi
        final accessToken = await authService.signIn();

        if (accessToken == null) {
          debugPrint("❌ Sign-in failed");
          await _clearUserData();
          clear();
          return GoogleLoginStatus.tokenInvalid;
        }

        // ✅ Ambil data dari lastLoginData — tidak hit backend lagi
        final loginData = authService.lastLoginData;
        authService.clearLastLoginData();

        if (loginData == null) {
          debugPrint("❌ No login data");
          return GoogleLoginStatus.error;
        }

        final status =
            (loginData['Status'] as String?)?.toLowerCase() ?? 'error';
        final noId = loginData['No_Id'] as String?;

        debugPrint("📊 Status: $status, No_Id: $noId");

        // Fetch customer detail pakai access_token yang sudah tersimpan
        if (noId != null) {
          try {
            final customers = await _customerService.getAll(no_id: noId);
            if (customers.isNotEmpty) {
              _customer = customers.first;
              await _saveCustomerData();
            }
          } catch (e) {
            debugPrint("⚠️ Fetch customer detail error: $e");
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
      debugPrint("❌ [UserProvider] checkLoginGoogle error: $e");
      debugPrint(stackTrace.toString());
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
      debugPrint("🔄 [UserProvider] Restoring session...");

      final sessionRestored = await authService.restoreSession();

      if (!sessionRestored) {
        debugPrint("❌ Auth session restore failed");
        _customer = null;
        _isInitialized = true;
        notifyListeners();
        return false;
      }

      debugPrint("✅ Auth session restored | Email: ${authService.email}");

      await loadUserData();

      if (_customer == null) {
        debugPrint("⚠️ No local customer data, fetching from backend...");
        final fetched = await _refreshCustomerFromBackend();
        if (!fetched) {
          debugPrint("❌ Failed to fetch customer data");
          await authService.signOut();
          return false;
        }
      }

      final lastSync = _userBox?.get(_keyLastSync);
      if (lastSync != null) {
        try {
          final hoursSinceSync =
              DateTime.now().difference(DateTime.parse(lastSync)).inHours;
          debugPrint("ℹ️ Last sync: ${hoursSinceSync}h ago");
          if (hoursSinceSync > 24) {
            debugPrint("🔄 Data stale, refreshing...");
            await _refreshCustomerFromBackend();
          }
        } catch (e) {
          debugPrint("⚠️ Last sync parse error: $e");
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
          debugPrint("✅ [UserProvider] Device token refreshed for: $userId");
        } catch (e) {
          // Non-fatal — notifikasi mungkin tidak jalan tapi app tetap bisa dipakai
          debugPrint("⚠️ [UserProvider] Device token refresh failed: $e");
        }
      }

      debugPrint("✅ Session restored: ${_customer!.namaDisplay}");
      return true;
    } catch (e, stackTrace) {
      debugPrint("❌ [UserProvider] Restore error: $e");
      debugPrint(stackTrace.toString());
      _isInitialized = true;
      notifyListeners();
      return false;
    }
  }

  Future<bool> _refreshCustomerFromBackend() async {
    try {
      debugPrint("🔄 [UserProvider] Refreshing customer from backend...");

      final token = await authService.getIdToken();
      if (token == null) {
        debugPrint("❌ No valid token");
        return false;
      }

      // Gunakan getAll dengan email dari authService jika tersedia
      final email = authService.email;
      if (email == null) {
        debugPrint("❌ No email available");
        return false;
      }

      final customers = await _customerService.getAll(email: email);
      if (customers.isNotEmpty) {
        _customer = customers.first;
        await _saveCustomerData();
        notifyListeners();
        debugPrint("✅ Customer refreshed: ${_customer!.namaDisplay}");
        return true;
      }

      debugPrint("❌ No customer data from backend");
      return false;
    } catch (e) {
      debugPrint("❌ [UserProvider] Backend refresh error: $e");
      return false;
    }
  }

  // =========================================================
  // 🚪 LOGOUT
  // =========================================================

  Future<void> logout() async {
    try {
      debugPrint("🚪 [UserProvider] Logging out...");

      // Hapus token dari storage + disconnect Google
      await authService.signOut();
      await _clearUserData();
      clear();
      apiClient.clearRole();

      debugPrint("✅ [UserProvider] Logout complete");
      notifyListeners();
    } catch (e) {
      debugPrint("❌ [UserProvider] Logout error: $e");
      clear();
      notifyListeners();
    }
  }

  Future<void> logoutAndSwitchAccount() async {
    try {
      debugPrint("🔄 [UserProvider] Switching account...");

      // disconnect → user HARUS pilih akun lagi
      await authService.disconnect();
      await _clearUserData();
      clear();
      apiClient.clearRole();

      debugPrint("✅ [UserProvider] Account switch complete");
      notifyListeners();
    } catch (e) {
      debugPrint("❌ [UserProvider] Switch account error: $e");
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
    debugPrint("✅ [UserProvider] Role set: $role");
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
    debugPrint("🔄 [UserProvider] Force refresh...");
    await _refreshCustomerFromBackend();
  }

  void printDebugState() {
    debugPrint("═══ UserProvider State ═══");
    debugPrint("Customer: ${_customer?.namaDisplay ?? 'null'}");
    debugPrint("Role: $_role");
    debugPrint("Is logged in: $isLoggedIn");
    debugPrint("Is loading: $_isLoading");
    debugPrint("Error: $_error");
    debugPrint("Initialized: $_isInitialized");
    if (_userBox != null) {
      debugPrint("Storage - Is logged in: ${_userBox!.get(_keyIsLoggedIn)}");
      debugPrint("Storage - Role: ${_userBox!.get(_keyRole)}");
      debugPrint("Storage - Last sync: ${_userBox!.get(_keyLastSync)}");
    }
    debugPrint("═══════════════════════════");
  }
}
