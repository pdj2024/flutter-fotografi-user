import 'dart:async';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:mpjnew/src/core/constants/helper.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/routing/navigation_provider.dart';
import 'package:mpjnew/src/core/utils/attachment_compressor.dart';
import 'package:mpjnew/src/data/models/complain_model.dart';
import 'package:mpjnew/src/features/auth/services/user_provider.dart';
import 'package:mpjnew/src/features/customer/services/pesanan_service.dart';
import 'package:mpjnew/src/features/customer/view/history/detail_order_page_V2.dart';
import 'package:mpjnew/src/features/customer/viewmodels/complain_provider.dart';
import 'package:mpjnew/src/features/customer/viewmodels/pesanan_provider.dart';
import 'package:mpjnew/src/features/customer/widget/attachment_preview_strip.dart';
import 'package:mpjnew/src/features/customer/widget/complain_attachment_picker.dart';
import 'package:mpjnew/src/features/customer/widget/complain_avatar.dart';
import 'package:mpjnew/src/features/customer/widget/complain_bubble.dart';
import 'package:mpjnew/src/features/customer/widget/dialog/confirm_dialog.dart';
import 'package:mpjnew/src/features/customer/widget/dialog/custom_snackbar.dart';
import 'package:mpjnew/src/features/customer/widget/linkified_text.dart';
import 'package:mpjnew/src/features/customer/widget/refresh_header.dart';

/// Thread diskusi Complain (StackOverflow-style: judul + daftar pesan flat +
/// input di bawah). Arsitektur fetch-based — tidak ada penyimpanan lokal,
/// state cuma hidup selama halaman ini terbuka.
class ComplainThreadPage extends StatefulWidget {
  /// Data yang sudah tersedia dari cache tombol entry-point — kalau diisi,
  /// halaman langsung tampil instan tanpa round-trip API.
  final ComplainModel? initial;
  final String? noOrder;
  final String? noComplain;

  /// Tombol "Lihat Pesanan" di AppBar -- disembunyikan kalau halaman ini
  /// dibuka DARI detail order (user sudah di situ, jadi shortcut kembali ke
  /// sana tidak diperlukan). Tetap tampil kalau dibuka dari Setting > List
  /// Complain atau dari notifikasi, karena di situ user belum tentu datang
  /// dari halaman order-nya.
  final bool showOrderAction;

  const ComplainThreadPage({
    super.key,
    this.initial,
    this.noOrder,
    this.noComplain,
    this.showOrderAction = true,
  });

  @override
  State<ComplainThreadPage> createState() => _ComplainThreadPageState();
}

class _ComplainThreadPageState extends State<ComplainThreadPage>
    with WidgetsBindingObserver {
  late final RefreshController _refreshController;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<PreparedAttachment> _pendingAttachments = [];
  late final Widget _refreshHeader = buildRefreshHeader();

  bool _openingOrder = false;
  bool _isPreparingAttachments = false;
  String? _vendorPhotoUrl;
  bool _vendorPhotoTried = false;
  bool _headerExpanded = false;
  bool _didInitialScroll = false;
  // Muncul begitu user scroll menjauh dari atas -- tombol pintas untuk
  // balik melihat lagi permasalahan utama di header card (index 0),
  // analog dengan FAB scroll-to-bottom di room_chat_page.dart tapi arah
  // sebaliknya (ke atas, bukan ke pesan terbaru).
  bool _showScrollToHeader = false;
  // Muncul begitu user scroll menjauh dari bawah -- FAB scroll-to-bottom,
  // gaya sama persis dengan yang di room_chat_page.dart.
  bool _showScrollToBottom = false;

  // -1 = belum pernah ada data (initial load ditangani terpisah oleh
  // _scheduleInitialScrollToBottom). Dipakai untuk mendeteksi pesan baru
  // yang masuk lewat provider (drain saat resume, push FCM foreground,
  // atau pull-to-refresh) supaya list auto-scroll ke bawah -- sebelum ini,
  // pesan baru itu memang sudah ada di data tapi tidak kelihatan sampai
  // ada rebuild lain yang kebetulan ikut scroll (mis. kirim pesan sendiri).
  int _lastDetailsCount = -1;

  // Diambil lewat context.read di didChangeDependencies (aman) dan dipakai
  // lagi di dispose() -- memanggil context.read langsung di dispose() bisa
  // crash ("Looking up a deactivated widget's ancestor is unsafe") kalau
  // widget ini dilepas bersamaan dengan leluhurnya.
  ComplainProvider? _complainProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshController = RefreshController(initialRefresh: false);
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    final showHeader = pos.pixels > 300;
    final showBottom = pos.maxScrollExtent - pos.pixels > 300;
    if (showHeader != _showScrollToHeader ||
        showBottom != _showScrollToBottom) {
      setState(() {
        _showScrollToHeader = showHeader;
        _showScrollToBottom = showBottom;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _complainProvider ??= context.read<ComplainProvider>();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<ComplainProvider>().drainPendingComplainRefetch();
    }
  }

  Future<void> _init() async {
    final provider = context.read<ComplainProvider>();
    if (widget.initial != null) {
      provider.setActive(widget.initial!);
    } else {
      await provider.loadActive(
        noOrder: widget.noOrder,
        noComplain: widget.noComplain,
      );
    }
    if (!mounted) return;

    final active = provider.active;
    if (active != null) {
      await ComplainProvider.setActiveComplainPref(active.noComplain);
      // Fire-and-forget: kalau ada pesan yang masuk selagi user di luar app,
      // ini yang memastikan thread langsung ter-refresh begitu dibuka --
      // tanpa perlu pull-to-refresh manual.
      unawaited(provider.drainPendingComplainRefetch());
    }

    // Dijadwalkan sebelum resolve foto vendor (yang bisa kena round-trip
    // API) supaya thread langsung terlihat di posisi bawah tanpa menunggu.
    _scheduleInitialScrollToBottom();

    final noOrder = active?.noOrder ?? widget.noOrder;
    if (noOrder != null && noOrder.isNotEmpty) {
      await _resolveVendorPhoto(noOrder);
    }
  }

  /// Balasan terbaru ada di paling bawah (seperti chat biasa), jadi saat
  /// pertama dibuka, thread harus langsung menampilkan itu -- bukan awal
  /// diskusi. Cuma sekali per buka halaman, tidak setiap rebuild.
  void _scheduleInitialScrollToBottom() {
    if (_didInitialScroll) return;
    _didInitialScroll = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _scrollToBottom({bool animate = false}) {
    if (!_scrollController.hasClients) return;
    final target = _scrollController.position.maxScrollExtent;
    if (animate) {
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(target);
    }
  }

  /// Kebalikan dari _scrollToBottom() -- balik ke header card (index 0)
  /// supaya user bisa lihat lagi permasalahan utama tanpa perlu scroll
  /// manual dari bawah.
  void _scrollToHeader() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  /// Foto vendor tidak ada di payload complain, jadi diambil dari order-nya.
  /// Cache provider dipakai dulu; fetch sekali kalau kosong (kasus masuk
  /// lewat Setting -> Complain tanpa pernah memuat daftar pesanan).
  Future<void> _resolveVendorPhoto(String noOrder) async {
    if (_vendorPhotoTried) return;
    _vendorPhotoTried = true;

    final cached = context.read<PesananProvider>().getPesananByNoOrder(noOrder);
    final cachedUrl = cached?.idMediaVendor;
    if (cachedUrl != null && cachedUrl.isNotEmpty) {
      setState(() => _vendorPhotoUrl = cachedUrl);
      return;
    }

    try {
      final orders = await PesananService().getAll(noBukti: noOrder);
      if (!mounted) return;
      setState(() => _vendorPhotoUrl = orders.firstOrNull?.idMediaVendor);
    } catch (_) {
      // Diamkan — avatar inisial adalah kondisi akhir yang wajar.
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.removeListener(_onScroll);
    // Bukan notifyListeners() jadi aman dipanggil sinkron di sini (beda
    // dengan clearActive() di bawah).
    ComplainProvider.setActiveComplainPref(null);
    // clearActive() memanggil notifyListeners() -- kalau dijalankan sekarang
    // (masih di frame yang sama saat halaman ini dibongkar/pop), Flutter
    // bisa melempar "setState() called when widget tree was locked" karena
    // Consumer<ComplainProvider> lain di layar sebelumnya ikut rebuild
    // synchronous di tengah proses unmount. Tunda ke frame berikutnya.
    final provider = _complainProvider;
    if (provider != null) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => provider.clearActive());
    }
    _messageController.dispose();
    _scrollController.dispose();
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    try {
      await context.read<ComplainProvider>().refreshActive();
      _refreshController.refreshCompleted();
    } catch (_) {
      _refreshController.refreshFailed();
    }
  }

  Future<void> _pickAttachments() async {
    if (_isPreparingAttachments) return;
    setState(() => _isPreparingAttachments = true);
    final result = await pickComplainAttachments(
      currentCount: _pendingAttachments.length,
    );
    if (!mounted) return;
    setState(() {
      _isPreparingAttachments = false;
      _pendingAttachments.addAll(result.accepted);
    });

    final message = attachmentPickMessage(result);
    if (message != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _removeAttachment(int index) {
    setState(() => _pendingAttachments.removeAt(index));
  }

  Future<void> _send() async {
    final text = _messageController.text.trim();
    if (text.isEmpty && _pendingAttachments.isEmpty) return;

    final userProv = context.read<UserProvider>();
    final senderId = userProv.customer?.noId ?? '';
    final provider = context.read<ComplainProvider>();

    final filesToUpload = List<PreparedAttachment>.from(_pendingAttachments);
    _messageController.clear();
    setState(() => _pendingAttachments.clear());

    List<String>? mediaIds;
    if (filesToUpload.isNotEmpty) {
      final result = await provider.uploadAttachments(filesToUpload, senderId);
      if (result.failed.isNotEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal mengunggah lampiran: ${result.failed.join(", ")}',
            ),
          ),
        );
      }
      mediaIds = result.mediaIds.isEmpty ? null : result.mediaIds;
    }

    final ok = await provider.sendReply(
      senderId: senderId,
      tipeUser: Constants.customer,
      message: text,
      idMedia: mediaIds,
    );

    if (!ok && mounted) {
      final err = provider.activeError;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err ?? 'Gagal mengirim pesan')),
      );
    } else if (ok) {
      // Pesan baru masuk di paling bawah -- ikut turunkan biar langsung
      // terlihat, tidak cuma nambah di luar layar.
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _scrollToBottom(animate: true));
    }
  }

  Future<void> _openOrderDetail(String noOrder) async {
    if (_openingOrder) return;
    setState(() => _openingOrder = true);
    try {
      final orders = await PesananService().getAll(noBukti: noOrder);
      if (!mounted) return;
      if (orders.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pesanan tidak ditemukan')),
        );
        return;
      }
      context.read<NavigationProvider>().navigateToPage(
            context,
            DetailOrderPageV2(pesananModel: orders.first),
            targetTabIndex: 2,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal membuka pesanan: $e')));
      }
    } finally {
      if (mounted) setState(() => _openingOrder = false);
    }
  }

  // Sama dengan nomor WA di ComplainMenuAction/HelpFab/SettingPage — kalau
  // masih ada yang mau ditanyakan selagi lihat thread (termasuk yang sudah
  // selesai), user bisa langsung hubungi admin, tanpa pesan default (beda
  // dari HelpFab yang mengirim template pesan).
  static const _adminWaNumber = '62895353837000';

  Future<void> _contactAdmin() async {
    final uri = Uri.parse('https://wa.me/$_adminWaNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _openImage(BuildContext context, String url) {
    Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _FullscreenImageViewer(url: url),
    ));
  }

  void _confirmSelesaikan(BuildContext context) {
    ConfirmDialog.showSelesaikanComplainDialog(
      context: context,
      onConfirm: () => _doSelesaikan(context),
    );
  }

  Future<void> _doSelesaikan(BuildContext context) async {
    final provider = context.read<ComplainProvider>();
    final ok =
        await provider.closeComplain(hasilAkhir: 'Diselesaikan oleh customer');
    if (!context.mounted) return;
    if (ok) {
      CustomSnackbar.showSuccessSnackbar(
          context, 'Complain berhasil diselesaikan.');
    } else {
      CustomSnackbar.showErrorSnackbar(
          context, provider.activeError ?? 'Gagal menyelesaikan complain');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F7),
        floatingActionButton: _showScrollToBottom
            ? Padding(
                padding: const EdgeInsets.only(bottom: 80),
                child: FloatingActionButton.small(
                  backgroundColor: Constants.primaryColor,
                  foregroundColor: Colors.white,
                  tooltip: 'Lihat balasan terbaru',
                  onPressed: () => _scrollToBottom(animate: true),
                  child: const Icon(Icons.keyboard_arrow_down),
                ),
              )
            : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        appBar: AppBar(
          title: Consumer<ComplainProvider>(
            builder: (context, provider, _) {
              final tracking = provider.active?.noTrackingKomplain;
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Complain',
                      style: TextStyle(
                          color: Colors.black, fontWeight: FontWeight.bold)),
                  if (tracking != null && tracking.isNotEmpty)
                    Text(
                      'No. $tracking',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.normal,
                          color: Colors.black54),
                    ),
                ],
              );
            },
          ),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 1,
          actions: [
            Consumer<ComplainProvider>(
              builder: (context, provider, _) {
                if (!widget.showOrderAction) return const SizedBox.shrink();
                final noOrder = provider.active?.noOrder;
                if (noOrder == null) return const SizedBox.shrink();
                return IconButton(
                  tooltip: 'Lihat Pesanan',
                  icon: _openingOrder
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.receipt_long_outlined),
                  onPressed:
                      _openingOrder ? null : () => _openOrderDetail(noOrder),
                );
              },
            ),
            Consumer<ComplainProvider>(
              builder: (context, provider, _) {
                final active = provider.active;

                return PopupMenuButton<String>(
                  color: Colors.white,
                  surfaceTintColor: Colors.transparent,
                  shadowColor: Colors.black26,
                  popUpAnimationStyle: AnimationStyle(
                    duration: const Duration(milliseconds: 150),
                  ),
                  icon: const Icon(Icons.more_vert, color: Colors.black87),
                  onSelected: (value) {
                    if (value == 'selesaikan') _confirmSelesaikan(context);
                    if (value == 'hubungiAdmin') _contactAdmin();
                  },
                  itemBuilder: (context) => [
                    (active == null || active.isClosed)
                        ? const PopupMenuItem(
                            value: 'hubungiAdmin',
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                FaIcon(
                                  FontAwesomeIcons.whatsapp,
                                  color: Color(0xFF25D366),
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Hubungi Admin',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          )
                        : const PopupMenuItem(
                            value: 'selesaikan',
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle_outline,
                                    size: 18, color: Constants.primaryColor),
                                SizedBox(width: 10),
                                Text(
                                  'Selesaikan Complain',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                  ],
                );
              },
            ),
          ],
        ),
        body: Stack(
          alignment: Alignment.topCenter,
          children: [
            Consumer<ComplainProvider>(
              builder: (context, provider, _) {
                final active = provider.active;

                if (active == null && provider.isLoadingActive) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (active == null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        provider.activeError ?? 'Complain tidak ditemukan',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                // Pesan pertama sudah ditampilkan di header card, jadi tidak
                // perlu diulang di list. Urutan kronologis (sudah terurut dari
                // ComplainModel.fromJson) -- balasan terbaru di paling bawah,
                // seperti chat pada umumnya. Halaman dibuka langsung scroll ke
                // situ, lihat _scheduleInitialScrollToBottom().
                final replies = active.details.length > 1
                    ? active.details.sublist(1)
                    : <ComplainMessageModel>[];

                // Pesan baru masuk lewat provider (drain refetch/push FCM/pull-
                // to-refresh) selagi halaman ini terbuka -- ikut turunkan biar
                // langsung terlihat, bukan cuma nambah item yang kescroll di
                // luar layar.
                if (_lastDetailsCount != -1 &&
                    active.details.length > _lastDetailsCount) {
                  WidgetsBinding.instance.addPostFrameCallback(
                      (_) => _scrollToBottom(animate: true));
                }
                _lastDetailsCount = active.details.length;

                final myId = context.watch<UserProvider>().customer?.noId;

                // Satu scrollable untuk seluruh halaman (header + balasan) —
                // dulu header (saat expanded) dan list balasan adalah dua
                // viewport scroll vertikal independen sekaligus. SmartRefresher
                // membungkus SELURUH ListView (header di index 0), jadi
                // pull-to-refresh berlaku dari mana saja termasuk area header di
                // paling atas, bukan cuma dari dalam list balasan seperti
                // sebelumnya.
                return Column(
                  children: [
                    Expanded(
                      child: SmartRefresher(
                        controller: _refreshController,
                        onRefresh: _onRefresh,
                        header: _refreshHeader,
                        // ListView biasa, BUKAN CustomScrollView+slivers -- sudah
                        // terbukti stabil dengan SmartRefresher di halaman room
                        // chat (lihat room_chat_page.dart). CustomScrollView
                        // (dengan SliverFillRemaining atau tidak) tetap membuat
                        // halaman ini tidak bisa discroll lagi setelah refresh
                        // pertama; ListView.builder tidak punya masalah itu.
                        child: ListView.builder(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          // +1 untuk header di index 0. Kalau replies kosong,
                          // index 1 diisi placeholder "Belum ada balasan".
                          itemCount: (replies.isEmpty ? 1 : replies.length) + 1,
                          itemBuilder: (context, i) {
                            if (i == 0) return _buildHeaderCard(active);
                            if (replies.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.only(top: 40, bottom: 200),
                                child: Center(child: Text('Belum ada balasan')),
                              );
                            }
                            final m = replies[i - 1];
                            return ComplainBubble(
                              message: m,
                              vendorPhotoUrl: _vendorPhotoUrl,
                              currentUserId: myId,
                            );
                          },
                        ),
                      ),
                    ),
                    if (active.isClosed)
                      _buildClosedBanner()
                    else ...[
                      AttachmentPreviewStrip(
                        items: _pendingAttachments,
                        onRemove: _removeAttachment,
                        padding:
                            const EdgeInsets.only(right: 16, left: 16, top: 16),
                      ),
                      _buildInputArea(provider),
                    ],
                  ],
                );
              },
            ),
            !_showScrollToHeader
                ? const SizedBox.shrink()
                : Positioned(
                    top: 12,
                    child: GestureDetector(
                      onTap: () => _scrollToHeader(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Constants.primaryColor.withOpacity(0.25)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Lihat Permasalahan Utama",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(Icons.keyboard_arrow_up_rounded,
                                size: 14, color: Colors.black.withOpacity(0.6)),
                          ],
                        ),
                      ),
                    ),
                  )
          ],
        ),
      ),
    );
  }

  /// Baris avatar + nama pengirim + tanggal + chip status — dipakai sama
  /// persis di versi ringkas maupun versi diperluas.
  Widget _buildHeaderTopRow(
    ComplainModel active,
    ComplainMessageModel? firstChat,
  ) {
    final closed = active.isClosed;
    final color = closed ? Colors.green : Colors.orange;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (firstChat != null) ...[
                ComplainAvatar(
                  message: firstChat,
                  vendorPhotoUrl: _vendorPhotoUrl,
                  radius: 14,
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      firstChat?.senderNama ?? 'Customer',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (firstChat != null)
                      Text(
                          "${Helper.formatTanggal(firstChat.tglCreated)} - ${active.noTrackingPesanan}",
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withOpacity(0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    closed
                        ? Icons.check_circle_rounded
                        : Icons.schedule_rounded,
                    size: 12,
                    color: color,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    closed ? 'Selesai' : 'Aktif',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: color),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// True kalau pesan pembuka tidak muat di 3 baris, atau punya lampiran —
  /// keduanya baru terlihat penuh lewat "Lihat selengkapnya".
  bool _headerHasMore(ComplainMessageModel? firstChat) {
    if (firstChat == null) return false;
    if (firstChat.attachments.isNotEmpty) return true;
    final maxWidth =
        MediaQuery.of(context).size.width - 24 - 32; // margin+padding
    final painter = TextPainter(
      text: TextSpan(
          text: firstChat.message, style: const TextStyle(fontSize: 14)),
      maxLines: 3,
      textDirection: ui.TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
    return painter.didExceedMaxLines;
  }

  /// Header complain — sekarang jadi item pertama (index 0) di ListView yang
  /// sama dengan balasan, bukan sibling Column+Expanded terhadap list
  /// balasan seperti dulu. Karena itu tidak perlu lagi dibatasi tinggi
  /// maksimum atau diberi scrollable sendiri saat expanded -- box ini boleh
  /// setinggi apapun, ListView di luar yang menampungnya dengan scroll.
  /// (Dulu ada ConstrainedBox+SingleChildScrollView di sini khusus untuk
  /// mencegah RenderFlex overflow saat header dan list berebut tinggi tetap
  /// yang sama -- mode kegagalan itu tidak mungkin lagi terjadi di sini.)
  Widget _buildHeaderCard(ComplainModel active) {
    final closed = active.isClosed;
    final firstChat = active.details.firstOrNull;
    final hasMore = _headerHasMore(firstChat);

    return GestureDetector(
      onTap: (!_headerExpanded && hasMore)
          ? () => setState(() => _headerExpanded = true)
          : null,
      child: AnimatedSize(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        alignment: Alignment.topCenter,
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
            ],
          ),
          child: _buildHeaderBody(active, firstChat, hasMore, closed),
        ),
      ),
    );
  }

  Widget _buildHeaderBody(
    ComplainModel active,
    ComplainMessageModel? firstChat,
    bool hasMore,
    bool closed,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeaderTopRow(active, firstChat),
        const SizedBox(height: 12),
        Text(
          active.judul.isEmpty ? 'Complain' : active.judul,
          maxLines: _headerExpanded ? null : 1,
          overflow:
              _headerExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 12),
        if (firstChat != null)
          LinkifiedText(
            text: firstChat.message,
            maxLines: _headerExpanded ? null : 3,
            overflow:
                _headerExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14),
          ),
        if (_headerExpanded &&
            firstChat != null &&
            firstChat.attachments.isNotEmpty) ...[
          const SizedBox(height: 8),
          _AttachmentCarousel(
            attachments: firstChat.attachments,
            onTapImage: (url) => _openImage(context, url),
          ),
        ],
        if (_headerExpanded && closed && active.tglClosed != null) ...[
          const SizedBox(height: 6),
          Text(
            'Ditutup pada ${DateFormat('dd MMM yyyy, HH:mm').format(active.tglClosed!.toLocal())}',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
        if (hasMore || _headerExpanded) ...[
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => setState(() => _headerExpanded = !_headerExpanded),
            child: Text(
              _headerExpanded ? 'Lihat lebih sedikit' : 'Lihat selengkapnya',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Constants.primaryColor,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildClosedBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline_rounded,
              size: 18, color: Colors.grey.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Complain ini sudah ditutup',
              style: TextStyle(
                  color: Colors.grey.shade700, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(ComplainProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          IconButton(
            icon: _isPreparingAttachments
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation(Constants.primaryColor),
                    ),
                  )
                : const Icon(Icons.image_outlined,
                    color: Constants.primaryColor),
            onPressed: provider.isSending || _isPreparingAttachments
                ? null
                : _pickAttachments,
          ),
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 120),
              child: TextField(
                controller: _messageController,
                keyboardType: TextInputType.multiline,
                maxLines: null,
                cursorColor: Constants.primaryColor,
                decoration: InputDecoration(
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  hintText: 'Tulis pesan...',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ),
          const SizedBox(width: 4),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: (_messageController.text.trim().isEmpty &&
                    _pendingAttachments.isEmpty)
                ? const SizedBox.shrink()
                : IconButton(
                    icon: provider.isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(
                                  Constants.primaryColor),
                            ),
                          )
                        : const Icon(Icons.send, color: Constants.primaryColor),
                    onPressed: provider.isSending ? null : _send,
                  ),
          ),
        ],
      ),
    );
  }
}

/// Galeri lampiran header complain — slidable (bukan tumpukan baris),
/// dengan dot indicator saat lampiran lebih dari satu.
class _AttachmentCarousel extends StatefulWidget {
  const _AttachmentCarousel({
    required this.attachments,
    required this.onTapImage,
  });

  final List<ComplainAttachmentModel> attachments;
  final void Function(String url) onTapImage;

  @override
  State<_AttachmentCarousel> createState() => _AttachmentCarouselState();
}

class _AttachmentCarouselState extends State<_AttachmentCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final attachments = widget.attachments;
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            height: 200,
            child: PageView.builder(
              controller: _pageController,
              itemCount: attachments.length,
              onPageChanged: (i) => setState(() => _currentPage = i),
              itemBuilder: (context, i) {
                final attachment = attachments[i];
                return GestureDetector(
                  onTap: () => widget.onTapImage(attachment.url),
                  child: CachedNetworkImage(
                    imageUrl: attachment.url,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => _placeholder(loading: true),
                    errorWidget: (_, __, ___) => _placeholder(broken: true),
                  ),
                );
              },
            ),
          ),
        ),
        if (attachments.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(attachments.length, (i) {
              final active = i == _currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 16 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: active ? Constants.primaryColor : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }

  Widget _placeholder({bool loading = false, bool broken = false}) {
    return Container(
      color: Colors.grey.shade200,
      child: Center(
        child: broken
            ? Icon(Icons.broken_image_outlined, color: Colors.grey.shade400)
            : const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
      ),
    );
  }
}

class _FullscreenImageViewer extends StatelessWidget {
  final String url;
  const _FullscreenImageViewer({required this.url});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Center(
          child: InteractiveViewer(
            child: CachedNetworkImage(imageUrl: url, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}
