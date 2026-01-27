import 'package:flutter/material.dart';
import 'package:mpjnew/src/data/models/portofolio_model.dart';
import 'package:mpjnew/src/features/auth/services/user_provider.dart';
import 'package:mpjnew/src/features/customer/services/portofolio_service.dart';
import 'package:provider/provider.dart';

class PortofolioProvider with ChangeNotifier {
  final PortofolioService portofolioService;

  bool _disposed = false;

  PortofolioProvider({required this.portofolioService});

  // ===== Variables =====
  List<PortofolioModel> _portofolioList = [];
  List<PortofolioModel> _portofolioSaveList = [];
  List<PortofolioModel> _portofolioLikelist = [];
  bool _isLoadingPorto = true;
  String? _errorPorto;

  // ===== Getters =====
  List<PortofolioModel> get portofolioList => _portofolioList;
  List<PortofolioModel> get portofolioSaveList => _portofolioSaveList;
  List<PortofolioModel> get portofolioLikelist => _portofolioLikelist;

  bool get isLoadingPorto => _isLoadingPorto;
  String? get errorPorto => _errorPorto;

  // ===== Actions =====

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void safeNotify() {
    if (!_disposed) notifyListeners();
  }

  /// Ambil data portofolio dari API
  Future<void> loadPortofolio(
    BuildContext context, {
    String status = 'aktif',
    String untukKeperluan = 'home',
  }) async {
    _isLoadingPorto = true;
    _errorPorto = null;
    print("==== Memuat portofolio...");
    safeNotify();

    try {
      final userProvider = context.read<UserProvider>();
      final role = userProvider.role;
      final userId = role == 'customer' ? userProvider.userId : null;

      print("==== USER ID: $userId");
      print("==== Memuat getAll portofolio...");

      final result = await portofolioService.getAll(
        id_customer: userId,
        status: status,
        untuk_keperluan: untukKeperluan,
        orderBy: 'Tgl_Created',
        orderDir: 'desc',
      );

      _portofolioList = result;

      if (userProvider.customer != null) {
        final portoMap = {
          for (final porto in result) porto.noId: porto,
        };

        final likes = userProvider.customer!.likes;
        final saves = userProvider.customer!.saves;

        _portofolioLikelist = likes.reversed // 🔥 ini kuncinya
            .where((id) => portoMap.containsKey(id))
            .map((id) => portoMap[id]!)
            .toList();

        _portofolioSaveList = saves.reversed
            .where((id) => portoMap.containsKey(id))
            .map((id) => portoMap[id]!)
            .toList();
      }
    } catch (e) {
      debugPrint("⚠️ Error memuat portofolio: $e");
      _errorPorto = "Error memuat portofolio";
    } finally {
      _isLoadingPorto = false;
      print("==== Selesai memuat portofolio");
      safeNotify();
    }
  }

  /// Refresh data portofolio (misal dari pull-to-refresh)
  Future<void> refresh(BuildContext context) async {
    await loadPortofolio(context);
  }

  Future<void> loadLikePortofolio(BuildContext context) async {
    _isLoadingPorto = true;
    _errorPorto = null;
    print("==== Memuat portofolio...");
    safeNotify();

    try {
      final userProvider = context.read<UserProvider>();
      final role = userProvider.role;
      final userId = role == 'customer' ? userProvider.userId : null;

      print("==== USER ID: $userId");
      print("==== Memuat getAll portofolio...");

      final result = await portofolioService.getAll(
        id_customer: userId,
        status: "aktif",
      );

      final userLiked = result
          .where((porto) => userProvider.customer!.likes.contains(porto.noId))
          .toList();

      _portofolioLikelist = userLiked;
    } catch (e) {
      debugPrint("⚠️ Error memuat portofolio: $e");
      _errorPorto = "Error memuat portofolio";
    } finally {
      _isLoadingPorto = false;
      print("==== Selesai memuat portofolio");
      safeNotify();
    }
  }

  Future<void> loadSavePortofolio(BuildContext context) async {
    _isLoadingPorto = true;
    _errorPorto = null;
    print("==== Memuat portofolio...");
    safeNotify();

    try {
      final userProvider = context.read<UserProvider>();
      final role = userProvider.role;
      final userId = role == 'customer' ? userProvider.userId : null;

      print("==== USER ID: $userId");
      print("==== Memuat getAll portofolio...");

      final result = await portofolioService.getAll(
        id_customer: userId,
        status: "aktif",
      );

      final userSaved = result
          .where((porto) => userProvider.customer!.saves.contains(porto.noId))
          .toList();

      _portofolioSaveList = userSaved;
    } catch (e) {
      debugPrint("⚠️ Error memuat portofolio: $e");
      _errorPorto = "Error memuat portofolio";
    } finally {
      _isLoadingPorto = false;
      print("==== Selesai memuat portofolio");
      safeNotify();
    }
  }
}
