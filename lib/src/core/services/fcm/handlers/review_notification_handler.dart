import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../utils/notification_channel_manager.dart';
import '../utils/notification_helper.dart';

class ReviewNotificationHandler {
  final FlutterLocalNotificationsPlugin notificationsPlugin;
  final Function(Map<String, dynamic>)? onReviewReceived;

  ReviewNotificationHandler({
    required this.notificationsPlugin,
    this.onReviewReceived,
  });

  /// Handle review message
  Future<void> handleMessage(RemoteMessage message) async {
    debugPrint('[ReviewHandler] ⭐ Handling review message...');

    try {
      final detail = NotificationHelper.parseDetail(message.data['detail']);

      // Trigger callback
      onReviewReceived?.call(detail);

      // Show notification
      await showNotification(message);
    } catch (e, st) {
      debugPrint('[ReviewHandler] ❌ Error: $e');
      debugPrint('[ReviewHandler] Stack: $st');
    }
  }

  /// Show review notification
  Future<void> showNotification(RemoteMessage message) async {
    try {
      final detail = NotificationHelper.parseDetail(message.data['detail']);

      final userName = detail['user_name'] as String? ?? 'Someone';
      final rating = detail['rating'] as num? ?? 0;
      final comment = detail['comment'] as String? ?? '';
      final orderId = detail['order_id'] as String? ?? '';

      debugPrint('[ReviewHandler] 🔔 Showing notification');
      debugPrint('[ReviewHandler]   User: $userName');
      debugPrint('[ReviewHandler]   Rating: $rating');

      final title = '⭐ New Review - ${_getStars(rating.toInt())}';
      final body = comment.isNotEmpty
          ? '$userName: $comment'
          : '$userName gave you a ${rating.toInt()}-star review';

      final androidDetails = AndroidNotificationDetails(
        NotificationChannelManager.reviewChannelId,
        'Reviews',
        channelDescription: 'Notifications for new reviews',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: 'ic_stat_pacific_data_jaya',
        styleInformation: BigTextStyleInformation(
          body,
          contentTitle: title,
        ),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final payload = NotificationHelper.createPayload({
        'type': 'review',
        'orderId': orderId,
        'rating': rating,
      });

      await notificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch % 100000,
        title,
        body,
        notificationDetails,
        payload: payload,
      );

      debugPrint('[ReviewHandler] ✅ Notification shown');
    } catch (e, st) {
      debugPrint('[ReviewHandler] ❌ Error: $e');
      debugPrint('[ReviewHandler] Stack: $st');
    }
  }

  String _getStars(int rating) {
    return '⭐' * rating.clamp(1, 5);
  }
}