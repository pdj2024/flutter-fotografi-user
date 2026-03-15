import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'fcm_chat_message.dart';

/// ═══════════════════════════════════════════════════════════════
/// FCM CHAT QUEUE
///
/// Antrian persisten untuk menyimpan pesan FCM yang diterima
/// di background isolate, supaya bisa dibaca kembali saat app
/// resume ke foreground.
///
/// Storage: SharedPreferences (aman di background isolate)
/// Key format: fcm_chat_queue
/// ═══════════════════════════════════════════════════════════════
class FcmChatQueue {
  static const String _queueKey = 'fcm_chat_queue';
  static const String _pendingFlagKey = 'fcm_chat_has_pending';
  static const int _maxQueueSize = 100;

  // =========================================
  // ENQUEUE - Dipanggil dari background isolate
  // =========================================

  /// Tambah pesan ke antrian persisten.
  /// Thread-safe karena SharedPreferences menggunakan file locking.
  static Future<bool> enqueue(FcmChatMessage message) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = _loadQueue(prefs);

      // Deduplicate: skip jika messageId sudah ada
      if (existing.any((m) => m.messageId == message.messageId)) {
        debugPrint(
            '[FcmQueue] ⚠️ Duplicate skipped: ${message.messageId}');
        return false;
      }

      existing.add(message);

      // Trim jika melebihi batas
      final trimmed = existing.length > _maxQueueSize
          ? existing.sublist(existing.length - _maxQueueSize)
          : existing;

      await _saveQueue(prefs, trimmed);
      await prefs.setBool(_pendingFlagKey, true);

      debugPrint(
          '[FcmQueue] ✅ Enqueued: ${message.messageId} (total: ${trimmed.length})');
      return true;
    } catch (e) {
      debugPrint('[FcmQueue] ❌ Enqueue error: $e');
      return false;
    }
  }

  // =========================================
  // DEQUEUE - Dipanggil dari main isolate saat resume
  // =========================================

  /// Ambil semua pesan dari antrian dan kosongkan.
  /// Dipanggil saat app resume ke foreground.
  static Future<List<FcmChatMessage>> dequeueAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messages = _loadQueue(prefs);

      if (messages.isEmpty) return [];

      // Bersihkan antrian
      await prefs.remove(_queueKey);
      await prefs.setBool(_pendingFlagKey, false);

      debugPrint('[FcmQueue] 📦 Dequeued ${messages.length} messages');
      return messages;
    } catch (e) {
      debugPrint('[FcmQueue] ❌ Dequeue error: $e');
      return [];
    }
  }

  // =========================================
  // CHECK
  // =========================================

  /// Cek apakah ada pesan pending tanpa memuat seluruh queue.
  /// Cocok untuk quick-check saat app resume.
  static Future<bool> hasPending() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_pendingFlagKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Cek jumlah pesan pending
  static Future<int> pendingCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return _loadQueue(prefs).length;
    } catch (_) {
      return 0;
    }
  }

  // =========================================
  // INTERNAL HELPERS
  // =========================================

  static List<FcmChatMessage> _loadQueue(SharedPreferences prefs) {
    try {
      final raw = prefs.getString(_queueKey);
      if (raw == null || raw.isEmpty) return [];

      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => FcmChatMessage.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[FcmQueue] ⚠️ Load error: $e');
      return [];
    }
  }

  static Future<void> _saveQueue(
    SharedPreferences prefs,
    List<FcmChatMessage> messages,
  ) async {
    final encoded = jsonEncode(messages.map((m) => m.toJson()).toList());
    await prefs.setString(_queueKey, encoded);
  }
}