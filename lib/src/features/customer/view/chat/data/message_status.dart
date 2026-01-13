/// Status pengiriman pesan dalam sistem chat
/// 
/// Flow status:
/// [pending] -> [sent] -> [delivered] -> [read]
///     |
///     v
///  [failed]
/// 
enum MessageStatus {
  /// Pesan sedang dalam proses pengiriman ke server
  pending('pending'),
  
  /// Pesan berhasil dikirim ke server
  sent('sent'),
  
  /// Pesan berhasil diterima oleh penerima (device)
  delivered('delivered'),
  
  /// Pesan sudah dibaca oleh penerima
  read('read'),
  
  /// Pesan gagal dikirim
  failed('failed');

  final String value;
  const MessageStatus(this.value);

  /// Parse string ke MessageStatus
  static MessageStatus fromString(String? status) {
    if (status == null || status.isEmpty) return MessageStatus.pending;
    
    return MessageStatus.values.firstWhere(
      (e) => e.value.toLowerCase() == status.toLowerCase(),
      orElse: () => MessageStatus.pending,
    );
  }

  /// Cek apakah status sudah terkirim (sent atau lebih)
  bool get isSent => index >= MessageStatus.sent.index;
  
  /// Cek apakah status sudah delivered atau lebih
  bool get isDelivered => index >= MessageStatus.delivered.index;
  
  /// Cek apakah status sudah read
  bool get isRead => this == MessageStatus.read;
  
  /// Cek apakah status failed
  bool get isFailed => this == MessageStatus.failed;
  
  /// Cek apakah status masih pending
  bool get isPending => this == MessageStatus.pending;
}

/// Tipe konten pesan
enum MessageContentType {
  /// Pesan teks biasa
  text('text'),
  
  /// Pesan berisi paket/produk
  paket('paket'),
  
  /// Pesan berisi penawaran
  penawaran('penawaran'),
  
  /// Pesan berisi pesanan (hasil dari penawaran yang sudah dibayar)
  pesanan('pesanan'),
  
  /// Pesan berisi gambar
  image('image'),
  
  /// Pesan sistem (notifikasi, dll)
  system('system');

  final String value;
  const MessageContentType(this.value);

  static MessageContentType fromString(String? type) {
    if (type == null || type.isEmpty) return MessageContentType.text;
    
    return MessageContentType.values.firstWhere(
      (e) => e.value.toLowerCase() == type.toLowerCase(),
      orElse: () => MessageContentType.text,
    );
  }
}

/// Tipe user dalam chat
enum ChatUserType {
  customer('customer'),
  vendor('vendor'),
  system('system');

  final String value;
  const ChatUserType(this.value);

  static ChatUserType fromString(String? type) {
    if (type == null || type.isEmpty) return ChatUserType.customer;
    
    return ChatUserType.values.firstWhere(
      (e) => e.value.toLowerCase() == type.toLowerCase(),
      orElse: () => ChatUserType.customer,
    );
  }
}