import 'package:flutter/widgets.dart';
import 'package:mpjnew/src/data/models/kota_model.dart';
import 'package:mpjnew/src/features/customer/services/kota_service.dart';

class KotaProvider with ChangeNotifier {
  final KotaService _kotaService;

  KotaProvider(this._kotaService);

  List<KotaModel> _kotaList = [];
  bool _isLoading = false;
  String? _errorkota;

  // ===== Getters =====
  List<KotaModel> get kotaList => _kotaList;

  // ===== Actions =====

  /// Ambil data kategori dari API
  Future<void> getAllKotaList({String status = 'aktif'}) async {
    _isLoading = true;
    _errorkota = null;
    notifyListeners();

    try {
      // Panggil service
      final kotaList = await _kotaService.getAll(status: status);
      _kotaList = kotaList;
    } catch (e) {
      debugPrint("⚠️ Error memuat kategori: $e");
      _errorkota = "Error memuat kategori";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  KotaModel getKota(String value) {
    return _kotaList.firstWhere(
        (element) => element.noId == value || element.namaKota == value);
  }
}
