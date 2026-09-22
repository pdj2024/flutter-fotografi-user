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

// ── Alur status linear ──────────────────────────────────────────────────
//
//   persiapan ──► proses ──► review ──► selesai
//                               │
//                               ▼
//                            revisi ──► review
//
// Transisi yang valid:
//   persiapan  → proses    (customer konfirmasi pemotretan selesai)
//   proses     → review    (vendor upload link + kirim ke review)
//   review     → revisi    (customer minta revisi)
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

// ════════════════════════════════════════════════════════════════════════
// StatusInfoLabel
//
// Label informasi tambahan yang ditampilkan di UI masing-masing app.
// Tidak disimpan ke database — hanya untuk keperluan tampilan.
// ════════════════════════════════════════════════════════════════════════

class StatusInfoLabel {
  /// Ikon/emoji yang merepresentasikan kondisi saat ini
  final String icon;

  /// Judul singkat kondisi saat ini
  final String title;

  /// Penjelasan detail apa yang perlu dilakukan / sedang terjadi
  final String body;

  const StatusInfoLabel({
    required this.icon,
    required this.title,
    required this.body,
  });
}

// ════════════════════════════════════════════════════════════════════════
// OrderStatusFlow
// ════════════════════════════════════════════════════════════════════════

class OrderStatusFlow {
  // ── Tabel semua transisi yang valid ──────────────────────────────────
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
    StatusTransition(
      from: 'review',
      to: 'revisi',
      actionLabel: 'Minta Revisi',
      confirmTitle: 'Minta Revisi',
      confirmMessage: 'Pesanan akan masuk ke tahap revisi.\n\n'
          'Tuliskan catatan revisi untuk vendor.',
    ),
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

  // ── Display label ─────────────────────────────────────────────────────

  static String displayLabel(String status) {
    switch (status) {
      case 'persiapan':
        return 'Menunggu Pemotretan';
      case 'proses':
        return 'Dalam Pengerjaan';
      case 'review':
        return 'Review Hasil';
      case 'revisi':
        return 'Dalam Revisi';
      case 'selesai':
        return 'Selesai';
      case 'menunggu bayar':
        return 'Menunggu Pembayaran';
      case 'dibatalkan':
      case 'batal':
        return 'Dibatalkan';
      case 'dibatalkan paid':
        return 'Dibatalkan & Dana Dikembalikan';
      case 'closed':
        return 'Ditutup';
      case 'expired':
        return 'Kadaluarsa';
      default:
        return status;
    }
  }

  // ════════════════════════════════════════════════════════════════════
  // defaultDeskripsi
  //
  // Deskripsi NETRAL yang disimpan ke HistoryOrderModel.deskripsi.
  // Tidak menyebut "customer" atau "vendor" secara spesifik agar
  // cocok ditampilkan di kedua app tanpa perlu dua versi data.
  // ════════════════════════════════════════════════════════════════════

  static String defaultDeskripsi(String from, String to) {
    switch ('$from→$to') {
      case 'persiapan→proses':
        return 'Sesi pemotretan telah dikonfirmasi selesai. '
            'Pesanan masuk ke tahap pengerjaan.';
      case 'proses→review':
        return 'Pengerjaan selesai. '
            'Hasil pekerjaan telah dikirimkan untuk direview.';
      case 'review→revisi':
        return 'Revisi diminta. '
            'Pekerjaan akan diperbaiki sesuai catatan yang diberikan.';
      case 'revisi→review':
        return 'Revisi selesai. '
            'Hasil terbaru telah dikirimkan kembali untuk direview.';
      case 'review→selesai':
        return 'Hasil pekerjaan disetujui. Pesanan dinyatakan selesai.';
      default:
        return 'Status diperbarui menjadi: ${displayLabel(to)}';
    }
  }

  // ════════════════════════════════════════════════════════════════════
  // vendorInfoLabel & customerInfoLabel
  //
  // Label tambahan KHUSUS per role — hanya untuk tampilan UI,
  // tidak disimpan ke database.
  //
  // Berisi panduan/konteks spesifik sesuai peran pengguna
  // pada status pesanan yang sedang aktif.
  // ════════════════════════════════════════════════════════════════════

  static StatusInfoLabel vendorInfoLabel(String status) {
    switch (status) {
      case 'persiapan':
        return const StatusInfoLabel(
          icon: '📅',
          title: 'Menunggu Konfirmasi Pemotretan',
          body: 'Lakukan sesi pemotretan sesuai jadwal yang disepakati. '
              'Customer akan mengonfirmasi setelah sesi selesai '
              'untuk melanjutkan ke tahap pengerjaan.',
        );
      case 'proses':
        return const StatusInfoLabel(
          icon: '🖼️',
          title: 'Sedang Mengerjakan',
          body: 'Upload hasil pekerjaan ke Google Drive, Dropbox, atau '
              'platform lainnya. Isi link hasil, lalu kirim ke customer '
              'untuk direview.',
        );
      case 'review':
        return const StatusInfoLabel(
          icon: '⏳',
          title: 'Menunggu Review Customer',
          body: 'Customer sedang mereview hasil pekerjaan Anda. '
              'Harap tunggu — customer akan memilih untuk menyetujui '
              'atau meminta revisi.',
        );
      case 'revisi':
        return const StatusInfoLabel(
          icon: '✏️',
          title: 'Mengerjakan Revisi',
          body: 'Perhatikan catatan revisi dari customer. '
              'Perbarui hasil pekerjaan, lalu kirim ulang ke customer '
              'untuk direview kembali.',
        );
      case 'selesai':
        return const StatusInfoLabel(
          icon: '🎉',
          title: 'Pesanan Selesai',
          body: 'Customer telah menyetujui hasil pekerjaan Anda. '
              'Terima kasih atas kerja keras Anda!',
        );
      case 'menunggu bayar':
        return const StatusInfoLabel(
          icon: '💳',
          title: 'Menunggu Pembayaran',
          body: 'Customer belum menyelesaikan pembayaran. '
              'Pesanan akan diproses setelah pembayaran dikonfirmasi.',
        );
      case 'dibatalkan':
      case 'batal':
        return const StatusInfoLabel(
          icon: '❌',
          title: 'Pesanan Dibatalkan',
          body: 'Pesanan ini telah dibatalkan dan tidak dapat dilanjutkan.',
        );
      case 'expired':
        return const StatusInfoLabel(
          icon: '⏰',
          title: 'Pembayaran Kadaluarsa',
          body:
              'Batas waktu pembayaran telah habis. Pesanan ini tidak dapat diproses.',
        );
      default:
        return StatusInfoLabel(
          icon: '📋',
          title: displayLabel(status),
          body: '',
        );
    }
  }

  static StatusInfoLabel customerInfoLabel(String status) {
    switch (status) {
      case 'persiapan':
        return const StatusInfoLabel(
          icon: '📅',
          title: 'Siapkan Sesi Pemotretan',
          body: 'Lakukan sesi pemotretan sesuai jadwal yang disepakati '
              'bersama vendor. Setelah sesi selesai, tekan tombol konfirmasi '
              'agar pesanan berlanjut ke tahap pengerjaan.',
        );
      case 'proses':
        return const StatusInfoLabel(
          icon: '⏳',
          title: 'Vendor Sedang Mengerjakan',
          body: 'Vendor sedang memproses hasil pemotretan Anda. '
              'Anda akan mendapat notifikasi saat hasil siap untuk direview.',
        );
      case 'review':
        return const StatusInfoLabel(
          icon: '👀',
          title: 'Hasil Siap Direview',
          body: 'Buka link hasil yang diberikan vendor untuk melihat '
              'hasilnya. Pilih Selesaikan jika sudah memuaskan, '
              'atau Minta Revisi jika ada yang perlu diperbaiki.',
        );
      case 'revisi':
        return const StatusInfoLabel(
          icon: '🔧',
          title: 'Vendor Mengerjakan Revisi',
          body: 'Permintaan revisi Anda telah diterima vendor. '
              'Harap tunggu hingga vendor mengirimkan hasil revisi '
              'untuk Anda review kembali.',
        );
      case 'selesai':
        return const StatusInfoLabel(
          icon: '🎉',
          title: 'Pesanan Selesai',
          body: 'Pesanan Anda telah selesai. '
              'Jangan lupa berikan ulasan untuk vendor agar membantu '
              'pengguna lain.',
        );
      case 'menunggu bayar':
        return const StatusInfoLabel(
          icon: '💳',
          title: 'Selesaikan Pembayaran',
          body: 'Pesanan berhasil dibuat. Silakan selesaikan pembayaran '
              'agar vendor dapat segera memproses pesanan Anda.',
        );
      case 'dibatalkan':
      case 'batal':
        return const StatusInfoLabel(
          icon: '❌',
          title: 'Pesanan Dibatalkan',
          body: 'Pesanan ini telah dibatalkan. '
              'Hubungi kami jika Anda memiliki pertanyaan.',
        );
      case 'expired':
        return const StatusInfoLabel(
          icon: '⏰',
          title: 'Pembayaran Kadaluarsa',
          body:
              'Batas waktu pembayaran telah habis dan pesanan ini tidak dapat diproses. '
              'Silakan buat pesanan baru jika masih membutuhkan layanan ini.',
        );
      default:
        return StatusInfoLabel(
          icon: '📋',
          title: displayLabel(status),
          body: '',
        );
    }
  }
}
