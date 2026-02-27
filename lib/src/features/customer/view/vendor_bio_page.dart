import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/routing/navigation_provider.dart';
import 'package:mpjnew/src/core/utils/shimmer_placeholder.dart';
import 'package:mpjnew/src/data/hive_entity/media_url_model.dart';
import 'package:mpjnew/src/data/hive_entity/portofolio_model.dart';
import 'package:mpjnew/src/data/models/vendor_model.dart';
import 'package:mpjnew/src/features/customer/view/chat/room_chat_page.dart';
import 'package:mpjnew/src/features/customer/view/single_post_page.dart';
import 'package:mpjnew/src/features/customer/view/vendor_list_package_page.dart';
import 'package:mpjnew/src/features/customer/viewmodels/portofolio_provider.dart';
import 'package:mpjnew/src/features/customer/widget/shimmer/vendor_bio_shimmer.dart';
import 'package:mpjnew/src/features/customer/services/portofolio_service.dart';
import 'package:mpjnew/src/features/customer/services/vendor_service.dart';
import 'package:provider/provider.dart';

class VendorBioPage extends StatefulWidget {
  final String idVendor;

  const VendorBioPage({super.key, required this.idVendor});

  @override
  State<VendorBioPage> createState() => _VendorBioPageState();
}

class _VendorBioPageState extends State<VendorBioPage> {
  bool isLoadingVendor = true;
  bool isLoadingPorto = true;

  final String _notFoundUsername = 'vendor-not-found';

  late VendorModel vendor;
  List<PortofolioModel> portofolioList = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fetchData();
    });
  }

  Future<void> _fetchData() async {
    setState(() {
      isLoadingVendor = true;
      isLoadingPorto = true;
    });

    try {
      final result =
          await VendorService().getAll(no_id: widget.idVendor, status: 'aktif');
      vendor = result.isNotEmpty ? result.first : _buildNotFoundVendor();
    } catch (_) {
      vendor = _buildNotFoundVendor();
    }
    if (!mounted) return;
    setState(() => isLoadingVendor = false);

    if (vendor.username != _notFoundUsername) {
      try {
        portofolioList = await PortofolioService().getAll(
          idVendor: widget.idVendor,
          status: 'aktif',
          orderBy: 'tgl_created',
          orderDir: 'desc',
        );
      } catch (_) {
        portofolioList = [];
      }
    }
    if (!mounted) return;
    setState(() => isLoadingPorto = false);
  }

  VendorModel _buildNotFoundVendor() => VendorModel(
        noId: widget.idVendor,
        username: _notFoundUsername,
        namaDisplay: 'Vendor Tidak Ditemukan',
        email: '',
        kota: '-',
        rating: 0,
        portofolio: [],
        paket: [],
        hargaMinPaket: 0,
        hargaMaxPaket: 0,
        tglCreated: DateTime(2000),
        idMedia: '',
        deskripsiBio: '',
        namaKota: '',
      );

  @override
  Widget build(BuildContext context) {
    if (isLoadingVendor) {
      return const Scaffold(
        backgroundColor: const Color(0xFFF9F9F9),
        body: VendorBioShimmer(),
      );
    }

    final bool vendorFound = vendor.username != _notFoundUsername;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: CustomScrollView(
        slivers: [
          // ── 1. SLIVER APP BAR ─────────────────────────────
          // Hanya foto background + avatar + nama + kota.
          // Tidak ada duplikasi — ini satu-satunya tempat nama & foto tampil.
          _buildSliverAppBar(context),

          // ── 2. INFO SECTION ───────────────────────────────
          // Rating, deskripsi, dan tombol aksi.
          // Menggantikan VendorBioCard sepenuhnya.
          SliverToBoxAdapter(
            child: _buildInfoSection(context, vendorFound),
          ),

          // ── 3. HEADER PORTOFOLIO ──────────────────────────
          if (!isLoadingPorto && portofolioList.isNotEmpty)
            SliverToBoxAdapter(
              child: _buildPortofolioHeader(context),
            ),

          // ── 4a. SHIMMER GRID ──────────────────────────────
          if (isLoadingPorto)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (_, __) => const ShimmerPlaceholder(radius: 12),
                  childCount: 6,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
              ),
            )

          // ── 4b. PORTO GRID ────────────────────────────────
          else if (portofolioList.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _VendorPortoGridItem(porto: portofolioList[i]),
                  childCount: portofolioList.length,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
              ),
            )

          // ── 4c. EMPTY STATE ───────────────────────────────
          else
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmptyPorto(),
            ),
        ],
      ),
    );
  }

  // ─── SliverAppBar ─────────────────────────────────────────────
  // Foto profil sebagai background, avatar + nama + kota di expanded.
  // Saat collapsed: hanya judul teks di AppBar, TIDAK ada avatar lagi.
  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFFF9F9F9),
      // Back button
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
      flexibleSpace: FlexibleSpaceBar(
        // Collapsed title: hanya nama, tidak ada avatar
        titlePadding: const EdgeInsets.fromLTRB(56, 0, 16, 14),

        // Expanded background: foto profil + overlay + avatar besar + teks
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Foto profil sebagai background blur-cover
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

            // Gradient gelap agar teks terbaca
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.1),
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),

            // Avatar + nama + kota di bagian bawah expanded
            Positioned(
              bottom: 44,
              left: 20,
              right: 20,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Avatar — satu-satunya tempat foto tampil
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 32,
                      backgroundColor: const Color(0xFFF9F9F9),
                      child: vendor.idMedia.isNotEmpty
                          ? ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: vendor.idMedia,
                                width: 64,
                                height: 64,
                                fit: BoxFit.cover,
                                placeholder: (_, __) =>
                                    const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white54,
                                ),
                                errorWidget: (_, __, ___) => const Icon(
                                  Icons.person,
                                  size: 32,
                                  color: Colors.white54,
                                ),
                              ),
                            )
                          : const Icon(Icons.person,
                              size: 32, color: Colors.white54),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Nama + kota — satu-satunya tempat nama tampil di header
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vendor.namaDisplay,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(color: Colors.black54, blurRadius: 6),
                            ],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (vendor.namaKota.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on_rounded,
                                  color: Colors.white70, size: 13),
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

  // ─── Info Section ──────────────────────────────────────────────
  // Rating, deskripsi bio, tombol "Lihat Paket" + "Chat".
  // Menggantikan VendorBioCard — tidak ada duplikasi foto/nama di sini.
  Widget _buildInfoSection(BuildContext context, bool vendorFound) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rating row
          if (vendor.rating > 0) ...[
            Row(
              children: [
                const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                const SizedBox(width: 4),
                Text(
                  vendor.rating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Rating',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
          ],

          // Deskripsi bio
          if (vendor.deskripsiBio.isNotEmpty) ...[
            Text(
              vendor.deskripsiBio,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Tombol aksi — hanya tampil jika vendor ditemukan
          if (vendorFound)
            Row(
              children: [
                // Lihat Paket
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Constants.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                VendorListPackagePage(vendor: vendor),
                          ),
                        );
                      },
                      icon: const Icon(Icons.list_alt_rounded, size: 18),
                      label: const Text(
                        'Lihat Paket',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Chat
                SizedBox(
                  height: 44,
                  width: 44,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                          color: Constants.primaryColor, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    onPressed: () {
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
                    child: const Icon(
                      Icons.chat_outlined,
                      color: Constants.primaryColor,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // ─── Header Portofolio ─────────────────────────────────────────
  Widget _buildPortofolioHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: Constants.primaryColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'Portofolio',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A2E),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Constants.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${portofolioList.length}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Constants.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Empty State ───────────────────────────────────────────────
  Widget _buildEmptyPorto() {
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Column(
        children: [
          Icon(Icons.photo_library_outlined,
              size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            'Belum ada portofolio',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Grid Item Portofolio
// ═══════════════════════════════════════════════════════════════

class _VendorPortoGridItem extends StatelessWidget {
  final PortofolioModel porto;

  const _VendorPortoGridItem({required this.porto});

  @override
  Widget build(BuildContext context) {
    final firstMedia =
        porto.mediaUrls.isNotEmpty ? porto.mediaUrls.first : null;
    final isVideo = (firstMedia?.contentType ?? '').startsWith('video');
    final hasMultiple = porto.mediaUrls.length > 1;

    return GestureDetector(
      onTap: () {
        context.read<PortofolioProvider>().setSelectedPortofolio(porto);
        context.read<NavigationProvider>().navigateToPage(
              hrsLogin: true,
              context,
              const SinglePostPage(),
              targetTabIndex: 0,
              targetPage: 'SinglePostPage',
            );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            firstMedia != null
                ? _BioMediaImage(media: firstMedia)
                : _placeholder(),

            // Gradient bawah
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.4),
                    ],
                    stops: const [0.55, 1.0],
                  ),
                ),
              ),
            ),

            // Badge video
            if (isVideo)
              const Positioned(
                bottom: 8,
                left: 8,
                child: Icon(Icons.play_circle_fill_rounded,
                    color: Colors.white, size: 24),
              ),

            // Badge jumlah media
            if (hasMultiple)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.collections_rounded,
                          color: Colors.white, size: 13),
                      const SizedBox(width: 3),
                      Text(
                        '${porto.mediaUrls.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        color: Colors.grey.shade200,
        child: Icon(Icons.image_not_supported_outlined,
            color: Colors.grey.shade400),
      );
}

// ═══════════════════════════════════════════════════════════════
// Media Image Loader
// ═══════════════════════════════════════════════════════════════

class _BioMediaImage extends StatelessWidget {
  final MediaUrlModel media;

  const _BioMediaImage({required this.media});

  @override
  Widget build(BuildContext context) {
    if (media.isCached && media.localPath != null) {
      final file = File(media.localPath!);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _networkImage(),
        );
      }
    }
    return _networkImage();
  }

  Widget _networkImage() {
    final isVideo = media.contentType?.startsWith('video') ?? false;
    final url = isVideo ? (media.thumbUrl ?? media.url) : media.url;
    final effectiveUrl = (url != null && url.trim().isNotEmpty)
        ? url
        : media.thumbUrl ?? media.idMedia;

    if (effectiveUrl == null || effectiveUrl.trim().isEmpty) {
      return _errorWidget();
    }

    return CachedNetworkImage(
      imageUrl: effectiveUrl,
      fit: BoxFit.cover,
      placeholder: (_, __) => const ShimmerPlaceholder(radius: 12),
      errorWidget: (_, __, ___) => _errorWidget(),
      fadeInDuration: const Duration(milliseconds: 250),
    );
  }

  Widget _errorWidget() => Container(
        color: Colors.grey.shade200,
        child: Icon(Icons.broken_image_outlined, color: Colors.grey.shade400),
      );
}
