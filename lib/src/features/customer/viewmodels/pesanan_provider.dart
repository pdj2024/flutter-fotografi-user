import 'package:flutter/material.dart';
import 'package:mpjnew/src/data/models/pesanan_model.dart';
import 'package:mpjnew/src/features/customer/services/pesanan_service.dart';

class PesananProvider with ChangeNotifier {
  final PesananService pesananService;

  PesananProvider({required this.pesananService});

  List<PesananModel> _pesananBelumBayar = [];
  List<PesananModel> _pesananProgress = [];
  List<PesananModel> _pesananSelesai = [];

  List<PesananModel> get pesananBelumBayar => _pesananBelumBayar;
  List<PesananModel> get pesananProgress => _pesananProgress;
  List<PesananModel> get pesananSelesai => _pesananSelesai;

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  set isLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  String? _errorPesanan;
  String? get errorPesanan => _errorPesanan;
  set errorPesanan(String? value) {
    _errorPesanan = value;
    notifyListeners();
  }

  Future<void> loadOrder({
    required String userId,
    String? vendorId,
    String status = 'aktif',
  }) async {
    _isLoading = true;
    _errorPesanan = null;
    notifyListeners();

    try {
      final belumBayar = await pesananService.getAll(
        status: status,
        statusBayar: "belum bayar",
        idCustomer: userId,
        orderBy: "Created_At",
        orderDir: "desc",
      );
      _pesananBelumBayar = belumBayar;

      final progress = await pesananService.getAll(
        status: status,
        idCustomer: userId,
        orderBy: "Created_At",
        orderDir: "desc",
      );
      _pesananProgress = progress;

      final selesai = await pesananService.getAll(
        status: "nonaktif",
        idCustomer: userId,
        orderBy: "Created_At",
        orderDir: "desc",
      );
      _pesananSelesai = selesai;
    } catch (e) {
      _errorPesanan = "Error memuat Penawaran";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
