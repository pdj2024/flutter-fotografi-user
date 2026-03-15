import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mpjnew/src/core/services/fcm/handlers/fcm_chat_notification_helper.dart';
import 'package:mpjnew/src/core/services/fcm_chat_message.dart';
import 'package:mpjnew/src/core/services/fcm_chat_provider.dart';
import 'package:mpjnew/src/core/services/fcm_chat_queue.dart';

/// ═══════════════════════════════════════════════════════════════
/// FCM CHAT SERVICE
///
/// Singleton orchestrator. Menghubungkan:
///   - Firebase Messaging (foreground + background)
///   - FcmChatNotificationHelper (tampilkan notifikasi lokal)
///   - FcmChatProvider (update state + stream untuk UI)
///   - FcmChatQueue (buffer pesan background)
///
/// ALUR FOREGROUND:
///   FCM onMessage → handleForeground() → provider.handleIncoming()
///   → stream emit → RoomChatPage StreamBuilder rebuild
///
/// ALUR BACKGROUND:
///   FCM background isolate → firebaseBackgroundHandler()
///   → FcmChatQueue.enqueue() → app resume → drainQueue()
///   → provider.handleIncoming() → stream emit → UI update
///
/// USAGE:
///   // Di main.dart
///   FirebaseMessaging.onBackgroundMessage(FcmChatService.backgroundHandler);
///   await FcmChatService.instance.initialize(provider: fcmChatProvider);
/// ═══════════════════════════════════════════════════════════════

// ─────────────────────────────────────────────────────────────────
// TOP-LEVEL FUNCTION (wajib top-level untuk background isolate)
// Daftarkan di main.dart: FirebaseMessaging.onBackgroundMessage(firebaseChatBgHandler)
// ─────────────────────────────────────────────────────────────────
@pragma('vm:entry-point')
Future<void> firebaseChatBgHandler(RemoteMessage message) async {
  debugPrint(
      '[FcmChatService] 🌙 Background message: ${message.messageId}');

  // Background isolate: hanya bisa pakai SharedPreferences, tidak bisa Provider
  // Semua pesan chat masuk ke queue untuk diproses saat app resume
  try {
    final parsed = _parseRemoteMessage(message);
    if (parsed == null) {
      debugPrint('[FcmChatService] ⚠️ Background: bukan pesan chat, skip');
      return;
    }

    await FcmChatQueue.enqueue(parsed);

    // Tampilkan notifikasi lokal di background
    final localPlugin = FlutterLocalNotificationsPlugin();
    await FcmChatNotificationHelper.createChannel(localPlugin);

    final helper = FcmChatNotificationHelper(localPlugin);
    await helper.show(
      message: parsed,
      senderName: parsed.senderName.isNotEmpty
          ? parsed.senderName
          : 'Pesan baru',
    );

    debugPrint(
        '[FcmChatService] ✅ Background: queued + notif shown');
  } catch (e) {
    debugPrint('[FcmChatService] ❌ Background error: $e');
  }
}

// ─────────────────────────────────────────────────────────────────
// MAIN SERVICE CLASS
// ─────────────────────────────────────────────────────────────────
class FcmChatService {
  static final FcmChatService instance = FcmChatService._internal();
  factory FcmChatService() => instance;
  FcmChatService._internal();

  final FlutterLocalNotificationsPlugin _notifPlugin =
      FlutterLocalNotificationsPlugin();
  late FcmChatNotificationHelper _notifHelper;

  FcmChatProvider? _provider;
  String? _activeRoomId;
  String? _currentUserId;

  bool _initialized = false;

  /// Callback saat notifikasi chat di-tap → navigasi ke room
  void Function(String roomId)? onNotificationTap;

  // =========================================
  // INIT
  // =========================================

  Future<void> initialize({
    required FcmChatProvider provider,
    void Function(String roomId)? onNotificationTap,
  }) async {
    if (_initialized) return;

    _provider = provider;
    this.onNotificationTap = onNotificationTap;
    _notifHelper = FcmChatNotificationHelper(_notifPlugin);

    await FcmChatNotificationHelper.initialize(
      _notifPlugin,
      onTap: _handleNotificationTap,
    );

    // Foreground listener
    FirebaseMessaging.onMessage.listen(_handleForeground);

    // App opened from notification (background → tap)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // App opened from terminated state
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      _handleMessageOpenedApp(initial);
    }

    _initialized = true;
    debugPrint('[FcmChatService] ✅ Initialized');
  }

  // =========================================
  // SESSION
  // =========================================

  void setCurrentUser(String userId) {
    _currentUserId = userId;
    _provider?.setCurrentUser(userId);
    debugPrint('[FcmChatService] 👤 User set: $userId');
  }

  void setActiveRoom(String? roomId) {
    _activeRoomId = roomId;
    _provider?.setActiveRoom(roomId);
    debugPrint('[FcmChatService] 🏠 Active room: $roomId');
  }

  // =========================================
  // FOREGROUND HANDLER
  // =========================================

  Future<void> _handleForeground(RemoteMessage message) async {
    debugPrint(
        '[FcmChatService] ☀️ Foreground message: ${message.messageId}');

    try {
      final parsed = _parseRemoteMessage(message);
      if (parsed == null) {
        debugPrint('[FcmChatService] ⚠️ Not a chat message, skip');
        return;
      }

      debugPrint(
          '[FcmChatService] 💬 Chat from ${parsed.senderId} → room ${parsed.roomId}');

      // Kirim ke provider (update state + stream)
      await _provider?.handleIncoming(parsed);

      // Tampilkan notifikasi hanya jika BUKAN room aktif
      if (parsed.roomId != _activeRoomId &&
          parsed.senderId != _currentUserId) {
        final senderName = _getSenderName(parsed);
        await _notifHelper.show(
          message: parsed,
          senderName: senderName,
          activeRoomId: _activeRoomId,
          currentUserId: _currentUserId,
        );
      }
    } catch (e, st) {
      debugPrint('[FcmChatService] ❌ Foreground error: $e\n$st');
    }
  }

  // =========================================
  // BACKGROUND QUEUE DRAIN
  // Panggil ini di AppLifecycleState.resumed
  // =========================================

  Future<void> drainQueue() async {
    debugPrint('[FcmChatService] 🔄 Draining background queue...');
    await _provider?.drainBackgroundQueue();
  }

  // =========================================
  // NOTIFICATION TAP
  // =========================================

  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('[FcmChatService] 👆 Notification tap (from bg)');
    final parsed = _parseRemoteMessage(message);
    if (parsed != null) {
      onNotificationTap?.call(parsed.roomId);
    }
  }

  void _handleNotificationTap(String? payload) {
    if (payload == null) return;
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final type = data['type'] as String?;
      if (type == 'chat') {
        final roomId = data['roomId'] as String?;
        if (roomId != null) {
          debugPrint(
              '[FcmChatService] 👆 Notification tap → room: $roomId');
          onNotificationTap?.call(roomId);
        }
      }
    } catch (e) {
      debugPrint('[FcmChatService] ❌ Tap parse error: $e');
    }
  }

  // =========================================
  // HELPERS
  // =========================================

  String _getSenderName(FcmChatMessage message) {
    // Gunakan callback dari provider jika ada
    if (_provider?.getSenderName != null) {
      try {
        return _provider!.getSenderName!(
            message.roomId, message.senderId);
      } catch (_) {}
    }

    // Fallback ke senderName dari payload
    if (message.senderName.isNotEmpty) {
      return message.senderName;
    }

    return 'Pesan baru';
  }

  void clearNotificationsForSender(String senderId) {
    _notifHelper.clearSender(senderId);
  }
}

// ─────────────────────────────────────────────────────────────────
// PARSE HELPER (top-level agar bisa dipakai di background isolate)
// ─────────────────────────────────────────────────────────────────

/// Parse RemoteMessage menjadi FcmChatMessage.
/// Return null jika bukan pesan chat atau data tidak valid.
FcmChatMessage? _parseRemoteMessage(RemoteMessage message) {
  try {
    final data = message.data;
    final type = data['type']?.toString() ?? '';

    // Hanya proses tipe 'chat'
    if (type != 'chat') return null;

    // Backend mengirim detail sebagai JSON string di field 'detail'
    // atau langsung sebagai flat map
    Map<String, dynamic> payload;

    if (data.containsKey('detail')) {
      final rawDetail = data['detail'];
      if (rawDetail is String && rawDetail.isNotEmpty) {
        try {
          payload = jsonDecode(rawDetail) as Map<String, dynamic>;
        } catch (_) {
          payload = data;
        }
      } else if (rawDetail is Map<String, dynamic>) {
        payload = rawDetail;
      } else {
        payload = data;
      }
    } else {
      payload = data;
    }

    // Validasi minimal
    final roomId =
        payload['room_id']?.toString() ?? payload['roomId']?.toString() ?? '';
    final senderId = payload['sender_id']?.toString() ??
        payload['senderId']?.toString() ??
        '';

    if (roomId.isEmpty || senderId.isEmpty) {
      debugPrint(
          '[FcmChatService] ⚠️ Missing roomId or senderId in payload');
      return null;
    }

    return FcmChatMessage.fromFcmPayload(payload);
  } catch (e) {
    debugPrint('[FcmChatService] ❌ Parse error: $e');
    return null;
  }
}