/// Notification Type Enum
enum NotificationType {
  chat,
  like,
  progress,
  review,
  payment,
  unknown;

  static NotificationType fromString(String? type) {
    switch (type?.toLowerCase()) {
      case 'chat':
        return NotificationType.chat;
      case 'like':
        return NotificationType.like;
      case 'progress':
      case 'progres':
        return NotificationType.progress;
      case 'review':
      case 'ulasan':
        return NotificationType.review;
      case 'payment':
        return NotificationType.payment;
      default:
        return NotificationType.unknown;
    }
  }
}
