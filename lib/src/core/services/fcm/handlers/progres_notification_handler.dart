import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/services/fcm/fcm_service.dart';
import 'package:mpjnew/src/core/services/fcm/utils/notification_channel_manager.dart';
import 'package:mpjnew/src/core/services/fcm/utils/notification_helper.dart';
import 'package:mpjnew/src/data/models/history_order_model.dart';

class ProgressNotificationHandler {
  final FlutterLocalNotificationsPlugin notificationsPlugin;
  final Function(HistoryOrderModel)? onProgressReceived;

  ProgressNotificationHandler({
    required this.notificationsPlugin,
    this.onProgressReceived,
  });

  /// ✅ Handle progress message - FOREGROUND & DATA PROCESSING
  Future<void> handleMessage(RemoteMessage message) async {
    debugPrint('═══════════════════════════════════════════════════');
    debugPrint('[ProgressHandler] 📊 HANDLING PROGRESS MESSAGE');
    debugPrint('═══════════════════════════════════════════════════');

    try {
      // ✅ STEP 1: Parse data dari FCM
      final progressData = parseProgressData(message);

      if (progressData == null) {
        debugPrint('[ProgressHandler] ⚠️ Failed to parse progress data');
        return;
      }

      debugPrint('[ProgressHandler] ✅ Progress data parsed successfully');
      debugPrint('[ProgressHandler]   Order: ${progressData.noOrder}');
      debugPrint(
          '[ProgressHandler]   Status: ${progressData.statusProgressPesanan}');
      debugPrint('[ProgressHandler]   Sender: ${progressData.senderId}');
      debugPrint('[ProgressHandler]   Description: ${progressData.deskripsi}');

      // ✅ STEP 2: Trigger callback untuk update provider
      // Ini akan mengupdate HistoryOrderProvider
      if (onProgressReceived != null) {
        onProgressReceived!(progressData);
        debugPrint(
            '[ProgressHandler] ✅ Callback triggered - Provider will update');
      } else {
        debugPrint('[ProgressHandler] ⚠️ No callback registered');
      }

      // ✅ STEP 3: Show notification
      await showNotification(message, progressData);

      debugPrint('[ProgressHandler] ✅ Message handling complete');
    } catch (e, st) {
      debugPrint('[ProgressHandler] ❌ Error: $e');
      debugPrint('[ProgressHandler] Stack: $st');
    }

    debugPrint('═══════════════════════════════════════════════════');
  }

  /// ✅ Parse progress data dari FCM message
  HistoryOrderModel? parseProgressData(RemoteMessage message) {
    try {
      final data = message.data;

      debugPrint('[ProgressHandler] 🔍 Parsing progress data...');
      debugPrint('[ProgressHandler]   Raw data: $data');

      // ✅ PERBAIKAN: Parse 'detail' field yang berupa JSON string
      Map<String, dynamic> detailData;

      if (data.containsKey('detail')) {
        final detailString = data['detail'];

        if (detailString is String) {
          // Detail masih berupa string, perlu di-parse
          debugPrint('[ProgressHandler]   Detail is String, parsing JSON...');
          detailData = jsonDecode(detailString) as Map<String, dynamic>;
        } else if (detailString is Map) {
          // Detail sudah berupa Map
          debugPrint('[ProgressHandler]   Detail is already Map');
          detailData = detailString as Map<String, dynamic>;
        } else {
          debugPrint('[ProgressHandler] ❌ Invalid detail format');
          return null;
        }
      } else {
        // Fallback: gunakan data langsung jika tidak ada 'detail'
        debugPrint('[ProgressHandler]   No detail field, using data directly');
        detailData = data;
      }

      debugPrint('[ProgressHandler]   Parsed detail: $detailData');

      // ✅ Parse menggunakan fromFCM
      final historyOrder = HistoryOrderModel.fromFCM(detailData);

      debugPrint('[ProgressHandler] ✅ HistoryOrderModel created');
      return historyOrder;
    } catch (e, st) {
      debugPrint('[ProgressHandler] ❌ Parse error: $e');
      debugPrint('[ProgressHandler]   Stack: $st');
      return null;
    }
  }

  /// ✅ Show progress notification
  Future<void> showNotification(
    RemoteMessage message,
    HistoryOrderModel progressData,
  ) async {
    try {
      debugPrint('[ProgressHandler] 🔔 Showing notification...');

      // ✅ Get status info using enum
      final status = OrderProgressStatus.fromString(
        progressData.statusProgressPesanan,
      );

      // ✅ Build notification content
      final title = '${status.emoji} ${status.title}';
      final body = progressData.deskripsi.isNotEmpty
          ? progressData.deskripsi
          : status.description;

      debugPrint('[ProgressHandler]   Title: $title');
      debugPrint('[ProgressHandler]   Body: $body');
      debugPrint('[ProgressHandler]   Status: ${status.name}');

      // ✅ Android notification details
      final androidDetails = AndroidNotificationDetails(
        NotificationChannelManager.progressChannelId,
        'Order Progress',
        channelDescription: 'Notifications for order progress updates',
        importance: Importance.high,
        priority: Priority.high,
        icon: 'ic_stat_pacific_data_jaya',
        enableVibration: true,
        playSound: true,
        styleInformation: BigTextStyleInformation(
          body,
          contentTitle: title,
          summaryText: 'Pesanan #${progressData.noOrder}',
        ),
        showWhen: true,
        when: DateTime.now().millisecondsSinceEpoch,
        color: Constants.primaryColor,
        category: AndroidNotificationCategory.status,
        // ✅ Add action buttons for certain statuses
        actions: _getNotificationActions(status),
      );

      // ✅ iOS notification details
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        categoryIdentifier: 'ORDER_PROGRESS',
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // ✅ Create payload untuk notification tap
      final payload = NotificationHelper.createPayload({
        'type': 'progress',
        'orderId': progressData.noOrder,
        'progressId': progressData.noId,
        'status': progressData.statusProgressPesanan,
      });

      // ✅ Show notification dengan ID unik per order
      final notificationId = NotificationHelper.generateNotificationId(
        progressData.noOrder,
      );

      await notificationsPlugin.show(
        notificationId,
        title,
        body,
        notificationDetails,
        payload: payload,
      );

      debugPrint(
          '[ProgressHandler] ✅ Notification shown (ID: $notificationId)');
    } catch (e, st) {
      debugPrint('[ProgressHandler] ❌ Notification error: $e');
      debugPrint('[ProgressHandler] Stack: $st');
    }
  }

  List<AndroidNotificationAction>? _getNotificationActions(
    OrderProgressStatus status,
  ) {
    switch (status) {
      case OrderProgressStatus.revisi:
        return [
          const AndroidNotificationAction(
            'view_order',
            'Lihat Detail',
            showsUserInterface: true,
          ),
        ];

      case OrderProgressStatus.selesai:
        return [
          const AndroidNotificationAction(
            'view_order',
            'Lihat Pesanan',
            showsUserInterface: true,
          ),
          const AndroidNotificationAction(
            'review',
            'Beri Ulasan',
            showsUserInterface: true,
          ),
        ];

      default:
        return [
          const AndroidNotificationAction(
            'view_order',
            'Lihat Detail',
            showsUserInterface: true,
          ),
        ];
    }
  }
}
