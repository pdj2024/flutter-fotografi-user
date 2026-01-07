import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mpjnew/src/data/models/chat_model.dart';
import 'package:mpjnew/src/features/customer/widget/dialog/custom_snackbar.dart';
import 'package:path/path.dart' as p;

class Helper {
  static void copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    CustomSnackbar.showSuccessSnackbar(context, "$label berhasil disalin");
  }

  static formatCurrency(num value, {String prefix = "IDR "}) {
    return "$prefix${NumberFormat("#,##0", "id_ID").format(value)}";
  }

  static String formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
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

  static String capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }
}

class CurrencyFormatter extends TextInputFormatter {
  final NumberFormat formatter = NumberFormat("#,##0", "id_ID");
  final String prefix;

  CurrencyFormatter({this.prefix = "IDR "});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Jika user menghapus semua, jangan error
    if (newValue.text.isEmpty || newValue.text == prefix.trim()) {
      return TextEditingValue(
        text: "",
        selection: const TextSelection.collapsed(offset: 0),
      );
    }

    // Buang prefix sebelum memproses
    String rawText = newValue.text.replaceAll(prefix, "");

    // Hilangkan karakter non-digit
    String digitsOnly = rawText.replaceAll(RegExp(r'[^0-9]'), "");

    if (digitsOnly.isEmpty) {
      return TextEditingValue(
        text: "",
        selection: const TextSelection.collapsed(offset: 0),
      );
    }

    // Ubah ke angka
    final number = int.parse(digitsOnly);

    // Format ulang
    final formatted = "$prefix${formatter.format(number)}";

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
