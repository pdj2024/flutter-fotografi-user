import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/constants/helper.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/routing/navigation_provider.dart';
import '../providers/custom_back_button.dart';

import 'fotographerbio.dart';
import '../../data/models/portofolio_model.dart';
import '../../data/models/paket_model.dart';
import '../../features/auth/services/user_provider.dart';
import 'services/portofolio_service.dart';
import 'services/paket_service.dart';
import 'single_chat.dart';

class SinglePostPage extends StatefulWidget {
  final String noId;

  const SinglePostPage({super.key, required this.noId});

  @override
  State<SinglePostPage> createState() => _SinglePostPageState();
}

class _SinglePostPageState extends State<SinglePostPage> {
  bool isLiked = false;
  bool isSaved = false;
  int likeCount = 0;
  final ScrollController _scrollController = ScrollController();

  Map<String, dynamic>? portofolioData;
  List<PaketModel> paketList = [];

  bool isLoading = true;
  bool isLoadingPaket = false;
  String? error;
  String? errorPaket;

  Future<void> _fetchData() async {
    setState(() {
      isLoading = true;
      error = null;
      paketList.clear();
      errorPaket = null;
    });

    try {
      final userId = context.read<UserProvider>().role == 'customer'
      ? context.read<UserProvider>().userId
      : null;

      final portofolioDataList = await PortofolioService().getAll(
            noId: widget.noId,
            status: "aktif",
            id_customer: userId
          );

      if (portofolioDataList.isEmpty) {
        error = "Portofolio tidak ditemukan.";
        return;
      }

      final portofolio = portofolioDataList.first;

      setState(() {
        isLiked = portofolio.isLiked;
        isSaved = portofolio.isSaved;
        likeCount = portofolio.likes;
      });
     
      portofolioData = portofolio.toJson();

      final List<String> idPaketList = List<String>.from(portofolio.idPaket ?? []);

      if (idPaketList.isNotEmpty) {
        setState(() {
          isLoadingPaket = true;
        });

        try {
          final paketData = await PaketService().getAll(
                idList: idPaketList,
                status: "aktif",
                
              );

          setState(() {
            paketList = paketData;
          });
        } catch (e) {
          errorPaket = "Gagal memuat paket: $e";
        } finally {
          isLoadingPaket = false;
        }
      }
    } catch (e) {
      error = "Terjadi kesalahan saat memuat data. $e";
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchData();
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
        leading: CustomBackButton(),
        title: const Text(
          "Portofolio",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text(error!))
              : RefreshIndicator(
                  onRefresh: _fetchData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    controller: _scrollController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildVendorHeader(portofolioData!),
                        _buildImage(portofolioData!),
                        _buildLikeSaveRow(),
                       // ✅ Sembunyikan likes jika null atau 0
                      if (likeCount > 0)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            "$likeCount likes",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (isLoadingPaket)
                          const Center(child: CircularProgressIndicator())
                        else if (errorPaket != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(errorPaket!,
                                style: const TextStyle(color: Colors.red)),
                          )
                        else if (paketList.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text(""),
                          )
                        else
                          ...paketList.map((paket) => OfferCard(
                                title: paket.nama_paket,
                                price: Helper.formatCurrency(paket.harga),
                                rincian: paket.rincian,
                              )),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
      floatingActionButton: (!isLoading && paketList.length > 1)
          ? FloatingActionButton(
              onPressed: _fetchData,
              backgroundColor: Constants.primaryColor,
              child: const Icon(Icons.refresh, color: Colors.white),
              tooltip: 'Refresh Paket',
            )
          : null,
    );
  }

Widget _buildVendorHeader(Map<String, dynamic> data) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
    child: Row(
      children: [
        // Semua dibungkus dalam GestureDetector
        Expanded(
          child: GestureDetector(
            onTap: () => context.read<NavigationProvider>().navigateToPage(
                  context,
                  PhotographerBio(idVendor: data['Id_Vendor']),
                  targetTabIndex: 0,
                ),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.grey[200],
                  child: ClipOval(
                    child: Image.network(
                      data['Id_Media_Vendor'],
                      width: 36,
                      height: 36,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.person, size: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Nama + rating
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        data['Username_Vendor'] ?? '',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(width: 6),
                      if (data['Rating_Vendor'] != null &&
                          data['Rating_Vendor'] != 0) ...[
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 2),
                        Text(
                          data['Rating_Vendor'].toString(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Tombol chat
        SizedBox(
          height: 44,
          width: 44,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Constants.primaryColor),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              padding: EdgeInsets.zero,
            ),
            onPressed: () {
              // context.read<NavigationProvider>().navigateToPage(
              //       context,
              //       SingleChat(
              //         receiverUserName: data['Username_Vendor'] ?? '',
              //         receiverEmail: "",
              //         receiverID: data['Id_Vendor'],
              //       ),
              //       targetTabIndex: 1,
              //     );
            },
            child: const Icon(Icons.chat_outlined,
                color: Constants.primaryColor),
          ),
        ),
      ],
    ),
  );
}


  Widget _buildImage(Map<String, dynamic> data) {
    final mediaUrl = (data['MediaUrls'] as List).isNotEmpty
        ? data['MediaUrls'][0]['Url']
        : null;

    return AspectRatio(
      aspectRatio: 5 / 4,
      child: mediaUrl != null
          ? Image.network(
              mediaUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(color: Colors.grey[300]),
                );
              },
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.grey.shade200,
                alignment: Alignment.center,
                child: const Icon(Icons.broken_image_outlined, size: 40),
              ),
            )
          : Container(
              color: Colors.grey.shade200,
              alignment: Alignment.center,
              child: const Icon(Icons.image, size: 40),
            ),
    );
  }

  Widget _buildLikeSaveRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 9, 16, 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: () async {
    final prevLiked = isLiked;
    final prevCount = likeCount;

   setState(() {
      isLiked = !isLiked;
      likeCount += isLiked ? 1 : -1; // update lokal langsung
    });

    try {
      await PortofolioService().action(
        no_id: context.read<UserProvider>().userId!,
        id_portofolio: widget.noId,
        action_type: isLiked ? "like" : "unlike",
      );
    } catch (e) {
      // rollback kalau error
     setState(() {
        isLiked = prevLiked;
        likeCount = prevCount;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengubah like: $e')),
      );
    }
  },
            child: Icon(
              isLiked ? Icons.favorite : Icons.favorite_border,
              color: isLiked ? Colors.red : Colors.black,
              size: 28,
            ),
          ),
          // const SizedBox(width: 16),
          // const Icon(Icons.chat_bubble_outline, size: 28),
          const Spacer(),
          GestureDetector(
          onTap: () async {
    final prevSaved = isSaved;


   setState(() {
      isSaved = !isSaved;
     
    });

    try {
      await PortofolioService().action(
        no_id: context.read<UserProvider>().userId!,
        id_portofolio: widget.noId,
        action_type: isSaved ? "save" : "unsave",
      );
    } catch (e) {
      // rollback kalau error
     setState(() {
        isSaved = prevSaved;
       
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengubah save: $e')),
      );
    }
  },
            child: Icon(
              isSaved ? Icons.bookmark : Icons.bookmark_border,
              color: isSaved ? Colors.amber : Colors.black,
              size: 29,
            ),
          ),
        ],
      ),
    );
  }
}

class OfferCard extends StatelessWidget {
  final String title;
  final String price;
    final String rincian;
  // final List<String> includes;

  const OfferCard({
    super.key,
    required this.title,
    required this.price,
    required this.rincian
    // required this.includes,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            price,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 12),
          const Text(
            "Rincian",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          // ...includes.map((item) => Padding(
          //       padding: const EdgeInsets.only(bottom: 2),
          //       child: Text("• $item", style: const TextStyle(fontSize: 13)),
          //     )),
          Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child:  Text(
          rincian,
          style: const TextStyle(fontSize: 13),
          softWrap: true,
        ),
              ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: Constants.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () {
                // context.read<NavigationProvider>().navigateToPage(
                //       context,
                //       SingleChat(
                //         receiverUserName: 'helooo',
                //         receiverEmail: "hello@gmail.com",
                //         receiverID: '123',
                //       ),
                //       targetTabIndex: 1,
                //     );
              },
              child: const Text(
                "Atur Jadwal",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
