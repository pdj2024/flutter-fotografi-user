import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/constants/helper.dart';
import 'package:mpjnew/src/core/routing/navigation_provider.dart';
import 'package:mpjnew/src/data/hive_entity/pesanan_model.dart';
import 'package:mpjnew/src/data/models/ulasan_model.dart';
import 'package:mpjnew/src/features/customer/services/ulasan_service.dart';
import 'package:mpjnew/src/features/customer/view/history/detail_order_page.dart';
import 'package:mpjnew/src/features/customer/view/history/detail_order_page_V2.dart';
import 'package:mpjnew/src/features/customer/widget/dialog/ulasan_dialog.dart';
import 'package:mpjnew/src/features/customer/viewmodels/pesanan_provider.dart';
import 'package:provider/provider.dart';

// ═══════════════════════════════════════════════════════════════
// FINISHED ORDER PAGE
// Halaman terpisah untuk pesanan yang sudah selesai.
// Diakses dari MainOrderPage via Navigator.push
// ═══════════════════════════════════════════════════════════════

class FinishedOrderPage extends StatefulWidget {
  const FinishedOrderPage({super.key});

  @override
  State<FinishedOrderPage> createState() => _FinishedOrderPageState();
}

class _FinishedOrderPageState extends State<FinishedOrderPage> {
  late DateTime _rangeStart;
  late DateTime _rangeEnd;
  late DateTime _defaultRangeStart;
  late DateTime _defaultRangeEnd;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _rangeStart = DateTime(now.year, now.month, 1);
    // Tanggal terakhir bulan berjalan -- bukan cuma "sampai hari ini".
    _rangeEnd = DateTime(now.year, now.month + 1, 0);
    _defaultRangeStart = _rangeStart;
    _defaultRangeEnd = _rangeEnd;
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  bool get _hasCustomRange =>
      !_rangeStart.isAtSameMomentAs(_defaultRangeStart) ||
      !_rangeEnd.isAtSameMomentAs(_defaultRangeEnd);

  Future<void> _load() {
    return context
        .read<PesananProvider>()
        .loadFinishedOrders(context, start: _rangeStart, end: _rangeEnd);
  }

  // tanggal1 (dari) & tanggal2 (sampai) dipisah jadi 2 field agar user bisa
  // atur masing-masing ujung rentang secara independen. Fetch tidak langsung
  // jalan tiap ganti 1 field — user tekan tombol "Cari" setelah kedua
  // tanggal sesuai, biar tidak double-fetch tiap ganti satu field.
  Future<void> _pickSingleDate({required bool isStart}) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final minDate = isStart ? DateTime(2020) : _rangeStart;
    final maxDate = isStart ? _rangeEnd : today;
    final initial = isStart ? _rangeStart : _rangeEnd;
    final safeInitial = initial.isBefore(minDate)
        ? minDate
        : (initial.isAfter(maxDate) ? maxDate : initial);

    final picked = await _showSingleDatePickerSheet(
      context,
      label: isStart ? 'Tanggal Dari' : 'Tanggal Sampai',
      initialDate: safeInitial,
      minDate: minDate,
      maxDate: maxDate,
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _rangeStart = picked;
      } else {
        _rangeEnd = picked;
      }
    });
  }

  // Bottom sheet date picker — style disamakan dengan DatePickerField
  // (dipakai di FormPenawaranPage vendor): blur backdrop + slide-up sheet.
  Future<DateTime?> _showSingleDatePickerSheet(
    BuildContext context, {
    required String label,
    required DateTime initialDate,
    required DateTime minDate,
    required DateTime maxDate,
  }) async {
    final controller = DateRangePickerController();
    DateTime tempPicked = initialDate;

    return showGeneralDialog<DateTime>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black45,
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (dialogContext, animation, _, child) {
        return StatefulBuilder(
          builder: (sbContext, setDialogState) {
            return Stack(
              children: [
                // ── BLUR BACKGROUND ──────────────────────────────────
                GestureDetector(
                  onTap: () => Navigator.pop(dialogContext),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                    child: Container(color: Colors.black.withOpacity(0.2)),
                  ),
                ),

                // ── BOTTOM SHEET ─────────────────────────────────────
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: SlideTransition(
                    position: Tween(
                      begin: const Offset(0, 1),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                        parent: animation, curve: Curves.easeOut)),
                    child: Material(
                      elevation: 8,
                      color: Colors.white,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(22)),
                      child: SizedBox(
                        height: 460,
                        child: Column(
                          children: [
                            // ── HEADER ────────────────────────────────
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  GestureDetector(
                                    onTap: () => Navigator.pop(dialogContext),
                                    child: const Text(
                                      "Batal",
                                      style: TextStyle(
                                          fontSize: 16, color: Colors.grey),
                                    ),
                                  ),
                                  Text(
                                    label,
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  GestureDetector(
                                    onTap: () => Navigator.pop(
                                        dialogContext, tempPicked),
                                    child: Text(
                                      "Pilih",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Constants.primaryColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const Divider(height: 0),

                            // ── DATE PICKER ────────────────────────────
                            Expanded(
                              child: SfDateRangePicker(
                                controller: controller,
                                backgroundColor: Colors.white,
                                selectionMode:
                                    DateRangePickerSelectionMode.single,
                                showNavigationArrow: true,
                                view: DateRangePickerView.month,
                                initialSelectedDate: initialDate,
                                initialDisplayDate: initialDate,
                                minDate: minDate,
                                maxDate: maxDate,
                                selectionColor: Constants.primaryColor,
                                todayHighlightColor: Constants.primaryColor,
                                headerStyle: DateRangePickerHeaderStyle(
                                  backgroundColor: Colors.white,
                                  textAlign: TextAlign.center,
                                  textStyle: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: Constants.primaryColor,
                                  ),
                                ),
                                onSelectionChanged: (args) {
                                  if (args.value is DateTime) {
                                    tempPicked = args.value as DateTime;
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildRangeFields() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
      child: Row(
        children: [
          Expanded(
            child: _buildDateField(
              label: 'Tanggal Dari',
              date: _rangeStart,
              onTap: () => _pickSingleDate(isStart: true),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildDateField(
              label: 'Tanggal Sampai',
              date: _rangeEnd,
              onTap: () => _pickSingleDate(isStart: false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 3),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('d MMM yyyy').format(date),
                  style: const TextStyle(
                      fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
                Icon(Icons.calendar_today_rounded,
                    size: 13, color: Constants.primaryColor),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchButton() {
    if (!_hasCustomRange) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _load,
          icon: const Icon(Icons.search_rounded, size: 18),
          label: const Text('Cari'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Constants.primaryColor,
            side: BorderSide(color: Constants.primaryColor),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12),
            textStyle:
                const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PesananProvider>();
    final orders = [
      ...provider.pesananSelesai,
      ...provider.pesananBatal,
    ]..sort((a, b) {
        final aTime = a.updatedAt ?? a.createdAt ?? DateTime(0);
        final bTime = b.updatedAt ?? b.createdAt ?? DateTime(0);
        return bTime.compareTo(aTime);
      });

    final isLoading = provider.isLoadingFinished && orders.isEmpty;
    final hasError = provider.errorFinished != null && orders.isEmpty;

    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F4F2),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF4F4F2),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'Pesanan Selesai',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: Column(
          children: [
            _buildRangeFields(),
            _buildSearchButton(),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : hasError
                      ? _buildError(provider.errorFinished!)
                      : orders.isEmpty
                          ? _buildEmpty()
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(10, 0, 10, 48),
                              itemCount: orders.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (ctx, i) =>
                                  _FinishedCard(order: orders[i]),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 40, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: _load, child: const Text('Coba Lagi')),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_outline_rounded,
                size: 38,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Tidak ada pesanan pada rentang ini',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F0F0F),
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Coba ubah rentang tanggal di atas,\natau pesanan yang selesai/dibatalkan\nakan muncul di sini',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: Colors.grey.shade500,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// FINISHED CARD — StatefulWidget karena fetch ulasan async
// Menggunakan UlasanService & UlasanDialog sama persis dengan
// DetailOrderPage untuk konsistensi
// ═══════════════════════════════════════════════════════════════

class _FinishedCard extends StatefulWidget {
  final PesananModel order;

  const _FinishedCard({required this.order});

  @override
  State<_FinishedCard> createState() => _FinishedCardState();
}

class _FinishedCardState extends State<_FinishedCard> {
  UlasanModel? _ulasan;
  bool _loadingUlasan = true;

  // Pembatalan lewat chat/FCM progress cuma nulis 'dibatalkan' ke
  // statusProgresPesanan, bukan ke status order-level — cek dua-duanya
  // biar tidak salah anggap pesanan batal sebagai "Selesai".
  bool get _isCancelledOrExpired =>
      widget.order.status == 'batal' ||
      widget.order.status == 'expired' ||
      widget.order.statusProgresPesanan == 'dibatalkan';

  @override
  void initState() {
    super.initState();
    if (!_isCancelledOrExpired) {
      _fetchUlasan();
    } else {
      _loadingUlasan = false;
    }
  }

  Future<void> _fetchUlasan() async {
    try {
      final list = await UlasanService().getAll(noOrder: widget.order.noBukti);
      if (mounted) {
        setState(() {
          _ulasan = list.isNotEmpty ? list.first : null;
          _loadingUlasan = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingUlasan = false);
    }
  }

  void _openUlasanDialog() {
    showDialog(
      context: context,
      builder: (_) => UlasanDialog(
        pesanan: widget.order,
        onSuccess: () async {
          // Reload ulasan setelah submit — sama seperti DetailOrderPage
          final list =
              await UlasanService().getAll(noOrder: widget.order.noBukti);
          if (mounted) {
            setState(() {
              _ulasan = list.isNotEmpty ? list.first : null;
            });
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Status bar: Selesai ───────────────────────────
          _buildStatusBar(),

          // ── Body ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Vendor info row
                _buildVendorRow(context),

                const SizedBox(height: 12),
                Divider(height: 1, color: Colors.grey.shade100),
                const SizedBox(height: 12),

                // Tanggal & lokasi
                _InfoRow(
                  icon: Icons.calendar_today_rounded,
                  text:
                      '${DateFormat("dd MMM yyyy").format(widget.order.tglRealisasi)}  •  ${Helper.toLocalTime(widget.order.tglRealisasi)}',
                ),
                const SizedBox(height: 5),
                _InfoRow(
                  icon: Icons.location_on_outlined,
                  text: widget.order.lokasi,
                ),

                const SizedBox(height: 14),

                // ── Rating / Ulasan section (hanya untuk selesai) ──
                if (!_isCancelledOrExpired) _buildUlasanSection(),

                const SizedBox(height: 12),

                // ── Tombol Lihat Detail ────────────────────
                _buildDetailButton(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Status bar ──────────────────────────────────────────────
  Widget _buildStatusBar() {
    final isExpired = widget.order.status == "expired";
    final isBatal = !isExpired && _isCancelledOrExpired;

    final Color bgColor;
    final Color iconColor;
    final Color textColor;
    final IconData icon;
    final String label;

    // Refund menimpa label terminal — customer perlu tahu status dananya,
    // bukan sekadar bahwa pesanannya batal.
    if (widget.order.isRefundDone) {
      bgColor = const Color(0xFFE8F5E9);
      iconColor = const Color(0xFF2E7D32);
      textColor = const Color(0xFF2E7D32);
      icon = Icons.check_circle_outline_rounded;
      label = 'Refund Selesai';
    } else if (widget.order.isRefundProcessing) {
      bgColor = const Color(0xFFFFF3E0);
      iconColor = const Color(0xFFD97706);
      textColor = const Color(0xFFD97706);
      icon = Icons.currency_exchange_rounded;
      label = 'Dana Sedang Direfund';
    } else if (isExpired) {
      bgColor = const Color(0xFFFFF3E0);
      iconColor = const Color(0xFFE65100);
      textColor = const Color(0xFFE65100);
      icon = Icons.timer_off_rounded;
      label = 'Expired';
    } else if (isBatal) {
      bgColor = const Color(0xFFFFEBEE);
      iconColor = const Color(0xFFC62828);
      textColor = const Color(0xFFC62828);
      icon = Icons.cancel_rounded;
      label = 'Dibatalkan';
    } else {
      bgColor = const Color(0xFFE8F5E9);
      iconColor = const Color(0xFF2E7D32);
      textColor = const Color(0xFF2E7D32);
      icon = Icons.check_circle_rounded;
      label = 'Selesai';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const Spacer(),
          Text(
            "#${widget.order.noTrackingPesanan ?? ""}",
            style: TextStyle(
              fontSize: 11,
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Vendor row ──────────────────────────────────────────────
  Widget _buildVendorRow(BuildContext context) {
    return Row(
      children: [
        // Avatar
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
      ],
    );
  }

  // ─── Ulasan section ──────────────────────────────────────────
  Widget _buildUlasanSection() {
    // Loading
    if (_loadingUlasan) {
      return Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.grey.shade400,
            ),
          ),
        ),
      );
    }

    // Sudah ada ulasan — tampilkan rating + isi
    if (_ulasan != null) {
      return _buildUlasanCard();
    }

    // Belum ada ulasan — tombol beri ulasan
    return _buildBeriUlasanButton();
  }

  // ─── Ulasan card (sudah ada review) ──────────────────────────
  Widget _buildUlasanCard() {
    final u = _ulasan!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDE7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFFFFF176).withOpacity(0.8), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: icon + label + tanggal
          Row(
            children: [
              const Icon(Icons.rate_review_rounded,
                  size: 16, color: Color(0xFFF9A825)),
              const SizedBox(width: 6),
              const Text(
                'Ulasan Anda',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFF57F17),
                ),
              ),
              const Spacer(),
              Text(
                Helper.formatTanggal(u.tglUlasan),
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Bintang + teks rating
          Row(
            children: [
              ...List.generate(5, (i) {
                return Icon(
                  i < u.rating
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  size: 20,
                  color: i < u.rating
                      ? const Color(0xFFF9A825)
                      : Colors.grey.shade300,
                );
              }),
              const SizedBox(width: 8),
              Text(
                Helper.getRatingText(u.rating),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Helper.getRatingColor(u.rating),
                ),
              ),
            ],
          ),

          if (u.isiUlasan.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                u.isiUlasan,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade800,
                  height: 1.5,
                ),
              ),
            ),
          ],

          // Balasan vendor (jika ada)
          if (u.adaBalasan == true &&
              u.isiBalasan != null &&
              u.isiBalasan!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.reply_rounded,
                          size: 14, color: Colors.blue.shade700),
                      const SizedBox(width: 5),
                      Text(
                        'Balasan Vendor',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      const Spacer(),
                      if (u.tglBalasan != null)
                        Text(
                          Helper.formatTanggal(u.tglBalasan!),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blue.shade600,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    u.isiBalasan!,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blue.shade800,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Tombol beri ulasan (belum ada review) ───────────────────
  Widget _buildBeriUlasanButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _openUlasanDialog();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8E1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFFFCC02).withOpacity(0.6),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.star_outline_rounded,
              color: Color(0xFFF9A825),
              size: 20,
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Bagaimana pengalamanmu?',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFF57F17),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF9A825),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Beri Ulasan',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Tombol detail ───────────────────────────────────────────
  Widget _buildDetailButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.read<NavigationProvider>().navigateToPage(
              context,
              DetailOrderPageV2(pesananModel: widget.order),
              // DetailOrderPage(pesananModel: widget.order),
              targetTabIndex: 2,
            );
      },
      child: Container(
        width: double.infinity,
        height: 42,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 15,
              color: Colors.grey.shade600,
            ),
            const SizedBox(width: 6),
            Text(
              'Lihat Detail Pesanan',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SHARED HELPER WIDGETS
// ═══════════════════════════════════════════════════════════════

class _VendorAvatar extends StatelessWidget {
  final String url;
  const _VendorAvatar({required this.url});

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return CircleAvatar(
        radius: 22,
        backgroundColor: Constants.primaryColor.withOpacity(0.12),
        child: Icon(Icons.person, size: 20, color: Constants.primaryColor),
      );
    }
    return CircleAvatar(
      radius: 22,
      backgroundColor: Colors.grey.shade200,
      backgroundImage: NetworkImage(url),
      onBackgroundImageError: (_, __) {},
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
