import 'package:intl/intl.dart';
import 'package:mpjnew/src/data/models/chat_model.dart';

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
}
