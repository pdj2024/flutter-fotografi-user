import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/services/fcm/utils/notification_channel_manager.dart';
import 'package:mpjnew/src/core/services/fcm/utils/notification_helper.dart';
import 'package:mpjnew/src/data/hive_entity/pesanan_model.dart';

class PaymentNotificationHandler {
  final FlutterLocalNotificationsPlugin notificationsPlugin;

  /// Callback dipanggil saat payment notification diterima,
  /// membawa [PesananModel] dengan data terbaru untuk update UI.
  final Function(PesananModel)? onPaymentReceived;

  PaymentNotificationHandler({
    required this.notificationsPlugin,
    this.onPaymentReceived,
  });

  // =========================================
  // HANDLE MESSAGE (FOREGROUND)
  // =========================================

  Future<void> handleMessage(RemoteMessage message) async {
    _log('💳 HANDLING PAYMENT MESSAGE');
    _log('Message ID: ${message.messageId}');
    _log('Raw Data: ${message.data}');

    try {
      final pesanan = parseFromMessage(message);

      if (pesanan == null) {
        _log('⚠️ Failed to parse pesanan — showing generic notification');
        await _showGenericNotification(message);
        return;
      }

      _log('✅ Parsed PesananModel: ${pesanan.noBukti} | statusBayar: ${pesanan.statusBayar}');

      // Trigger callback → update UI/Provider
      if (onPaymentReceived != null) {
        _log('📤 Triggering onPaymentReceived callback...');
        onPaymentReceived!(pesanan);
      } else {
        _log('⚠️ No callback registered');
      }

      // Show local notification
      await showNotification(message, pesanan);
    } catch (e, st) {
      _log('❌ Error handling message: $e\n$st');
      await _showGenericNotification(message);
    }
  }

  // =========================================
  // PARSE — Gunakan PesananModel.fromJson
  // =========================================

  /// Parse [RemoteMessage] menjadi [PesananModel].
  /// Mendukung struktur:
  ///   - data['detail'] = JSON string berisi field pesanan
  ///   - data['payload'] = JSON string berisi field pesanan
  ///   - data langsung berisi field pesanan
  PesananModel? parseFromMessage(RemoteMessage message) {
    try {
      final data = message.data;
      _log('🔍 Parsing message data...');

      Map<String, dynamic> jsonMap = {};

      if (data.containsKey('detail')) {
        jsonMap = _tryDecodeJson(data['detail']) ?? {};
      } else if (data.containsKey('payload')) {
        jsonMap = _tryDecodeJson(data['payload']) ?? {};
      }

      // Fallback: gunakan raw data langsung
      if (jsonMap.isEmpty) {
        _log('📋 Using raw data as fallback');
        jsonMap = Map<String, dynamic>.from(data);
      }

      _log('📦 Final JSON keys: ${jsonMap.keys.toList()}');

      // Normalisasi key agar cocok dengan PesananModel.fromJson
      // (server kadang kirim snake_case, model expect PascalCase)
      final normalized = _normalizeKeys(jsonMap);

      _log('📦 Normalized keys: ${normalized.keys.toList()}');

      final pesanan = PesananModel.fromJson(normalized);

      // Minimal validation
      if (pesanan.noBukti.isEmpty) {
        _log('❌ noBukti kosong — data tidak valid');
        return null;
      }

      return pesanan;
    } catch (e, st) {
      _log('❌ Parse error: $e\n$st');
      return null;
    }
  }

  /// Normalisasi key dari snake_case / camelCase ke PascalCase
  /// sesuai format yang diharapkan [PesananModel.fromJson].
  Map<String, dynamic> _normalizeKeys(Map<String, dynamic> raw) {
    const keyMap = {
      // snake_case → PascalCase
      'no_bukti': 'No_Bukti',
      'no_tracking_pesanan': 'No_Tracking_Pesanan',
      'status': 'Status',
      'status_progress_pesanan': 'Status_Progress_Pesanan',
      'status_progres_pesanan': 'Status_Progress_Pesanan',
      'deskripsi_progress_pesanan': 'Deskripsi_Progress_Pesanan',
      'no_penawaran': 'No_Penawaran',
      'id_vendor': 'Id_Vendor',
      'nama_vendor': 'Nama_Vendor',
      'id_media_vendor': 'Id_Media_Vendor',
      'id_customer': 'Id_Customer',
      'nama_customer': 'Nama_Customer',
      'id_paket': 'Id_Paket',
      'nama_paket': 'Nama_Paket',
      'harga': 'Harga',
      'lokasi': 'Lokasi',
      'kota': 'Kota',
      'nama_kota': 'Nama_Kota',
      'tgl_realisasi': 'Tgl_Realisasi',
      'metode_bayar': 'Metode_Bayar',
      'status_bayar': 'Status_Bayar',
      'id_payment_gateway': 'Id_Payment_Gateway',
      'order_id_midtrans': 'Order_Id_Midtrans',
      'expiry_time': 'Expiry_Time',
      'payment_number_1': 'Payment_Number_1',
      'payment_number_2': 'Payment_Number_2',
      'link_snap': 'Link_Snap',
      'link_url': 'Link_Url',
      'subtotal': 'Subtotal',
      'tot_dpp': 'Tot_DPP',
      'ppn': 'PPN',
      'incl_ppn': 'Incl_PPN',
      'tot_ppn': 'Tot_PPN',
      'grand_total': 'Grand_Total',
      'created_at': 'Created_At',
      'updated_at': 'Updated_At',
      // camelCase → PascalCase
      'noBukti': 'No_Bukti',
      'noTrackingPesanan': 'No_Tracking_Pesanan',
      'statusBayar': 'Status_Bayar',
      'statusProgressPesanan': 'Status_Progress_Pesanan',
      'metodeBayar': 'Metode_Bayar',
      'grandTotal': 'Grand_Total',
      'idVendor': 'Id_Vendor',
      'idCustomer': 'Id_Customer',
      'idPaket': 'Id_Paket',
      'namaPaket': 'Nama_Paket',
      'tglRealisasi': 'Tgl_Realisasi',
      'expiryTime': 'Expiry_Time',
      'linkSnap': 'Link_Snap',
      'linkUrl': 'Link_Url',
      'totDpp': 'Tot_DPP',
      'totPpn': 'Tot_PPN',
      'inclPpn': 'Incl_PPN',
      'createdAt': 'Created_At',
      'updatedAt': 'Updated_At',
      'orderIdMidtrans': 'Order_Id_Midtrans',
      'paymentNumber1': 'Payment_Number_1',
      'paymentNumber2': 'Payment_Number_2',
      'idPaymentGateway': 'Id_Payment_Gateway',
    };

    final result = <String, dynamic>{};

    raw.forEach((key, value) {
      final mappedKey = keyMap[key] ?? key;
      result[mappedKey] = value;
    });

    return result;
  }

  Map<String, dynamic>? _tryDecodeJson(dynamic value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) return value;
    if (value is String) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map<String, dynamic>) return decoded;
      } catch (e) {
        _log('⚠️ JSON decode failed: $e');
      }
    }
    return null;
  }

  // =========================================
  // SHOW NOTIFICATION
  // =========================================

  Future<void> showNotification(
    RemoteMessage message,
    PesananModel pesanan,
  ) async {
    try {
      final statusBayar = pesanan.statusBayar?.toLowerCase() ?? '';
      final orderRef = pesanan.noTrackingPesanan ?? "";

      final _NotifContent content = _resolveContent(statusBayar, orderRef);

      _log('🔔 Showing notification: ${content.title}');

      final androidDetails = AndroidNotificationDetails(
        NotificationChannelManager.progressChannelId,
        'Payment Updates',
        channelDescription: 'Notifikasi update status pembayaran',
        importance: Importance.max,
        priority: Priority.high,
        icon: 'ic_stat_pacific_data_jaya',
        enableVibration: true,
        playSound: true,
        color: Constants.primaryColor,
        showWhen: true,
        when: DateTime.now().millisecondsSinceEpoch,
        category: AndroidNotificationCategory.status,
        styleInformation: BigTextStyleInformation(
          content.body,
          contentTitle: content.title,
          summaryText: pesanan.metodeBayar != null
              ? 'Via ${pesanan.metodeBayar}'
              : 'Pesanan #${pesanan.noTrackingPesanan}',
        ),
        actions: _getActions(statusBayar),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        categoryIdentifier: 'PAYMENT_UPDATE',
      );

      final payload = NotificationHelper.createPayload({
        'type': 'payment',
        'noBukti': pesanan.noBukti,
        'statusBayar': pesanan.statusBayar ?? '',
        'noTrackingPesanan': pesanan.noTrackingPesanan ?? '',
      });

      final notifId = NotificationHelper.generateNotificationId(
        'payment_${pesanan.noTrackingPesanan}',
      );

      await notificationsPlugin.show(
        notifId,
        content.title,
        content.body,
        NotificationDetails(android: androidDetails, iOS: iosDetails),
        payload: payload,
      );

      _log('✅ Notification shown (ID: $notifId)');
    } catch (e, st) {
      _log('❌ showNotification error: $e\n$st');
    }
  }

  _NotifContent _resolveContent(String statusBayar, String orderRef) {
    switch (statusBayar) {
      case 'capture':
      case 'settlement':
      case 'berhasil':
      case 'success':
        return _NotifContent(
          title: '✅ Pembayaran Berhasil',
          body: 'Pembayaran untuk pesanan $orderRef telah berhasil diproses.',
        );
      case 'pending':
      case 'menunggu':
        return _NotifContent(
          title: '⏳ Menunggu Pembayaran',
          body: 'Menunggu konfirmasi pembayaran untuk pesanan $orderRef.',
        );
      case 'expired':
      case 'kadaluarsa':
        return _NotifContent(
          title: '⏰ Pembayaran Kadaluarsa',
          body: 'Waktu pembayaran untuk pesanan $orderRef telah habis.',
        );
      case 'failed':
      case 'gagal':
        return _NotifContent(
          title: '❌ Pembayaran Gagal',
          body: 'Pembayaran untuk pesanan $orderRef gagal diproses.',
        );
      default:
        return _NotifContent(
          title: '💳 Update Pembayaran',
          body: 'Status pembayaran: $statusBayar untuk pesanan $orderRef.',
        );
    }
  }

  List<AndroidNotificationAction> _getActions(String statusBayar) {
    switch (statusBayar) {
      case 'capture':
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

  // =========================================
  // GENERIC FALLBACK
  // =========================================

  Future<void> _showGenericNotification(RemoteMessage message) async {
    try {
      final title = message.notification?.title ?? 'Update Pembayaran';
      final body = message.notification?.body ??
          'Ada update status pembayaran untuk pesanan Anda.';

      final androidDetails = AndroidNotificationDetails(
        NotificationChannelManager.progressChannelId,
        'Payment Updates',
        channelDescription: 'Notifikasi update status pembayaran',
        importance: Importance.high,
        priority: Priority.high,
        icon: 'ic_stat_pacific_data_jaya',
      );

      await notificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title,
        body,
        NotificationDetails(
          android: androidDetails,
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );

      _log('✅ Generic notification shown');
    } catch (e) {
      _log('❌ Generic notification error: $e');
    }
  }

  // =========================================
  // UTIL
  // =========================================

  void _log(String msg) {
    debugPrint('[PaymentHandler] $msg');
  }
}

/// Internal helper untuk konten notifikasi
class _NotifContent {
  final String title;
  final String body;
  const _NotifContent({required this.title, required this.body});
}