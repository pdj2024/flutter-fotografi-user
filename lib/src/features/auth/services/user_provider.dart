import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/constants/login_status.dart';
import 'package:mpjnew/src/core/services/api_singleton.dart';
import 'package:mpjnew/src/data/models/customer_model.dart';
import 'package:mpjnew/src/features/auth/services/auth_service.dart';
import 'package:mpjnew/src/features/customer/services/customer_service.dart';
import 'package:mpjnew/src/features/customer/services/device_token_service.dart';
import 'package:mpjnew/src/features/customer/services/vendor_service.dart';

class UserProvider with ChangeNotifier {
  // ✅ Gunakan singleton AuthService
  final AuthService _authService = AuthService();
  final CustomerService _customerService;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  UserProvider({
    required CustomerService customerService,
    required VendorService vendorService,
  }) : _customerService = customerService;

  DeviceTokenService get deviceTokenService => DeviceTokenService();

  // 🔑 Storage Keys
  static const String _keyRole = 'user_role';
  static const String _keyCustomer = 'user_customer_data';
  static const String _keyIsLoggedIn = 'user_is_logged_in';

  String _role = 'customer';
  String? _photoUrl;
  CustomerModel? _customer;

  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  String? get role => _role;
  String? get photoUrl => _photoUrl;
  CustomerModel? get customer => _customer;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInitialized => _isInitialized;

  // ✅ Getter yang lebih akurat
  bool get isLoggedIn => _customer != null && _authService.isLoggedIn;

  String? get userId => _customer?.noId;

  String get displayName => _customer?.namaDisplay ?? '';

  void setRole(String role) {
    _role = role;
    apiClient.setRole(role);
    notifyListeners();
  }

  void setPhotoUrl(String photoUrl) {
    _photoUrl = photoUrl;
    notifyListeners();
  }

  // =========================================================
  // 💾 SAVE & LOAD USER DATA
  // =========================================================
  Future<void> _saveCustomerData() async {
    try {
      if (_customer != null) {
        final customerJson = jsonEncode(_customer!.toJson());
        await _storage.write(key: _keyCustomer, value: customerJson);
        await _storage.write(key: _keyIsLoggedIn, value: 'true');
      }
      await _storage.write(key: _keyRole, value: _role);

      print("💾 [UserProvider] Customer data tersimpan");
    } catch (e) {
      print("❌ [UserProvider] Error save customer data: $e");
    }
  }

  Future<void> loadUserData() async {
    try {
      print("🔄 [UserProvider] Loading user data dari storage...");

      final customerJson = await _storage.read(key: _keyCustomer);
      if (customerJson != null && customerJson.isNotEmpty) {
        try {
          final customerMap = jsonDecode(customerJson);
          _customer = CustomerModel.fromJson(customerMap);
          print("✅ [UserProvider] Customer data loaded: ${_customer?.namaDisplay}");
        } catch (e) {
          print("❌ [UserProvider] Error parsing customer JSON: $e");
          await _storage.delete(key: _keyCustomer);
          _customer = null;
        }
      } else {
        _customer = null;
      }

      final savedRole = await _storage.read(key: _keyRole);
      if (savedRole != null && savedRole.isNotEmpty) {
        _role = savedRole;
        apiClient.setRole(_role);
      }

      _isInitialized = true;
      notifyListeners();
    } catch (e, stackTrace) {
      print("❌ [UserProvider] Error load user data: $e");
      print(stackTrace);
      _customer = null;
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> _clearUserData() async {
    try {
      await _storage.delete(key: _keyCustomer);
      await _storage.delete(key: _keyRole);
      await _storage.delete(key: _keyIsLoggedIn);

      print("🗑️ [UserProvider] User data dihapus dari storage");
    } catch (e) {
      print("❌ [UserProvider] Error clear user data: $e");
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

      // 1️⃣ Login ke Google
      final idToken = await _authService.login(silent: silent);

      if (idToken == null) {
        print("❌ [UserProvider] Login gagal, token null");
        // ✅ JANGAN logout di sini jika silent login gagal
        if (!silent) {
          await _clearUserData();
          clear();
        }
        return GoogleLoginStatus.tokenInvalid;
      }

      print("✅ [UserProvider] Token didapat, cek status di backend...");

      // 2️⃣ Check status di backend
      final result = await _customerService.checkGoogleLogin();

      // 3️⃣ Handle status CREATED
      if (result.status == GoogleLoginStatus.created) {
        setRole(role);
        _customer = result.customer;
        await _saveCustomerData();
        notifyListeners();
        return GoogleLoginStatus.created;
      }

      // 4️⃣ Handle status AKTIF
      if (result.status == GoogleLoginStatus.aktif && result.customer != null) {
        _customer = result.customer!;
        await _saveCustomerData();

        await deviceTokenService.addDeviceToken(_customer!.noId);
        setRole(role);

        print("✅ [UserProvider] User aktif: ${_customer!.namaDisplay}");
        notifyListeners();
        return GoogleLoginStatus.aktif;
      }

      print("⚠️ [UserProvider] Status: ${result.status}");
      return result.status;
    } catch (e, stackTrace) {
      _error = "Login gagal: $e";
      print("❌ [UserProvider] Error checkLoginGoogle: $e");
      print(stackTrace);
      notifyListeners();
      return GoogleLoginStatus.error;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> restoreSession() async {
    try {
      print("🔄 [UserProvider] Attempting to restore session...");

      final sessionRestored = await _authService.restoreSession();

      if (!sessionRestored) {
        print("❌ [UserProvider] Session tidak bisa di-restore");
        _customer = null;
        _isInitialized = true;
        notifyListeners();
        return false;
      }

      await loadUserData();

      if (_customer == null) {
        print("⚠️ [UserProvider] Customer data tidak ada, coba refresh dari backend");

        try {
          final result = await _customerService.checkGoogleLogin();
          if (result.customer != null) {
            _customer = result.customer;
            await _saveCustomerData();
            notifyListeners();
            print("✅ [UserProvider] Customer data di-refresh: ${_customer!.namaDisplay}");
            return true;
          } else {
            print("❌ [UserProvider] Gagal mendapatkan data customer dari backend");
            return false;
          }
        } catch (e) {
          print("❌ [UserProvider] Gagal refresh dari backend: $e");
          return false;
        }
      }

      print("✅ [UserProvider] Session restored: ${_customer!.namaDisplay}");
      return true;
    } catch (e, stackTrace) {
      print("❌ [UserProvider] Error restore session: $e");
      print(stackTrace);
      _isInitialized = true;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      print("🚪 [UserProvider] Logging out...");

      // 1️⃣ Remove device token
      if (_customer != null) {
        try {
          await deviceTokenService.removeDeviceToken(_customer!.noId);
        } catch (e) {
          print("⚠️ [UserProvider] Error remove device token: $e");
        }
      }

      // 2️⃣ Logout dari AuthService
      await _authService.logout();

      // 3️⃣ Clear semua data
      await _clearUserData();
      clear();

      apiClient.clearRole();

      print("✅ [UserProvider] Logout berhasil");
      notifyListeners();
    } catch (e) {
      print("❌ [UserProvider] Error logout: $e");
      clear();
      notifyListeners();
    }
  }

  /// ✅ Logout dan ganti akun
  Future<void> logoutAndSwitchAccount() async {
    try {
      print("🔄 [UserProvider] Logout dan ganti akun...");

      if (_customer != null) {
        try {
          await deviceTokenService.removeDeviceToken(_customer!.noId);
        } catch (e) {
          print("⚠️ [UserProvider] Error remove device token: $e");
        }
      }

      await _authService.logoutAndRevoke();
      await _clearUserData();
      clear();
      apiClient.clearRole();

      print("✅ [UserProvider] Logout dan revoke berhasil");
      notifyListeners();
    } catch (e) {
      print("❌ [UserProvider] Error logoutAndSwitchAccount: $e");
      clear();
      notifyListeners();
    }
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
}