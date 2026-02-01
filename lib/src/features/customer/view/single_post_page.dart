import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/routing/navigation_provider.dart';
import 'package:mpjnew/src/data/hive_entity/paket_model.dart';
import 'package:mpjnew/src/data/models/portofolio_model.dart';
import 'package:mpjnew/src/data/models/ulasan_model.dart';
import 'package:mpjnew/src/features/auth/services/user_provider.dart';
import 'package:mpjnew/src/features/customer/services/ulasan_service.dart';
import 'package:mpjnew/src/features/customer/view/chat/room_chat_page.dart';
import 'package:mpjnew/src/features/customer/viewmodels/room_chat_provider.dart';
import 'package:mpjnew/src/features/customer/widget/image_post.dart';
import 'package:mpjnew/src/features/customer/widget/offer_card.dart';
import 'package:mpjnew/src/features/customer/widget/post_header.dart';
import 'package:mpjnew/src/features/customer/services/paket_service.dart';
import 'package:mpjnew/src/features/customer/services/portofolio_service.dart';
import 'package:provider/provider.dart';

class SinglePostPage extends StatefulWidget {
  final String noId;
  final String? idVendor;

  const SinglePostPage({super.key, required this.noId, this.idVendor});

  @override
  State<SinglePostPage> createState() => _SinglePostPageState();
}

class _SinglePostPageState extends State<SinglePostPage> {
  final UlasanService _ulasanService = UlasanService();
  final ScrollController _scrollController = ScrollController();

  bool isLiked = false;
  bool isSaved = false;
  int likeCount = 0;

  PortofolioModel? portofolio;
  List<PaketModel> paketList = [];
  Map<String, List<UlasanModel>> _ulasanByPaket = {};

  bool isLoading = false;
  bool isLoadingPaket = false;
  bool _isLoadingUlasan = false;
  String? error;
  String? errorPaket;

  /// ✅ Safe setState wrapper
  void _safeSetState(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }

  Future<void> _fetchData() async {
    if (!mounted) return;

    _safeSetState(() {
      isLoading = true;
      error = null;
      paketList.clear();
      errorPaket = null;
    });

    try {
      debugPrint("📍 [SinglePost] Fetching portfolio: ${widget.noId}");
      debugPrint("📍 [SinglePost] Vendor ID: ${widget.idVendor}");

      final portofolioDataList = await PortofolioService().getAll(
        noId: widget.noId,
        idVendor: widget.idVendor,
        status: "aktif",
      );

      if (!mounted) return;

      if (portofolioDataList.isEmpty) {
        _safeSetState(() {
          error = "Portofolio tidak ditemukan.";
          isLoading = false;
        });
        return;
      }

      portofolio = portofolioDataList.first;

      // ✅ Check user provider safely
      final userProvider = context.read<UserProvider>();
      final customer = userProvider.customer;

      if (customer != null) {
        _safeSetState(() {
          isLiked = customer.likes.contains(widget.noId);
          isSaved = customer.saves.contains(widget.noId);
          likeCount = portofolio!.likes;
        });
      }

      final List<String> idPaketList = List<String>.from(portofolio!.idPaket);

      if (idPaketList.isNotEmpty) {
        _safeSetState(() {
          isLoadingPaket = true;
        });

        try {
          final paketData = await PaketService().getAll(
            idList: idPaketList,
            status: "aktif",
          );

          if (!mounted) return;

          _safeSetState(() {
            paketList = paketData;
            isLoadingPaket = false;
          });

          // Load ulasan after paket loaded
          await _loadUlasan();
        } catch (e) {
          debugPrint("❌ [SinglePost] Error loading paket: $e");

          if (!mounted) return;

          _safeSetState(() {
            errorPaket = "Gagal memuat paket: $e";
            isLoadingPaket = false;
          });
        }
      }
    } catch (e) {
      debugPrint("❌ [SinglePost] Error: $e");

      if (!mounted) return;

      _safeSetState(() {
        error = "Terjadi kesalahan saat memuat data. $e";
      });
    } finally {
      if (mounted) {
        _safeSetState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _loadUlasan() async {
    if (!mounted) return;

    _safeSetState(() {
      _isLoadingUlasan = true;
    });

    try {
      final allUlasan = await _ulasanService.getAll(
        idVendor: widget.idVendor,
        status: 'aktif',
        orderBy: 'Tgl_Ulasan',
        orderDir: 'DESC',
      );

      if (!mounted) return;

      debugPrint('[SinglePost] ✅ Loaded ${allUlasan.length} total ulasan');

      // Kelompokkan ulasan berdasarkan paket
      final Map<String, List<UlasanModel>> ulasanByPaket = {};

      for (var ulasan in allUlasan) {
        if (ulasan.idPaket != null && ulasan.idPaket.isNotEmpty) {
          final paketIds = ulasan.idPaket.split(',');

          for (var paketId in paketIds) {
            final trimmedId = paketId.trim();

            if (trimmedId.isNotEmpty) {
              if (!ulasanByPaket.containsKey(trimmedId)) {
                ulasanByPaket[trimmedId] = [];
              }

              ulasanByPaket[trimmedId]!.add(ulasan);
            }
          }
        }
      }

      // Debug summary
      debugPrint('[SinglePost] 📊 Ulasan grouped by paket:');
      ulasanByPaket.forEach((paketId, ulasanList) {
        debugPrint(
            '[SinglePost]   📦 Paket $paketId: ${ulasanList.length} ulasan');
      });

      if (!mounted) return;

      _safeSetState(() {
        _ulasanByPaket = ulasanByPaket;
        _isLoadingUlasan = false;
      });

      debugPrint('[SinglePost] ✅ Ulasan state updated successfully');
    } catch (e, stackTrace) {
      debugPrint('[SinglePost] ❌ Error loading ulasan: $e');
      debugPrint('[SinglePost] Stack trace: $stackTrace');

      if (!mounted) return;

      _safeSetState(() {
        _isLoadingUlasan = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fetchData();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F9F9),
        elevation: 1,
        title: const Text(
          "Portofolio",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(error!),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _fetchData,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                )
              : portofolio == null
                  ? const Center(child: Text('Data tidak ditemukan'))
                  : RefreshIndicator(
                      onRefresh: _fetchData,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        controller: _scrollController,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            PostHeader(portofolio: portofolio!),
                            ImagePost(mediaUrl: portofolio!.mediaUrls),
                            _buildLikeSaveRow(),
                            if (isLoadingPaket)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(32),
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            else if (errorPaket != null)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.red.shade200,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.error_outline,
                                          color: Colors.red.shade700),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          errorPaket!,
                                          style: TextStyle(
                                            color: Colors.red.shade900,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else if (paketList.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(32),
                                child: Center(
                                  child: Text(
                                    "Belum ada paket tersedia",
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                              )
                            else
                              ...paketList.map((paket) {
                                final ulasanList =
                                    _ulasanByPaket[paket.no_id] ?? [];
                                return OfferCard(
                                  vendorId: portofolio!.idVendor,
                                  paket: paket,
                                  ulasanList: ulasanList,
                                  onSend: () => _handleSendOffer(paket),
                                );
                              }),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
      floatingActionButton: (!isLoading && portofolio != null)
          ? FloatingActionButton(
              onPressed: _fetchData,
              backgroundColor: Constants.primaryColor,
              child: const Icon(Icons.refresh, color: Colors.white),
              tooltip: 'Refresh Paket',
            )
          : null,
    );
  }

  /// Handle send offer action
  Future<void> _handleSendOffer(PaketModel paket) async {
    if (!mounted) return;

    _safeSetState(() {
      isLoading = true;
    });

    try {
      final userId = context.read<UserProvider>().userId;

      if (userId == null) {
        throw Exception('User not logged in');
      }

      final roomChatProvider = context.read<RoomChatProvider>();

      roomChatProvider.setTawaranPaket(paket);
      roomChatProvider.activeRoomId = null;
      roomChatProvider.vendorId = paket.id_vendor;

      await roomChatProvider.sendMessage(
        currentUserId: userId,
      );

      if (!mounted) return;

      _safeSetState(() {
        isLoading = false;
      });

      // Close current page and navigate to chat
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (mounted) {
        context.read<NavigationProvider>().navigateToPage(
              context,
              RoomChatPage(partnerId: paket.id_vendor),
              targetTabIndex: 1,
            );
      }
    } catch (e) {
      debugPrint('❌ [SinglePost] Error sending offer: $e');

      if (!mounted) return;

      _safeSetState(() {
        isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengirim tawaran: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildLikeSaveRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 9, 16, 4),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => _handleLikeToggle(),
                child: Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  color: isLiked ? Colors.red : Colors.black,
                  size: 28,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _handleSaveToggle(),
                child: Icon(
                  isSaved ? Icons.bookmark : Icons.bookmark_border,
                  color: isSaved ? Colors.amber : Colors.black,
                  size: 29,
                ),
              ),
            ],
          ),
        ),

        // Show likes count if > 0
        if (likeCount > 0)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              "$likeCount likes",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        const SizedBox(height: 8),
      ],
    );
  }

  /// Handle like toggle
  Future<void> _handleLikeToggle() async {
    if (!mounted) return;

    final prevLiked = isLiked;
    final prevCount = likeCount;

    // Optimistic update
    _safeSetState(() {
      isLiked = !isLiked;
      likeCount += isLiked ? 1 : -1;
    });

    try {
      final userId = context.read<UserProvider>().userId;

      if (userId == null) {
        throw Exception('User not logged in');
      }

      await PortofolioService().action(
        no_id: userId,
        id_portofolio: widget.noId,
        action_type: isLiked ? "like" : "unlike",
      );
    } catch (e) {
      debugPrint('❌ [SinglePost] Error toggling like: $e');

      // Rollback on error
      if (!mounted) return;

      _safeSetState(() {
        isLiked = prevLiked;
        likeCount = prevCount;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengubah like: $e')),
        );
      }
    }
  }

  /// Handle save toggle
  Future<void> _handleSaveToggle() async {
    if (!mounted) return;

    final prevSaved = isSaved;

    // Optimistic update
    _safeSetState(() {
      isSaved = !isSaved;
    });

    try {
      final userId = context.read<UserProvider>().userId;

      if (userId == null) {
        throw Exception('User not logged in');
      }

      await PortofolioService().action(
        no_id: userId,
        id_portofolio: widget.noId,
        action_type: isSaved ? "save" : "unsave",
      );
    } catch (e) {
      debugPrint('❌ [SinglePost] Error toggling save: $e');

      // Rollback on error
      if (!mounted) return;

      _safeSetState(() {
        isSaved = prevSaved;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengubah save: $e')),
        );
      }
    }
  }
}
