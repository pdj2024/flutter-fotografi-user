/// Notification Type Enum
enum NotificationType {
  chat,
  like,
  progress,
  review,
  payment,
  complainHeader,
  complainDetail,
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
      case 'komplain_header':
        return NotificationType.complainHeader;
      case 'komplain_detail':
        return NotificationType.complainDetail;
      default:
        return NotificationType.unknown;
    }
  }
}
