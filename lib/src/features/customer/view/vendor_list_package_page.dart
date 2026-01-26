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
import 'package:mpjnew/src/features/customer/view/page_wrapper.dart';
import 'package:mpjnew/src/features/customer/viewmodels/room_chat_provider.dart';
import 'package:mpjnew/src/features/customer/widget/offer_card.dart';
import 'package:mpjnew/src/features/customer/widget/vendor_bio_card.dart';
import 'package:mpjnew/src/features/customer/services/paket_service.dart';
import 'package:mpjnew/src/features/customer/widget/custom_back_button.dart';
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
    // ✅ FIX: Gunakan addPostFrameCallback untuk akses context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  /// ✅ FIXED: Load ulasan dengan vendor ID yang benar
  Future<void> _loadUlasan() async {
    if (!mounted) return;

    setState(() {
      _isLoadingUlasan = true;
    });

    try {
      debugPrint('═══════════════════════════════════════════════════');
      debugPrint(
          '[VendorListPackage] 📝 Loading ulasan for vendor: ${widget.vendor.noId}');
      debugPrint(
          '[VendorListPackage] Vendor name: ${widget.vendor.namaDisplay}');

      // ✅ FIX: Gunakan widget.vendor.noId, BUKAN userProvider.userId
      final allUlasan = await _ulasanService.getAll(
        idVendor: widget.vendor.noId, // ✅ FIXED: ID vendor yang benar
        status: 'aktif',
        orderBy: 'Tgl_Ulasan',
        orderDir: 'DESC',
      );

      if (!mounted) return;

      debugPrint(
          '[VendorListPackage] ✅ Loaded ${allUlasan.length} total ulasan');

      // Kelompokkan ulasan berdasarkan paket
      final Map<String, List<UlasanModel>> ulasanByPaket = {};

      for (var ulasan in allUlasan) {
        debugPrint('[VendorListPackage] 📄 Processing ulasan: ${ulasan.noId}');
        debugPrint('[VendorListPackage]   idPaket: ${ulasan.idPaket}');
        debugPrint('[VendorListPackage]   Rating: ${ulasan.rating}');
        debugPrint('[VendorListPackage]   Comment: ${ulasan.isiBalasan}');

        // Cek apakah ulasan memiliki idPaket
        if (ulasan.idPaket != null && ulasan.idPaket.isNotEmpty) {
          // ✅ Handle multiple paket IDs (comma separated)
          final paketIds = ulasan.idPaket.split(',');

          for (var paketId in paketIds) {
            final trimmedId = paketId.trim();

            if (trimmedId.isNotEmpty) {
              if (!ulasanByPaket.containsKey(trimmedId)) {
                ulasanByPaket[trimmedId] = [];
              }

              ulasanByPaket[trimmedId]!.add(ulasan);
              debugPrint('[VendorListPackage]   ✅ Added to paket: $trimmedId');
            }
          }
        } else {
          debugPrint('[VendorListPackage]   ⚠️ No paket ID found');
        }
      }

      // Debug: Print summary
      debugPrint('[VendorListPackage] 📊 Ulasan grouped by paket:');
      ulasanByPaket.forEach((paketId, ulasanList) {
        debugPrint(
            '[VendorListPackage]   📦 Paket $paketId: ${ulasanList.length} ulasan');
      });

      // ✅ Verify paket IDs match
      debugPrint('[VendorListPackage] 📦 Current paket list:');
      for (var paket in paketList) {
        debugPrint(
            '[VendorListPackage]   - ${paket.no_id}: ${paket.nama_paket}');
        final count = ulasanByPaket[paket.no_id]?.length ?? 0;
        debugPrint('[VendorListPackage]     → $count ulasan found');
      }

      debugPrint('═══════════════════════════════════════════════════');

      if (!mounted) return;

      setState(() {
        _ulasanByPaket = ulasanByPaket;
        _isLoadingUlasan = false;
      });

      debugPrint('[VendorListPackage] ✅ Ulasan state updated successfully');
    } catch (e, stackTrace) {
      debugPrint('[VendorListPackage] ❌ Error loading ulasan: $e');
      debugPrint('[VendorListPackage] Stack trace: $stackTrace');

      if (!mounted) return;

      setState(() {
        _isLoadingUlasan = false;
      });
    }
  }

  Future<void> _fetchData() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      debugPrint(
          '[VendorListPackage] 🔄 Fetching paket for vendor: ${widget.vendor.noId}');

      final data = await PaketService().getAll(
        idVendor: widget.vendor.noId,
        status: 'aktif',
        orderBy: "tgl_created",
        orderDir: "desc",
      );

      debugPrint('[VendorListPackage] ✅ Loaded ${data.length} paket');

      if (!mounted) return;

      setState(() {
        paketList = data;
      });

      // ✅ Load ulasan setelah paket berhasil dimuat
      await _loadUlasan();
    } catch (e, stackTrace) {
      debugPrint('[VendorListPackage] ❌ Error fetching paket: $e');
      debugPrint('[VendorListPackage] Stack trace: $stackTrace');

      if (!mounted) return;

      setState(() {
        errorMessage = e.toString();
      });
    } finally {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FullScreenPage(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFFF9F9F9),
          elevation: 1,
          title: Text(
            "Daftar Paket",
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        backgroundColor: const Color(0xfff9f9f9),
        body: RefreshIndicator(
          onRefresh: _fetchData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                VendorBioCard(
                  vendor: widget.vendor,
                  isListPackagePage: true,
                ),
                Divider(),
                SizedBox(height: 10),

                // ✅ Loading state
                if (isLoading)
                  Column(
                    children: List.generate(
                      4,
                      (index) => Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: ShimmerPlaceholder(
                          height: 150,
                          radius: 10,
                        ),
                      ),
                    ),
                  )
                // ✅ Error state
                else if (errorMessage != null)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Icon(Icons.error_outline,
                              size: 48, color: Colors.red),
                          SizedBox(height: 16),
                          Text(
                            "Gagal memuat paket",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            errorMessage!,
                            style: TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _fetchData,
                            child: Text('Coba Lagi'),
                          ),
                        ],
                      ),
                    ),
                  )
                // ✅ Empty state
                else if (paketList.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Icon(Icons.inventory_2_outlined,
                              size: 48, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            "Belum ada paket tersedia",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                // ✅ Paket list dengan ulasan
                else
                  Column(
                    children: paketList.map((paket) {
                      // ✅ Get ulasan untuk paket ini
                      final ulasanList = _ulasanByPaket[paket.no_id] ?? [];

                      debugPrint(
                          '[VendorListPackage] 🎨 Rendering paket: ${paket.no_id}');
                      debugPrint(
                          '[VendorListPackage]   Ulasan count: ${ulasanList.length}');

                      return OfferCard(
                        paket: paket,
                        vendorId: widget.vendor.noId,
                        ulasanList: ulasanList, // ✅ Pass ulasan list
                        onSend: () async {
                          // ✅ Check login first
                          final userProvider = context.read<UserProvider>();
                          if (userProvider.userId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Silakan login terlebih dahulu'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                            return;
                          }

                          setState(() {
                            isLoading = true;
                          });

                          try {
                            final userId = userProvider.userId!;
                            final roomChatProvider =
                                context.read<RoomChatProvider>();

                            roomChatProvider.setTawaranPaket(paket);
                            roomChatProvider.activeRoomId = null;
                            roomChatProvider.vendorId = paket.id_vendor;

                            await roomChatProvider.sendMessage(
                              currentUserId: userId,
                            );

                            if (!mounted) return;

                            setState(() {
                              isLoading = false;
                            });

                            Navigator.pop(context);

                            if (!mounted) return;

                            context.read<NavigationProvider>().navigateToPage(
                                  context,
                                  targetTabIndex: 1,
                                  RoomChatPage(
                                    partnerId: paket.id_vendor,
                                  ),
                                );
                          } catch (e) {
                            debugPrint(
                                '[VendorListPackage] ❌ Error sending message: $e');

                            if (!mounted) return;

                            setState(() {
                              isLoading = false;
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Gagal mengirim pesan: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                      );
                    }).toList(),
                  ),

                SizedBox(height: 100),
              ],
            ),
          ),
        ),
        floatingActionButton: paketList.isNotEmpty
            ? FloatingActionButton(
                onPressed: _fetchData,
                backgroundColor: Constants.primaryColor,
                child: const Icon(Icons.refresh, color: Colors.white),
                tooltip: 'Refresh Paket',
              )
            : null,
      ),
    );
  }
}
