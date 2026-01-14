import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:mpjnew/src/core/services/api_client.dart';
import 'package:mpjnew/src/core/services/api_singleton.dart';
import 'package:mpjnew/src/data/models/history_order_model.dart';
import 'package:signalr_netcore/http_connection_options.dart';
import 'package:signalr_netcore/hub_connection.dart';
import 'package:signalr_netcore/hub_connection_builder.dart';

/// Konfigurasi untuk HistoryOrderService
class HistoryOrderServiceConfig {
  final String hubUrl;
  final String role; // 'customer' atau 'vendor'
  final Future<String?> Function() getToken;
  final int requestTimeout;
  final List<int> retryDelays;

  const HistoryOrderServiceConfig({
    required this.hubUrl,
    required this.role,
    required this.getToken,
    this.requestTimeout = 15000,
    this.retryDelays = const [1000, 2000, 5000, 10000, 30000],
  });
}

class HistoryOrderService {
  final String entity = 'Orderprogress';
  final String controller = 'orderprogress';

  final ApiClient _client = apiClient;

  // =========================================
  // SIGNALR CONNECTION - STANDALONE
  // =========================================
  HubConnection? _hubConnection;
  HistoryOrderServiceConfig? _config;
  String _currentUserId = '';
  bool _isConnecting = false;

  final Set<String> _joinedOrders = {};

  // =========================================
  // CALLBACKS
  // =========================================

  /// Callback ketika menerima update progress baru
  Function(HistoryOrderModel progress)? onProgressReceived;

  /// Callback ketika status koneksi berubah
  Function(bool isConnected, String? error)? onConnectionChanged;

  /// Callback ketika reconnect berhasil
  Function()? onReconnected;

  // =========================================
  // GETTERS
  // =========================================

  bool get isConnected => _hubConnection?.state == HubConnectionState.Connected;
  bool get isConnecting => _isConnecting;
  String get currentUserId => _currentUserId;
  Set<String> get joinedOrders => Set.unmodifiable(_joinedOrders);

  // =========================================
  // CONNECTION
  // =========================================

  /// Connect ke SignalR hub untuk order progress
  Future<bool> connect({
    required HistoryOrderServiceConfig config,
    required String userId,
  }) async {
    debugPrint('[HistoryOrderService] ═══════════════════════════════════════');
    debugPrint('[HistoryOrderService] 🔌 CONNECTING TO SIGNALR');
    debugPrint('[HistoryOrderService] ═══════════════════════════════════════');

    if (_isConnecting) {
      debugPrint('[HistoryOrderService] ⏸️ Already connecting, skip');
      return false;
    }

    if (isConnected && _currentUserId == userId) {
      debugPrint('[HistoryOrderService] ✅ Already connected for user $userId');
      return true;
    }

    _isConnecting = true;
    _config = config;
    _currentUserId = userId;

    try {
      debugPrint('[HistoryOrderService] 👤 User ID: $userId');
      debugPrint('[HistoryOrderService] 🌐 Hub URL: ${config.hubUrl}');
      debugPrint('[HistoryOrderService] 👥 Role: ${config.role}');
      debugPrint(
          '[HistoryOrderService] ⏱️ Timeout: ${config.requestTimeout}ms');

      // Get token
      debugPrint('[HistoryOrderService] 🔑 Getting authentication token...');
      final token = await config.getToken();

      if (token == null || token.isEmpty) {
        debugPrint('[HistoryOrderService] ❌ No token available');
        return false;
      }

      debugPrint(
          '[HistoryOrderService] ✅ Token retrieved (length: ${token.length})');

      // Disconnect existing if any
      if (_hubConnection != null) {
        debugPrint(
            '[HistoryOrderService] 🔌 Disconnecting existing connection...');
        await disconnect();
      }

      // Build connection
      debugPrint('[HistoryOrderService] 🔧 Building SignalR connection...');
      final fullUrl = '${config.hubUrl}?role=${config.role}';
      debugPrint('[HistoryOrderService] 🌐 Full URL: $fullUrl');

      _hubConnection = HubConnectionBuilder()
          .withUrl(
            fullUrl,
            options: HttpConnectionOptions(
              accessTokenFactory: () async {
                debugPrint('[HistoryOrderService] 🔑 Token factory called');
                return token;
              },
              requestTimeout: config.requestTimeout,
            ),
          )
          .withAutomaticReconnect(retryDelays: config.retryDelays)
          .build();

      debugPrint('[HistoryOrderService] ✅ Connection built');

      // Setup listeners
      debugPrint('[HistoryOrderService] 🎧 Setting up event listeners...');
      _setupListeners();

      // Start connection
      debugPrint('[HistoryOrderService] 🚀 Starting connection...');
      await _hubConnection!.start();

      debugPrint(
          '[HistoryOrderService] ═══════════════════════════════════════');
      debugPrint('[HistoryOrderService] ✅ CONNECTED SUCCESSFULLY');
      debugPrint(
          '[HistoryOrderService] Connection ID: ${_hubConnection!.connectionId}');
      debugPrint('[HistoryOrderService] State: ${_hubConnection!.state}');
      debugPrint(
          '[HistoryOrderService] ═══════════════════════════════════════');

      onConnectionChanged?.call(true, null);

      return true;
    } catch (e, st) {
      debugPrint(
          '[HistoryOrderService] ═══════════════════════════════════════');
      debugPrint('[HistoryOrderService] ❌ CONNECTION FAILED');
      debugPrint(
          '[HistoryOrderService] ═══════════════════════════════════════');
      debugPrint('[HistoryOrderService] Error: $e');
      debugPrint('[HistoryOrderService] Stack trace: $st');
      debugPrint(
          '[HistoryOrderService] ═══════════════════════════════════════');

      onConnectionChanged?.call(false, e.toString());
      return false;
    } finally {
      _isConnecting = false;
    }
  }

  /// Disconnect dari SignalR
  Future<void> disconnect() async {
    try {
      if (_hubConnection != null) {
        debugPrint('[HistoryOrderService] 🔌 Disconnecting...');
        await _hubConnection!.stop();
        debugPrint('[HistoryOrderService] ✅ Disconnected');
      }
    } catch (e) {
      debugPrint('[HistoryOrderService] ❌ Disconnect error: $e');
    } finally {
      _hubConnection = null;
      _joinedOrders.clear();
      onConnectionChanged?.call(false, null);
    }
  }

  // =========================================
  // LISTENERS SETUP
  // =========================================

  void _setupListeners() {
    if (_hubConnection == null) {
      debugPrint(
          '[HistoryOrderService] ⚠️ Cannot setup listeners: connection is null');
      return;
    }

    debugPrint(
        '[HistoryOrderService] 🎧 Setting up SignalR event listeners...');

    // ✅ LISTENER: Progress baru (sesuai dengan C# backend)
    // Backend sends: "ProgressPesananUpdated"
    _hubConnection!.on('ProgressPesananUpdated', (args) {
      debugPrint(
          '[HistoryOrderService] ═══════════════════════════════════════');
      debugPrint(
          '[HistoryOrderService] 📨 ProgressPesananUpdated EVENT RECEIVED');
      debugPrint(
          '[HistoryOrderService] ═══════════════════════════════════════');
      debugPrint('[HistoryOrderService] Args type: ${args?.runtimeType}');
      debugPrint('[HistoryOrderService] Args length: ${args?.length}');
      debugPrint('[HistoryOrderService] Raw args: $args');

      if (args == null || args.isEmpty) {
        debugPrint('[HistoryOrderService] ⚠️ Empty args received');
        return;
      }

      _handleProgressReceived(args);
    });

    // Connection lifecycle
    _hubConnection!.onclose(({error}) {
      debugPrint(
          '[HistoryOrderService] ═══════════════════════════════════════');
      debugPrint('[HistoryOrderService] 🔌 CONNECTION CLOSED');
      debugPrint(
          '[HistoryOrderService] ═══════════════════════════════════════');
      if (error != null) {
        debugPrint('[HistoryOrderService] Error: $error');
      }
      debugPrint(
          '[HistoryOrderService] ═══════════════════════════════════════');

      onConnectionChanged?.call(false, error?.toString());
    });

    _hubConnection!.onreconnecting(({error}) {
      debugPrint(
          '[HistoryOrderService] ═══════════════════════════════════════');
      debugPrint('[HistoryOrderService] 🔄 RECONNECTING...');
      debugPrint(
          '[HistoryOrderService] ═══════════════════════════════════════');
      if (error != null) {
        debugPrint('[HistoryOrderService] Reason: $error');
      }
      debugPrint(
          '[HistoryOrderService] ═══════════════════════════════════════');

      onConnectionChanged?.call(false, 'reconnecting');
    });

    _hubConnection!.onreconnected(({connectionId}) async {
      debugPrint(
          '[HistoryOrderService] ═══════════════════════════════════════');
      debugPrint('[HistoryOrderService] ✅ RECONNECTED');
      debugPrint(
          '[HistoryOrderService] ═══════════════════════════════════════');
      debugPrint('[HistoryOrderService] New Connection ID: $connectionId');
      debugPrint(
          '[HistoryOrderService] ═══════════════════════════════════════');

      onConnectionChanged?.call(true, null);

      debugPrint('[HistoryOrderService] 🔄 Rejoining order groups...');
      await _rejoinAfterReconnect();
      onReconnected?.call();
    });

    debugPrint('[HistoryOrderService] ✅ Event listeners setup complete');
  }

  // =========================================
  // EVENT HANDLERS
  // =========================================

  void _handleProgressReceived(List<Object?> args) {
    try {
      debugPrint(
          '[HistoryOrderService] ───────────────────────────────────────');
      debugPrint('[HistoryOrderService] 🔍 PARSING PROGRESS DATA');
      debugPrint(
          '[HistoryOrderService] ───────────────────────────────────────');

      final raw = args[0];
      debugPrint('[HistoryOrderService] Raw data type: ${raw.runtimeType}');
      debugPrint('[HistoryOrderService] Raw data: $raw');

      final data = _parseData(raw);
      debugPrint(
          '[HistoryOrderService] ───────────────────────────────────────');
      debugPrint('[HistoryOrderService] 📦 Parsed data map:');
      data.forEach((key, value) {
        debugPrint(
            '[HistoryOrderService]   $key: $value (${value.runtimeType})');
      });
      debugPrint(
          '[HistoryOrderService] ───────────────────────────────────────');

      // Map dari C# backend ke Dart model
      // C# sends: No_Order, Tgl_Progress, Deskripsi, No_Id, Sender_Id, Status, Tipe_User, Status_Progress
      final progress = HistoryOrderModel(
        noId: data['no_Id']?.toString() ?? '',
        noOrder: data['no_Order']?.toString() ?? '',
        tglProgress: _parseDateTime(data['tgl_Progress']),
        deskripsi: data['deskripsi']?.toString() ?? '',
        senderId: data['sender_Id']?.toString() ?? '',
        tipeUser: data['tipe_User']?.toString() ?? '',
        namaSender: '', // Backend tidak kirim, akan di-fill dari database
        status: data['status']?.toString() ?? '',
        statusProgressPesanan: data['status_Progress']?.toString() ?? '',
      );

      debugPrint(
          '[HistoryOrderService] ═══════════════════════════════════════');
      debugPrint('[HistoryOrderService] ✅ PROGRESS MODEL CREATED');
      debugPrint(
          '[HistoryOrderService] ═══════════════════════════════════════');
      debugPrint('[HistoryOrderService] No Order: ${progress.noOrder}');
      debugPrint('[HistoryOrderService] No ID: ${progress.noId}');
      debugPrint(
          '[HistoryOrderService] Status Progress: ${progress.statusProgressPesanan}');
      debugPrint('[HistoryOrderService] Deskripsi: ${progress.deskripsi}');
      debugPrint('[HistoryOrderService] Sender ID: ${progress.senderId}');
      debugPrint('[HistoryOrderService] Tipe User: ${progress.tipeUser}');
      debugPrint('[HistoryOrderService] Tanggal: ${progress.tglProgress}');
      debugPrint('[HistoryOrderService] Status: ${progress.status}');
      debugPrint(
          '[HistoryOrderService] ═══════════════════════════════════════');

      debugPrint(
          '[HistoryOrderService] 📢 Calling onProgressReceived callback...');
      onProgressReceived?.call(progress);
      debugPrint('[HistoryOrderService] ✅ Callback executed');
    } catch (e, st) {
      debugPrint(
          '[HistoryOrderService] ═══════════════════════════════════════');
      debugPrint('[HistoryOrderService] ❌ PARSE PROGRESS ERROR');
      debugPrint(
          '[HistoryOrderService] ═══════════════════════════════════════');
      debugPrint('[HistoryOrderService] Error: $e');
      debugPrint('[HistoryOrderService] Stack trace: $st');
      debugPrint('[HistoryOrderService] Raw args: $args');
      debugPrint(
          '[HistoryOrderService] ═══════════════════════════════════════');
    }
  }

  // =========================================
  // ORDER GROUP MANAGEMENT
  // =========================================

  /// Join order group untuk menerima updates
  Future<bool> joinOrder(String noOrder) async {
    debugPrint('[HistoryOrderService] ═══════════════════════════════════════');
    debugPrint('[HistoryOrderService] 📦 JOINING ORDER GROUP');
    debugPrint('[HistoryOrderService] ═══════════════════════════════════════');

    if (!isConnected) {
      debugPrint('[HistoryOrderService] ⚠️ Cannot join: not connected');
      debugPrint(
          '[HistoryOrderService] Current state: ${_hubConnection?.state}');
      return false;
    }

    if (noOrder.isEmpty) {
      debugPrint('[HistoryOrderService] ⚠️ Cannot join: empty order number');
      return false;
    }

    if (_joinedOrders.contains(noOrder)) {
      debugPrint('[HistoryOrderService] ℹ️ Already joined order: $noOrder');
      return true;
    }

    try {
      debugPrint('[HistoryOrderService] 📡 Invoking JoinOrder...');
      debugPrint('[HistoryOrderService] Order: $noOrder');
      debugPrint('[HistoryOrderService] Group name: order-$noOrder');

      await _hubConnection!.invoke('JoinOrder', args: [noOrder]);

      _joinedOrders.add(noOrder);

      debugPrint(
          '[HistoryOrderService] ═══════════════════════════════════════');
      debugPrint('[HistoryOrderService] ✅ JOINED ORDER GROUP');
      debugPrint('[HistoryOrderService] Order: $noOrder');
      debugPrint(
          '[HistoryOrderService] Total joined orders: ${_joinedOrders.length}');
      debugPrint(
          '[HistoryOrderService] All joined: ${_joinedOrders.join(", ")}');
      debugPrint(
          '[HistoryOrderService] ═══════════════════════════════════════');

      return true;
    } catch (e, st) {
      debugPrint(
          '[HistoryOrderService] ═══════════════════════════════════════');
      debugPrint('[HistoryOrderService] ❌ JOIN ORDER ERROR');
      debugPrint(
          '[HistoryOrderService] ═══════════════════════════════════════');
      debugPrint('[HistoryOrderService] Order: $noOrder');
      debugPrint('[HistoryOrderService] Error: $e');
      debugPrint('[HistoryOrderService] Stack trace: $st');
      debugPrint(
          '[HistoryOrderService] ═══════════════════════════════════════');
      return false;
    }
  }

  /// Join multiple orders
  Future<void> joinOrders(List<String> orderIds) async {
    debugPrint('[HistoryOrderService] 📦 Joining ${orderIds.length} orders...');

    for (final orderId in orderIds) {
      if (orderId.isNotEmpty) {
        await joinOrder(orderId);
      }
    }

    debugPrint('[HistoryOrderService] ✅ Finished joining orders');
  }

  /// Leave order group
  Future<void> leaveOrder(String noOrder) async {
    if (!isConnected) return;

    try {
      debugPrint('[HistoryOrderService] 👋 Leaving order group: $noOrder');

      await _hubConnection!.invoke('LeaveOrder', args: [noOrder]);
      _joinedOrders.remove(noOrder);

      debugPrint('[HistoryOrderService] ✅ Left order group: $noOrder');
      debugPrint(
          '[HistoryOrderService] Remaining joined orders: ${_joinedOrders.length}');
    } catch (e) {
      debugPrint('[HistoryOrderService] ❌ Leave order error: $e');
    }
  }

  /// Rejoin orders after reconnection
  Future<void> _rejoinAfterReconnect() async {
    final orders = List<String>.from(_joinedOrders);
    _joinedOrders.clear();

    debugPrint(
        '[HistoryOrderService] 🔄 Rejoining ${orders.length} orders after reconnect...');

    for (final orderId in orders) {
      await joinOrder(orderId);
    }

    debugPrint('[HistoryOrderService] ✅ Rejoin complete');
  }

  // =========================================
  // API METHODS
  // =========================================

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
      debugPrint(
          '[HistoryOrderService] ═══════════════════════════════════════');
      debugPrint('[HistoryOrderService] 🌐 API CALL: getAll');
      debugPrint(
          '[HistoryOrderService] ═══════════════════════════════════════');

      final queryParams = {
        if (noid != null) 'no_id': noid,
        if (senderId != null) 'sender_id': senderId,
        if (status != null) 'status': status,
        if (noOrder != null) 'no_order': noOrder,
        if (deskripsi != null) 'deskripsi': deskripsi,
        if (orderBy != null) 'orderby': orderBy,
        if (orderDir != null) 'orderdir': orderDir,
      };

      debugPrint('[HistoryOrderService] Query parameters:');
      queryParams.forEach((key, value) {
        debugPrint('[HistoryOrderService]   $key: $value');
      });

      final response = await _client.get(
        '/$controller/getAll',
        queryParameters: queryParams,
      );

      debugPrint(
          '[HistoryOrderService] ───────────────────────────────────────');
      debugPrint('[HistoryOrderService] 📥 Response received');
      debugPrint('[HistoryOrderService] Status code: ${response.statusCode}');
      debugPrint('[HistoryOrderService] Body length: ${response.body.length}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final data = decoded['Data'];

        debugPrint('[HistoryOrderService] Data type: ${data.runtimeType}');

        if (data is List) {
          final progressList = (data as List? ?? [])
              .map((item) {
                try {
                  return HistoryOrderModel.fromJson(item);
                } catch (e) {
                  debugPrint(
                      '[HistoryOrderService] ⚠️ Failed to parse item: $e');
                  debugPrint('[HistoryOrderService] Item: $item');
                  return null;
                }
              })
              .whereType<HistoryOrderModel>()
              .toList();

          debugPrint(
              '[HistoryOrderService] ═══════════════════════════════════════');
          debugPrint('[HistoryOrderService] ✅ API SUCCESS');
          debugPrint(
              '[HistoryOrderService] Total items: ${progressList.length}');
          debugPrint(
              '[HistoryOrderService] ═══════════════════════════════════════');

          return progressList;
        } else {
          debugPrint(
              '[HistoryOrderService] ⚠️ Data is not a list, returning empty');
          return [];
        }
      } else if (response.statusCode == 204) {
        debugPrint('[HistoryOrderService] ℹ️ No content (204)');
        return [];
      } else {
        debugPrint(
            '[HistoryOrderService] ❌ Error status: ${response.statusCode}');
        debugPrint('[HistoryOrderService] Body: ${response.body}');
        throw Exception('Gagal load $entity (${response.statusCode})');
      }
    } catch (e, st) {
      debugPrint(
          '[HistoryOrderService] ═══════════════════════════════════════');
      debugPrint('[HistoryOrderService] ❌ API ERROR');
      debugPrint(
          '[HistoryOrderService] ═══════════════════════════════════════');
      debugPrint('[HistoryOrderService] Error: $e');
      debugPrint('[HistoryOrderService] Stack trace: $st');
      debugPrint(
          '[HistoryOrderService] ═══════════════════════════════════════');
      throw Exception('Error saat mengambil $entity: $e');
    }
  }

  Future<void> create(HistoryOrderModel model) async {
    debugPrint('[HistoryOrderService] ═══════════════════════════════════════');
    debugPrint('[HistoryOrderService] 📤 API CALL: create');
    debugPrint('[HistoryOrderService] ═══════════════════════════════════════');

    final jsonBody = jsonEncode(model.toJsonCreate());
    debugPrint('[HistoryOrderService] Request body: $jsonBody');

    final response = await apiClient.post(
      '/$controller/create',
      body: jsonBody,
      headers: {'Content-Type': 'application/json'},
    );

    debugPrint('[HistoryOrderService] ───────────────────────────────────────');
    debugPrint('[HistoryOrderService] URL: ${response.request?.url}');
    debugPrint('[HistoryOrderService] Status Code: ${response.statusCode}');
    debugPrint('[HistoryOrderService] Response Body: ${response.body}');
    debugPrint('[HistoryOrderService] ───────────────────────────────────────');

    if (response.statusCode != 200) {
      debugPrint('[HistoryOrderService] ❌ Create failed');
      throw Exception('Gagal membuat progress pesanan');
    }

    debugPrint('[HistoryOrderService] ✅ Create success');
    debugPrint(
        '[HistoryOrderService] ℹ️ SignalR will broadcast ProgressPesananUpdated automatically');
    debugPrint('[HistoryOrderService] ═══════════════════════════════════════');
  }

  /// UPDATE
  Future<void> update(HistoryOrderModel model) async {
    debugPrint('[HistoryOrderService] 📤 API CALL: update (${model.noId})');

    final response = await apiClient.put(
      '/$controller/update',
      queryParameters: {'no_id': model.noId},
      body: jsonEncode(model.toJson()),
      headers: {'Content-Type': 'application/json'},
    );

    debugPrint('[HistoryOrderService] Update response: ${response.statusCode}');

    if (response.statusCode != 200) {
      throw Exception('Gagal mengupdate $entity');
    }

    debugPrint('[HistoryOrderService] ✅ Update success');
  }

  /// DELETE
  Future<void> delete(String noId) async {
    debugPrint('[HistoryOrderService] 🗑️ API CALL: delete ($noId)');

    final response = await apiClient.delete(
      '/$controller/delete',
      queryParameters: {'no_id': noId},
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('Gagal menghapus $entity');
    }

    debugPrint('[HistoryOrderService] ✅ Delete success');
  }

  // =========================================
  // UTILITIES
  // =========================================

  Map<String, dynamic> _parseData(dynamic obj) {
    debugPrint('[HistoryOrderService] 🔍 Parsing data...');
    debugPrint('[HistoryOrderService] Input type: ${obj.runtimeType}');

    if (obj is Map) {
      final result = obj.map((k, v) => MapEntry(k.toString(), v));
      debugPrint(
          '[HistoryOrderService] ✅ Parsed as Map (${result.length} keys)');
      return result;
    }

    if (obj is String) {
      try {
        debugPrint('[HistoryOrderService] Attempting JSON decode...');
        final decoded = jsonDecode(obj);
        if (decoded is Map) {
          final result = decoded.map((k, v) => MapEntry(k.toString(), v));
          debugPrint(
              '[HistoryOrderService] ✅ Parsed as JSON Map (${result.length} keys)');
          return result;
        }
      } catch (e) {
        debugPrint('[HistoryOrderService] ⚠️ JSON decode failed: $e');
      }
    }

    debugPrint('[HistoryOrderService] ⚠️ Could not parse, returning empty map');
    return {};
  }

  DateTime _parseDateTime(dynamic value) {
    if (value == null) {
      debugPrint(
          '[HistoryOrderService] ⚠️ DateTime is null, using current time');
      return DateTime.now();
    }
    if (value is DateTime) return value.toLocal();
    try {
      return DateTime.parse(value.toString()).toLocal();
    } catch (e) {
      debugPrint(
          '[HistoryOrderService] ⚠️ DateTime parse failed: $e, using current time');
      return DateTime.now();
    }
  }

  /// Clean up
  void dispose() {
    debugPrint('[HistoryOrderService] 🔌 Disposing service...');
    _hubConnection?.stop();
    _hubConnection = null;
    _joinedOrders.clear();
    onProgressReceived = null;
    onConnectionChanged = null;
    onReconnected = null;
    debugPrint('[HistoryOrderService] ✅ Service disposed');
  }

  // =====================================================
  // 📝 CREATE HISTORY - HELPER METHODS
  // =====================================================

  static HistoryOrderModel createMenungguPembayaran({
    required String noOrder,
    required String senderId,
  }) {
    return HistoryOrderModel(
      noId: '',
      noOrder: noOrder,
      tglProgress: DateTime.now(),
      deskripsi: 'Pesanan berhasil dibuat',
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
      deskripsi: 'Pesanan selesai dikerjakan. minta review dari customer',
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
      deskripsi: customDeskripsi ?? 'Pesanan telah dibatalkan.',
      senderId: senderId,
      tipeUser: 'Customer',
      namaSender: '',
      status: 'Aktif',
      statusProgressPesanan: 'dibatalkan',
    );
  }

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
        return 'Pesanan telah selesai. Terima kasih atas kepercayaan Anda!';
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
}
