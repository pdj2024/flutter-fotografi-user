// ═══════════════════════════════════════════════════════════════
// PAYMENT TIMER STATUS — sama persis dengan pesanan_card.dart
// ═══════════════════════════════════════════════════════════════

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/constants/helper.dart';
import 'package:mpjnew/src/core/utils/deadline_helper.dart';
import 'package:mpjnew/src/data/hive_entity/pesanan_model.dart';
import 'package:mpjnew/src/features/customer/view/history/widget/card_button.dart';
import 'package:mpjnew/src/features/customer/view/history/widget/status_config.dart';
import 'package:mpjnew/src/features/customer/viewmodels/pesanan_provider.dart';
import 'package:mpjnew/src/features/customer/widget/dialog/extend_deadline_flow.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PaymentTimerStatus {
  final bool isExpired;
  final Duration? remainingTime;

  const PaymentTimerStatus({
    required this.isExpired,
    this.remainingTime,
  });
}

class OrderHistoryCard extends StatefulWidget {
  final PesananModel order;
  final VoidCallback onTap;
  final VoidCallback onChat;
  final VoidCallback onPay;
  final VoidCallback onReview;
  final VoidCallback? onBatal;
  final VoidCallback? onGantiMetode;

  const OrderHistoryCard({
    required this.order,
    required this.onTap,
    required this.onChat,
    required this.onPay,
    required this.onReview,
    this.onBatal,
    this.onGantiMetode,
  });

  @override
  State<OrderHistoryCard> createState() => _OrderHistoryCardState();
}

class _OrderHistoryCardState extends State<OrderHistoryCard> {
  PaymentTimerStatus? _timerStatus;
  Timer? _updateTimer;

  static const _timeout = Duration(minutes: 5);

  String get _statusStr =>
      widget.order.statusProgresPesanan ?? 'menunggu bayar';

  /// Pembayaran sudah dikonfirmasi (capture/settlement) tapi server belum geser status
  bool get _isSettledPending =>
      _statusStr == 'menunggu bayar' &&
      PesananProvider.isPaymentSettled(widget.order.statusBayar);

  bool get _isUnpaid => _statusStr == 'menunggu bayar' && !_isSettledPending;

  /// Pesanan sudah dibayar tapi pengerjaan belum dimulai — masih boleh
  /// dibatalkan customer, dengan konsekuensi dana direfund.
  bool get _canCancelPaid => PesananProvider.needsRefund(widget.order);
  bool get _isReview => _statusStr == 'review';

  Duration? get _remaining => remainingIfNearDeadline(widget.order);

  /// Pembayaran sudah expired — deteksi Snap dan Core.
  /// Snap  : cek linkSnap + expiryTime / umur > 30 hari.
  /// Core  : cek metodeBayar ada tapi paymentNumber1&2 + expiryTime semuanya null
  ///         (Midtrans menghapus data ketika expired) + umur > 1 hari.
  bool get _isPaymentExpired {
    if (!_isUnpaid) return false;
    final o = widget.order;

    // ── Snap ──────────────────────────────────────────────────────
    if (o.linkSnap != null && o.linkSnap!.isNotEmpty) {
      if (o.expiryTime != null) return o.expiryTime!.isBefore(DateTime.now());
      final ref = o.createdAt ?? o.updatedAt;
      if (ref != null) return DateTime.now().difference(ref).inDays >= 30;
      return false;
    }

    // ── Core ──────────────────────────────────────────────────────
    final hasMethods = o.metodeBayar != null && o.metodeBayar!.isNotEmpty;
    if (hasMethods) {
      final noNum = (o.paymentNumber1 == null || o.paymentNumber1!.isEmpty) &&
          (o.paymentNumber2 == null || o.paymentNumber2!.isEmpty);
      if (noNum && o.expiryTime == null) {
        final ref = o.createdAt ?? o.updatedAt;
        // Beri jeda 1 hari agar fresh order yang belum dapat payment number
        // tidak dianggap expired.
        if (ref == null) return true;
        return DateTime.now().difference(ref).inDays >= 1;
      }
    }

    return false;
  }

  @override
  void initState() {
    super.initState();
    if (_isUnpaid && !_isPaymentExpired) {
      _loadTimerStatus();
      _startPeriodicUpdate();
    }
    // Expired & settled-pending: tidak perlu countdown timer
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  void _startPeriodicUpdate() {
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) _loadTimerStatus();
    });
  }

  Future<void> _loadTimerStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final noBukti = widget.order.noBukti;
    final storageKey = 'payment_start_$noBukti';
    final statusKey = 'payment_status_$noBukti';

    final storedTime = prefs.getString(storageKey);
    final paymentStatus = prefs.getString(statusKey);

    if (!mounted) return;

    if (storedTime == null) {
      // Belum mulai pembayaran
      setState(() {
        _timerStatus = const PaymentTimerStatus(
          isExpired: false,
          remainingTime: null,
        );
      });
      return;
    }

    final startTime = DateTime.parse(storedTime);
    final elapsed = DateTime.now().difference(startTime);
    final remaining = _timeout - elapsed;

    if (remaining.inSeconds <= 0 || paymentStatus == 'expired') {
      // Auto-mark expired
      if (paymentStatus != 'expired') {
        await prefs.setString(statusKey, 'expired');
      }
      setState(() {
        _timerStatus = const PaymentTimerStatus(
          isExpired: true,
          remainingTime: Duration.zero,
        );
      });
    } else {
      setState(() {
        _timerStatus = PaymentTimerStatus(
          isExpired: false,
          remainingTime: remaining,
        );
      });
    }
  }

  /// Dipanggil saat user tap "Bayar" — mulai/reset timer
  Future<void> _startPaymentTimer() async {
    final prefs = await SharedPreferences.getInstance();
    final noBukti = widget.order.noBukti;
    await prefs.setString(
        'payment_start_$noBukti', DateTime.now().toIso8601String());
    await prefs.remove('payment_status_$noBukti');
    await _loadTimerStatus();
    widget.onPay();
  }

  /// Dipanggil saat user tap "Coba Lagi" setelah expired
  Future<void> _retryPayment() async {
    final prefs = await SharedPreferences.getInstance();
    final noBukti = widget.order.noBukti;
    await prefs.setString(
        'payment_start_$noBukti', DateTime.now().toIso8601String());
    await prefs.remove('payment_status_$noBukti');
    await _loadTimerStatus();
    widget.onPay();
  }

  @override
  Widget build(BuildContext context) {
    final cfg = getStatus(_statusStr,
        isRefundProcessing: widget.order.isRefundProcessing,
        isRefundDone: widget.order.isRefundDone);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x07000000),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Status bar ───────────────────────────────────────
          _buildStatusBar(cfg),

          // ── Body ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 14, 10, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Vendor + paket
                _buildVendorRow(),

                const SizedBox(height: 12),
                Divider(height: 1, color: Colors.grey.shade100),
                const SizedBox(height: 12),

                // Tanggal & lokasi
                _InfoRow(
                  icon: Icons.calendar_today_rounded,
                  text:
                      '${Helper.formatTanggal(widget.order.tglRealisasi)}  •  ${Helper.toLocalTime(widget.order.tglRealisasi)}',
                ),
                const SizedBox(height: 5),
                _InfoRow(
                  icon: Icons.location_on_outlined,
                  text: widget.order.lokasi,
                ),

                // Settled-pending banner — pembayaran terkonfirmasi, server belum update
                if (_isSettledPending) ...[
                  const SizedBox(height: 12),
                  _buildSettledPendingBanner(),
                ],

                // Progress status banner — tampil untuk semua status KECUALI menunggu bayar
                if (!_isUnpaid && !_isSettledPending) ...[
                  const SizedBox(height: 12),
                  _buildProgressBanner(),
                ],

                // Reminder batas pengerjaan
                if (_remaining != null) ...[
                  const SizedBox(height: 12),
                  _buildDeadlineReminder(),
                ],

                // Payment Timer/Expired Banner — tampil untuk menunggu bayar
                if (_isUnpaid &&
                    (_isPaymentExpired || _timerStatus != null)) ...[
                  const SizedBox(height: 12),
                  _buildPaymentBanner(),
                ],

                const SizedBox(height: 14),

                // Action buttons row
                _buildActionRow(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Status bar ────────────────────────────────────────────────
  Widget _buildStatusBar(StatusConfig cfg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: cfg.bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Icon(cfg.icon, size: 14, color: cfg.color),
          const SizedBox(width: 6),
          Text(
            cfg.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: cfg.color,
            ),
          ),
          const Spacer(),
          Text(
            '#${widget.order.noTrackingPesanan}',
            style: TextStyle(
              fontSize: 11,
              color: cfg.color.withOpacity(0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.receipt_long_rounded,
                          color: Colors.black54, size: 24),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Opsi Pesanan',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          SizedBox(height: 2),
                          Text('Pilih tindakan untuk pesanan ini',
                              style:
                                  TextStyle(fontSize: 13, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: Colors.grey.shade200),
              if (widget.onGantiMetode != null)
                ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.payment_outlined,
                        color: Colors.blue.shade600, size: 22),
                  ),
                  title: const Text('Ganti Metode Pembayaran',
                      style:
                          TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
                  trailing:
                      Icon(Icons.chevron_right, color: Colors.grey.shade400),
                  onTap: () {
                    Navigator.pop(ctx);
                    widget.onGantiMetode!();
                  },
                ),
              ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.cancel_outlined,
                      color: Color(0xFFDC2626), size: 22),
                ),
                title: const Text('Batalkan Pesanan',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Color(0xFFDC2626))),
                trailing:
                    Icon(Icons.chevron_right, color: Colors.grey.shade400),
                onTap: () {
                  Navigator.pop(ctx);
                  // Dialog konfirmasi + info refund dipegang showBatalPesananFlow
                  // (lihat batal_pesanan_flow.dart) supaya semua titik masuk
                  // pembatalan menampilkan hal yang sama.
                  widget.onBatal?.call();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Vendor row ────────────────────────────────────────────────
  Widget _buildVendorRow() {
    final canShowMenu = (_isUnpaid || _canCancelPaid) && widget.onBatal != null;
    return Row(
      children: [
        _VendorAvatar(url: widget.order.idMediaVendor ?? ''),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.order.namaVendor ?? 'Vendor',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F0F0F),
                  height: 1.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Constants.primaryColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  widget.order.namaPaket,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Constants.primaryColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        if (canShowMenu) ...[
          GestureDetector(
            onTap: () => _showActionSheet(context),
            child: Container(
              padding: const EdgeInsets.all(3),
              child: Icon(Icons.more_vert, size: 16),
            ),
          ),
          const SizedBox(width: 6),
        ],
      ],
    );
  }

  // ─── Progress Status Banner — persiapan / proses / review / revisi ──
  Widget _buildProgressBanner() {
    final cfg = getStatus(_statusStr,
        isRefundProcessing: widget.order.isRefundProcessing,
        isRefundDone: widget.order.isRefundDone);
    final deskripsi = widget.order.deskripsiProgresPesanan ?? '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cfg.bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cfg.color.withOpacity(0.35), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 1),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: cfg.color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(cfg.icon, size: 14, color: cfg.color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cfg.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: cfg.color,
                  ),
                ),
                if (deskripsi.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    deskripsi,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: cfg.color.withOpacity(0.85),
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Deadline reminder ──────────────────────────────────────────
  Widget _buildDeadlineReminder() {
    final remaining = _remaining!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timer_outlined, size: 15, color: Colors.red.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Sisa waktu pengerjaan: ${formatRemainingDeadline(remaining)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.red.shade700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              OutlineButton(
                icon: Icons.chat_outlined,
                label: 'Ingatkan Vendor',
                onTap: widget.onChat,
                color: Colors.red.shade700,
                borderColor: Colors.red.shade300,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: PrimaryButton(
                  icon: Icons.event_available_outlined,
                  label: 'Perpanjang',
                  onTap: () => showExtendDeadlineFlow(context, widget.order),
                  color: Colors.red.shade700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Settled-Pending Banner ────────────────────────────────────
  Widget _buildSettledPendingBanner() {
    return _PaymentBannerContainer(
      color: Colors.green.shade700,
      bgColor: Colors.green.shade50,
      borderColor: Colors.green.shade200,
      icon: Icons.check_circle_outline_rounded,
      iconBgColor: Colors.green.shade100,
      title: 'Pembayaran Terkonfirmasi',
      subtitle: 'Menunggu proses dari vendor',
      trailing: null,
    );
  }

  // ─── Payment Timer Banner ──────────────────────────────────────
  Widget _buildPaymentBanner() {
    // 0. Pembayaran sudah expired (Snap atau Core)
    if (_isPaymentExpired) {
      return _PaymentBannerContainer(
        color: Colors.grey.shade600,
        bgColor: Colors.grey.shade100,
        borderColor: Colors.grey.shade300,
        icon: Icons.link_off_rounded,
        iconBgColor: Colors.grey.shade200,
        title: 'Pembayaran Expired',
        subtitle: 'Buka detail pesanan untuk informasi selanjutnya',
      );
    }

    final status = _timerStatus!;

    // 1. Belum mulai timer (remainingTime == null)
    if (status.remainingTime == null) {
      return _PaymentBannerContainer(
        color: Colors.blue.shade700,
        bgColor: Colors.blue.shade50,
        borderColor: Colors.blue.shade200,
        icon: Icons.payment_outlined,
        iconBgColor: Colors.blue.shade100,
        title: 'Menunggu Pembayaran',
        subtitle: 'Tap "Bayar Sekarang" untuk melanjutkan',
        trailing: null,
      );
    }

    // 2. Expired
    if (status.isExpired) {
      return _PaymentBannerContainer(
        color: Colors.red.shade700,
        bgColor: Colors.red.shade50,
        borderColor: Colors.red.shade200,
        icon: Icons.timer_off_outlined,
        iconBgColor: Colors.red.shade100,
        title: 'Waktu Pembayaran Habis',
        subtitle: 'Tap "Coba Lagi" untuk memulai ulang',
        trailing: null,
      );
    }

    // 3. Timer aktif — tampilkan countdown
    final remaining = status.remainingTime!;
    final isWarning = remaining.inSeconds < 60;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isWarning
              ? [Colors.red.shade400, Colors.red.shade500]
              : [Colors.orange.shade400, Colors.orange.shade500],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: (isWarning ? Colors.red : Colors.orange).withOpacity(0.25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              shape: BoxShape.circle,
            ),
            child:
                const Icon(Icons.timer_outlined, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Pembayaran Sedang Diproses',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Countdown pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              Helper.formatDuration(remaining),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: isWarning ? Colors.red.shade700 : Colors.orange.shade700,
                letterSpacing: 0.5,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Action buttons row ────────────────────────────────────────
  Widget _buildActionRow() {
    // Tentukan tombol primary berdasarkan status + timer
    Widget primaryButton;

    if (_isSettledPending) {
      primaryButton = PrimaryButton(
        icon: Icons.arrow_forward_rounded,
        label: 'Detail',
        onTap: widget.onTap,
        color: Constants.primaryColor,
      );
    } else if (_isUnpaid) {
      // Pembayaran expired → langsung ke detail, jangan buka WebView
      if (_isPaymentExpired) {
        primaryButton = PrimaryButton(
          icon: Icons.arrow_forward_rounded,
          label: 'Lihat Detail',
          onTap: widget.onTap,
          color: Colors.grey.shade600,
        );
      } else {
        final status = _timerStatus;

        if (status == null) {
          // Loading timer, disable sementara
          primaryButton = PrimaryButton(
            icon: Icons.payment_rounded,
            label: 'Bayar Sekarang',
            onTap: widget.onPay,
            color: Constants.primaryColor,
          );
        } else if (status.isExpired) {
          // Expired → Coba Lagi (orange)
          primaryButton = PrimaryButton(
            icon: Icons.refresh_rounded,
            label: 'Coba Lagi',
            onTap: _retryPayment,
            color: Colors.orange.shade700,
          );
        } else if (status.remainingTime != null) {
          // Timer aktif → Lanjut Bayar (orange)
          primaryButton = PrimaryButton(
            icon: Icons.payment_rounded,
            label: 'Lanjut Bayar',
            onTap: widget.onPay,
            color: Constants.primaryColor,
          );
        } else {
          // Belum mulai → Bayar Sekarang (biru)
          primaryButton = PrimaryButton(
            icon: Icons.payment_rounded,
            label: 'Bayar Sekarang',
            onTap: _startPaymentTimer,
            color: const Color(0xFF1565C0),
          );
        }
      } // end else (!_isSnapLinkExpired)
    } else if (_isReview) {
      primaryButton = PrimaryButton(
        icon: Icons.arrow_forward_rounded,
        label: 'Detail',
        onTap: widget.onTap,
        color: Constants.primaryColor, // Sesuai StatusProgresConstant review
      );
    } else {
      primaryButton = PrimaryButton(
        icon: Icons.arrow_forward_rounded,
        label: 'Detail',
        onTap: widget.onTap,
        color: Constants.primaryColor,
      );
    }

    return Row(
      children: [
        // Chat — selalu ada
        OutlineButton(
          icon: Icons.chat_outlined,
          label: 'Chat',
          onTap: widget.onChat,
          color: Colors.grey.shade700,
          borderColor: Colors.grey.shade300,
        ),
        const SizedBox(width: 8),
        Expanded(child: primaryButton),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PAYMENT BANNER CONTAINER — reusable untuk state belum bayar & expired
// ═══════════════════════════════════════════════════════════════

class _PaymentBannerContainer extends StatelessWidget {
  final Color color;
  final Color bgColor;
  final Color borderColor;
  final IconData icon;
  final Color iconBgColor;
  final String title;
  final String subtitle;
  final Widget? trailing;

  const _PaymentBannerContainer({
    required this.color,
    required this.bgColor,
    required this.borderColor,
    required this.icon,
    required this.iconBgColor,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: color.withOpacity(0.8)),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade500),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// HELPER WIDGETS
// ═══════════════════════════════════════════════════════════════

class _VendorAvatar extends StatelessWidget {
  final String url;
  const _VendorAvatar({required this.url});

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return CircleAvatar(
        radius: 22,
        backgroundColor: Constants.primaryColor.withOpacity(0.15),
        child: Icon(Icons.person, size: 20, color: Constants.primaryColor),
      );
    }
    return CircleAvatar(
      radius: 22,
      backgroundColor: Colors.grey.shade200,
      backgroundImage: NetworkImage(url),
    );
  }
}
