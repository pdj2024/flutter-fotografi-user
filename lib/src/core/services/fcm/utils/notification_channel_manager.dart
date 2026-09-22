import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationChannelManager {
  static const String chatChannelId = 'chat_messages';
  static const String likeChannelId = 'likes';
  static const String progressChannelId = 'order_progress';
  static const String reviewChannelId = 'reviews';
  static const String complainChannelId = 'complain';

  /// Create all notification channels
  static Future<void> createAllChannels(
    FlutterLocalNotificationsPlugin plugin,
  ) async {
    final androidPlugin = plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) return;

    await Future.wait([
      _createChatChannel(androidPlugin),
      _createLikeChannel(androidPlugin),
      _createProgressChannel(androidPlugin),
      _createReviewChannel(androidPlugin),
      _createComplainChannel(androidPlugin),
    ]);

    debugPrint('[Channels] ✅ All notification channels created');
  }

  static Future<void> _createChatChannel(
    AndroidFlutterLocalNotificationsPlugin plugin,
  ) async {
    const channel = AndroidNotificationChannel(
      chatChannelId,
      'Chat Messages',
      description: 'Notifications for new chat messages',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    await plugin.createNotificationChannel(channel);
    debugPrint('[Channels] ✅ Chat channel created');
  }

  static Future<void> _createLikeChannel(
    AndroidFlutterLocalNotificationsPlugin plugin,
  ) async {
    const channel = AndroidNotificationChannel(
      likeChannelId,
      'Likes',
      description: 'Notifications for portfolio likes',
      importance: Importance.defaultImportance,
      playSound: true,
    );

    await plugin.createNotificationChannel(channel);
    debugPrint('[Channels] ✅ Like channel created');
  }

  static Future<void> _createProgressChannel(
    AndroidFlutterLocalNotificationsPlugin plugin,
  ) async {
    const channel = AndroidNotificationChannel(
      progressChannelId,
      'Order Progress',
      description: 'Notifications for order progress updates',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await plugin.createNotificationChannel(channel);
    debugPrint('[Channels] ✅ Progress channel created');
  }

  static Future<void> _createReviewChannel(
    AndroidFlutterLocalNotificationsPlugin plugin,
  ) async {
    const channel = AndroidNotificationChannel(
      reviewChannelId,
      'Reviews',
      description: 'Notifications for new reviews',
      importance: Importance.defaultImportance,
      playSound: true,
    );

    await plugin.createNotificationChannel(channel);
    debugPrint('[Channels] ✅ Review channel created');
  }

  static Future<void> _createComplainChannel(
    AndroidFlutterLocalNotificationsPlugin plugin,
  ) async {
    const channel = AndroidNotificationChannel(
      complainChannelId,
      'Complain',
      description: 'Notifications for new complain messages',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await plugin.createNotificationChannel(channel);
    debugPrint('[Channels] ✅ Complain channel created');
  }
}