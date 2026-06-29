import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:mpjnew/src/core/services/api_client.dart';
import 'package:mpjnew/src/core/services/api_singleton.dart';
import 'package:mpjnew/src/data/models/history_order_model.dart';

/// ✅ Simplified HistoryOrderService - API operations only
/// Real-time updates handled by FCM
class HistoryOrderService {
  final String entity = 'Orderprogress';
  final String controller = 'orderprogress';

  final ApiClient _client = apiClient;

  // =========================================
  // API METHODS - CRUD Operations
  // =========================================

  /// Get all history for specific order or all orders
  Future<List<HistoryOrderModel>> getAll({
    String? noid,
    String? senderId,
    String? deskripsi,
    String? noOrder,
    String? status,
    String? orderBy,
    String? orderDir,
  }) async {
    try {
      debugPrint('[HistoryOrderService] 📥 Fetching histories...');
      debugPrint('[HistoryOrderService] Parameters:');
      if (noOrder != null) debugPrint('[HistoryOrderService]   noOrder: $noOrder');
      if (status != null) debugPrint('[HistoryOrderService]   status: $status');

      final queryParams = {
        if (noid != null) 'no_id': noid,
        if (senderId != null) 'sender_id': senderId,
        if (status != null) 'status': status,
        if (noOrder != null) 'no_order': noOrder,
        if (deskripsi != null) 'deskripsi': deskripsi,
        if (orderBy != null) 'orderby': orderBy,
        if (orderDir != null) 'orderdir': orderDir,
      };

      final response = await _client.get(
        '/$controller/getAll',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final data = decoded['Data'];

        if (data is List) {
          final histories = (data as List)
              .map((item) {
                try {
                  return HistoryOrderModel.fromJson(item);
                } catch (e) {
                  debugPrint('[HistoryOrderService] ⚠️ Parse error: $e');
                  return null;
                }
              })
              .whereType<HistoryOrderModel>()
              .toList();

          debugPrint('[HistoryOrderService] ✅ Fetched ${histories.length} histories');
          return histories;
        }
        return [];
      } else if (response.statusCode == 204) {
        debugPrint('[HistoryOrderService] ℹ️ No content (204)');
        return [];
      } else {
        throw Exception('Failed to load $entity (${response.statusCode})');
      }
    } catch (e) {
      debugPrint('[HistoryOrderService] ❌ Error: $e');
      throw Exception('Error loading $entity: $e');
    }
  }

  /// Create new progress
  /// Backend will broadcast FCM notification to relevant users
  Future<String> create(HistoryOrderModel model) async {
    try {
      debugPrint('[HistoryOrderService] 📤 Creating progress...');
      debugPrint('[HistoryOrderService]   Order: ${model.noOrder}');
      debugPrint('[HistoryOrderService]   Status: ${model.statusProgressPesanan}');

      final response = await _client.post(
        '/$controller/create',
        body: jsonEncode(model.toJsonCreate()),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final historyId = decoded['NewId'];
        
        debugPrint('[HistoryOrderService] ✅ Progress created: $historyId');
        debugPrint('[HistoryOrderService] ℹ️ FCM notification will be sent by backend');
        
        return historyId;
      } else {
        throw Exception('Failed to create progress (${response.statusCode})');
      }
    } catch (e) {
      debugPrint('[HistoryOrderService] ❌ Create error: $e');
      throw Exception('Error creating progress: $e');
    }
  }

  /// Update existing progress
  Future<void> update(HistoryOrderModel model) async {
    try {
      debugPrint('[HistoryOrderService] 📝 Updating progress: ${model.noId}');

      final response = await _client.put(
        '/$controller/update',
        queryParameters: {'no_id': model.noId},
        body: jsonEncode(model.toJson()),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        debugPrint('[HistoryOrderService] ✅ Progress updated');
      } else {
        throw Exception('Failed to update $entity (${response.statusCode})');
      }
    } catch (e) {
      debugPrint('[HistoryOrderService] ❌ Update error: $e');
      throw Exception('Error updating $entity: $e');
    }
  }

  /// Delete progress
  Future<void> delete(String noId) async {
    try {
      debugPrint('[HistoryOrderService] 🗑️ Deleting progress: $noId');

      final response = await _client.delete(
        '/$controller/delete',
        queryParameters: {'no_id': noId},
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        debugPrint('[HistoryOrderService] ✅ Progress deleted');
      } else {
        throw Exception('Failed to delete $entity (${response.statusCode})');
      }
    } catch (e) {
      debugPrint('[HistoryOrderService] ❌ Delete error: $e');
      throw Exception('Error deleting $entity: $e');
    }
  }

  // =========================================
  // HELPER METHODS - Factory Methods
  // =========================================

  static HistoryOrderModel createMenungguPembayaran({
    required String noOrder,
    required String senderId,
    String deskripsi = 'Pesanan berhasil dibuat',
  }) {
    return HistoryOrderModel(
      noId: '',
      noOrder: noOrder,
      tglProgress: DateTime.now(),
      deskripsi: deskripsi,
      senderId: senderId,
      tipeUser: 'Customer',
      namaSender: '',
      status: 'Aktif',
      statusProgressPesanan: 'menunggu bayar',
    );
  }

  static HistoryOrderModel createPersiapan({
    required String noOrder,
    required String senderId,
  }) {
    return HistoryOrderModel(
      noId: '',
      noOrder: noOrder,
      tglProgress: DateTime.now(),
      deskripsi: 'Pembayaran diterima',
      senderId: senderId,
      tipeUser: 'Customer',
      namaSender: '',
      status: 'Aktif',
      statusProgressPesanan: 'persiapan',
    );
  }

  static HistoryOrderModel createProses({
    required String noOrder,
    required String senderId,
  }) {
    return HistoryOrderModel(
      noId: '',
      noOrder: noOrder,
      tglProgress: DateTime.now(),
      deskripsi: 'Pesanan sedang dikerjakan oleh vendor',
      senderId: senderId,
      tipeUser: 'Vendor',
      namaSender: '',
      status: 'Aktif',
      statusProgressPesanan: 'proses',
    );
  }

  static HistoryOrderModel createReview({
    required String noOrder,
    required String senderId,
  }) {
    return HistoryOrderModel(
      noId: '',
      noOrder: noOrder,
      tglProgress: DateTime.now(),
      deskripsi: 'Pesanan selesai dikerjakan, mohon berikan ulasan',
      senderId: senderId,
      tipeUser: 'Customer',
      namaSender: '',
      status: 'Aktif',
      statusProgressPesanan: 'review',
    );
  }

  static HistoryOrderModel createRevisi({
    required String noOrder,
    required String senderId,
  }) {
    return HistoryOrderModel(
      noId: '',
      noOrder: noOrder,
      tglProgress: DateTime.now(),
      deskripsi: 'Vendor sedang melakukan revisi',
      senderId: senderId,
      tipeUser: 'Vendor',
      namaSender: '',
      status: 'Aktif',
      statusProgressPesanan: 'revisi',
    );
  }

  static HistoryOrderModel createSelesai({
    required String noOrder,
    required String senderId,
  }) {
    return HistoryOrderModel(
      noId: '',
      noOrder: noOrder,
      tglProgress: DateTime.now(),
      deskripsi: 'Pesanan telah selesai',
      senderId: senderId,
      tipeUser: 'Customer',
      namaSender: '',
      status: 'Aktif',
      statusProgressPesanan: 'selesai',
    );
  }

  static HistoryOrderModel createDibatalkan({
    required String noOrder,
    required String senderId,
    String? customDeskripsi,
  }) {
    return HistoryOrderModel(
      noId: '',
      noOrder: noOrder,
      tglProgress: DateTime.now(),
      deskripsi: customDeskripsi ?? 'Pesanan telah dibatalkan',
      senderId: senderId,
      tipeUser: 'Customer',
      namaSender: '',
      status: 'Aktif',
      statusProgressPesanan: 'dibatalkan',
    );
  }

  /// Create progress with custom status
  static HistoryOrderModel createHistory({
    required String noOrder,
    required String senderId,
    required String statusProgressPesanan,
    String? customDeskripsi,
    String? customTipeUser,
  }) {
    return HistoryOrderModel(
      noId: '',
      noOrder: noOrder,
      tglProgress: DateTime.now(),
      deskripsi: customDeskripsi ?? getStatusDescription(statusProgressPesanan),
      senderId: senderId,
      tipeUser: customTipeUser ?? getTipeUserByStatus(statusProgressPesanan),
      namaSender: '',
      status: 'Aktif',
      statusProgressPesanan: statusProgressPesanan,
    );
  }

  // =========================================
  // UTILITY METHODS
  // =========================================

  static List<String> getAllStatusList() {
    return [
      'menunggu bayar',
      'persiapan',
      'proses',
      'review',
      'revisi',
      'selesai',
      'dibatalkan',
    ];
  }

  static String getStatusDescription(String status) {
    switch (status.toLowerCase()) {
      case 'menunggu bayar':
        return 'Pesanan berhasil dibuat. Silakan selesaikan pembayaran.';
      case 'persiapan':
        return 'Pembayaran diterima. Vendor sedang menyiapkan pesanan Anda.';
      case 'proses':
        return 'Pesanan sedang dikerjakan oleh vendor.';
      case 'review':
        return 'Pesanan selesai dikerjakan. Mohon berikan ulasan Anda.';
      case 'revisi':
        return 'Vendor sedang melakukan revisi sesuai permintaan Anda.';
      case 'selesai':
        return 'Pesanan telah selesai. Terima kasih!';
      case 'dibatalkan':
        return 'Pesanan telah dibatalkan.';
      default:
        return 'Status tidak diketahui';
    }
  }

  static String getTipeUserByStatus(String status) {
    switch (status.toLowerCase()) {
      case 'menunggu bayar':
      case 'review':
      case 'selesai':
        return 'Customer';
      case 'persiapan':
      case 'proses':
      case 'revisi':
        return 'Vendor';
      case 'dibatalkan':
        return 'Customer';
      default:
        return 'Unknown';
    }
  }

  static String getStatusEmoji(String status) {
    switch (status.toLowerCase()) {
      case 'menunggu bayar':
        return '💳';
      case 'persiapan':
        return '📦';
      case 'proses':
        return '⚙️';
      case 'review':
        return '⭐';
      case 'revisi':
        return '🔧';
      case 'selesai':
        return '🎉';
      case 'dibatalkan':
        return '❌';
      default:
        return '📋';
    }
  }
}