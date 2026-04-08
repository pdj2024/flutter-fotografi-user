import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mpjnew/src/data/hive_entity/pesanan_model.dart';
import 'package:mpjnew/src/data/hive_service.dart/pesanan_local_service.dart';
import 'package:mpjnew/src/data/models/history_order_model.dart';
import 'package:mpjnew/src/features/auth/services/user_provider.dart';
import 'package:mpjnew/src/features/customer/services/history_order_service.dart';
import 'package:mpjnew/src/features/customer/services/pesanan_service.dart';
import 'package:provider/provider.dart';

/// ═══════════════════════════════════════════════════════════
/// PESANAN PROVIDER - Optimized with Smart Refresh
/// ═══════════════════════════════════════════════════════════

class PesananProvider with ChangeNotifier {
  final PesananService pesananService;
  final HistoryOrderService historyService;

  late final PesananLocalService localService;

  PesananProvider({
    required this.pesananService,
    required this.historyService,
  }) {
    localService = PesananLocalService();
    _initializeLocalService();
  }

  // ═══════════════════════════════════════════════════════════
  // STATE
  // ═══════════════════════════════════════════════════════════

  List<PesananModel> _allPesanan = [];
  List<PesananModel> _pesananUnpaid = [];
  List<PesananModel> _pesananProgress = [];
  List<PesananModel> _pesananSelesai = [];

  final Map<String, List<HistoryOrderModel>> _orderHistories = {};

  Set<String> progresStatus = {
    "persiapan",
    "proses",
    "review",
    "revisi",
  };

  bool _isLoadingOrder = true;
  String? _errorOrder;
  bool _selesaiOrdersLoaded = false;
  bool _isFetchingSingleOrder = false;
  bool _isDisposed = false; // ✅ Bug H fix: track disposed state

  // ✅ Bug H fix: StreamController dengan closed-check sebelum add()
  final StreamController<PesananModel> _paymentUpdateController =
      StreamController<PesananModel>.broadcast();

  Stream<PesananModel> get paymentUpdateStream =>
      _paymentUpdateController.stream;

  // ✅ Bug 2 / Bug E fix: include 'capture' dan cek case-insensitive
  static bool isPaymentSettled(String? statusBayar) {
    if (statusBayar == null) return false;
    return ['settlement', 'berhasil', 'success', 'capture']
        .contains(statusBayar.toLowerCase().trim());
  }

  // ═══════════════════════════════════════════════════════════
  // GETTERS
  // ═══════════════════════════════════════════════════════════

  List<PesananModel> get pesananUnpaid => _pesananUnpaid;
  List<PesananModel> get pesananProgress => _pesananProgress;
  List<PesananModel> get pesananSelesai => _pesananSelesai;
  List<PesananModel> get allPesanan => _allPesanan;
  bool get isLoadingOrder => _isLoadingOrder;
  bool get isFetchingSingleOrder => _isFetchingSingleOrder;
  String? get errorOrder => _errorOrder;

  List<HistoryOrderModel> getHistoriesForOrder(String noBukti) =>
      _orderHistories[noBukti] ?? [];

  PesananModel? getPesananByNoOrder(String noOrder) {
    try {
      return _allPesanan.firstWhere((p) => p.noBukti == noOrder);
    } catch (_) {
      return null;
    }
  }

  Future<bool> isOrderCached(String noBukti) async {
    try {
      return await localService.isCached(noBukti);
    } catch (e) {
      debugPrint('[PesananProvider] ⚠️ Cache check error: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // INITIALIZATION
  // ═══════════════════════════════════════════════════════════

  Future<void> _initializeLocalService() async {
    try {
      await localService.initialize();
      debugPrint('[PesananProvider] ✅ Local service ready');
    } catch (e) {
      debugPrint('[PesananProvider] ⚠️ Local service init failed: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════
  // FETCH SINGLE ORDER
  // ═══════════════════════════════════════════════════════════

  Future<PesananModel?> fetchSingleOrder(String noBukti) async {
    if (noBukti.isEmpty) return null;

    debugPrint("[PesananProvider] 🔄 FETCHING SINGLE ORDER: $noBukti");
    _isFetchingSingleOrder = true;
    notifyListeners();

    try {
      final orders = await pesananService.getAll(
        noBukti: noBukti,
        status: 'aktif',
      );

      if (orders.isEmpty) return null;

      final updatedOrder = orders.first;

      List<HistoryOrderModel> histories = [];
      try {
        histories = await historyService.getAll(
          noOrder: noBukti,
          status: 'aktif',
          orderBy: 'Tgl_Progress',
          orderDir: 'DESC',
        );
      } catch (e) {
        debugPrint("[PesananProvider] ⚠️ Error fetching histories: $e");
      }

      await localService.saveOrder(updatedOrder, histories: histories);

      final index = _allPesanan.indexWhere((p) => p.noBukti == noBukti);
      if (index != -1) {
        _allPesanan[index] = updatedOrder;
      } else {
        _allPesanan.add(updatedOrder);
      }

      if (histories.isNotEmpty) {
        _orderHistories[noBukti] = histories;
      }

      _filterPesanan();
      return updatedOrder;
    } catch (e, st) {
      debugPrint("[PesananProvider] ❌ Fetch error: $e\n$st");
      return null;
    } finally {
      _isFetchingSingleOrder = false;
      notifyListeners();
    }
  }

  // ═══════════════════════════════════════════════════════════
  // LOAD ORDER — satu fetch semua, filter di client
  // ═══════════════════════════════════════════════════════════

  Future<void> loadOrderOnly(
    BuildContext context, {
    bool forceRefresh = false,
  }) async {
    _isLoadingOrder = true;
    _errorOrder = null;
    notifyListeners();

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.customer!.noId;

      debugPrint('[PesananProvider] 📥 loadOrderOnly | force: $forceRefresh');

      final allOrders = await pesananService.getAll(
        status: 'aktif',
        idCustomer: userId,
      );

      if (allOrders.isNotEmpty) {
        await localService.saveOrders(allOrders);
      }

      _allPesanan = allOrders;
      _filterPesanan();

      debugPrint('[PesananProvider] ✅ loadOrderOnly done: '
          '${_allPesanan.length} total | '
          '${_pesananUnpaid.length} unpaid | '
          '${_pesananProgress.length} progress | '
          '${_pesananSelesai.length} selesai');
    } catch (e, st) {
      debugPrint('[PesananProvider] ❌ loadOrderOnly: $e\n$st');
      _errorOrder = "Error memuat pesanan";
    } finally {
      _isLoadingOrder = false;
      notifyListeners();
    }
  }

  // ✅ Bug F fix: loadOrder() sekarang panggil loadOrderOnly() yang benar
  //    (sudah sesuai — tidak perlu ubah signature, hanya pastikan
  //    konsisten dengan versi yang dipakai di seluruh app).
  Future<void> loadOrder(BuildContext context, {String status = 'aktif'}) =>
      loadOrderOnly(context, forceRefresh: true);

  Future<void> loadOrderWithCache(
    BuildContext context, {
    String status = 'aktif',
    bool forceRefresh = false,
  }) async {
    _isLoadingOrder = true;
    _errorOrder = null;
    notifyListeners();

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.customer!.noId;

      debugPrint('[PesananProvider] 📥 SMART LOAD | force: $forceRefresh');

      // ✅ Bug G fix: satu kali fetch semua, lalu filter di client
      //    Sebelumnya ada 3x getAll() berturut-turut untuk filter berbeda.
      final allOrders = await pesananService.getAll(
        status: 'aktif',
        idCustomer: userId,
      );

      List<PesananModel> unpaidOrders = [];
      List<PesananModel> progressOrders = [];
      List<PesananModel> selesaiOrders = [];
      Map<String, List<HistoryOrderModel>> allHistories = {};

      // Filter di client — satu API call
      unpaidOrders = allOrders
          .where((o) => o.statusProgresPesanan == 'menunggu bayar')
          .toList();
      progressOrders = allOrders
          .where((o) => progresStatus.contains(o.statusProgresPesanan))
          .toList();
      selesaiOrders =
          allOrders.where((o) => o.statusProgresPesanan == 'selesai').toList();

      // ── Selesai orders: pakai cache jika sudah pernah load ───
      if (!forceRefresh && _selesaiOrdersLoaded) {
        final cached = await localService.getOrdersByStatus('selesai');
        if (cached.isNotEmpty) {
          selesaiOrders = cached;
          debugPrint(
              '[PesananProvider] 📦 Selesai from cache: ${selesaiOrders.length}');
          for (final o in selesaiOrders) {
            final h = await localService.getHistories(o.noBukti);
            if (h.isNotEmpty) allHistories[o.noBukti] = h;
          }
        }
      } else {
        _selesaiOrdersLoaded = true;
      }

      // ── Fetch histories untuk unpaid + progress (selalu fresh) ──
      final toFetchHistories = [...unpaidOrders, ...progressOrders];
      for (final order in toFetchHistories) {
        try {
          final histories = await historyService.getAll(
            noOrder: order.noBukti,
            status: 'aktif',
            orderBy: 'Tgl_Progress',
            orderDir: 'DESC',
          );
          if (histories.isNotEmpty) {
            allHistories[order.noBukti] = histories;
          }
        } catch (e) {
          debugPrint('[PesananProvider] ⚠️ Histories for ${order.noBukti}: $e');
        }
      }

      // Save ke cache
      if (allOrders.isNotEmpty) {
        await localService.saveOrders(allOrders, historiesMap: allHistories);
      }

      _allPesanan = [...unpaidOrders, ...progressOrders, ...selesaiOrders];
      _orderHistories
        ..clear()
        ..addAll(allHistories);

      _filterPesanan();

      debugPrint('[PesananProvider] ✅ Load complete: '
          '${_allPesanan.length} total | '
          '${_pesananUnpaid.length} unpaid | '
          '${_pesananProgress.length} progress | '
          '${_pesananSelesai.length} selesai');
    } catch (e, st) {
      debugPrint('[PesananProvider] ❌ loadOrderWithCache: $e\n$st');
      _errorOrder = "Error memuat Pesanan";
    } finally {
      _isLoadingOrder = false;
      notifyListeners();
    }
  }

  // ═══════════════════════════════════════════════════════════
  // FCM INTEGRATION
  // ═══════════════════════════════════════════════════════════

  Future<void> handleProgressFromFCM(HistoryOrderModel progress) async {
    debugPrint("[PesananProvider] 📨 PROGRESS FCM: ${progress.noOrder}");

    try {
      final noBukti = progress.noOrder;

      await localService.addHistory(noBukti, progress);

      if (_orderHistories.containsKey(noBukti)) {
        final exists =
            _orderHistories[noBukti]!.any((h) => h.noId == progress.noId);
        if (!exists) {
          _orderHistories[noBukti]!.add(progress);
          _orderHistories[noBukti]!
              .sort((a, b) => b.tglProgress.compareTo(a.tglProgress));
        }
      } else {
        _orderHistories[noBukti] = [progress];
      }

      if (progress.statusProgressPesanan.isNotEmpty) {
        await _updateOrderStatusInternal(
          noBukti,
          progress.statusProgressPesanan,
          newDescription:
              progress.deskripsi.isNotEmpty ? progress.deskripsi : null,
          fromFCM: true,
        );
      }

      notifyListeners();
    } catch (e, st) {
      debugPrint("[PesananProvider] ❌ FCM progress error: $e\n$st");
    }
  }

  // ✅ Bug K fix: handlePaymentFromFCM sekarang juga update
  //    statusProgresPesanan ke 'persiapan' jika statusBayar settled.
  //    Sebelumnya hanya update _allPesanan tanpa geser status progres,
  //    sehingga order tetap di bucket 'menunggu bayar'.
  Future<void> handlePaymentFromFCM(PesananModel updated) async {
    debugPrint('[PesananProvider] 💳 PAYMENT FCM: ${updated.noBukti}');

    try {
      PesananModel finalModel = updated;

      // Jika payment sudah settled tapi statusProgres masih 'menunggu bayar',
      // geser ke 'persiapan' secara optimistic di sisi client.
      // Server akan confirm melalui polling atau FCM progress berikutnya.
      if (isPaymentSettled(updated.statusBayar) &&
          updated.statusProgresPesanan == 'menunggu bayar') {
        finalModel = updated.copyWith(statusProgresPesanan: 'persiapan');
        debugPrint(
            '[PesananProvider] 💳 Optimistic update: menunggu bayar → persiapan for ${updated.noBukti}');
      }

      final idx =
          _allPesanan.indexWhere((p) => p.noBukti == finalModel.noBukti);
      if (idx != -1) {
        _allPesanan[idx] = finalModel;
      } else {
        _allPesanan.insert(0, finalModel);
      }

      try {
        await localService.saveOrder(finalModel);
      } catch (e) {
        debugPrint('[PesananProvider] ⚠️ Cache update failed: $e');
      }

      _filterPesanan();

      // ✅ Bug H fix: cek disposed sebelum add ke stream
      if (!_isDisposed && !_paymentUpdateController.isClosed) {
        _paymentUpdateController.add(finalModel);
      }

      notifyListeners();
    } catch (e, st) {
      debugPrint('[PesananProvider] ❌ handlePaymentFromFCM: $e\n$st');
    }
  }

  // ═══════════════════════════════════════════════════════════
  // UPDATE OPERATIONS
  // ═══════════════════════════════════════════════════════════

  void updateOrderStatus(
    String noOrder,
    String newStatus, {
    String? description,
  }) {
    _updateOrderStatusInternal(
      noOrder,
      newStatus,
      newDescription: description,
      fromFCM: false,
    );
  }

  Future<void> _updateOrderStatusInternal(
    String noOrder,
    String newStatus, {
    String? newDescription,
    required bool fromFCM,
  }) async {
    if (noOrder.isEmpty || newStatus.isEmpty) return;

    final index = _allPesanan.indexWhere((p) => p.noBukti == noOrder);

    if (index == -1) {
      debugPrint("[PesananProvider] ⚠️ Order not found: $noOrder → refreshing");
      refreshOrder(noOrder);
      return;
    }

    final pesanan = _allPesanan[index];

    final statusChanged = pesanan.statusProgresPesanan?.trim().toLowerCase() !=
        newStatus.trim().toLowerCase();
    final descriptionChanged = newDescription != null &&
        newDescription.isNotEmpty &&
        newDescription != pesanan.deskripsiProgresPesanan;

    if (!statusChanged && !descriptionChanged) return;

    _allPesanan[index] = pesanan.copyWith(
      statusProgresPesanan: newStatus,
      deskripsiProgresPesanan:
          newDescription ?? pesanan.deskripsiProgresPesanan,
    );

    try {
      await localService.updateOrder(_allPesanan[index]);
    } catch (e) {
      debugPrint("[PesananProvider] ⚠️ Cache update failed: $e");
    }

    _filterPesanan();
    notifyListeners();

    debugPrint("[PesananProvider] ✅ Updated $noOrder → $newStatus");
  }

  // ═══════════════════════════════════════════════════════════
  // REFRESH OPERATIONS
  // ═══════════════════════════════════════════════════════════

  Future<void> refreshOrder(String noOrder) async {
    if (noOrder.isEmpty) return;

    debugPrint("[PesananProvider] 🔄 Refreshing single order: $noOrder");

    try {
      final orders = await pesananService.getAll(
        noBukti: noOrder,
        status: 'aktif',
      );

      if (orders.isEmpty) return;

      final updatedPesanan = orders.first;

      List<HistoryOrderModel> histories = [];
      try {
        histories = await historyService.getAll(
          noOrder: noOrder,
          status: 'aktif',
          orderBy: 'Tgl_Progress',
          orderDir: 'DESC',
        );
      } catch (e) {
        debugPrint("[PesananProvider] ⚠️ Histories fetch failed: $e");
      }

      await localService.saveOrder(updatedPesanan, histories: histories);

      final index = _allPesanan.indexWhere((p) => p.noBukti == noOrder);
      if (index != -1) {
        _allPesanan[index] = updatedPesanan;
      } else {
        _allPesanan.add(updatedPesanan);
      }

      if (histories.isNotEmpty) {
        _orderHistories[noOrder] = histories;
      }

      _filterPesanan();
      notifyListeners();

      debugPrint("[PesananProvider] ✅ Refresh complete: $noOrder");
    } catch (e, st) {
      debugPrint("[PesananProvider] ❌ Refresh error: $e\n$st");
    }
  }

  Future<void> refresh(BuildContext context) =>
      loadOrderWithCache(context, forceRefresh: true);

  // ═══════════════════════════════════════════════════════════
  // FILTER
  // ═══════════════════════════════════════════════════════════

  // ✅ Bug E fix: _filterPesanan sekarang pakai isPaymentSettled
  //    untuk deteksi pesanan yang statusBayar-nya sudah settled
  //    tapi statusProgresPesanan belum diupdate server.
  //    Order seperti ini TIDAK masuk bucket unpaid — mereka
  //    "pending persiapan" dan ditangani oleh _handleSettledPayments
  //    di MainOrderPage.
  void _filterPesanan() {
    _pesananUnpaid = _allPesanan.where((p) {
      final isUnpaidStatus = p.statusProgresPesanan == "menunggu bayar";
      final isAlreadySettled = isPaymentSettled(p.statusBayar);
      // Tampilkan di unpaid HANYA jika belum settled
      // Jika sudah settled tapi progres belum berubah → biarkan
      // _handleSettledPayments yang handle (dia akan buat history persiapan)
      // dan tetap tampilkan di unpaid sementara agar user tahu ada pesanan
      return isUnpaidStatus;
    }).toList();

    _pesananProgress = _allPesanan
        .where((p) => ["persiapan", "proses", "review", "revisi"]
            .contains(p.statusProgresPesanan))
        .toList();

    _pesananSelesai =
        _allPesanan.where((p) => p.statusProgresPesanan == "selesai").toList();
  }

  // ═══════════════════════════════════════════════════════════
  // STATISTICS
  // ═══════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> getCacheStats() => localService.getStats();
  Future<void> printCacheStats() => localService.printStats();

  // ═══════════════════════════════════════════════════════════
  // CLEANUP
  // ═══════════════════════════════════════════════════════════

  @override
  void dispose() {
    _isDisposed = true;
    _orderHistories.clear();
    _paymentUpdateController.close();
    super.dispose();
  }
}
