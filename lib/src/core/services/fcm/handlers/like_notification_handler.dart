import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import '../utils/notification_channel_manager.dart';
import '../utils/notification_helper.dart';

class LikeNotificationHandler {
  final FlutterLocalNotificationsPlugin notificationsPlugin;
  final Function(String portofolioId, String userId)? onLikeReceived;

  LikeNotificationHandler({
    required this.notificationsPlugin,
    this.onLikeReceived,
  });

  /// Handle like message
  Future<void> handleMessage(RemoteMessage message) async {
    debugPrint('[LikeHandler] ❤️ Handling like message...');

    try {
      final detail = NotificationHelper.parseDetail(message.data['detail']);
      final portofolioId = detail['portofolio_id'] as String?;
      final userId = detail['user_id'] as String?;

      if (portofolioId != null && userId != null) {
        onLikeReceived?.call(portofolioId, userId);
      }

      await showNotification(message);
    } catch (e, st) {
      debugPrint('[LikeHandler] ❌ Error: $e');
      debugPrint('[LikeHandler] Stack: $st');
    }
  }

  /// Show like notification
  Future<void> showNotification(RemoteMessage message) async {
    try {
      final detail = NotificationHelper.parseDetail(message.data['detail']);
      final userName = detail['user_name'] as String? ?? 'Someone';
      final portofolioTitle =
          detail['portofolio_title'] as String? ?? 'your portfolio';

      debugPrint('[LikeHandler] 🔔 Showing notification');
      debugPrint('[LikeHandler]   User: $userName');
      debugPrint('[LikeHandler]   Portfolio: $portofolioTitle');

      const androidDetails = AndroidNotificationDetails(
        NotificationChannelManager.likeChannelId,
        'Likes',
        channelDescription: 'Notifications for portfolio likes',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        color: Constants.primaryColor,
        icon: 'ic_stat_pacific_data_jaya',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final payload = NotificationHelper.createPayload({
        'type': 'like',
        'portofolioId': detail['portofolio_id'],
        'userId': detail['user_id'],
      });

      await notificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch % 100000,
        '❤️ New Like',
        '$userName liked $portofolioTitle',
        notificationDetails,
        payload: payload,
      );

      debugPrint('[LikeHandler] ✅ Notification shown');
    } catch (e, st) {
      debugPrint('[LikeHandler] ❌ Error: $e');
      debugPrint('[LikeHandler] Stack: $st');
    }
  }
}