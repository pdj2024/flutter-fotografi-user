import 'package:flutter/material.dart';
import 'package:mpjnew/src/data/models/pesanan_model.dart';
import 'package:mpjnew/src/features/customer/services/pesanan_service.dart';

class PesananProvider with ChangeNotifier {
  final PesananService pesananService;

  PesananProvider({required this.pesananService});

  /// ALL DATA
  List<PesananModel> _allPesanan = [];

  /// FILTERED DATA
  List<PesananModel> _pesananUnpaid = [];
  List<PesananModel> _pesananProgress = [];
  List<PesananModel> _pesananSelesai = [];

  List<PesananModel> get pesananUnpaid => _pesananUnpaid;
  List<PesananModel> get pesananProgress => _pesananProgress;
  List<PesananModel> get pesananSelesai => _pesananSelesai;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorPesanan;
  String? get errorPesanan => _errorPesanan;

  /// ==============================
  /// LOAD ORDER (1x FETCH)
  /// ==============================
  Future<void> loadOrder({
    required String userId,
    String status = 'aktif',
  }) async {
    _isLoading = true;
    _errorPesanan = null;
    notifyListeners();
    print("📦 Memuat pesanan...");

    try {
      /// 🔥 FETCH SEKALI SAJA
      final result = await pesananService.getAll(
        idCustomer: userId,
        status: status,
        orderBy: "Created_At",
        orderDir: "desc",
      );

      _allPesanan = result;

      /// 🔽 FILTER DATA
      _filterPesanan();
    } catch (e) {
      _errorPesanan = "Error memuat pesanan";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// ==============================
  /// FILTER LOGIC
  /// ==============================
  void _filterPesanan() {
    _pesananUnpaid = _allPesanan.where((pesanan) {
      return pesanan.statusProgresPesanan == "menunggu bayar";
    }).toList();

    _pesananProgress = _allPesanan.where((pesanan) {
      return [
        "persiapan",
        "proses",
        "review",
        "revisi",
      ].contains(pesanan.statusProgresPesanan);
    }).toList();

    _pesananSelesai = _allPesanan.where((pesanan) {
      return pesanan.statusProgresPesanan == "selesai";
    }).toList();
  }
}
