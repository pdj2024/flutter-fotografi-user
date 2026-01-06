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
  final AuthService _authService;
  final CustomerService _customerService;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  UserProvider({
    required AuthService authService,
    required CustomerService customerService,
    required VendorService vendorService,
  })  : _authService = authService,
        _customerService = customerService;

  DeviceTokenService get deviceTokenService => DeviceTokenService();

  // 🔑 Storage Keys
  static const String _keyRole = 'user_role';
  static const String _keyCustomer = 'user_customer_data';
  static const String _keyEmail = 'user_email';
  static const String _keyNamaDisplay = 'user_nama_display';

  String _role = 'customer';
  String? _photoUrl;
  CustomerModel? _customer;

  bool _isLoading = false;
  String? _error;

  String? get role => _role;
  String? get photoUrl => _photoUrl;
  CustomerModel? get customer => _customer;
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool get isLoggedIn => _customer != null;

  String? get userId {
    if (_role == 'customer') return _customer?.noId;
    return null;
  }

  String get displayName {
    if (_role == 'customer') return _customer?.namaDisplay ?? '';
    return '';
  }

  void setRole(String role) {
    _role = role;
    apiClient.setRole(role); // tetap pastikan header ikut di-set
    notifyListeners();
  }

  void setPhotoUrl(String photoUrl) {
    _photoUrl = photoUrl;
    notifyListeners();
  }

  // =========================================================
  // 💾 SAVE & LOAD USER DATA
  // =========================================================

  /// Simpan data vendor ke secure storage
  Future<void> _saveVendorData() async {
    try {
      if (_customer != null) {
        final customerJson = jsonEncode(_customer!.toJson());
        await _storage.write(key: _keyCustomer, value: customerJson);
        await _storage.write(key: _keyEmail, value: _customer?.email);
        await _storage.write(
            key: _keyNamaDisplay, value: _customer?.namaDisplay ?? "");
      }

      await _storage.write(key: _keyRole, value: _role);

      print("💾 User data tersimpan");
    } catch (e) {
      print("❌ Error save vendor data: $e");
    }
  }

  /// Load data customer dari secure storage
  Future<void> loadUserData() async {
    try {
      print("🔄 Loading user data dari storage...");

      // Load vendor data
      final customerJson = await _storage.read(key: _keyCustomer);
      if (customerJson != null && customerJson.isNotEmpty) {
        try {
          final vendorMap = jsonDecode(customerJson);
          _customer = CustomerModel.fromJson(vendorMap);
          print("✅ Vendor data loaded: ${_customer?.namaDisplay}");
        } catch (e) {
          print("❌ Error parsing vendor JSON: $e");
          // Hapus data corrupt
          await _storage.delete(key: _keyCustomer);
          _customer = null;
        }
      } else {
        print("⚠️ Vendor JSON kosong atau null");
        _customer = null;
      }

      // Load role
      final savedRole = await _storage.read(key: _keyRole);
      if (savedRole != null && savedRole.isNotEmpty) {
        _role = savedRole;
        apiClient.setRole(_role);
        print("✅ Role loaded: $_role");
      }

      print(
          "📊 Load Summary - Vendor: ${_customer?.namaDisplay}, Email: ${_customer?.email}, Role: $_role");

      notifyListeners();
    } catch (e, stackTrace) {
      print("❌ Error load vendor data: $e");
      print(stackTrace);
      // Reset state jika error
      _customer = null;
    }
  }

  /// Hapus semua data user dari storage
  Future<void> _clearUserData() async {
    try {
      await _storage.delete(key: _keyCustomer);
      await _storage.delete(key: _keyEmail);
      await _storage.delete(key: _keyNamaDisplay);
      await _storage.delete(key: _keyRole);

      print("🗑️ User data dihapus dari storage");
    } catch (e) {
      print("❌ Error clear user data: $e");
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
      print("🔐 checkLoginGoogle | role: $role, silent: $silent");

      // 1️⃣ Login ke Google
      final idToken = await _authService.login(silent: silent);

      if (idToken == null) {
        print("❌ Login gagal, token null");
        await logout();
        return GoogleLoginStatus.tokenInvalid;
      }

      print("✅ Token didapat, cek status di backend...");

      // 2️⃣ Check status di backend
      final result = await _customerService.checkGoogleLogin();

      // 3️⃣ Handle status CREATED (user baru)
      if (result.status == GoogleLoginStatus.created) {
        setRole(role);
        _customer = result.customer;

        await _saveVendorData();

        notifyListeners();
        return GoogleLoginStatus.created;
      }

      // 4️⃣ Handle status AKTIF
      if (result.status == GoogleLoginStatus.aktif && result.customer != null) {
        _customer = result.customer!;

        await _saveVendorData();

        // Register device token
        await deviceTokenService.addDeviceToken(_customer!.noId);

        setRole(role);

        print("✅ User aktif: ${_customer!.namaDisplay}");

        notifyListeners();
        return GoogleLoginStatus.aktif;
      }

      // 7️⃣ Handle status lainnya
      print("⚠️ Status: ${result.status}");
      return result.status;
    } catch (e, stackTrace) {
      _error = "Login gagal: $e";
      print("❌ Error checkLoginGoogle: $e");
      print(stackTrace);
      notifyListeners();
      return GoogleLoginStatus.error;
    } finally {
      _setLoading(false);
    }
  }

  /// Restore session dari storage dengan pengecekan lebih detail
  Future<bool> restoreSession() async {
    try {
      print("🔄 Attempting to restore session...");

      // 1️⃣ Restore session dari AuthService
      final sessionRestored = await _authService.restoreSession();

      if (!sessionRestored) {
        print("❌ Session tidak bisa di-restore");
        return false;
      }

      // 2️⃣ Load user data dari storage
      await loadUserData();

      // 3️⃣ Beri waktu untuk proses selesai
      await Future.delayed(Duration(milliseconds: 100));

      // 4️⃣ Validasi data customer
      if (_customer == null) {
        print(
            "⚠️ Customer data tidak ada setelah load, coba refresh dari backend");

        try {
          final result = await _customerService.checkGoogleLogin();
          if (result.customer != null) {
            _customer = result.customer;
            await _saveVendorData();
            notifyListeners();
            print(
                "✅ Customer data di-refresh dari backend: ${_customer!.namaDisplay}");
            return true;
          } else {
            print("❌ Gagal mendapatkan data customer dari backend");
            return false;
          }
        } catch (e) {
          print("❌ Gagal refresh dari backend: $e");
          return false;
        }
      }

      print("✅ Session restored successfully: ${_customer!.namaDisplay}");
      return true;
    } catch (e, stackTrace) {
      print("❌ Error restore session: $e");
      print(stackTrace);
      return false;
    }
  }

  Future<void> logout() async {
    try {
      print("🚪 Logging out...");

      // 1️⃣ Remove device token jika vendor ada
      if (_customer != null) {
        try {
          await deviceTokenService.removeDeviceToken(_customer!.noId);
        } catch (e) {
          print("⚠️ Error remove device token: $e");
        }
      }

      // 2️⃣ Logout dari AuthService
      await _authService.logout();

      // 3️⃣ Clear user data dari storage
      await _clearUserData();

      // 4️⃣ Clear state
      _customer = null;
      _role = Constants.vendor;
      _error = null;

      apiClient.clearRole();

      print("✅ Logout berhasil");
      notifyListeners();
    } catch (e) {
      print("❌ Error logout: $e");
      // Tetap clear state meskipun ada error
      _customer = null;
      notifyListeners();
    }
  }

  /// Clear semua data (untuk dipanggil dari NavigationProvider)
  void clear() {
    _customer = null;
    _role = Constants.customer;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
