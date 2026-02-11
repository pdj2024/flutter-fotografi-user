import 'dart:convert';

class NotificationHelper {
  /// Parse detail from FCM message
  static Map<String, dynamic> parseDetail(dynamic detail) {
    if (detail is String) {
      try {
        return jsonDecode(detail) as Map<String, dynamic>;
      } catch (e) {
        print('[NotificationHelper] ⚠️ Failed to parse detail: $e');
        return {};
      }
    } else if (detail is Map) {
      return Map<String, dynamic>.from(detail);
    }
    return {};
  }

  /// Create JSON payload for notification
  static String createPayload(Map<String, dynamic> data) {
    return jsonEncode(data);
  }

  /// Parse JSON payload
  static Map<String, dynamic>? parsePayload(String? payload) {
    if (payload == null || payload.isEmpty) return null;

    try {
      return jsonDecode(payload) as Map<String, dynamic>;
    } catch (e) {
      print('[NotificationHelper] ⚠️ Failed to parse payload: $e');
      return null;
    }
  }

  /// Generate notification ID from string
  static int generateNotificationId(String id) {
    return id.hashCode;
  }

  /// Truncate text if too long
  static String truncateText(String text, {int maxLength = 100}) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - 3)}...';
  }
}