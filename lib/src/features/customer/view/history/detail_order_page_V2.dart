import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/constants/helper.dart';
import 'package:mpjnew/src/core/routing/navigation_provider.dart';
import 'package:mpjnew/src/core/utils/deadline_helper.dart';
import 'package:mpjnew/src/core/services/refund_transaksi_service.dart';
import 'package:mpjnew/src/core/utils/shimmer_placeholder.dart';
import 'package:mpjnew/src/data/models/refund_transaksi_model.dart';
import 'package:mpjnew/src/data/models/metode_pembayaran_model.dart';
import 'package:mpjnew/src/data/hive_entity/paket_model.dart';
import 'package:mpjnew/src/data/hive_entity/penawaran_model.dart';
import 'package:mpjnew/src/data/hive_entity/pesanan_model.dart';
import 'package:mpjnew/src/data/models/ulasan_model.dart';
import 'package:mpjnew/src/features/customer/services/metode_pembayaran_service.dart';
import 'package:mpjnew/src/features/customer/services/paket_service.dart';
import 'package:mpjnew/src/features/customer/services/penawaran_service.dart';
import 'package:mpjnew/src/features/customer/services/ulasan_service.dart';
import 'package:mpjnew/src/features/customer/view/chat/room_chat_page.dart';
import 'package:mpjnew/src/features/customer/view/complain/complain_thread_page.dart';
import 'package:mpjnew/src/features/customer/view/history/detail_order_shimmer.dart';
import 'package:mpjnew/src/features/customer/view/history/section/location_section.dart';
import 'package:mpjnew/src/features/customer/view/history/section/package_section.dart';
import 'package:mpjnew/src/features/customer/view/history/section/payment_section.dart';
import 'package:mpjnew/src/features/customer/view/history/section/refund_section.dart';
import 'package:mpjnew/src/features/customer/view/history/section/progress_section.dart';
import 'package:mpjnew/src/features/customer/view/history/section/result_section.dart';
import 'package:mpjnew/src/features/customer/view/history/section/ulasan_section.dart';
import 'package:mpjnew/src/features/customer/view/history/widget/complain_menu_action.dart';
import 'package:mpjnew/src/features/customer/view/history/widget/expandable_card.dart';
import 'package:mpjnew/src/features/customer/view/history/widget/header_info_card.dart';
import 'package:mpjnew/src/features/customer/view/history/widget/sticky_button_bar.dart';
import 'package:mpjnew/src/features/customer/view/history/widget/status_config.dart';
import 'package:mpjnew/src/features/customer/viewmodels/complain_provider.dart';
import 'package:mpjnew/src/features/customer/viewmodels/history_order_provider.dart';
import 'package:mpjnew/src/features/customer/viewmodels/pesanan_provider.dart';
import 'package:mpjnew/src/features/customer/widget/dialog/custom_snackbar.dart';
import 'package:mpjnew/src/features/customer/widget/dialog/extend_deadline_flow.dart';
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
  RefundTransaksiModel? _refundTransaksi;
  PaketModel? paket;
  PenawaranModel? penawaran;
  MetodePembayaranModel? metodePembayaran;
  late HistoryOrderProvider historyProvider;

  bool isLoading = false;
  bool isPaymentExpanded = false;
  bool isPackageExpanded = false;
  bool isProgressExpanded = true;

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

      context
          .read<ComplainProvider>()
          .checkForOrder(widget.pesananModel.noBukti);

      final pesananProvider = context.read<PesananProvider>();
      final orderStatus = widget.pesananModel.status?.toLowerCase() ?? '';
      final isTerminal = orderStatus == 'batal' || orderStatus == 'expired';
      if (pesananProvider.getPesananByNoOrder(widget.pesananModel.noBukti) ==
              null ||
          isTerminal) {
        await pesananProvider.refreshOrder(widget.pesananModel.noBukti);
      }

      final wasTracked =
          historyProvider.isOrderTracked(widget.pesananModel.noBukti);
      await historyProvider.trackOrder(widget.pesananModel.noBukti);
      if (wasTracked) {
        await historyProvider.fetchHistoryForOrder(widget.pesananModel.noBukti);
      }

      final pesanan =
          pesananProvider.getPesananByNoOrder(widget.pesananModel.noBukti) ??
              widget.pesananModel;
      paket = (await PaketService().getAll(noId: pesanan.idPaket)).firstOrNull;

      // Paket adalah nilai default; penawaran yang disepakati bisa saja
      // mengubah rincian/revisi/harga dari default itu. PackageSection
      // memprioritaskan data penawaran ini, baru fallback ke paket.
      penawaran =
          (pesanan.noPenawaran != null && pesanan.noPenawaran!.isNotEmpty)
              ? (await PenawaranService().getAll(noId: pesanan.noPenawaran))
                  .firstOrNull
              : null;

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

      // Status refund dari transaksi refund kalau ada; kalau endpoint-nya
      // belum siap, service mengembalikan [] dan label status jatuh balik ke
      // pesanan.tglRefund/tglRefunded seperti sebelumnya.
      if (_statusTerminal(pesanan.statusProgresPesanan) ||
          _statusTerminal(pesanan.status)) {
        final transaksi =
            await RefundTransaksiService().getAll(idPesanan: pesanan.noBukti);
        _refundTransaksi = transaksi.firstOrNull;
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
      context
          .read<ComplainProvider>()
          .checkForOrder(widget.pesananModel.noBukti);

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
    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xFFF9F9F9),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF9F9F9),
          elevation: 0,
          title: const Text('Detail Pesanan',
              style:
                  TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          actions: [ComplainMenuAction(pesanan: widget.pesananModel)],
        ),
        body: Consumer2<PesananProvider, ComplainProvider>(
          builder: (context, pesananProvider, complainProvider, _) {
            final pesananFromProvider = pesananProvider
                .getPesananByNoOrder(widget.pesananModel.noBukti);

            if (isLoading && pesananFromProvider == null) {
              return DetailOrderShimmer(fetchData: fetchData);
            }

            final pesanan = pesananFromProvider ?? widget.pesananModel;
            final orderStatus = pesanan.status?.toLowerCase() ?? '';
            final isTerminalOrder =
                orderStatus == 'batal' || orderStatus == 'expired';
            final status = isTerminalOrder
                ? orderStatus
                : pesanan.statusProgresPesanan?.toLowerCase() ?? '';

            final transition = OrderStatusFlow.get('persiapan', 'proses');
            final btnLabel =
                transition?.actionLabel ?? 'Konfirmasi Pemotretan Selesai';

            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);
            final tglShoot = pesanan.tglRealisasi != null
                ? DateTime(pesanan.tglRealisasi.year,
                    pesanan.tglRealisasi.month, pesanan.tglRealisasi.day)
                : null;

            final bool isBeforeShoot =
                tglShoot != null && today.isBefore(tglShoot);
            final bool isOnShootDay =
                tglShoot != null && today.isAtSameMomentAs(tglShoot);

            final dotColor = _cfg(pesanan.statusProgresPesanan ?? "").color;
            final shootLabel = isBeforeShoot
                ? 'Dijadwalkan ${Helper.formatTanggal(pesanan.tglRealisasi)}'
                : isOnShootDay
                    ? 'Sesi pemotretan hari ini'
                    : 'Sesi pemotretan sudah berlangsung';

            // for Complain
            final checking = complainProvider.isChecking(pesanan.noBukti);
            final error = complainProvider.getCheckError(pesanan.noBukti);
            final complain =
                complainProvider.getCachedForOrder(pesanan.noBukti);
            return SafeArea(
              child: Scaffold(
                backgroundColor: const Color(0xFFF9F9F9),
                bottomNavigationBar: complain != null && !complain.isClosed
                    ? StickyButtonBar(
                        btnLabel: "Lihat Complain",
                        dotColor: dotColor,
                        icon: Icons.report_outlined,
                        keterangan: "Complain sedang berlangsung",
                        onTap: checking
                            ? null
                            : () async {
                                if (error != null) {
                                  await complainProvider
                                      .checkForOrder(pesanan.noBukti);
                                  return;
                                }
                                Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => ComplainThreadPage(
                                    noComplain: complain.noComplain,
                                    noOrder: pesanan.noBukti,
                                    showOrderAction: false,
                                  ),
                                ));
                              },
                      )
                    : status == 'persiapan'
                        ? StickyButtonBar(
                            btnLabel: btnLabel,
                            dotColor: dotColor,
                            icon: Icons.camera_alt_rounded,
                            keterangan: shootLabel,
                            onTap: _konfirmasiPemotretan,
                          )
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
                        HeaderInfoCard(
                          status: status,
                          pesanan: pesanan,
                          haveComplain: complain != null && !complain.isClosed,
                        ),
                        const SizedBox(height: 12),
                        _buildProfileCard(pesanan),
                        const SizedBox(height: 12),
                        if (pesanan.linkUrl != null &&
                            pesanan.linkUrl!.isNotEmpty) ...[
                          ResultSection(
                            pesanan: pesanan,
                            onShowUlasanDialog: _showUlasanDialog,
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (_refundTransaksi != null &&
                            _refundTransaksi!.adaDanaCustomer)
                          RefundSection(transaksi: _refundTransaksi!),
                        LocationSection(
                          pesanan: pesanan,
                          onExtendDeadline: (pesanan.tglPengerjaanMax != null &&
                                  {'proses', 'review', 'revisi'}.contains(
                                      pesanan.statusProgresPesanan
                                          ?.trim()
                                          .toLowerCase()))
                              ? () => showExtendDeadlineFlow(context, pesanan)
                              : null,
                        ),
                        ProgressSection(pesanan: pesanan),
                        PaymentSection(pesanan: pesanan),
                        if (paket != null)
                          ExpandableCard(
                            title: 'Detail Paket',
                            isExpanded: isPackageExpanded,
                            onToggle: () => setState(
                                () => isPackageExpanded = !isPackageExpanded),
                            content: PackageSection(
                                paket: paket,
                                pesanan: pesanan,
                                penawaran: penawaran),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // PROFILE CARD
  // ═══════════════════════════════════════════════════════════════

  static bool _statusTerminal(String? status) => const {
        'batal',
        'dibatalkan',
        'refund paid',
        'expired',
        'closed',
      }.contains((status ?? '').toLowerCase().trim());

  Widget _buildProfileCard(PesananModel pesanan) {
    final status = pesanan.statusProgresPesanan?.toLowerCase() ?? '';

    // Transaksi refund lebih otoritatif kalau ada; kalau tidak (endpoint
    // belum siap / belum ada barisnya), pakai penanda di pesanan.
    // Refund 0% → bukan "Dana Sedang Direfund", cukup "Dibatalkan".
    final trx = _refundTransaksi;
    final cfg = getStatus(
      status,
      isRefundProcessing: trx != null
          ? trx.isProses && trx.adaDanaCustomer
          : pesanan.isRefundProcessing,
      isRefundDone: trx != null
          ? trx.isPaid && trx.adaDanaCustomer
          : pesanan.isRefundDone,
    );

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
              const SizedBox(width: 8),
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
            UlasanSection(
              pesanan: pesanan,
              ulasan: ulasan,
              onPressedBerikanUlasan: () => _showUlasanDialog(),
            ),
          ],
          if (remainingIfNearDeadline(pesanan) != null) ...[
            const SizedBox(height: 12),
            _buildDeadlineReminder(pesanan, remainingIfNearDeadline(pesanan)!),
          ],
        ],
      ),
    );
  }

  Widget _buildDeadlineReminder(PesananModel pesanan, Duration remaining) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timer_outlined, size: 16, color: Colors.red.shade700),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Sisa waktu pengerjaan: ${formatRemainingDeadline(remaining)}',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.red.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Pastikan vendor bisa selesai tepat waktu -- ingatkan vendor, '
            'atau perpanjang batas pengerjaan.',
            style: TextStyle(
                fontSize: 11.5, color: Colors.red.shade600, height: 1.4),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    context.read<NavigationProvider>().popAllToRoot();
                    context.read<NavigationProvider>().navigateToPage(
                          context,
                          RoomChatPage(partnerId: pesanan.idVendor),
                          targetTabIndex: 1,
                        );
                  },
                  icon: const Icon(Icons.chat_outlined, size: 16),
                  label: const Text('Ingatkan Vendor'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                    side: BorderSide(color: Colors.red.shade300),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => showExtendDeadlineFlow(context, pesanan),
                  icon: const Icon(Icons.event_available_outlined, size: 16),
                  label: const Text('Perpanjang'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
