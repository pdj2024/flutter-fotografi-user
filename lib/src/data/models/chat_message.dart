// import 'package:intl/intl.dart';

// class ChatMessage {
//   final String text;
//   final DateTime time;
//   final bool isMe;
//   final String category;
//   final int? hargaPaket;
//   final DateTime? tglRealisasi;
//   final String? lokasiPaket;
//   final String? namaPaket;

//   ChatMessage({
//     required this.text,
//     required this.time,
//     required this.isMe,
//     required this.category,
//     this.hargaPaket,
//     this.tglRealisasi,
//     this.lokasiPaket,
//     this.namaPaket,
//   });
// }

// Map<String, List<ChatMessage>> groupMessagesByDate(List<ChatMessage> messages) {
//   final Map<String, List<ChatMessage>> grouped = {};
//   for (var message in messages) {
//     final key = _formatDateLabel(message.time);
//     grouped.putIfAbsent(key, () => []).add(message);
//   }
//   return grouped;
// }

// String _formatDateLabel(DateTime date) {
//   final now = DateTime.now();
//   final today = DateTime(now.year, now.month, now.day);
//   final messageDate = DateTime(date.year, date.month, date.day);

//   if (messageDate == today) return "Hari ini";
//   if (messageDate == today.subtract(const Duration(days: 1))) return "Kemarin";

//   return DateFormat("d MMM yyyy", "id_ID").format(date);
// }