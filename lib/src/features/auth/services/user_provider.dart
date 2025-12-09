import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/constants/login_status.dart';
import 'package:mpjnew/src/core/services/api_singleton.dart';
import 'package:mpjnew/src/core/services/google_login_result.dart';
import 'package:mpjnew/src/data/models/customer_model.dart';
import 'package:mpjnew/src/features/auth/services/auth_service.dart';
import 'package:mpjnew/src/features/customer/services/customer_service.dart';
import 'package:mpjnew/src/features/customer/services/vendor_service.dart';

class UserProvider with ChangeNotifier {
  final AuthService _authService;
  final CustomerService _customerService;

  UserProvider({
    required AuthService authService,
    required CustomerService customerService,
    required VendorService vendorService,
  })  : _authService = authService,
        _customerService = customerService;

  String? _role;
  String? _photoUrl;
  CustomerModel? _customer;

  bool _isLoading = false;
  String? _error;

  String? get role => _role;
  String? get photoUrl => _photoUrl;
  CustomerModel? get customer => _customer;
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool get isLoggedIn => _role != null;

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

  Future<GoogleLoginResult> checkLoginGoogle({
    required String role,
    bool silent = false,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      final idToken = await _authService.login(silent: silent);

      if (idToken == null) {
        await _authService.logout(); // fix terpenting
        _customer = null;
        _role = null;
        notifyListeners();
        return GoogleLoginResult(GoogleLoginStatus.tokenInvalid,
            customer: null);
      }

      final result = await _customerService.checkGoogleLogin();

      if (result.status == GoogleLoginStatus.created) {
        setRole(role);
        setPhotoUrl(authService.photoUrl ?? '');
        notifyListeners();
        return result;
      }

      if (result.status == GoogleLoginStatus.aktif && result.customer != null) {
        _customer = result.customer!;
        if (_customer!.namaDisplay == '') {
          _customer = _customer!.copyWith(namaDisplay: authService.displayName);
        }
        setPhotoUrl(authService.photoUrl ?? '');
        setRole(role);
        notifyListeners();
        return result;
      }

      return result;
    } catch (e) {
      _error = "Login gagal: $e";
      notifyListeners();

      return GoogleLoginResult(GoogleLoginStatus.error, customer: null);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _customer = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
