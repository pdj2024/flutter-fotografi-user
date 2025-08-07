import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../providers/constants.dart';
import '../providers/navigation_provider.dart';
import '../providers/custom_back_button.dart';


import 'fotographerbio.dart';
import 'models/portofolio_model.dart';
import 'providers/paket_provider.dart';
import 'providers/portofolio_provider.dart';
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
  final ScrollController _scrollController = ScrollController();

  Map<String, dynamic>? portofolioData;
  bool isLoading = true;
  String? error;

  Future<void> _fetchData() async {
  setState(() {
    isLoading = true;
    error = null;
  });

  try {
    final List<PortofolioModel> dataList =
    await context.read<PortofolioProvider>().service.getAll(noId: widget.noId, status: 'aktif');

    if (dataList.isNotEmpty) {
      portofolioData = dataList[0].toJson(); // konversi ke Map jika kamu butuh akses by key

     final idPaketList = List<String>.from(portofolioData?['Id_Paket'] ?? []);

      if (idPaketList.isNotEmpty) {
        await context.read<PaketProvider>().service.getAll(
          idList: idPaketList,
          status: 'aktif',
        );
}


    } else {
      error = 'Portofolio tidak ditemukan.';
    }


  } catch (e) {
    error = 'Terjadi kesalahan saat memuat data.';
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
    final paketProvider = context.watch<PaketProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F9F9),
        elevation: 1,
        leading: CustomBackButton(),
        title: const Text("Portofolio",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text("${portofolioData!['Likes']} likes",
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 12),
                        if (paketProvider.isLoading)
                          const Center(child: CircularProgressIndicator())
                        else if (paketProvider.error != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              "Gagal memuat paket: ${paketProvider.error}",
                              style: const TextStyle(color: Colors.red),
                            ),
                          )
                        else if (paketProvider.paketList.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text(""),
                          )
                        else
                          ...paketProvider.paketList.map((paket) {
                            return OfferCard(
                              title: paket.nama_paket,
                              price: Constants.formatCurrency(paket.harga),
                              includes: [
                                if (paket.rincian.isNotEmpty) paket.rincian,
                                "Aktif: ${paket.aktif ? 'Ya' : 'Tidak'}",
                              ],
                            );
                          }).toList(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
      floatingActionButton: (!isLoading &&
              paketProvider.paketList.length > 1)
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
          Expanded(
            child: GestureDetector(
              onTap: () => context.read<NavigationProvider>().navigateToPage(
                    context,
                    PhotographerBio(idVendor: data['Id_Vendor']),
                    targetTabIndex: 0,
                  ),
              child: Row(
                children: [
                  Text(
                    data['Username_Vendor'] ?? '',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.star, color: Colors.amber, size: 16),
                  const SizedBox(width: 2),
                  Text(
                    (data['Rating_Vendor'] ?? 0).toString(),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
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
                context.read<NavigationProvider>().navigateToPage(
                      context,
                      SingleChat(
                          receiverUserName: data['Username_Vendor'] ?? '',
                          receiverEmail: "",
                          receiverID: data['Id_Vendor']),
                      targetTabIndex: 1,
                    );
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
            onTap: () => setState(() => isLiked = !isLiked),
            child: Icon(
              isLiked ? Icons.favorite : Icons.favorite_border,
              color: isLiked ? Colors.red : Colors.black,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          const Icon(Icons.chat_bubble_outline, size: 28),
          const Spacer(),
          GestureDetector(
            onTap: () => setState(() => isSaved = !isSaved),
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
  final List<String> includes;

  const OfferCard({
    super.key,
    required this.title,
    required this.price,
    required this.includes,
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
          Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text(price, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 12),
          const Text("Rincian", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          ...includes.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text("• $item", style: const TextStyle(fontSize: 13)),
              )),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Constants.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: () {
                context.read<NavigationProvider>().navigateToPage(
                      context,
                      SingleChat(
                          receiverUserName: 'helooo',
                          receiverEmail: "hello@gmail.com",
                          receiverID: '123'),
                      targetTabIndex: 1,
                    );
              },
              child: const Text("Atur Jadwal",
                  style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
