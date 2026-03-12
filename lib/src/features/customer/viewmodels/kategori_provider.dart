import 'package:flutter/material.dart';
import 'package:mpjnew/src/data/models/kategori_model.dart';
import 'package:mpjnew/src/features/customer/services/kategori_service.dart';

class KategoriProvider with ChangeNotifier {
  final KategoriService _kategoriService;

  KategoriProvider(this._kategoriService);

  List<KategoriModel> _kategoriList = [];
  bool _showAllKategori = false;
  bool _isLoadingKategori = false;
  String? _errorKategori;
  int maxKategoriPerRow = 4;

  // ===== Getters =====
  List<KategoriModel> get kategoriList => _kategoriList;
  bool get showAllKategori => _showAllKategori;
  bool get isLoadingKategori => _isLoadingKategori;
  String? get errorKategori => _errorKategori;

// ===== Actions =====

  /// Ambil data kategori dari API
  Future<void> loadKategori(
      {String status = 'aktif', String? namaKategori}) async {
    _isLoadingKategori = true;

    _errorKategori = null;
    notifyListeners();

    try {
      // Panggil service
      final kList = await _kategoriService.getAll(
        status: status,
        namaKategori: namaKategori ?? "",
      );

      _kategoriList = kList;
    } catch (e) {
      debugPrint("⚠️ Error memuat kategori: $e");
      _errorKategori = "Error memuat kategori";
    } finally {
      _isLoadingKategori = false;
      notifyListeners();
    }
  }

  /// Ubah tampilan kategori (lihat semua / tutup)
  void toggleShowAllKategori() {
    _showAllKategori = !_showAllKategori;
    notifyListeners();
  }

  /// --- Fungsi Membagi Kategori ke dalam Baris ---
  List<List<KategoriModel>> get kategoriRows {
    List<List<KategoriModel>> rows = [];

    if (_kategoriList.isEmpty) return rows;

    for (int i = 0; i < _kategoriList.length;) {
      final remaining = _kategoriList.length - i;

      if (remaining == maxKategoriPerRow + 1) {
        rows.add(_kategoriList.sublist(i, i + 3));
        rows.add(_kategoriList.sublist(i + 3, i + 5));
        i += 5;
      } else {
        final take =
            remaining >= maxKategoriPerRow ? maxKategoriPerRow : remaining;
        rows.add(_kategoriList.sublist(i, i + take));
        i += take;
      }
    }

    return rows;
  }

  /// Reset kategori (misalnya saat logout)
  void clearKategori() {
    _kategoriList = [];
    _errorKategori = null;
    _isLoadingKategori = false;
    _showAllKategori = false;
    notifyListeners();
  }
}
