import 'dart:convert';

import 'package:mpjnew/src/core/services/api_singleton.dart';
import 'package:mpjnew/src/features/customer/services/customer_service.dart';

/// Cek keunikan username lintas tabel customer & vendor — backend sama,
/// tapi username dibagi dua tabel berbeda, jadi harus dicek keduanya.
class UsernameAvailabilityService {
  final CustomerService _customerService = CustomerService();

  /// [excludeNoId] supaya user yang menyimpan tanpa mengubah username
  /// sendiri tidak dianggap "sudah dipakai" oleh datanya sendiri.
  Future<bool> isTaken(String username, {String? excludeNoId}) async {
    final customerMatches =
        await _customerService.getByUsername(username: username);
    final takenByCustomer = customerMatches.any((c) => c.noId != excludeNoId);
    if (takenByCustomer) return true;
    return _isTakenInVendor(username);
  }

  Future<bool> _isTakenInVendor(String username) async {
    final response = await apiClient
        .get('/vendor/get-byUsername', queryParameters: {'username': username});
    if (response.statusCode == 204) return false;
    if (response.statusCode != 200) {
      throw Exception(
          'Gagal memeriksa username vendor (${response.statusCode})');
    }
    final data = jsonDecode(response.body)['Data'];
    if (data == null) return false;
    if (data is List) return data.isNotEmpty;
    if (data is Map) return true;
    return false;
  }
}
