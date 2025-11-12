import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/services/api_singleton.dart';
import 'package:mpjnew/src/features/auth/services/auth_service.dart';
import '../../../data/models/customer_model.dart';
import '../../../data/models/vendor_model.dart';
import '../../../pages/fotografi_user/services/customer_service.dart';
import '../../../pages/fotografi_user/services/vendor_service.dart'; // Untuk setRole()

class UserProvider with ChangeNotifier {
  final AuthService _authService;
  final CustomerService _customerService;
  final VendorService _vendorService;

  UserProvider({
    required AuthService authService,
    required CustomerService customerService,
    required VendorService vendorService,
  })  : _authService = authService,
        _customerService = customerService,
        _vendorService = vendorService;


  String? _role;
  CustomerModel? _customer;
  VendorModel? _vendor;

  bool _isLoading = false;
  String? _error;

  String? get role => _role;
  CustomerModel? get customer => _customer;
  VendorModel? get vendor => _vendor;
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool get isLoggedIn => _role != null;

    String? get userId {
    if (_role == 'customer') return _customer?.no_id;
    if (_role == 'vendor') return _vendor?.noId;
    return null;
  }

  String get displayName {
    if (_role == 'customer') return _customer?.nama_display ?? '';
    if (_role == 'vendor') return _vendor?.namaDisplay ?? '';
    return '';
  }

  void setRole(String role) {
  _role = role;
  apiClient.setRole(role); // tetap pastikan header ikut di-set
  notifyListeners();
}

  Future<void> checkLoginGoogle({required String role, bool silent = false}) async {
    _setLoading(true);
    _error = null;

    try {
      final idToken = await _authService.login(silent: silent);
      if (idToken == null) {
        _customer = null;
        _vendor = null;
        _role = null;
        return;
      }

     setRole(role); // atur X-Jenis-User: customer/vendor

      
      if (role == 'customer') {
        _customer = await _customerService.checkGoogleLogin();
        _vendor = null;
      } else if (role == 'vendor') {
        _vendor = await _vendorService.checkGoogleLogin();
        _customer = null;
      }
    } catch (e) {
      _error = "Login gagal: $e";
      print(_error);
    }

    _setLoading(false);
  }

    Future<void> logout() async {
    await _authService.logout();
    _customer = null;
    _vendor = null;
    _role = null;
    notifyListeners();
  }

    void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }


}