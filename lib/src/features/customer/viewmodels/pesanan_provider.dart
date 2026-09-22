import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  List<PesananModel> _pesananBatal = [];

  final Map<String, List<HistoryOrderModel>> _orderHistories = {};

  Set<String> progresStatus = {
    "persiapan",
    "proses",
    "review",
    "revisi",
  };

  /// Status yang dianggap "aktif" untuk tab Pesanan (bukan halaman Riwayat).
  /// Backend tidak punya filter "semua kecuali selesai/dibatalkan" dalam
  /// satu request, jadi ini di-fetch paralel satu per status.
  static const List<String> _activeStatuses = [
    'menunggu bayar',
    'persiapan',
    'proses',
    'review',
    'revisi',
  ];

  bool _isLoadingOrder = true;
  String? _errorOrder;

  // Guard: `loadOrder()` dipanggil dari main_menu.dart (background, saat
  // boot) DAN dari MainOrderPage._checkAndInit() (saat tab Pesanan pertama
  // dibuka) — dua momen yang sering nyaris bersamaan. Tanpa ini, keduanya
  // menembak fan-out 5 GET paralel yang sama dua kali berturut-turut.
  Future<void>? _loadOrderInFlight;
  bool _isLoadingFinished = false;
  String? _errorFinished;
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

  /// Order masih bisa dibatalkan customer — sebelum pengerjaan/pemotretan
  /// dimulai. Sumber tunggal aturan ini; dipakai di OrderHistoryCard (list)
  /// dan ComplainMenuAction (detail) supaya keduanya konsisten.
  static bool canCancel(PesananModel o) {
    final prog =
        (o.statusProgresPesanan ?? 'menunggu bayar').toLowerCase().trim();
    if (prog == 'menunggu bayar') return true;
    if (prog == 'persiapan') return isPaymentSettled(o.statusBayar);
    return false;
  }

  /// Order sudah dibayar (uang sudah masuk) sehingga pembatalan harus lewat
  /// jalur refund: tampilkan nominal pengembalian lalu minta rekening tujuan.
  ///
  /// Hanya `persiapan` — begitu pemotretan masuk tahap pengerjaan, pesanan
  /// tidak bisa dibatalkan sama sekali (lihat [canCancel]).
  static bool needsRefund(PesananModel o) {
    final prog =
        (o.statusProgresPesanan ?? 'menunggu bayar').toLowerCase().trim();
    return isPaymentSettled(o.statusBayar) && prog == 'persiapan';
  }

  // ═══════════════════════════════════════════════════════════
  // GETTERS
  // ═══════════════════════════════════════════════════════════

  List<PesananModel> get pesananUnpaid => _pesananUnpaid;
  List<PesananModel> get pesananProgress => _pesananProgress;
  List<PesananModel> get pesananSelesai => _pesananSelesai;
  List<PesananModel> get pesananBatal => _pesananBatal;
  List<PesananModel> get allPesanan => _allPesanan;
  bool get isLoadingOrder => _isLoadingOrder;
  bool get isFetchingSingleOrder => _isFetchingSingleOrder;
  String? get errorOrder => _errorOrder;
  bool get isLoadingFinished => _isLoadingFinished;
  String? get errorFinished => _errorFinished;

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
      );

      if (orders.isEmpty) return null;

      final updatedOrder = await _autoCompleteIfOverdue(orders.first);

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
  }) {
    final inFlight = _loadOrderInFlight;
    if (inFlight != null) {
      debugPrint('[PesananProvider] ⏸️ loadOrderOnly already in flight — join');
      return inFlight;
    }
    final future = _loadOrderOnlyImpl(context, forceRefresh: forceRefresh);
    _loadOrderInFlight = future;
    return future.whenComplete(() => _loadOrderInFlight = null);
  }

  Future<void> _loadOrderOnlyImpl(
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

      // Backend tidak punya filter "semua kecuali selesai/dibatalkan" dalam
      // satu request -- fetch paralel satu per status aktif. Selesai/batal
      // sekarang jadi tanggung jawab loadFinishedOrders() (dipanggil dari
      // halaman Riwayat), bukan di sini.
      final results =
          await Future.wait(_activeStatuses.map((s) => pesananService.getAll(
                idCustomer: userId,
                status: 'aktif',
                statusProgresPesanan: s,
                orderBy: 'Created_At',
                orderDir: 'desc',
              )));
      final allOrders = await _autoCompleteListIfOverdue(
          results.expand((list) => list).toList());

      _allPesanan = allOrders;
      _filterPesanan();

      // Status_Progress_Pesanan + Deskripsi_Progress_Pesanan sudah ikut di
      // setiap order dari getAll() -- tidak perlu lagi fetch timeline
      // history per order di sini. Timeline lengkap tetap lazy per halaman
      // Detail Order (HistoryOrderProvider).
      if (allOrders.isNotEmpty) {
        await localService.saveOrders(allOrders);
      }

      debugPrint('[PesananProvider] ✅ loadOrderOnly done: '
          '${_allPesanan.length} total | '
          '${_pesananUnpaid.length} unpaid | '
          '${_pesananProgress.length} progress');
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

      // Fetch paralel per status aktif -- lihat catatan di loadOrderOnly().
      final results =
          await Future.wait(_activeStatuses.map((s) => pesananService.getAll(
                idCustomer: userId,
                status: 'aktif',
                statusProgresPesanan: s,
                orderBy: 'Created_At',
                orderDir: 'desc',
              )));
      final allOrders = await _autoCompleteListIfOverdue(
          results.expand((list) => list).toList());

      if (allOrders.isNotEmpty) {
        await localService.saveOrders(allOrders);
      }

      _allPesanan = allOrders;
      _filterPesanan();

      debugPrint('[PesananProvider] ✅ Load complete: '
          '${_allPesanan.length} total | '
          '${_pesananUnpaid.length} unpaid | '
          '${_pesananProgress.length} progress');
    } catch (e, st) {
      debugPrint('[PesananProvider] ❌ loadOrderWithCache: $e\n$st');
      _errorOrder = "Error memuat Pesanan";
    } finally {
      _isLoadingOrder = false;
      notifyListeners();
    }
  }

  // ═══════════════════════════════════════════════════════════
  // LOAD FINISHED ORDERS — dipanggil dari FinishedOrderPage saat dibuka
  // ═══════════════════════════════════════════════════════════

  /// Order selesai/dibatalkan tidak selalu `status: 'aktif'` (order selesai
  /// pun bisa tetap `Status: "aktif"` di backend), jadi filternya cukup dari
  /// status_progress_pesanan saja, tanpa param `status`.
  Future<void> loadFinishedOrders(
    BuildContext context, {
    required DateTime start,
    required DateTime end,
  }) async {
    _isLoadingFinished = true;
    _errorFinished = null;
    notifyListeners();

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.customer!.noId;
      final fmt = DateFormat('yyyy-MM-dd');
      final tgl1 = fmt.format(start);
      final tgl2 = fmt.format(end);

      final results = await Future.wait([
        pesananService.getAll(
          idCustomer: userId,
          statusProgresPesanan: 'selesai',
          tglCreated1: tgl1,
          tglCreated2: tgl2,
          orderBy: 'Created_At',
          orderDir: 'desc',
        ),
        pesananService.getAll(
          idCustomer: userId,
          statusProgresPesanan: 'dibatalkan',
          tglCreated1: tgl1,
          tglCreated2: tgl2,
          orderBy: 'Created_At',
          orderDir: 'desc',
        ),
      ]);

      _pesananSelesai = results[0];
      _pesananBatal = results[1];

      final combined = [..._pesananSelesai, ..._pesananBatal];
      if (combined.isNotEmpty) {
        await localService.saveOrders(combined);
      }

      debugPrint('[PesananProvider] ✅ loadFinishedOrders: '
          '${_pesananSelesai.length} selesai | ${_pesananBatal.length} batal');
    } catch (e, st) {
      debugPrint('[PesananProvider] ❌ loadFinishedOrders: $e\n$st');
      _errorFinished = 'Error memuat riwayat pesanan';
    } finally {
      _isLoadingFinished = false;
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

      // Refresh full order data in background so the detail page shows
      // the latest linkUrl, revisi, and other fields from the server.
      refreshOrder(noBukti);
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
      );

      if (orders.isEmpty) return;

      final updatedPesanan = await _autoCompleteIfOverdue(orders.first);

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
  // ✅ Bug fix: sebelumnya cuma cek field `status` ('batal'/'expired').
  // Tapi pembatalan yang jalan lewat _batalkanPesanan()/FCM progress
  // (lihat HistoryOrderService.createDibatalkan) menulis 'dibatalkan' ke
  // `statusProgresPesanan`, BUKAN ke `status` — order-level `status` di
  // state lokal tetap 'aktif' sampai ada refetch penuh dari server.
  // Akibatnya order itu tidak masuk progres (statusProgres bukan salah
  // satu dari persiapan/proses/review/revisi), tidak masuk selesai, DAN
  // tidak masuk batal (status masih 'aktif') — order hilang total dari
  // UI. Cek `statusProgresPesanan == 'dibatalkan'` di sini menutup gap-nya.
  static bool _isInactiveStatus(PesananModel p) =>
      p.status == "batal" ||
      p.status == "expired" ||
      p.statusProgresPesanan == "dibatalkan";

  // ═══════════════════════════════════════════════════════════
  // AUTO-SELESAI SAAT LEWAT BATAS PENGERJAAN
  //
  // Dijalankan atas setiap pesanan yang baru di-fetch dari API (lihat
  // pemanggilnya di fetchSingleOrder/loadOrderOnly/loadOrderWithCache/
  // refreshOrder). Kalau statusnya masih proses/review/revisi tapi
  // Tgl_Pengerjaan_Max sudah lewat, pesanan otomatis ditandai selesai
  // lewat mekanisme yang sama dipakai SelesaikanDialog (POST progress
  // 'selesai'), tanpa menunggu aksi manual customer.
  //
  // Catatan cakupan: layar yang fetch pesanan lewat jalur lain (mis.
  // tombol "Lihat Pesanan" di Complain thread, atau detail_order_page.dart
  // V1 lama) tidak lewat provider ini sehingga tidak ikut ter-cover di
  // sini -- pesanan itu akan terkoreksi sendiri begitu ada layar lain
  // yang memanggil loadOrder/refreshOrder.
  // ═══════════════════════════════════════════════════════════

  final Set<String> _autoCompletingNoBukti = {};

  static const Set<String> _autoCompleteEligibleStatuses = {
    'proses',
    'review',
    'revisi',
  };

  Future<PesananModel> _autoCompleteIfOverdue(PesananModel p) async {
    if (_isInactiveStatus(p)) return p;
    final st = p.statusProgresPesanan?.trim().toLowerCase();
    if (st == null || !_autoCompleteEligibleStatuses.contains(st)) return p;
    final deadline = p.tglPengerjaanMax;
    if (deadline == null || !DateTime.now().isAfter(deadline)) return p;
    if (_autoCompletingNoBukti.contains(p.noBukti)) return p;

    _autoCompletingNoBukti.add(p.noBukti);
    try {
      final selesaiHistory = HistoryOrderService.createSelesai(
        noOrder: p.noBukti,
        senderId: p.idCustomer,
      );
      await HistoryOrderService().create(selesaiHistory);
      debugPrint(
          '[PesananProvider] ⏰ Auto-completed overdue order: ${p.noBukti}');
      return p.copyWith(statusProgresPesanan: 'selesai');
    } catch (e, st) {
      debugPrint(
          '[PesananProvider] ⚠️ Auto-complete failed for ${p.noBukti}: $e\n$st');
      return p;
    } finally {
      _autoCompletingNoBukti.remove(p.noBukti);
    }
  }

  Future<List<PesananModel>> _autoCompleteListIfOverdue(
          List<PesananModel> list) =>
      Future.wait(list.map(_autoCompleteIfOverdue));

  void _filterPesanan() {
    _pesananUnpaid = _allPesanan.where((p) {
      if (_isInactiveStatus(p)) return false;
      return p.statusProgresPesanan == "menunggu bayar" &&
          !isPaymentSettled(p.statusBayar);
    }).toList();

    _pesananProgress = _allPesanan.where((p) {
      if (_isInactiveStatus(p)) return false;
      if (["persiapan", "proses", "review", "revisi"]
          .contains(p.statusProgresPesanan)) {
        return true;
      }
      // Pesanan statusBayar sudah settled tapi server belum geser statusProgres →
      // tampilkan di progress (bukan unpaid) agar summary count akurat
      if (p.statusProgresPesanan == "menunggu bayar" &&
          isPaymentSettled(p.statusBayar)) {
        return true;
      }
      return false;
    }).toList();

    // _pesananSelesai/_pesananBatal TIDAK lagi diturunkan dari _allPesanan --
    // _allPesanan sekarang cuma berisi order dengan status-progress aktif
    // (lihat loadOrderOnly/loadOrderWithCache). Keduanya diisi terpisah oleh
    // loadFinishedOrders() saat FinishedOrderPage dibuka.
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
