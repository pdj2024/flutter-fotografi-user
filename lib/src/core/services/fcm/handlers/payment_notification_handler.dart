import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/services/fcm/utils/notification_channel_manager.dart';
import 'package:mpjnew/src/core/services/fcm/utils/notification_helper.dart';

/// Model untuk payment notification data
class PaymentNotificationData {
  final String noBukti;
  final String statusBayar;
  final String? noTrackingPesanan;
  final int? grandTotal;
  final String? paymentMethod;
  final DateTime? timestamp;

  PaymentNotificationData({
    required this.noBukti,
    required this.statusBayar,
    this.noTrackingPesanan,
    this.grandTotal,
    this.paymentMethod,
    this.timestamp,
  });

  factory PaymentNotificationData.fromJson(Map<String, dynamic> json) {
    return PaymentNotificationData(
      noBukti: json['no_bukti']?.toString() ?? json['noBukti']?.toString() ?? '',
      statusBayar: json['status_bayar']?.toString() ?? json['statusBayar']?.toString() ?? '',
      noTrackingPesanan: json['no_tracking_pesanan']?.toString() ?? json['noTrackingPesanan']?.toString(),
      grandTotal: json['grand_total'] != null ? int.tryParse(json['grand_total'].toString()) : null,
      paymentMethod: json['payment_method']?.toString() ?? json['metodeBayar']?.toString(),
      timestamp: json['timestamp'] != null ? DateTime.tryParse(json['timestamp'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'noBukti': noBukti,
    'statusBayar': statusBayar,
    'noTrackingPesanan': noTrackingPesanan,
    'grandTotal': grandTotal,
    'paymentMethod': paymentMethod,
    'timestamp': timestamp?.toIso8601String(),
  };

  @override
  String toString() {
    return 'PaymentNotificationData('
        'noBukti: $noBukti, '
        'statusBayar: $statusBayar, '
        'noTrackingPesanan: $noTrackingPesanan, '
        'grandTotal: $grandTotal, '
        'paymentMethod: $paymentMethod, '
        'timestamp: $timestamp'
        ')';
  }
}

class PaymentNotificationHandler {
  final FlutterLocalNotificationsPlugin notificationsPlugin;
  final Function(PaymentNotificationData)? onPaymentReceived;

  PaymentNotificationHandler({
    required this.notificationsPlugin,
    this.onPaymentReceived,
  });

  /// ✅ Handle payment message - FOREGROUND & DATA PROCESSING
  Future<void> handleMessage(RemoteMessage message) async {
    debugPrint('═══════════════════════════════════════════════════');
    debugPrint('[PaymentHandler] 💳 HANDLING PAYMENT MESSAGE');
    debugPrint('═══════════════════════════════════════════════════');
    debugPrint('[PaymentHandler] 📦 RAW MESSAGE DATA:');
    debugPrint('[PaymentHandler]    Message ID: ${message.messageId}');
    debugPrint('[PaymentHandler]    Sent Time: ${message.sentTime}');
    
    // ✅ STEP 1: Debug RAW data
    debugPrint('[PaymentHandler] 🔍 RAW DATA STRUCTURE:');
    debugPrint('[PaymentHandler]    Data keys: ${message.data.keys.toList()}');
    message.data.forEach((key, value) {
      debugPrint('[PaymentHandler]       $key: $value (${value.runtimeType})');
    });

    // ✅ Debug notification if present
    if (message.notification != null) {
      debugPrint('[PaymentHandler] 🔔 NOTIFICATION:');
      debugPrint('[PaymentHandler]    Title: ${message.notification!.title}');
      debugPrint('[PaymentHandler]    Body: ${message.notification!.body}');
    }

    try {
      // ✅ STEP 2: Parse data dari FCM
      final paymentData = parsePaymentData(message);

      if (paymentData == null) {
        debugPrint('[PaymentHandler] ⚠️ Failed to parse payment data');
        debugPrint('[PaymentHandler] 💡 Showing generic notification anyway');
        
        // Show generic notification with raw data
        await _showGenericNotification(message);
        return;
      }

      debugPrint('[PaymentHandler] ✅ Payment data parsed successfully');
      debugPrint('[PaymentHandler]    Data: $paymentData');

      // ✅ STEP 3: Trigger callback untuk update provider
      if (onPaymentReceived != null) {
        debugPrint('[PaymentHandler] 📤 Triggering callback to PesananProvider...');
        onPaymentReceived!(paymentData);
        debugPrint('[PaymentHandler] ✅ Callback triggered - Provider will update');
      } else {
        debugPrint('[PaymentHandler] ⚠️ No callback registered - Provider won\'t update');
      }

      // ✅ STEP 4: Show notification
      await showNotification(message, paymentData);

      debugPrint('[PaymentHandler] ✅ Message handling complete');
    } catch (e, st) {
      debugPrint('[PaymentHandler] ❌ Error: $e');
      debugPrint('[PaymentHandler] Stack: $st');
      
      // Try to show generic notification on error
      try {
        await _showGenericNotification(message);
      } catch (e2) {
        debugPrint('[PaymentHandler] ❌ Failed to show generic notification: $e2');
      }
    }

    debugPrint('═══════════════════════════════════════════════════');
  }

  /// ✅ Parse payment data dari FCM message dengan extensive debugging
  PaymentNotificationData? parsePaymentData(RemoteMessage message) {
    try {
      final data = message.data;

      debugPrint('[PaymentHandler] 🔍 PARSING PAYMENT DATA...');
      debugPrint('[PaymentHandler]    Raw data type: ${data.runtimeType}');
      debugPrint('[PaymentHandler]    Raw data: $data');

      Map<String, dynamic> detailData = {};

      // ✅ STRATEGI 1: Cek jika ada field 'detail'
      if (data.containsKey('detail')) {
        debugPrint('[PaymentHandler] 📋 Found \'detail\' field');
        final detailString = data['detail'];

        if (detailString is String) {
          debugPrint('[PaymentHandler]    Detail is String, parsing JSON...');
          debugPrint('[PaymentHandler]    Detail content: $detailString');
          
          try {
            detailData = jsonDecode(detailString) as Map<String, dynamic>;
            debugPrint('[PaymentHandler]    ✅ JSON parsed successfully');
          } catch (e) {
            debugPrint('[PaymentHandler]    ❌ JSON parse failed: $e');
            debugPrint('[PaymentHandler]    💡 Will try using raw data instead');
            detailData = data;
          }
        } else if (detailString is Map) {
          debugPrint('[PaymentHandler]    Detail is already Map');
          detailData = detailString as Map<String, dynamic>;
        } else {
          debugPrint('[PaymentHandler]    ⚠️ Unknown detail format: ${detailString.runtimeType}');
          detailData = data;
        }
      } 
      // ✅ STRATEGI 2: Cek jika ada field 'payload'
      else if (data.containsKey('payload')) {
        debugPrint('[PaymentHandler] 📋 Found \'payload\' field');
        final payloadString = data['payload'];
        
        if (payloadString is String) {
          try {
            detailData = jsonDecode(payloadString) as Map<String, dynamic>;
            debugPrint('[PaymentHandler]    ✅ Payload JSON parsed');
          } catch (e) {
            debugPrint('[PaymentHandler]    ❌ Payload parse failed: $e');
            detailData = data;
          }
        } else if (payloadString is Map) {
          detailData = payloadString as Map<String, dynamic>;
        } else {
          detailData = data;
        }
      }
      // ✅ STRATEGI 3: Gunakan data langsung
      else {
        debugPrint('[PaymentHandler] 📋 No detail/payload field, using raw data');
        detailData = data;
      }

      debugPrint('[PaymentHandler] 🔍 FINAL DETAIL DATA:');
      debugPrint('[PaymentHandler]    Keys: ${detailData.keys.toList()}');
      detailData.forEach((key, value) {
        debugPrint('[PaymentHandler]       $key: $value');
      });

      // ✅ Parse menggunakan fromJson
      final paymentData = PaymentNotificationData.fromJson(detailData);

      // ✅ Validate critical fields
      if (paymentData.noBukti.isEmpty) {
        debugPrint('[PaymentHandler] ❌ Critical field missing: noBukti is empty');
        debugPrint('[PaymentHandler] 💡 Available data: $detailData');
        return null;
      }

      if (paymentData.statusBayar.isEmpty) {
        debugPrint('[PaymentHandler] ⚠️ Warning: statusBayar is empty');
      }

      debugPrint('[PaymentHandler] ✅ PaymentNotificationData created');
      debugPrint('[PaymentHandler]    $paymentData');
      
      return paymentData;
    } catch (e, st) {
      debugPrint('[PaymentHandler] ❌ Parse error: $e');
      debugPrint('[PaymentHandler]    Stack: $st');
      debugPrint('[PaymentHandler]    Raw message data: ${message.data}');
      return null;
    }
  }

  /// ✅ Show payment notification
  Future<void> showNotification(
    RemoteMessage message,
    PaymentNotificationData paymentData,
  ) async {
    try {
      debugPrint('[PaymentHandler] 🔔 SHOWING NOTIFICATION...');

      // ✅ Determine notification content based on payment status
      String title;
      String body;
      String emoji;

      switch (paymentData.statusBayar.toLowerCase()) {
        case 'settlement':
        case 'berhasil':
        case 'success':
          emoji = '✅';
          title = '$emoji Pembayaran Berhasil';
          body = 'Pembayaran untuk pesanan ${paymentData.noTrackingPesanan ?? paymentData.noBukti} berhasil diproses.';
          break;
        
        case 'pending':
        case 'menunggu':
          emoji = '⏳';
          title = '$emoji Menunggu Pembayaran';
          body = 'Menunggu konfirmasi pembayaran untuk pesanan ${paymentData.noTrackingPesanan ?? paymentData.noBukti}.';
          break;
        
        case 'expired':
        case 'kadaluarsa':
          emoji = '⏰';
          title = '$emoji Pembayaran Kadaluarsa';
          body = 'Waktu pembayaran untuk pesanan ${paymentData.noTrackingPesanan ?? paymentData.noBukti} telah habis.';
          break;
        
        case 'failed':
        case 'gagal':
          emoji = '❌';
          title = '$emoji Pembayaran Gagal';
          body = 'Pembayaran untuk pesanan ${paymentData.noTrackingPesanan ?? paymentData.noBukti} gagal diproses.';
          break;
        
        default:
          emoji = '💳';
          title = '$emoji Update Pembayaran';
          body = 'Status pembayaran: ${paymentData.statusBayar} untuk pesanan ${paymentData.noTrackingPesanan ?? paymentData.noBukti}.';
      }

      debugPrint('[PaymentHandler]    Title: $title');
      debugPrint('[PaymentHandler]    Body: $body');
      debugPrint('[PaymentHandler]    Status: ${paymentData.statusBayar}');

      // ✅ Android notification details
      final androidDetails = AndroidNotificationDetails(
        NotificationChannelManager.progressChannelId, // Use progress channel for now
        'Payment Updates',
        channelDescription: 'Notifications for payment status updates',
        importance: Importance.max,
        priority: Priority.high,
        icon: 'ic_stat_pacific_data_jaya',
        enableVibration: true,
        playSound: true,
        styleInformation: BigTextStyleInformation(
          body,
          contentTitle: title,
          summaryText: paymentData.paymentMethod != null 
              ? 'Via ${paymentData.paymentMethod}' 
              : 'Pesanan #${paymentData.noBukti}',
        ),
        color: Constants.primaryColor,
        showWhen: true,
        when: paymentData.timestamp?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch,
        category: AndroidNotificationCategory.status,
        actions: _getNotificationActions(paymentData.statusBayar),
      );

      // ✅ iOS notification details
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        categoryIdentifier: 'PAYMENT_UPDATE',
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // ✅ Create payload untuk notification tap
      final payload = NotificationHelper.createPayload({
        'type': 'payment',
        'noBukti': paymentData.noBukti,
        'statusBayar': paymentData.statusBayar,
        'noTrackingPesanan': paymentData.noTrackingPesanan,
      });

      // ✅ Show notification dengan ID unik per order
      final notificationId = NotificationHelper.generateNotificationId(
        'payment_${paymentData.noBukti}',
      );

      await notificationsPlugin.show(
        notificationId,
        title,
        body,
        notificationDetails,
        payload: payload,
      );

      debugPrint('[PaymentHandler] ✅ Notification shown (ID: $notificationId)');
    } catch (e, st) {
      debugPrint('[PaymentHandler] ❌ Notification error: $e');
      debugPrint('[PaymentHandler] Stack: $st');
    }
  }

  /// ✅ Show generic notification when parsing fails
  Future<void> _showGenericNotification(RemoteMessage message) async {
    try {
      debugPrint('[PaymentHandler] 🔔 Showing generic notification...');

      final title = message.notification?.title ?? 'Update Pembayaran';
      final body = message.notification?.body ?? 'Ada update pembayaran untuk pesanan Anda.';

      final androidDetails = AndroidNotificationDetails(
        NotificationChannelManager.progressChannelId,
        'Payment Updates',
        channelDescription: 'Notifications for payment status updates',
        importance: Importance.high,
        priority: Priority.high,
        icon: 'ic_stat_pacific_data_jaya',
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

      await notificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title,
        body,
        notificationDetails,
      );

      debugPrint('[PaymentHandler] ✅ Generic notification shown');
    } catch (e) {
      debugPrint('[PaymentHandler] ❌ Generic notification error: $e');
    }
  }

  /// ✅ Get notification actions based on payment status
  List<AndroidNotificationAction>? _getNotificationActions(String statusBayar) {
    switch (statusBayar.toLowerCase()) {
      case 'settlement':
      case 'berhasil':
      case 'success':
        return [
          const AndroidNotificationAction(
            'view_order',
            'Lihat Pesanan',
            showsUserInterface: true,
          ),
        ];

      case 'expired':
      case 'kadaluarsa':
      case 'failed':
      case 'gagal':
        return [
          const AndroidNotificationAction(
            'retry_payment',
            'Coba Lagi',
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