import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/services/fcm/utils/notification_channel_manager.dart';
import 'package:mpjnew/src/core/services/fcm/utils/notification_helper.dart';

class ComplainNotificationHandler {
  final FlutterLocalNotificationsPlugin notificationsPlugin;
  final Function(String? noComplain, String? noOrder)? onHeaderReceived;
  final Function(String? noComplain, String? noOrder)? onDetailReceived;

  ComplainNotificationHandler({
    required this.notificationsPlugin,
    this.onHeaderReceived,
    this.onDetailReceived,
  });

  /// Tipe komplain_header — metadata complain berubah (status/prioritas/dll).
  Future<void> handleHeaderMessage(RemoteMessage message) async {
    await _handle(message, isHeader: true, onReceived: onHeaderReceived);
  }

  /// Tipe komplain_detail — pesan baru masuk ke satu complain.
  Future<void> handleDetailMessage(RemoteMessage message) async {
    await _handle(message, isHeader: false, onReceived: onDetailReceived);
  }

  Future<void> _handle(
    RemoteMessage message, {
    required bool isHeader,
    required Function(String?, String?)? onReceived,
  }) async {
    debugPrint(
        '[ComplainHandler] 📣 Handling ${isHeader ? 'header' : 'detail'} message');
    try {
      final detail = NotificationHelper.parseDetail(message.data['detail']);

      final noComplain =
          (detail['No_Complain'] ?? detail['no_complain'])?.toString();
      // no_order TIDAK ADA di payload komplain_detail — itu wajar, jangan
      // dianggap error. Cuma ada di komplain_header.
      final noOrder = (detail['No_Order'] ?? detail['no_order'])?.toString();

      // Backend sudah kirim title/body siap pakai — pakai langsung.
      final title = message.data['title']?.toString() ??
          (isHeader ? 'Complain diperbarui' : 'Complain');
      final body =
          message.data['body']?.toString() ?? 'Ada pembaruan pada complain Anda';

      debugPrint('[ComplainHandler]   noComplain=$noComplain noOrder=$noOrder');

      onReceived?.call(noComplain, noOrder);

      await showNotification(
        noComplain: noComplain,
        noOrder: noOrder,
        title: title,
        body: body,
        isHeader: isHeader,
      );
    } catch (e, st) {
      debugPrint('[ComplainHandler] ❌ Error: $e');
      debugPrint('$st');
    }
  }

  Future<void> showNotification({
    String? noComplain,
    String? noOrder,
    required String title,
    required String body,
    required bool isHeader,
  }) async {
    try {
      final androidDetails = AndroidNotificationDetails(
        NotificationChannelManager.complainChannelId,
        'Complain',
        channelDescription: 'Notifications for new complain messages',
        importance: Importance.high,
        priority: Priority.high,
        icon: 'ic_stat_pacific_data_jaya',
        enableVibration: true,
        playSound: true,
        styleInformation: BigTextStyleInformation(body, contentTitle: title),
        showWhen: true,
        when: DateTime.now().millisecondsSinceEpoch,
        color: Constants.primaryColor,
        category: AndroidNotificationCategory.message,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        categoryIdentifier: 'COMPLAIN',
      );

      final notificationDetails =
          NotificationDetails(android: androidDetails, iOS: iosDetails);

      final payload = NotificationHelper.createPayload({
        'type': isHeader ? 'komplain_header' : 'komplain_detail',
        'noComplain': noComplain,
        'noOrder': noOrder,
      });

      final notificationId = NotificationHelper.generateNotificationId(
        noComplain ?? noOrder ?? 'complain',
      );

      await notificationsPlugin.show(
        notificationId,
        title,
        body,
        notificationDetails,
        payload: payload,
      );
    } catch (e, st) {
      debugPrint('[ComplainHandler] ❌ Notification error: $e');
      debugPrint('$st');
    }
  }
}