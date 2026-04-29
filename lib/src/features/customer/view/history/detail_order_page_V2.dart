import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/constants/helper.dart';
import 'package:mpjnew/src/core/routing/navigation_provider.dart';
import 'package:mpjnew/src/core/utils/shimmer_placeholder.dart';
import 'package:mpjnew/src/data/models/history_order_model.dart';
import 'package:mpjnew/src/data/models/metode_pembayaran_model.dart';
import 'package:mpjnew/src/data/hive_entity/paket_model.dart';
import 'package:mpjnew/src/data/hive_entity/pesanan_model.dart';
import 'package:mpjnew/src/data/models/ulasan_model.dart';
import 'package:mpjnew/src/features/customer/services/metode_pembayaran_service.dart';
import 'package:mpjnew/src/features/customer/services/paket_service.dart';
import 'package:mpjnew/src/features/customer/services/ulasan_service.dart';
import 'package:mpjnew/src/features/customer/view/chat/room_chat_page.dart';
import 'package:mpjnew/src/features/customer/view/history/detail_order_shimmer.dart';
import 'package:mpjnew/src/features/customer/view/history/webview_page.dart';
import 'package:mpjnew/src/features/customer/view/history/widget/status_config.dart';
import 'package:mpjnew/src/features/customer/viewmodels/history_order_provider.dart';
import 'package:mpjnew/src/features/customer/viewmodels/pesanan_provider.dart';
import 'package:mpjnew/src/features/customer/widget/dialog/custom_snackbar.dart';
import 'package:mpjnew/src/features/customer/widget/dialog/revisi_dialog.dart';
import 'package:mpjnew/src/features/customer/widget/dialog/selesaikan_dialog.dart';
import 'package:mpjnew/src/features/customer/widget/dialog/ulasan_dialog.dart';
import 'package:mpjnew/src/features/customer/widget/konfirmasi_pemotretan_dialog.dart';
import 'package:mpjnew/src/features/customer/widget/order_status_flow.dart';
import 'package:mpjnew/src/features/customer/widget/refresh_header.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class DetailOrderPageV2 extends StatefulWidget {
  final PesananModel pesananModel;
  const DetailOrderPageV2({super.key, required this.pesananModel});

  @override
  State<DetailOrderPageV2> createState() => _DetailOrderPageV2State();
}

class _DetailOrderPageV2State extends State<DetailOrderPageV2> {
  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);

  UlasanModel? ulasan;
  PaketModel? paket;
  MetodePembayaranModel? metodePembayaran;
  late HistoryOrderProvider historyProvider;

  bool isLoading = false;
  bool isPaymentExpanded = false;
  bool isPackageExpanded = false;
  bool isProgressExpanded = true;
  bool _isStatusInfoExpanded = false;
  bool _isSubmittingStatus = false;

  int _previousHistoryCount = 0;
  Timer? _updateTimer;

  // ── Single source of truth untuk warna & icon status ──
  StatusConfig _cfg(String status) => getStatus(status);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchData();
      _setupHistoryListener();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    historyProvider = context.read<HistoryOrderProvider>();
    _previousHistoryCount =
        historyProvider.getHistoryCount(widget.pesananModel.noBukti);
  }

  @override
  void dispose() {
    historyProvider.untrackOrder(widget.pesananModel.noBukti);
    _updateTimer?.cancel();
    _refreshController.dispose();
    super.dispose();
  }

  void _setupHistoryListener() {
    final hp = context.read<HistoryOrderProvider>();
    hp.addListener(() {
      if (!mounted) return;
      final count = hp.getHistoryCount(widget.pesananModel.noBukti);
      if (count != _previousHistoryCount) {
        _previousHistoryCount = count;
        _updateTimer?.cancel();
        _updateTimer = Timer(const Duration(milliseconds: 300), () {
          if (mounted) setState(() {});
        });
      }
    });
  }

  Future<void> fetchData() async {
    try {
      setState(() => isLoading = true);

      final pesananProvider = context.read<PesananProvider>();

      if (pesananProvider.getPesananByNoOrder(widget.pesananModel.noBukti) ==
          null) {
        await pesananProvider.refreshOrder(widget.pesananModel.noBukti);
      }

      historyProvider.trackOrder(widget.pesananModel.noBukti);
      await historyProvider.fetchHistoryForOrder(widget.pesananModel.noBukti);

      final pesanan =
          pesananProvider.getPesananByNoOrder(widget.pesananModel.noBukti);
      if (pesanan != null) {
        paket =
            (await PaketService().getAll(noId: pesanan.idPaket)).firstOrNull;

        if (pesanan.metodeBayar != null && pesanan.metodeBayar!.isNotEmpty) {
          final hasLinkSnap =
              pesanan.linkSnap != null && pesanan.linkSnap!.isNotEmpty;

          final metodeList = hasLinkSnap
              ? await MetodePembayaranService()
                  .getAll(paymentSnap: pesanan.metodeBayar)
              : await MetodePembayaranService()
                  .getAll(caraBayar: pesanan.metodeBayar);

          metodePembayaran = metodeList.firstOrNull;
        }

        if (pesanan.statusProgresPesanan?.toLowerCase() == 'selesai') {
          final list = await UlasanService().getAll(noOrder: pesanan.noBukti);
          ulasan = list.isNotEmpty ? list.first : null;
        }
      }
    } catch (e) {
      if (mounted) CustomSnackbar.showErrorSnackbar(context, e.toString());
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _onRefresh() async {
    if (!mounted) {
      _refreshController.refreshCompleted();
      return;
    }
    try {
      final pesananProvider = context.read<PesananProvider>();
      await pesananProvider.refreshOrder(widget.pesananModel.noBukti);
      await historyProvider.fetchHistoryForOrder(widget.pesananModel.noBukti);

      final pesanan =
          pesananProvider.getPesananByNoOrder(widget.pesananModel.noBukti);
      if (pesanan != null) {
        // ✅ Refresh metode pembayaran
        if (pesanan.metodeBayar != null && pesanan.metodeBayar!.isNotEmpty) {
          final hasLinkSnap =
              pesanan.linkSnap != null && pesanan.linkSnap!.isNotEmpty;

          final metodeList = hasLinkSnap
              ? await MetodePembayaranService()
                  .getAll(paymentSnap: pesanan.metodeBayar)
              : await MetodePembayaranService()
                  .getAll(caraBayar: pesanan.metodeBayar);

          if (mounted)
            setState(() => metodePembayaran = metodeList.firstOrNull);
        }

        if (pesanan.statusProgresPesanan?.toLowerCase() == 'selesai') {
          final list = await UlasanService().getAll(noOrder: pesanan.noBukti);
          if (mounted)
            setState(() => ulasan = list.isNotEmpty ? list.first : null);
        }
      }

      _refreshController.refreshCompleted();
    } catch (_) {
      _refreshController.refreshFailed();
    }
  }

  Future<void> _konfirmasiPemotretan() async {
    final pesanan = context
        .read<PesananProvider>()
        .getPesananByNoOrder(widget.pesananModel.noBukti);
    if (pesanan == null) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => KonfirmasiPemotretanDialog(
        pesanan: pesanan,
        onSuccess: () async {
          if (!mounted) return;
          await context
              .read<PesananProvider>()
              .refreshOrder(widget.pesananModel.noBukti);
          await historyProvider
              .fetchHistoryForOrder(widget.pesananModel.noBukti);
        },
      ),
    );
  }

  Future<void> _mintaRevisi() async {
    final pesananProvider = context.read<PesananProvider>();
    final pesanan =
        pesananProvider.getPesananByNoOrder(widget.pesananModel.noBukti);
    if (pesanan == null) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => RevisiDialog(
        pesanan: pesanan,
        onSuccess: () async {
          if (!mounted) return;
          await pesananProvider.refreshOrder(widget.pesananModel.noBukti);
          await historyProvider
              .fetchHistoryForOrder(widget.pesananModel.noBukti);
        },
      ),
    );
  }

  Future<void> _selesaikanPesanan() async {
    final pesananProvider = context.read<PesananProvider>();
    final pesanan =
        pesananProvider.getPesananByNoOrder(widget.pesananModel.noBukti);
    if (pesanan == null) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => SelesaikanDialog(
        pesanan: pesanan,
        onSuccess: () async {
          if (!mounted) return;
          await pesananProvider.refreshOrder(widget.pesananModel.noBukti);
          await historyProvider
              .fetchHistoryForOrder(widget.pesananModel.noBukti);
          if (mounted) {
            await Future.delayed(const Duration(milliseconds: 800));
            if (mounted) _showUlasanDialog();
          }
        },
      ),
    );
  }

  void _showUlasanDialog() {
    final pesanan = context
        .read<PesananProvider>()
        .getPesananByNoOrder(widget.pesananModel.noBukti);
    if (pesanan == null) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => UlasanDialog(
        pesanan: pesanan,
        onSuccess: () async {
          final list = await UlasanService().getAll(noOrder: pesanan.noBukti);
          if (mounted)
            setState(() => ulasan = list.isNotEmpty ? list.first : null);
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F9F9),
        elevation: 0,
        title: const Text('Detail Pesanan',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: Consumer<PesananProvider>(
        builder: (context, pesananProvider, _) {
          final pesanan =
              pesananProvider.getPesananByNoOrder(widget.pesananModel.noBukti);

          if (isLoading || pesanan == null) {
            return DetailOrderShimmer(fetchData: fetchData);
          }

          final status = pesanan.statusProgresPesanan?.toLowerCase() ?? '';

          return Scaffold(
            backgroundColor: const Color(0xFFF9F9F9),
            bottomNavigationBar: status == 'persiapan'
                ? _buildStickyKonfirmasiBar(pesanan)
                : null,
            body: SmartRefresher(
              controller: _refreshController,
              onRefresh: _onRefresh,
              physics: const AlwaysScrollableScrollPhysics(),
              header: buildRefreshHeader(),
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                    10, 10, 10, status == 'persiapan' ? 120 : 80),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatusInfoCard(status, pesanan),
                    const SizedBox(height: 12),
                    _buildProfileCard(pesanan),
                    const SizedBox(height: 12),
                    if ((status == 'review' || status == 'revisi') &&
                        pesanan.linkUrl != null &&
                        pesanan.linkUrl!.isNotEmpty) ...[
                      _buildLinkResultCard(pesanan),
                      const SizedBox(height: 12),
                    ],
                    if (status == 'revisi') ...[
                      _buildRevisiWaitingBanner(),
                      const SizedBox(height: 12),
                    ],
                    _buildExpandableCard(
                      title: 'Pembayaran',
                      isExpanded: isPaymentExpanded,
                      onToggle: () => setState(
                          () => isPaymentExpanded = !isPaymentExpanded),
                      summaryWidget: !isPaymentExpanded
                          ? _buildPaymentSummary(pesanan)
                          : null,
                      content: _buildPaymentContent(pesanan),
                    ),
                    _buildProgressSection(pesanan),
                    _buildCardSection(
                        title: 'Lokasi & Jadwal',
                        content: _buildLocationContent(pesanan)),
                    if (paket != null)
                      _buildExpandableCard(
                        title: 'Detail Paket',
                        isExpanded: isPackageExpanded,
                        onToggle: () => setState(
                            () => isPackageExpanded = !isPackageExpanded),
                        content: _buildPackageContent(),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // STATUS INFO CARD
  // ✅ Gunakan OrderStatusFlow.customerInfoLabel() — return StatusInfoLabel
  // ═══════════════════════════════════════════════════════════════

  Widget _buildStatusInfoCard(String status, PesananModel pesanan) {
    // ── Ambil info dari customerInfoLabel — teks & icon dari satu sumber ──
    final infoLabel = OrderStatusFlow.customerInfoLabel(status);

    StatusConfig cfg = _cfg(status);
    Color borderColor = cfg.color;
    Color bgColor = cfg.bgColor;
    IconData icon = cfg.icon;

    String shortText;
    String fullText = infoLabel.body;

    // Override khusus untuk status persiapan berdasarkan tanggal
    if (status == 'persiapan') {
      final now = DateTime.now();
      final tglRealisasi = pesanan.tglRealisasi;
      final today = DateTime(now.year, now.month, now.day);
      final tglShoot = tglRealisasi != null
          ? DateTime(tglRealisasi.year, tglRealisasi.month, tglRealisasi.day)
          : null;

      if (tglShoot == null) {
        fullText = infoLabel.body;
      } else if (today.isBefore(tglShoot)) {
        bgColor = Colors.grey.shade50;
        borderColor = Colors.grey.shade400;
        icon = Icons.schedule_rounded;
        fullText =
            'Pemotretan dijadwalkan pada ${Helper.formatTanggal(tglRealisasi!)}. '
            'Tombol konfirmasi akan aktif pada hari pemotretan atau setelahnya. '
            'Pastikan Anda hadir sesuai jadwal dan siap mengonfirmasi setelah sesi selesai.';
      } else if (today.isAtSameMomentAs(tglShoot)) {
        icon = Icons.camera_alt_outlined;
        fullText = 'Pemotretan dijadwalkan hari ini. Setelah sesi selesai, '
            'segera tekan tombol Konfirmasi Pemotretan Selesai di bawah '
            'agar vendor dapat mulai mengerjakan hasil foto Anda.';
      } else {
        bgColor = _cfg('proses').bgColor;
        borderColor = _cfg('proses').color;
        icon = Icons.warning_amber_rounded;
        fullText = 'Pemotretan sudah melewati tanggal yang dijadwalkan '
            '(${Helper.formatTanggal(tglRealisasi!)}). '
            'Segera konfirmasi jika sesi telah selesai dilaksanakan. '
            'Jika tidak dikonfirmasi dalam 3×24 jam dari tanggal realisasi, '
            'pesanan akan otomatis lanjut ke tahap pengerjaan oleh vendor.';
      }
    }

    if (fullText.isEmpty) return const SizedBox.shrink();

    // Potong kalimat pertama untuk shortText
    final dotSpace = fullText.indexOf('. ');
    if (dotSpace != -1) {
      shortText = fullText.substring(0, dotSpace + 1);
    } else {
      const maxShort = 60;
      shortText = fullText.length > maxShort
          ? '${fullText.substring(0, maxShort).trimRight()}...'
          : fullText;
    }

    final bool canExpand = shortText.trim() != fullText.trim();

    return GestureDetector(
      onTap: canExpand
          ? () => setState(() => _isStatusInfoExpanded = !_isStatusInfoExpanded)
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 18, color: borderColor),
                const SizedBox(width: 10),
                Expanded(
                  child: AnimatedCrossFade(
                    firstChild: Text(
                      shortText,
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade800,
                          height: 1.5),
                    ),
                    secondChild: Text(
                      fullText,
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade800,
                          height: 1.5),
                    ),
                    crossFadeState: _isStatusInfoExpanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 250),
                  ),
                ),
              ],
            ),
            if (canExpand) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 28),
                child: Text(
                  _isStatusInfoExpanded ? 'Sembunyikan' : 'Selengkapnya',
                  style: TextStyle(
                    fontSize: 12,
                    color: borderColor,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                    decorationColor: borderColor,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // REVISI WAITING BANNER
  // ═══════════════════════════════════════════════════════════════

  Widget _buildRevisiWaitingBanner() {
    final cfg = _cfg('revisi');
    // ✅ Teks dari customerInfoLabel, bukan hardcode
    final info = OrderStatusFlow.customerInfoLabel('revisi');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cfg.bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cfg.color.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cfg.color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(cfg.icon, size: 18, color: cfg.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  info.title, // ✅ dari customerInfoLabel
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: cfg.color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  info.body, // ✅ dari customerInfoLabel
                  style: TextStyle(fontSize: 12, color: cfg.color, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // LINK HASIL KERJA
  // ═══════════════════════════════════════════════════════════════

  Widget _buildLinkResultCard(PesananModel pesanan) {
    final status = pesanan.statusProgresPesanan?.toLowerCase() ?? '';
    final cfg = _cfg(status);
    final isRevisi = status == 'revisi';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cfg.color.withOpacity(0.5)),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: cfg.bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.photo_library_outlined,
                    color: cfg.color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isRevisi
                      ? 'Hasil Kerja Sebelum Revisi'
                      : 'Hasil Pekerjaan Vendor',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
              InkWell(
                onTap: () => Helper.copyToClipboard(
                    context, pesanan.linkUrl!, 'Link Hasil'),
                borderRadius: BorderRadius.circular(20),
                child: Tooltip(
                  message: 'Salin link',
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: cfg.bgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.copy_rounded, size: 16, color: cfg.color),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: () => context.read<NavigationProvider>().navigateToPage(
                  context,
                  WebviewPage(url: pesanan.linkUrl!),
                  targetTabIndex: 2,
                ),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: cfg.bgColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: cfg.color.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.link_rounded, size: 16, color: cfg.color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      pesanan.linkUrl!,
                      style: TextStyle(
                        fontSize: 13,
                        color: cfg.color,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.underline,
                        decorationColor: cfg.color,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.open_in_new_rounded, size: 14, color: cfg.color),
                ],
              ),
            ),
          ),
          if (status == 'review') ...[
            const SizedBox(height: 10),
            _buildCustomerActionArea('review', pesanan),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // STICKY BOTTOM BAR
  // ═══════════════════════════════════════════════════════════════

  Widget _buildStickyKonfirmasiBar(PesananModel pesanan) {
    final now = DateTime.now();
    final tglRealisasi = pesanan.tglRealisasi;
    final today = DateTime(now.year, now.month, now.day);
    final tglShoot = tglRealisasi != null
        ? DateTime(tglRealisasi.year, tglRealisasi.month, tglRealisasi.day)
        : null;

    final bool isBeforeShoot = tglShoot != null && today.isBefore(tglShoot);
    final bool isOnShootDay =
        tglShoot != null && today.isAtSameMomentAs(tglShoot);
    final bool isAfterShoot = tglShoot != null && today.isAfter(tglShoot);

    // ✅ Warna dot dari _cfg — tidak ada magic color manual
    final dotColor = isBeforeShoot
        ? Colors.grey
        : isOnShootDay
            ? _cfg('persiapan').color
            : _cfg('proses').color;

    // ✅ Label dari OrderStatusFlow.displayLabel
    final shootLabel = isBeforeShoot
        ? 'Sesi pemotretan belum dimulai'
        : isOnShootDay
            ? 'Sesi pemotretan sedang berlangsung hari ini'
            : 'Sesi pemotretan sudah berlangsung';

    // ✅ Label tombol dari OrderStatusFlow.transitions
    final transition = OrderStatusFlow.get('persiapan', 'proses');
    final btnLabel = transition?.actionLabel ?? 'Konfirmasi Pemotretan Selesai';

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        boxShadow: const [
          BoxShadow(
              color: Colors.black12, blurRadius: 8, offset: Offset(0, -2)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration:
                    BoxDecoration(color: dotColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  shootLabel,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed:
                  (isOnShootDay || isAfterShoot) ? _konfirmasiPemotretan : null,
              icon: const Icon(Icons.camera_alt_rounded, size: 20),
              label: Text(
                btnLabel, // ✅ dari OrderStatusFlow.transitions
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Constants.primaryColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                disabledForegroundColor: Colors.grey.shade500,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // CUSTOMER ACTION AREA
  // ✅ Label tombol dari OrderStatusFlow.transitions
  // ═══════════════════════════════════════════════════════════════

  Widget _buildCustomerActionArea(String status, PesananModel pesanan) {
    if (status != 'review') return const SizedBox.shrink();

    final cfgRevisi = _cfg('revisi');
    final cfgSelesai = _cfg('selesai');

    // ✅ Label dari transitions — satu sumber kebenaran
    final revisiTransition = OrderStatusFlow.get('review', 'revisi');
    final selesaiTransition = OrderStatusFlow.get('review', 'selesai');

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _isSubmittingStatus ? null : _mintaRevisi,
            icon: _isSubmittingStatus
                ? SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: cfgRevisi.color))
                : Icon(cfgRevisi.icon, size: 18), // ✅ icon dari cfg
            label: Text(
              revisiTransition?.actionLabel ??
                  'Minta Revisi', // ✅ label dari transitions
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: cfgRevisi.color,
              side: BorderSide(color: cfgRevisi.color, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isSubmittingStatus ? null : _selesaikanPesanan,
            icon: _isSubmittingStatus
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : Icon(cfgSelesai.icon, size: 18), // ✅ icon dari cfg
            label: Text(
              selesaiTransition?.actionLabel ??
                  'Selesaikan', // ✅ label dari transitions
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: cfgSelesai.color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // PROGRESS SECTION
  // ═══════════════════════════════════════════════════════════════

  Widget _buildProgressSection(PesananModel pesanan) {
    return Consumer<HistoryOrderProvider>(
      builder: (context, hp, _) {
        final histories = hp.getHistoryForOrder(pesanan.noBukti);
        final isLoadingH = hp.isLoadingOrder(pesanan.noBukti);
        final errorH = hp.getErrorForOrder(pesanan.noBukti);

        if (isLoadingH && histories.isEmpty) return _buildProgressShimmer();
        if (errorH != null && histories.isEmpty)
          return _buildProgressError(errorH, pesanan.noBukti);

        return _buildExpandableCard(
          title: 'Riwayat Progress',
          isExpanded: isProgressExpanded,
          onToggle: () =>
              setState(() => isProgressExpanded = !isProgressExpanded),
          summaryWidget: !isProgressExpanded && histories.isNotEmpty
              ? _buildProgressSummaryRow(histories.first)
              : null,
          content: histories.isEmpty
              ? _buildProgressEmpty()
              : Column(
                  children: List.generate(
                    histories.length,
                    (i) => _buildTimelineItem(
                      histories[i],
                      isFirst: i == 0,
                      isLast: i == histories.length - 1,
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildProgressSummaryRow(HistoryOrderModel history) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
                color: Constants.primaryColorVendor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              history.deskripsi,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500),
            ),
          ),
          _buildLiveBadge(),
        ],
      ),
    );
  }

  Widget _buildLiveBadge() {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
                color: Colors.green, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text('Live',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade700)),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(HistoryOrderModel history,
      {required bool isFirst, required bool isLast}) {
    // ✅ Warna & label dari _cfg() + OrderStatusFlow.displayLabel
    final cfg = _cfg(history.statusProgressPesanan);
    final dotColor = isFirst ? cfg.color : Colors.grey.shade400;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration:
                    BoxDecoration(color: dotColor, shape: BoxShape.circle),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: Colors.grey.shade300,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${Helper.formatTanggal(history.tglProgress)}, ${Helper.toLocalTime(history.tglProgress)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isFirst ? cfg.bgColor : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      // ✅ Label dari cfg (sudah pakai OrderStatusFlow.displayLabel di dalamnya)
                      cfg.label,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isFirst ? cfg.color : Colors.grey.shade500),
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (history.statusProgressPesanan == 'revisi' ||
                      (history.statusProgressPesanan == 'proses' &&
                          history.deskripsi.toLowerCase().contains('revisi')))
                    _buildRevisionNote(history.deskripsi, cfg)
                  else
                    Text(
                      history.deskripsi,
                      style: TextStyle(
                        fontSize: 14,
                        color: isFirst
                            ? Constants.primaryColorVendor
                            : Colors.black54,
                        fontWeight:
                            isFirst ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevisionNote(String deskripsi, StatusConfig cfg) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cfg.bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: cfg.color, width: 3)),
      ),
      child: Text(deskripsi,
          style: TextStyle(
              fontSize: 13, color: Colors.grey.shade800, height: 1.4)),
    );
  }

  Widget _buildProgressEmpty() {
    return Column(
      children: [
        Icon(Icons.timeline_rounded, size: 52, color: Colors.grey.shade300),
        const SizedBox(height: 8),
        Text('Belum ada riwayat progress',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildProgressShimmer() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
                color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
              height: 14,
              width: 100,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 14),
          ...List.generate(
            3,
            (_) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                          color: Colors.grey.shade300, shape: BoxShape.circle)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                            height: 10,
                            width: 70,
                            decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(4))),
                        const SizedBox(height: 5),
                        Container(
                            height: 12,
                            decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(4))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressError(String msg, String noBukti) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
          const SizedBox(height: 8),
          Text('Gagal memuat progress',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
          const SizedBox(height: 4),
          Text(msg,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => historyProvider.fetchHistoryForOrder(noBukti),
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
                backgroundColor: Constants.primaryColorVendor,
                foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // ULASAN SECTION
  // ═══════════════════════════════════════════════════════════════

  Widget _buildUlasanSection(PesananModel pesanan) {
    if (ulasan == null) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _showUlasanDialog,
          icon: const Icon(Icons.rate_review_outlined, size: 18),
          label: const Text('Berikan Ulasan',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          style: OutlinedButton.styleFrom(
            foregroundColor: Constants.primaryColor,
            side: BorderSide(color: Constants.primaryColor, width: 1.5),
            padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );
    }
    return _buildUlasanCard();
  }

  Widget _buildUlasanCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: Constants.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: Icon(Icons.rate_review_rounded,
                    color: Constants.primaryColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Ulasan Anda',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(
                      '${Helper.formatTanggal(ulasan!.tglUlasan)}, ${Helper.toLocalTime(ulasan!.tglUlasan)}',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ...List.generate(
                  5,
                  (i) => Icon(
                        i < ulasan!.rating
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: i < ulasan!.rating
                            ? Colors.amber
                            : Colors.grey.shade300,
                        size: 22,
                      )),
              const SizedBox(width: 8),
              Text(Helper.getRatingText(ulasan!.rating),
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Helper.getRatingColor(ulasan!.rating))),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8)),
            child: Text(ulasan!.isiUlasan,
                style: TextStyle(
                    fontSize: 13, color: Colors.grey.shade800, height: 1.5)),
          ),
          if (ulasan!.adaBalasan == true &&
              ulasan!.isiBalasan != null &&
              ulasan!.isiBalasan!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
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
                      const SizedBox(width: 6),
                      Text('Balasan Vendor',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue.shade700)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(ulasan!.isiBalasan!,
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue.shade800,
                          height: 1.5)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // PROFILE CARD
  // ═══════════════════════════════════════════════════════════════

  Widget _buildProfileCard(PesananModel pesanan) {
    final status = pesanan.statusProgresPesanan?.toLowerCase() ?? '';
    final cfg = _cfg(status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              pesanan.idMediaVendor != null && pesanan.idMediaVendor!.isNotEmpty
                  ? CircleAvatar(
                      radius: 26,
                      child: CachedNetworkImage(
                        imageUrl: pesanan.idMediaVendor!,
                        imageBuilder: (ctx, img) =>
                            CircleAvatar(radius: 26, backgroundImage: img),
                        placeholder: (ctx, _) => ShimmerPlaceholder(radius: 26),
                        errorWidget: (_, __, ___) => const CircleAvatar(
                            backgroundColor: Colors.grey,
                            child: Icon(Icons.person,
                                color: Colors.white, size: 18)),
                      ),
                    )
                  : Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Constants.primaryColorVendor,
                            Constants.primaryColorVendor.withOpacity(0.7)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          (pesanan.namaVendor?.isEmpty ?? true
                                  ? 'V'
                                  : pesanan.namaVendor![0])
                              .toUpperCase(),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pesanan.namaVendor ?? 'Vendor',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(pesanan.noTrackingPesanan ?? pesanan.kota,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black45)),
                    const SizedBox(height: 6),
                    // ✅ Badge menggunakan cfg.label (dari OrderStatusFlow.displayLabel)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: cfg.bgColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: cfg.color.withOpacity(0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(cfg.icon, size: 12, color: cfg.color),
                          const SizedBox(width: 4),
                          Text(cfg.label, // ✅ dari cfg, bukan hardcode
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: cfg.color)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 40,
                width: 40,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Constants.primaryColor),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    padding: EdgeInsets.zero,
                  ),
                  onPressed: () {
                    context.read<NavigationProvider>().popAllToRoot();
                    context.read<NavigationProvider>().navigateToPage(
                          context,
                          RoomChatPage(partnerId: pesanan.idVendor),
                          targetTabIndex: 1,
                        );
                  },
                  child: const Icon(Icons.chat_outlined,
                      color: Constants.primaryColor, size: 18),
                ),
              ),
            ],
          ),
          if (status == 'selesai') ...[
            const SizedBox(height: 12),
            _buildUlasanSection(pesanan),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // PAYMENT
  // ═══════════════════════════════════════════════════════════════

  Widget _buildPaymentSummary(PesananModel pesanan) {
    final isPaid =
        pesanan.statusBayar == 'settlement' || pesanan.statusBayar == 'capture';
    // ✅ Warna dari getStatus — bukan hardcode Colors.green / Colors.orange
    final payColor =
        isPaid ? _cfg('selesai').color : _cfg('menunggu bayar').color;
    final payBg =
        isPaid ? _cfg('selesai').bgColor : _cfg('menunggu bayar').bgColor;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: payBg,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: payColor.withOpacity(0.4)),
            ),
            child: Text(
              isPaid ? 'Sudah Bayar' : 'Belum Bayar',
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, color: payColor),
            ),
          ),
          Text(
            Helper.formatCurrency(pesanan.grandTotal),
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Constants.primaryColorVendor),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentContent(PesananModel pesanan) {
    final isPaid = PesananProvider.isPaymentSettled(pesanan.statusBayar);
    final payColor =
        isPaid ? _cfg('selesai').color : _cfg('menunggu bayar').color;

    final bool isInclPpn = pesanan.inclPpn == true;
    final bool isExclPpn = pesanan.inclPpn == false;
    final int ppnAmount = pesanan.totPpn ?? 0;
    final int ppnPercent = pesanan.ppn ?? 0;
    final int adminFee = metodePembayaran?.fee ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow(
          label: 'Nomor Bukti',
          value: pesanan.noTrackingPesanan ?? '-',
          icon: Icons.receipt_long_outlined,
          copyable: true,
        ),
        const SizedBox(height: 8),
        _buildInfoRow(
          label: 'Metode Pembayaran',
          value: pesanan.metodeBayar != null
              ? pesanan.metodeBayar!.replaceAll('_', ' ').toUpperCase()
              : '-',
          icon: Icons.account_balance_wallet_outlined,
        ),
        const SizedBox(height: 8),
        _buildInfoRow(
          label: 'Status Pembayaran',
          icon: Icons.schedule_outlined,
          value: isPaid ? 'Sudah Bayar' : 'Belum Bayar',
          valueColor: payColor,
        ),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 12),

        // ── Header Ringkasan ─────────────────────────────
        const Text(
          'Ringkasan Pembayaran',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),

        // ── Subtotal ─────────────────────────────────────
        _buildPriceRow(
          'Subtotal',
          Helper.formatCurrency(pesanan.subtotal - adminFee),
        ),

        if (!isInclPpn) const SizedBox(height: 6),

        // ── Keterangan PPN (include) ─────────────────────
        if (isInclPpn)
          Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 6),
            child: Text(
              ppnPercent > 0
                  ? 'Harga sudah termasuk PPN $ppnPercent%'
                  : 'Harga sudah termasuk PPN',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),

        // ── Biaya Admin ──────────────────────────────────
        _buildPriceRow(
          'Biaya admin',
          Helper.formatCurrency(adminFee),
        ),

        if (!isInclPpn) const SizedBox(height: 6),

        // ── Baris PPN (exclude) ──────────────────────────
        if (isExclPpn) ...[
          _buildPriceRow(
            ppnPercent > 0 ? 'PPN $ppnPercent%' : 'PPN',
            Helper.formatCurrency(ppnAmount),
          ),
          const SizedBox(height: 6),
        ],

        const Divider(height: 20),

        // ── Total ────────────────────────────────────────
        _buildPriceRow(
          'Total Pembayaran',
          Helper.formatCurrency(pesanan.grandTotal),
          isBold: true,
          valueColor: Constants.primaryColorVendor,
        ),
      ],
    );
  }

  Widget _buildLocationContent(PesananModel pesanan) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Tanggal Pemotretan',
            value: Helper.formatTanggal(pesanan.tglRealisasi)),
        const SizedBox(height: 10),
        _buildInfoRow(
            icon: Icons.access_time,
            label: 'Waktu',
            value: Helper.toLocalTime(pesanan.tglRealisasi)),
        const SizedBox(height: 10),
        _buildInfoRow(
            icon: Icons.location_city_outlined,
            label: 'Kota',
            value: pesanan.namaKota ?? '-'),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.location_on_outlined,
                size: 18, color: Colors.black45),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Alamat Lengkap',
                      style: TextStyle(fontSize: 12, color: Colors.black54)),
                  const SizedBox(height: 2),
                  Text(pesanan.lokasi,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPackageContent() {
    if (paket == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: Constants.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.card_giftcard,
                  color: Constants.primaryColor, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(paket!.nama_paket,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(Helper.formatCurrency(paket!.harga ?? paket!.harga),
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Constants.primaryColorVendor)),
                ],
              ),
            ),
          ],
        ),
        if (paket!.rincian.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 10),
          const Text('Rincian Paket',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 6),
          Text(paket!.rincian,
              style: const TextStyle(
                  fontSize: 13, color: Colors.black87, height: 1.5)),
        ],
      ],
    );
  }

  Widget _buildExpandableCard({
    required String title,
    required bool isExpanded,
    required VoidCallback onToggle,
    required Widget content,
    Widget? summaryWidget,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(title,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold)),
                    ),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(Icons.keyboard_arrow_down_rounded,
                          color: Colors.grey.shade600),
                    ),
                  ],
                ),
                if (!isExpanded && summaryWidget != null) summaryWidget,
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: content,
                  ),
                  crossFadeState: isExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 200),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardSection({required String title, required Widget content}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color valueColor = Colors.black,
    bool copyable = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.black45),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(label,
                      style:
                          const TextStyle(fontSize: 13, color: Colors.black54)),
                  if (copyable)
                    InkWell(
                      onTap: () =>
                          Helper.copyToClipboard(context, value, label),
                      child: Icon(Icons.copy_rounded,
                          size: 16, color: Constants.primaryColorVendor),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(value,
                  style: TextStyle(
                      color: valueColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow(String label, String value,
      {bool isBold = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 14,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Text(value,
            style: TextStyle(
                fontSize: 14,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: valueColor ?? Colors.black87)),
      ],
    );
  }
}
