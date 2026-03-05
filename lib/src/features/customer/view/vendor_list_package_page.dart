import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/routing/navigation_provider.dart';
import 'package:mpjnew/src/core/utils/shimmer_placeholder.dart';
import 'package:mpjnew/src/data/hive_entity/paket_model.dart';
import 'package:mpjnew/src/data/models/ulasan_model.dart';
import 'package:mpjnew/src/data/models/vendor_model.dart';
import 'package:mpjnew/src/features/auth/services/user_provider.dart';
import 'package:mpjnew/src/features/customer/services/ulasan_service.dart';
import 'package:mpjnew/src/features/customer/view/chat/room_chat_page.dart';
import 'package:mpjnew/src/features/customer/viewmodels/room_chat_provider.dart';
import 'package:mpjnew/src/features/customer/widget/offer_card.dart';
import 'package:mpjnew/src/features/customer/services/paket_service.dart';
import 'package:provider/provider.dart';

class VendorListPackagePage extends StatefulWidget {
  final VendorModel vendor;

  const VendorListPackagePage({super.key, required this.vendor});

  @override
  State<VendorListPackagePage> createState() => _VendorListPackagePageState();
}

class _VendorListPackagePageState extends State<VendorListPackagePage> {
  final UlasanService _ulasanService = UlasanService();

  bool isLoading = true;
  bool _isLoadingUlasan = false;
  String? errorMessage;
  List<PaketModel> paketList = [];
  Map<String, List<UlasanModel>> _ulasanByPaket = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchData());
  }

  Future<void> _loadUlasan() async {
    if (!mounted) return;
    setState(() => _isLoadingUlasan = true);

    try {
      final allUlasan = await _ulasanService.getAll(
        idVendor: widget.vendor.noId,
        status: 'aktif',
        orderBy: 'Tgl_Ulasan',
        orderDir: 'DESC',
      );
      if (!mounted) return;

      final Map<String, List<UlasanModel>> ulasanByPaket = {};
      for (var ulasan in allUlasan) {
        if (ulasan.idPaket != null && ulasan.idPaket.isNotEmpty) {
          for (var paketId in ulasan.idPaket.split(',')) {
            final id = paketId.trim();
            if (id.isNotEmpty) {
              ulasanByPaket.putIfAbsent(id, () => []).add(ulasan);
            }
          }
        }
      }

      if (!mounted) return;
      setState(() => _ulasanByPaket = ulasanByPaket);
    } catch (e) {
      debugPrint('[VendorListPackage] ❌ Error loading ulasan: $e');
    } finally {
      if (mounted) setState(() => _isLoadingUlasan = false);
    }
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final data = await PaketService().getAll(
        idVendor: widget.vendor.noId,
        status: 'aktif',
        orderBy: 'tgl_created',
        orderDir: 'desc',
      );
      if (!mounted) return;
      setState(() => paketList = data);
      await _loadUlasan();
    } catch (e) {
      if (!mounted) return;
      setState(() => errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _sendPaket(PaketModel paket) async {
    final userProvider = context.read<UserProvider>();
    if (userProvider.userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan login terlebih dahulu'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => isLoading = true);
    try {
      final roomChatProvider = context.read<RoomChatProvider>();
      roomChatProvider.setTawaranPaket(paket);
      roomChatProvider.activeRoomId = null;
      roomChatProvider.vendorId = paket.id_vendor;
      await roomChatProvider.sendMessage(currentUserId: userProvider.userId!);

      if (!mounted) return;
      setState(() => isLoading = false);
      Navigator.pop(context);

      if (!mounted) return;
      context.read<NavigationProvider>().navigateToPage(
            context,
            RoomChatPage(partnerId: paket.id_vendor),
            targetTabIndex: 1,
          );
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengirim pesan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: CustomScrollView(
        slivers: [
          // ── Sliver AppBar — info vendor ringkas ───────────
          _buildSliverAppBar(),

          // ── Konten paket ──────────────────────────────────
          if (isLoading)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, __) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ShimmerPlaceholder(height: 150, radius: 12),
                  ),
                  childCount: 4,
                ),
              ),
            )
          else if (errorMessage != null)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildErrorState(),
            )
          else if (paketList.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmptyState(),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(0, 20, 0, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final paket = paketList[index];
                    final ulasanList = _ulasanByPaket[paket.no_id] ?? [];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: OfferCard(
                        paket: paket,
                        vendorId: widget.vendor.noId,
                        ulasanList: ulasanList,
                        onSend: () => _sendPaket(paket),
                      ),
                    );
                  },
                  childCount: paketList.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Sliver AppBar ─────────────────────────────────────────────
  // Info vendor ringkas: foto kecil + nama + kota + tombol chat.
  // Tidak ada duplikasi nama/foto karena collapsed & expanded
  // menampilkan hal yang sama dalam proporsi berbeda.
  Widget _buildSliverAppBar() {
    final vendor = widget.vendor;

    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFF1A1A2E),
      leading: GestureDetector(
        onTap: () => Navigator.of(context).maybePop(),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
        ),
      ),
      // Collapsed: judul halaman saja
      title: const Text(
        'Pilihan Paket',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      actions: [
        // Tombol chat di AppBar — selalu visible
        GestureDetector(
          onTap: () {
            context.read<NavigationProvider>().popAllToRoot();
            context.read<NavigationProvider>().navigateToPage(
                  context,
                  RoomChatPage(
                    roomId: null,
                    partnerId: vendor.noId,
                    partnerUsername: vendor.username,
                    partnerAvatarUrl: vendor.idMedia,
                  ),
                  targetTabIndex: 1,
                );
          },
          child: Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chat_outlined,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: EdgeInsets.zero,
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Background foto profil vendor
            vendor.idMedia.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: vendor.idMedia,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        Container(color: const Color(0xFF1A1A2E)),
                    errorWidget: (_, __, ___) =>
                        Container(color: const Color(0xFF1A1A2E)),
                  )
                : Container(color: const Color(0xFF1A1A2E)),

            // Gradient overlay
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.2),
                    Colors.black.withOpacity(0.75),
                  ],
                ),
              ),
            ),

            // Info vendor di bagian bawah expanded
            Positioned(
              bottom: 16,
              left: 20,
              right: 20,
              child: Row(
                children: [
                  // Avatar
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: const Color(0xFF2A2A3E),
                      child: vendor.idMedia.isNotEmpty
                          ? ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: vendor.idMedia,
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => const Icon(
                                  Icons.person,
                                  size: 24,
                                  color: Colors.white54,
                                ),
                              ),
                            )
                          : const Icon(Icons.person,
                              size: 24, color: Colors.white54),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          vendor.namaDisplay,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(color: Colors.black54, blurRadius: 6),
                            ],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (vendor.namaKota.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const Icon(Icons.location_on_rounded,
                                  color: Colors.white70, size: 12),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  vendor.namaKota,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (vendor.rating > 0) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded,
                                  color: Colors.amber, size: 14),
                              const SizedBox(width: 3),
                              Text(
                                vendor.rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Error State ───────────────────────────────────────────────
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 56, color: Colors.red.shade300),
            const SizedBox(height: 16),
            const Text(
              'Gagal memuat paket',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage!,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _fetchData,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Constants.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Empty State ───────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined,
                size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'Belum ada paket tersedia',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
