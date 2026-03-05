// ════════════════════════════════════════════════════════════════════════
// order_status_flow.dart
//
// Definisi alur status pesanan — digunakan oleh KEDUA app.
//
// Salin file ini ke:
//   • Vendor  : lib/src/features/vendor/viewmodels/order_status_flow.dart
//   • Customer: lib/src/features/customer/viewmodels/order_status_flow.dart
//
// Tidak ada dependency ke Flutter/package lain — pure Dart.
// ════════════════════════════════════════════════════════════════════════

// ── Alur 1 jalur linear ──────────────────────────────────────────────────
//
//   persiapan ──► proses ──► review ──► selesai
//                               │
//                               ▼
//                            revisi ──► review
//
// Transisi yang valid:
//   persiapan  → proses    (customer konfirmasi pemotretan selesai)
//   proses     → review    (vendor upload link + kirim ke review)
//   review     → revisi    (customer minta revisi)   ← UPDATED
//   revisi     → review    (vendor selesai revisi, kirim ulang ke review)
//   review     → selesai   (customer selesaikan)
// ─────────────────────────────────────────────────────────────────────────

/// Metadata satu transisi status
class StatusTransition {
  final String from;
  final String to;

  /// Label tombol aksi di UI
  final String actionLabel;

  /// Judul dialog konfirmasi
  final String confirmTitle;

  /// Pesan dialog konfirmasi
  final String confirmMessage;

  const StatusTransition({
    required this.from,
    required this.to,
    required this.actionLabel,
    required this.confirmTitle,
    required this.confirmMessage,
  });
}

/// Pusat aturan alur status pesanan fotografi
class OrderStatusFlow {
  // ── Tabel semua transisi yang valid ─────────────────────────────────
  static const List<StatusTransition> transitions = [
    StatusTransition(
      from: 'persiapan',
      to: 'proses',
      actionLabel: 'Konfirmasi Pemotretan Selesai',
      confirmTitle: 'Konfirmasi Pemotretan',
      confirmMessage: 'Apakah sesi pemotretan sudah selesai?\n\n'
          'Pesanan akan masuk ke tahap pengerjaan oleh vendor.',
    ),
    StatusTransition(
      from: 'proses',
      to: 'review',
      actionLabel: 'Kirim ke Review',
      confirmTitle: 'Kirim Hasil ke Customer',
      confirmMessage: 'Pastikan link hasil kerja sudah diisi.\n\n'
          'Customer akan mereview hasil pengerjaan Anda.',
    ),

    // ── review → revisi (customer minta revisi) ──────────────────────
    StatusTransition(
      from: 'review',
      to: 'revisi',
      actionLabel: 'Minta Revisi',
      confirmTitle: 'Minta Revisi',
      confirmMessage: 'Pesanan akan masuk ke tahap revisi.\n\n'
          'Tuliskan catatan revisi untuk vendor.',
    ),

    // ── revisi → review (vendor selesai revisi) ──────────────────────
    StatusTransition(
      from: 'revisi',
      to: 'review',
      actionLabel: 'Kirim Ulang ke Review',
      confirmTitle: 'Kirim Ulang Hasil ke Customer',
      confirmMessage: 'Pastikan link hasil revisi sudah diperbarui.\n\n'
          'Customer akan mereview ulang hasil pekerjaan Anda.',
    ),

    StatusTransition(
      from: 'review',
      to: 'selesai',
      actionLabel: 'Selesaikan Pesanan',
      confirmTitle: 'Selesaikan Pesanan',
      confirmMessage: 'Pesanan akan ditandai selesai.\n\n'
          'Anda akan diminta memberikan ulasan untuk vendor.',
    ),
  ];

  /// Apakah transisi dari [from] ke [to] valid?
  static bool isValid(String from, String to) =>
      transitions.any((t) => t.from == from && t.to == to);

  /// Metadata transisi — null jika tidak valid
  static StatusTransition? get(String from, String to) {
    try {
      return transitions.firstWhere((t) => t.from == from && t.to == to);
    } catch (_) {
      return null;
    }
  }

  // ── Display label ────────────────────────────────────────────────────

  static String displayLabel(String status) {
    switch (status) {
      case 'persiapan':
        return 'Menunggu Pemotretan';
      case 'proses':
        return 'Dalam Pengerjaan';
      case 'review':
        return 'Review Hasil';
      case 'revisi':
        return 'Dalam Revisi'; // ← ADDED
      case 'selesai':
        return 'Selesai';
      case 'menunggu bayar':
        return 'Menunggu Pembayaran';
      case 'dibatalkan':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  // ── Info card text ───────────────────────────────────────────────────

  static String vendorInfo(String status) {
    switch (status) {
      case 'persiapan':
        return 'Pesanan sedang dalam tahap persiapan pemotretan. '
            'Customer akan mengonfirmasi setelah sesi pemotretan selesai '
            'untuk melanjutkan ke tahap pengerjaan.';
      case 'proses':
        return 'Upload link hasil pekerjaan (Google Drive, Dropbox, dll), '
            'lalu kirim ke customer untuk direview.';
      case 'review':
        return 'Customer sedang mereview hasil pekerjaan Anda. '
            'Tunggu keputusan customer — revisi atau selesaikan.';
      case 'revisi': // ← ADDED
        return 'Customer meminta revisi. Perbarui hasil pekerjaan sesuai '
            'catatan yang diberikan, lalu kirim ulang ke customer untuk direview.';
      case 'selesai':
        return 'Pesanan telah selesai. Terima kasih atas kerja keras Anda!';
      default:
        return '';
    }
  }

  static String customerInfo(String status) {
    switch (status) {
      case 'persiapan':
        return 'Pesanan Anda sedang dalam tahap persiapan. '
            'Setelah sesi pemotretan selesai, tekan tombol konfirmasi '
            'untuk melanjutkan ke tahap pengerjaan oleh vendor.';
      case 'proses':
        return 'Vendor sedang mengerjakan hasil pemotretan Anda. '
            'Anda akan diberitahu saat hasil siap untuk direview.';
      case 'review':
        return 'Hasil pekerjaan vendor sudah siap! '
            'Silakan buka link yang diberikan untuk melihat hasilnya, '
            'lalu pilih Revisi jika ada yang perlu diperbaiki '
            'atau Selesaikan jika sudah memuaskan.';
      case 'revisi': // ← ADDED
        return 'Permintaan revisi Anda sudah diterima vendor. '
            'Vendor sedang mengerjakan perbaikan sesuai catatan yang Anda berikan. '
            'Harap tunggu hingga vendor mengirimkan ulang hasil revisi untuk direview.';
      case 'selesai':
        return 'Pesanan telah selesai. '
            'Terima kasih telah menggunakan layanan kami!';
      default:
        return '';
    }
  }

  // ── Default deskripsi progress ───────────────────────────────────────

  static String defaultDeskripsi(String from, String to) {
    switch ('$from→$to') {
      case 'persiapan→proses':
        return 'Customer telah mengonfirmasi pemotretan selesai. '
            'Pesanan masuk ke tahap pengerjaan.';
      case 'proses→review':
        return 'Vendor telah menyelesaikan pengerjaan. '
            'Silakan review hasil melalui link yang disediakan.';
      case 'review→revisi': // ← UPDATED (was review→proses)
        return 'Customer meminta revisi. '
            'Vendor akan mengerjakan ulang sesuai catatan.';
      case 'revisi→review': // ← ADDED
        return 'Vendor telah menyelesaikan revisi. '
            'Silakan review ulang hasil melalui link yang disediakan.';
      case 'review→selesai':
        return 'Customer telah menyetujui hasil pekerjaan. Pesanan selesai.';
      default:
        return 'Status diperbarui: ${displayLabel(to)}';
    }
  }
}