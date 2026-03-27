import 'package:flutter/foundation.dart';
import 'package:mpjnew/src/data/hive_service.dart/pesanan_local_service.dart';
import 'package:mpjnew/src/data/hive_service.dart/portofolio_local_service.dart';
import 'package:mpjnew/src/features/customer/viewmodels/chat_provider.dart';

/// ═══════════════════════════════════════════════════════════════
/// CUSTOMER LOCAL STORAGE MANAGER
///
/// Masalah yang diselesaikan:
/// - Data customer A bocor ke customer B saat ganti akun
///
/// Data yang di-manage:
/// 1. Portofolio (liked + saved) → PortofolioLocalService
///    - Tidak pakai key prefix karena box terpisah per tipe
///    - Isolasi cukup dengan clear saat logout
///
/// 2. Pesanan → PesananLocalService
///    - Box: pesanan_box + history_order_box
///    - Data pesanan bersifat personal, clear saat logout
///
/// 3. Chat → HiveChatRepository (via CustomerChatProvider)
///    - Box per room: "chat_rooms", "chat_messages_{roomId}"
///    - close() saat logout, buka ulang saat login
///
/// Lifecycle:
///   Login  → setActiveCustomer(id) → init semua service
///   Logout → clearOnLogout() → clearActiveCustomer()
///   Delete → deleteAllData() (hapus permanen dari disk)
///
/// Catatan perbedaan dengan vendor:
/// - Vendor: pakai key prefix ({vendorId}_{key}) karena satu box
///   bisa berisi data multi-vendor (vendor app shared device)
/// - Customer: tidak pakai prefix karena tiap customer clear box
///   penuh saat logout (customer app lebih personal, jarang shared)
/// ═══════════════════════════════════════════════════════════════

class LocalStorageService {
  // ── Singleton ─────────────────────────────────────────────────
  static final LocalStorageService instance = LocalStorageService._internal();
  LocalStorageService._internal();

  // ── State ─────────────────────────────────────────────────────
  String? _activeCustomerId;

  // ── Getters ───────────────────────────────────────────────────
  String? get activeCustomerId => _activeCustomerId;
  bool get hasActiveCustomer => _activeCustomerId != null;

  // ═══════════════════════════════════════════════════════════════
  // 🔐 SESSION MANAGEMENT
  // ═══════════════════════════════════════════════════════════════

  /// Dipanggil saat customer berhasil login.
  /// Harus dipanggil SEBELUM initialize() pada semua service.
  void setActiveCustomer(String customerId) {
    if (_activeCustomerId == customerId) {
      debugPrint('[CustomerStorage] ℹ️ Customer sudah aktif: $customerId');
      return;
    }

    debugPrint('═══════════════════════════════════════════════════');
    debugPrint('[CustomerStorage] 🔐 Active customer set: $customerId');
    if (_activeCustomerId != null) {
      debugPrint('[CustomerStorage]    Previous: $_activeCustomerId');
      debugPrint('[CustomerStorage]    ⚠️ Ganti akun tanpa logout dulu!');
    }
    debugPrint('═══════════════════════════════════════════════════');

    _activeCustomerId = customerId;
  }

  /// Hanya clear active customer ID — data Hive TETAP tersimpan.
  /// Dipanggil dari clearOnLogout() setelah semua data di-clear.
  void clearActiveCustomer() {
    debugPrint(
        '[CustomerStorage] 🚪 Active customer cleared: $_activeCustomerId');
    _activeCustomerId = null;
  }

  // ═══════════════════════════════════════════════════════════════
  // 🚪 LOGOUT — Clear semua data + in-memory state
  // ═══════════════════════════════════════════════════════════════

  /// Dipanggil saat customer logout.
  ///
  /// Yang terjadi:
  /// - Portofolio liked + saved: data Hive di-clear (media file juga)
  /// - Pesanan: data Hive di-clear (order + history)
  /// - Chat: box Hive di-tutup, stream di-close
  ///
  /// Mengapa portofolio & pesanan di-clear (bukan hanya in-memory)?
  /// Karena data ini bersifat sangat personal (like, save, order history).
  /// Berbeda dengan vendor yang mungkin share device dan perlu cache
  /// untuk login ulang cepat.
  Future<void> clearOnLogout({
    required PortofolioLocalService portofolioService,
    required PesananLocalService pesananService,
    required ChatProvider chatProvider,
  }) async {
    debugPrint('═══════════════════════════════════════════════════');
    debugPrint('[CustomerStorage] 🚪 Logout cleanup...');
    debugPrint('[CustomerStorage]    Customer: $_activeCustomerId');
    debugPrint('═══════════════════════════════════════════════════');

    try {
      // 1. Portofolio: hapus liked + saved + media cache
      await portofolioService.clearAll();
      debugPrint('[CustomerStorage]    ✅ Portofolio liked & saved cleared');

      // 2. Pesanan: hapus orders + histories
      await pesananService.clearAll();
      debugPrint('[CustomerStorage]    ✅ Pesanan & histories cleared');

      // 3. Chat: tutup box, close streams
      //    Data chat TETAP di disk untuk referensi history
      //    (berbeda dengan portofolio/pesanan yang di-clear)
      await chatProvider.closeAndClearInMemory();
      debugPrint(
          '[CustomerStorage]    ✅ Chat boxes closed (data on disk intact)');

      // 4. Clear active customer
      clearActiveCustomer();

      debugPrint('[CustomerStorage] ✅ Logout cleanup complete');
      debugPrint('═══════════════════════════════════════════════════');
    } catch (e, st) {
      debugPrint('[CustomerStorage] ❌ Error during logout: $e');
      debugPrint(st.toString());
      // Tetap clear meski error
      clearActiveCustomer();
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // 🗑️ HARD DELETE — Hapus semua data untuk customer ini
  // ═══════════════════════════════════════════════════════════════

  /// Hapus SEMUA data untuk customer secara permanen.
  /// Gunakan hanya untuk hapus akun.
  Future<void> deleteAllData({
    required PortofolioLocalService portofolioService,
    required PesananLocalService pesananService,
    String? customerId,
  }) async {
    final targetId = customerId ?? _activeCustomerId;

    debugPrint('═══════════════════════════════════════════════════');
    debugPrint('[CustomerStorage] 🗑️ DELETING ALL DATA');
    debugPrint('[CustomerStorage]    Customer: $targetId');
    debugPrint('═══════════════════════════════════════════════════');

    // 1. Portofolio (liked + saved + media)
    await portofolioService.clearAll();
    debugPrint('[CustomerStorage]    ✅ Portofolio deleted');

    // 2. Pesanan + histories
    await pesananService.clearAll();
    debugPrint('[CustomerStorage]    ✅ Pesanan deleted');

    if (targetId == _activeCustomerId) {
      clearActiveCustomer();
    }

    debugPrint('[CustomerStorage] ✅ All data deleted');
    debugPrint('═══════════════════════════════════════════════════');
  }

  // ═══════════════════════════════════════════════════════════════
  // 🔍 GUARD HELPERS
  // ═══════════════════════════════════════════════════════════════

  /// Cek apakah customer aktif sama dengan yang diharapkan.
  /// Gunakan sebelum operasi yang butuh customer spesifik.
  bool isActiveCustomer(String customerId) {
    return _activeCustomerId == customerId;
  }

  /// Assert bahwa ada customer aktif.
  /// Lempar exception jika tidak ada.
  void requireActiveCustomer(String context) {
    if (_activeCustomerId == null) {
      throw StateError(
        '[CustomerStorage] $context dipanggil tanpa activeCustomer. '
        'Pastikan setActiveCustomer() dipanggil setelah login.',
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // 🔍 DEBUG
  // ═══════════════════════════════════════════════════════════════

  void printState() {
    debugPrint('═══ CustomerLocalStorageManager State ═══');
    debugPrint('Active customer : ${_activeCustomerId ?? "NONE"}');
    debugPrint('Has active      : $hasActiveCustomer');
    debugPrint('═════════════════════════════════════════');
  }

  Future<void> printStats({
    required PortofolioLocalService portofolioService,
    required PesananLocalService pesananService,
  }) async {
    debugPrint('═══════════════════════════════════════════════════');
    debugPrint('📊 CUSTOMER LOCAL STORAGE STATS');
    debugPrint('   Customer: ${_activeCustomerId ?? "NONE"}');
    debugPrint('───────────────────────────────────────────────────');

    await portofolioService.printStats();
    await pesananService.printStats();

    debugPrint('═══════════════════════════════════════════════════');
  }
}

// ═══════════════════════════════════════════════════════════════
// CONTOH URUTAN INISIALISASI
// ═══════════════════════════════════════════════════════════════
//
// Di login screen / splash handler:
//
//   // 1. Customer berhasil login
//   final customer = await authService.login(email, password);
//
//   // 2. Set active customer PERTAMA SEKALI
//   CustomerLocalStorageManager.instance.setActiveCustomer(customer.noId);
//
//   // 3. Init chat provider (butuh activeCustomer untuk box naming)
//   await chatProvider.initialize(
//     userId: customer.noId,
//     userType: 'customer',
//   );
//
//   // 4. Load portofolio dari cache (liked + saved)
//   await portofolioProvider.loadFromCache();
//
//   // 5. Load pesanan dari cache
//   await pesananProvider.loadFromCache();
//
//   // 6. Navigate ke home
//
// ──────────────────────────────────────────────────────────────
//
// Di logout:
//
//   await CustomerLocalStorageManager.instance.clearOnLogout(
//     portofolioService: portofolioLocalService,
//     pesananService: pesananLocalService,
//     chatProvider: chatProvider,
//   );
//   // Navigate ke login screen
