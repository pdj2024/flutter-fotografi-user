import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mpjnew/src/data/models/chat_model.dart';
import 'package:path/path.dart' as p;

class Helper {
static formatCurrency(num value, {String prefix = "IDR "}) {
    return "$prefix${NumberFormat("#,##0", "id_ID").format(value)}";
  }

  static Map<String, List<ChatModel>> groupMessagesByDate(
      List<ChatModel> messages) {
    final Map<String, List<ChatModel>> grouped = {};
    for (var message in messages) {
      final key = _formatDateLabel(message.sentAt);
      grouped.putIfAbsent(key, () => []).add(message);
    }
    return grouped;
  }

  static String _formatDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) return "Hari ini";
    if (messageDate == today.subtract(const Duration(days: 1)))
      return "Kemarin";

    return DateFormat("d MMM yyyy", "id_ID").format(date);
  }

  static int parseCurrencyToInt(String text) {
    // hapus IDR, spasi, dan titik
    String cleaned = text
        .replaceAll("IDR", "")
        .replaceAll("Rp", "") // kalau pakai Rp juga aman
        .replaceAll(".", "")
        .replaceAll(",", "")
        .trim();

    if (cleaned.isEmpty) return 0;

    return int.parse(cleaned);
  }

  static String getContentType(File file) {
    final ext = p.extension(file.path).toLowerCase();

    switch (ext) {
      case ".jpg":
      case ".jpeg":
        return "image/jpeg";
      case ".png":
        return "image/png";
      case ".webp":
        return "image/webp";
      case ".gif":
        return "image/gif";
      case ".svg":
        return "image/svg+xml";

      case ".mp4":
        return "video/mp4";
      case ".mov":
        return "video/quicktime";

      case ".pdf":
        return "application/pdf";
      case ".txt":
        return "text/plain";
      case ".json":
        return "application/json";

      default:
        return "application/octet-stream"; // fallback
    }
  }

  static int offsetTimeZone(String zone) {
    switch (zone) {
      case "WIB":
        return 7;
      case "WITA":
        return 8;
      case "WIT":
        return 9;
      default:
        return 0;
    }
  }

  static DateTime toUTC(DateTime date, TimeOfDay time, String zone) {
    final local = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    // ubah ke utc + pastikan Kind = UTC
    final utc = local.subtract(Duration(hours: offsetTimeZone(zone)));

    return DateTime.utc(
      utc.year,
      utc.month,
      utc.day,
      utc.hour,
      utc.minute,
    );
  }

  static String getZonaIndonesia(DateTime date) {
    Duration offset = date.timeZoneOffset;

    if (offset.inHours == 7) return "WIB";
    if (offset.inHours == 8) return "WITA";
    if (offset.inHours == 9) return "WIT";

    return ""; // kosong jika di luar Indonesia
  }

  static String toLocalTime(DateTime date) {
    DateTime tglUTC = DateTime.parse(date.toIso8601String());

    DateTime local = tglUTC.toLocal();

    String zona = getZonaIndonesia(local);
    String jam = DateFormat("HH:mm").format(local);

    return "$jam $zona";
  }
}
