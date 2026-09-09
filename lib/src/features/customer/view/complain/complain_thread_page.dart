import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mpjnew/src/core/constants/helper.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
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

class _ComplainThreadPageState extends State<ComplainThreadPage> {
  late final RefreshController _refreshController;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<PreparedAttachment> _pendingAttachments = [];
  bool _openingOrder = false;
  bool _isPreparingAttachments = false;
  String? _vendorPhotoUrl;
  bool _vendorPhotoTried = false;
  bool _headerExpanded = false;
  bool _didInitialScroll = false;

  // Diambil lewat context.read di didChangeDependencies (aman) dan dipakai
  // lagi di dispose() -- memanggil context.read langsung di dispose() bisa
  // crash ("Looking up a deactivated widget's ancestor is unsafe") kalau
  // widget ini dilepas bersamaan dengan leluhurnya.
  ComplainProvider? _complainProvider;

  @override
  void initState() {
    super.initState();
    _refreshController = RefreshController(initialRefresh: false);
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _complainProvider ??= context.read<ComplainProvider>();
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
    // Dijadwalkan sebelum resolve foto vendor (yang bisa kena round-trip
    // API) supaya thread langsung terlihat di posisi bawah tanpa menunggu.
    _scheduleInitialScrollToBottom();

    final noOrder = provider.active?.noOrder ?? widget.noOrder;
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
    await context.read<ComplainProvider>().refreshActive();
    _refreshController.refreshCompleted();
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

  void _openImage(BuildContext context, String url) {
    Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _FullscreenImageViewer(url: url),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: const Text('Complain',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
        ],
      ),
      body: SafeArea(
        child: Consumer<ComplainProvider>(
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

            final myId = context.watch<UserProvider>().customer?.noId;

            return Stack(
              children: [
                Column(
                  children: [
                    _buildCollapsedHeaderCard(active),
                    Expanded(
                      child: SmartRefresher(
                        controller: _refreshController,
                        onRefresh: _onRefresh,
                        header: buildRefreshHeader(),
                        child: replies.isEmpty
                            ? ListView(
                                children: const [
                                  SizedBox(height: 80),
                                  Center(child: Text('Belum ada balasan')),
                                ],
                              )
                            : ListView.builder(
                                controller: _scrollController,
                                padding:
                                    const EdgeInsets.only(top: 8, bottom: 8),
                                itemCount: replies.length,
                                itemBuilder: (context, i) {
                                  final m = replies[i];
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
                ),
                // Header lengkap tampil sebagai overlay yang menimpa thread
                // (bukan mendorong layout) supaya posisi list tidak berubah.
                if (_headerExpanded) ...[
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: () => setState(() => _headerExpanded = false),
                      child: Container(color: Colors.black.withOpacity(0.35)),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: _buildExpandedHeaderOverlay(active),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  /// Baris avatar + nama pengirim + tanggal + chip status — dipakai sama
  /// persis di versi ringkas maupun overlay lengkap. [onClose] hanya diisi
  /// di versi overlay (tombol untuk menutupnya).
  Widget _buildHeaderTopRow(
    ComplainModel active,
    ComplainMessageModel? firstChat, {
    VoidCallback? onClose,
  }) {
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
            if (onClose != null)
              InkWell(
                onTap: onClose,
                borderRadius: BorderRadius.circular(16),
                child: const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child:
                      Icon(Icons.close_rounded, size: 20, color: Colors.grey),
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

  /// Versi ringkas — selalu tampil di atas thread, maksimal 3 baris pesan.
  Widget _buildCollapsedHeaderCard(ComplainModel active) {
    final firstChat = active.details.firstOrNull;
    final hasMore = _headerHasMore(firstChat);

    return GestureDetector(
      onTap: hasMore ? () => setState(() => _headerExpanded = true) : null,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderTopRow(active, firstChat),
            const SizedBox(height: 12),
            Text(
              active.judul.isEmpty ? 'Complain' : active.judul,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 12),
            if (firstChat != null)
              Text(
                firstChat.message,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14),
              ),
            if (hasMore) ...[
              const SizedBox(height: 6),
              Text(
                'Lihat selengkapnya',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Constants.primaryColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Versi lengkap — tampil sebagai overlay yang menimpa thread (lihat
  /// build()), bisa discroll sendiri kalau isinya panjang (teks + lampiran),
  /// dan tidak memindahkan posisi scroll daftar balasan di baliknya.
  Widget _buildExpandedHeaderOverlay(ComplainModel active) {
    final closed = active.isClosed;
    final firstChat = active.details.firstOrNull;
    final maxHeight = MediaQuery.of(context).size.height * 0.7;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Material(
        elevation: 12,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderTopRow(
                  active,
                  firstChat,
                  onClose: () => setState(() => _headerExpanded = false),
                ),
                const SizedBox(height: 12),
                Text(
                  active.judul.isEmpty ? 'Complain' : active.judul,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 12),
                if (firstChat != null) ...[
                  Text(
                    firstChat.message,
                    style: const TextStyle(fontSize: 14),
                  ),
                  if (firstChat.attachments.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    // Gambar pertama tampil besar sebagai bukti utama.
                    GestureDetector(
                      onTap: () =>
                          _openImage(context, firstChat.attachments.first.url),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: CachedNetworkImage(
                          imageUrl: firstChat.attachments.first.url,
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => _mediaBox(loading: true),
                          errorWidget: (_, __, ___) => _mediaBox(broken: true),
                        ),
                      ),
                    ),
                    // Sisanya sebagai thumbnail — sama seperti ComplainBubble.
                    if (firstChat.attachments.length > 1) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            firstChat.attachments.skip(1).map((attachment) {
                          return GestureDetector(
                            onTap: () => _openImage(context, attachment.url),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: CachedNetworkImage(
                                imageUrl: attachment.url,
                                width: 84,
                                height: 84,
                                fit: BoxFit.cover,
                                placeholder: (_, __) =>
                                    _mediaBox(loading: true),
                                errorWidget: (_, __, ___) =>
                                    _mediaBox(broken: true),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ],
                if (closed && active.tglClosed != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Ditutup pada ${DateFormat('dd MMM yyyy, HH:mm').format(active.tglClosed!.toLocal())}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
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

  Widget _mediaBox({bool loading = false, bool broken = false}) {
    return Container(
      width: 84,
      height: 84,
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

class _FullscreenImageViewer extends StatelessWidget {
  final String url;
  const _FullscreenImageViewer({required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
    );
  }
}
