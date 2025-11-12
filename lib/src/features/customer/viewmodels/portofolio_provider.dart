import 'package:flutter/material.dart';
import 'package:mpjnew/src/data/models/portofolio_model.dart';
import 'package:mpjnew/src/features/auth/services/user_provider.dart';
import 'package:mpjnew/src/pages/fotografi_user/services/portofolio_service.dart';

class PortofolioProvider with ChangeNotifier {
  final PortofolioService portofolioService;
  final UserProvider userProvider;

  PortofolioProvider(
      {required this.portofolioService, required this.userProvider});

  // ===== Variables =====
  List<PortofolioModel> _portofolioList = [];
  bool _isLoadingPorto = true;
  String? _errorPorto;

  // ===== Getters =====
  List<PortofolioModel> get portofolioList => _portofolioList;
  bool get isLoadingPorto => _isLoadingPorto;
  String? get errorPorto => _errorPorto;

  // ===== Actions =====

  /// Ambil data portofolio dari API
  Future<void> loadPortofolio({
    String status = 'aktif',
    String untukKeperluan = 'home',
  }) async {
    _isLoadingPorto = true;
    _errorPorto = null;
    print("==== Memuat portofolio...");
    notifyListeners();

    try {
      // Ambil userId jika role = customer
      final role = userProvider.role;
      final userId = role == 'customer' ? userProvider.userId : null;

      print("==== USER ID: $userId");

      // Panggil service untuk ambil data
      print("==== Memuat getall portofolio...");
      final result = await portofolioService.getAll(
        id_customer: userId,
        status: status,
        untuk_keperluan: untukKeperluan,
      );
      print("CEK MEDIA URL ${result.first.mediaUrls.first.url}");

      _portofolioList = result;
    } catch (e) {
      debugPrint("⚠️ Error memuat portofolio: $e");
      _errorPorto = "Error memuat portofolio";
    } finally {
      _isLoadingPorto = false;
      print("==== Selesai memuat portofolio");
      notifyListeners();
    }
  }

  /// Refresh data portofolio (misal dari pull-to-refresh)
  Future<void> refresh() async {
    await loadPortofolio();
  }
}
