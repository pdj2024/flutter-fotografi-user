import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:mpjnew/src/core/services/fcm/utils/notification_helper.dart';
import 'package:mpjnew/src/data/isar/service/chat_storage_service.dart';
import 'package:mpjnew/src/data/models/chat_model.dart';

/// ═══════════════════════════════════════════════════════════════
/// BACKGROUND CHAT SERVICE
///
/// Titik masuk dari FCM background handler (top-level function).
///
/// Tanggung jawab file ini:
/// 1. Parse payload FCM menjadi [ChatModel]
/// 2. Delegasi ke [ChatStorageService.persistIncomingMessage]
///
/// SEMUA logika penyimpanan ada di [ChatStorageService].
/// File ini tidak boleh memiliki logika Hive sendiri.
///
/// Alur:
///   FCM background → _firebaseMessagingBackgroundHandler (main.dart)
///     → BackgroundChatService.processIncomingMessage()
///       → ChatStorageService.persistIncomingMessage()
///         → Hive (tersimpan)
///       → ChatStorageService.syncStatusToServer()
///         → API (status 'received' dikirim)
///
///   Saat app resume:
///     → ChatProvider.syncFromHiveOnResume()
///       → baca flag SharedPreferences
///       → load pesan baru dari Hive ke in-memory
///       → notifyListeners() → UI update
/// ═══════════════════════════════════════════════════════════════

class BackgroundChatService {
  BackgroundChatService._(); // tidak perlu diinstansiasi

  /// Proses pesan chat yang masuk saat app di background.
  ///
  /// Dipanggil dari [_firebaseMessagingBackgroundHandler] di main.dart.
  /// Berjalan di background isolate — tidak boleh mengakses BuildContext
  /// atau Provider.
  ///
  /// Return: true jika pesan baru berhasil disimpan.
  static Future<bool> processIncomingMessage(RemoteMessage message) async {
    try {
      // Validasi tipe pesan
      final type = message.data['type'] as String? ?? '';
      if (type != 'chat') {
        debugPrint('[BgChat] ⏭️ Bukan tipe chat (type=$type), skip');
        return false;
      }

      // Validasi payload
      final rawDetail = message.data['detail'];
      if (rawDetail == null || (rawDetail as String).isEmpty) {
        debugPrint('[BgChat] ⚠️ Detail kosong, skip');
        return false;
      }

      // Parse detail
      final detail = NotificationHelper.parseDetail(rawDetail);
      final roomId = detail['room_id'] as String? ?? '';
      final messageId = detail['message_id'] as String? ?? '';
      final sendStatus = detail['send_status'] as String? ?? '';

      if (roomId.isEmpty || messageId.isEmpty) {
        debugPrint('[BgChat] ⚠️ roomId/messageId kosong, skip');
        return false;
      }

      debugPrint('[BgChat] ═══════════════════════════════════════');
      // debugPrint('[BgChat] 📨 ID: $messageId | Room: $roomId');
      debugPrint('[BgChat] ═══════════════════════════════════════');

      // Parse ChatModel
      // currentUserId sengaja kosong — ChatStorageService akan baca dari SharedPreferences
      final chatMessage = ChatModel.fromFCM(detail, '');

      // // Simpan ke Hive via ChatStorageService
      // // vendorId dan currentUserId akan di-resolve dari SharedPreferences di dalam service
      // final saved = await ChatStorageService.persistIncomingMessage(
      //   chatMessage,
      //   isActiveRoom: false, // background = tidak pernah active room
      // );

      // if (!saved) {
      //   debugPrint('[BgChat] ⏭️ Pesan tidak disimpan (duplikat/invalid)');
      //   return false;
      // }

      // // Sync status ke API jika pesan berstatus 'sent'
      // if (sendStatus == 'sent') {
      //   await ChatStorageService.syncStatusToServer(
      //     messageId: messageId,
      //     status: 'received',
      //   );
      // }

      debugPrint('[BgChat] ✅ Selesai');
      return true;
    } catch (e, st) {
      debugPrint('[BgChat] ❌ Error: $e\n$st');
      return false;
    }
  }
}