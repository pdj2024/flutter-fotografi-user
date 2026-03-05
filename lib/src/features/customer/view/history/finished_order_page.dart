import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
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

class FinishedOrderPage extends StatelessWidget {
  const FinishedOrderPage({super.key});

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<PesananProvider>().pesananSelesai;

    return Scaffold(
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
      body: orders.isEmpty
          ? _buildEmpty()
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 48),
              itemCount: orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) => _FinishedCard(order: orders[i]),
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
              'Belum ada pesanan selesai',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F0F0F),
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pesanan yang sudah selesai\nakan muncul di sini',
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

  @override
  void initState() {
    super.initState();
    _fetchUlasan();
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

                // ── Rating / Ulasan section ────────────────
                _buildUlasanSection(),

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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFFE8F5E9),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded,
              size: 14, color: Color(0xFF2E7D32)),
          const SizedBox(width: 6),
          const Text(
            'Selesai',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2E7D32),
            ),
          ),
          const Spacer(),
          Text(
            widget.order.noBukti.length > 8
                ? '#${widget.order.noBukti.substring(widget.order.noBukti.length - 8)}'
                : '#${widget.order.noBukti}',
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF388E3C),
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
