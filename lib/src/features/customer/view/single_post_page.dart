import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/data/models/paket_model.dart';
import 'package:mpjnew/src/data/models/portofolio_model.dart';
import 'package:mpjnew/src/features/auth/services/user_provider.dart';
import 'package:mpjnew/src/features/customer/widget/image_post.dart';
import 'package:mpjnew/src/features/customer/widget/offer_card.dart';
import 'package:mpjnew/src/features/customer/widget/post_header.dart';
import 'package:mpjnew/src/pages/fotografi_user/services/paket_service.dart';
import 'package:mpjnew/src/pages/fotografi_user/services/portofolio_service.dart';
import 'package:mpjnew/src/pages/providers/custom_back_button.dart';
import 'package:provider/provider.dart';

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

  late PortofolioModel portofolio;
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

      final portofolioDataList = await PortofolioService()
          .getAll(noId: widget.noId, status: "aktif", id_customer: userId);

      if (portofolioDataList.isEmpty) {
        error = "Portofolio tidak ditemukan.";
        return;
      }

      portofolio = portofolioDataList.first;

      setState(() {
        isLiked = portofolio.isLiked;
        isSaved = portofolio.isSaved;
        likeCount = portofolio.likes;
      });

      // portofolioData = portofolio.toJson();

      final List<String> idPaketList = List<String>.from(portofolio.idPaket);

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
                        PostHeader(portofolio: portofolio),
                        ImagePost(mediaUrl: portofolio.mediaUrls),
                        _buildLikeSaveRow(),
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
                          ...paketList.map(
                            (paket) => OfferCard(
                              paket: paket,
                              portofolio: portofolio,
                            ),
                          ),
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

  Widget _buildLikeSaveRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
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
                  print(
                      "============= User ID: ${context.read<UserProvider>().userId!}");

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
        ),
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
      ],
    );
  }
}
