import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mpjnew/src/pages/fotografi_user/providers/paket_provider.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../providers/constants.dart';
import '../providers/custom_back_button.dart';
import '../providers/navigation_provider.dart';
import 'single_chat.dart';
import 'fotographerbio.dart';

class PilihanPaket extends StatefulWidget {
  final String namaVendor;
  final String userName;
  final String kotaVendor;
  final double ratingVendor;
  final String idVendor;
  final String fotoProfil;

  const PilihanPaket({
    super.key,
    required this.namaVendor,
    required this.userName,
    required this.kotaVendor,
    required this.ratingVendor,
    required this.idVendor,
    required this.fotoProfil,
  });

  @override
  State<PilihanPaket> createState() => _PilihanPaketState();
}

class _PilihanPaketState extends State<PilihanPaket> {
  Future<void> _doRefresh() async {
    await context.read<PaketProvider>().getAll();
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await context.read<PaketProvider>().getAll();
    });
  }

  Widget _shimmerBox({double? w, double? h, double r = 0}) =>
      Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(r),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final paketProvider = context.watch<PaketProvider>();
    final paketList = paketProvider.paketList;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F9F9),
        elevation: 1,
        leading: CustomBackButton(),
        title: Text(
          "Paket oleh ${widget.userName} - ${widget.idVendor}",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      backgroundColor: const Color(0xfff9f9f9),
      body: RefreshIndicator(
        onRefresh: _doRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              // Profil Header
              Container(
                margin: const EdgeInsets.only(top: 20, bottom: 16),
                child: GestureDetector(
                  onTap: () =>
                      context.read<NavigationProvider>().navigateToPage(
                            context,
                            PhotographerBio(
                              idVendor: 'ven_2',
                            ),
                            targetTabIndex: 0,
                          ), //Ubah idVendor sesuai kebutuhan
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.grey.shade300,
                        child: ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: context
                                .read<NavigationProvider>()
                                .ambilGambar(
                                    '1d98c486-b810-42d8-8779-3b0ca34154ef-image_cropper_1748677884447.jpg'),
                            width: 60, // radius * 2
                            height: 60,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Shimmer.fromColors(
                              baseColor: Colors.grey.shade300,
                              highlightColor: Colors.grey.shade100,
                              child: Container(
                                width: 60,
                                height: 60,
                                color: Colors.white,
                              ),
                            ),
                            errorWidget: (context, url, error) => Icon(
                              Icons.error,
                              size: 30,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.namaVendor,
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Photographer',
                              style: TextStyle(fontSize: 13),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(Icons.location_on_outlined,
                                    size: 14, color: Colors.grey.shade600),
                                SizedBox(width: 4),
                                Text(
                                  widget.kotaVendor,
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.star, size: 20, color: Colors.amber),
                              SizedBox(width: 4),
                              Text(
                                widget.ratingVendor.toString(),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 44,
                            width: 44,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                    color: Constants.primaryColor),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: EdgeInsets.zero,
                              ),
                              onPressed: () {
                                context
                                    .read<NavigationProvider>()
                                    .navigateToPage(
                                      context,
                                      SingleChat(
                                          receiverUserName: widget.userName,
                                          receiverEmail: "hello@gmail.com",
                                          receiverID: '123'),
                                      targetTabIndex: 1,
                                    );
                              },
                              child: const Icon(Icons.chat_outlined,
                                  size: 20, color: Constants.primaryColor),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // List Paket
              Consumer<PaketProvider>(
                builder: (context, paketProvider, _) {
                  if (paketProvider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  // Tampilkan error hanya jika error dan list kosong
                  if (paketProvider.error != null &&
                      paketProvider.paketList.isEmpty) {
                    return Center(
                      child: Text(
                        "Gagal memuat paket: ${paketProvider.error}",
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  }
                  final paketList = paketProvider.paketList;
                  if (paketList.isEmpty) {
                    return const Center(
                        child: Text("Belum ada paket tersedia."));
                  }
                  return Column(
                    children: paketList.map((paket) {
                      return buildPackageCard(
                        context: context,
                        title: paket.nama_paket,
                        price: Constants.formatCurrency(paket.harga),
                        duration: paket.rincian,
                        photos: "Aktif: ${paket.aktif ? "Ya" : "Tidak"}",
                      );
                    }).toList(),
                  );
                },
              ),

              // // List Paket
              // buildPackageCard(
              //   context: context,
              //   title: "Wedding Package",
              //   price: "IDR 500,000",
              //   duration: "6 jam",
              //   photos: "200 foto",
              // ),
              // buildPackageCard(
              //   context: context,
              //   title: "Engagement Package",
              //   price: "IDR 300,000",
              //   duration: "2 jam",
              //   photos: "100 foto",
              // ),
            ],
          ),
        ),
      ),
      floatingActionButton: (paketList.length > 1)
          ? FloatingActionButton(
              onPressed: _doRefresh,
              backgroundColor: Constants.primaryColor,
              child: const Icon(Icons.refresh, color: Colors.white),
              tooltip: 'Refresh Paket',
            )
          : null,
    );
  }

  Widget buildPackageCard({
    required BuildContext context,
    required String title,
    required String price,
    required String duration,
    required String photos,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold)),
              Text(price,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("• $duration"),
                  Text("• $photos"),
                  const Text("• Google Drive"),
                ],
              )),
          // const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Constants.primaryColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
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
              child: const Text('Atur Jadwal',
                  style: TextStyle(color: Colors.white)),
            ),
          )
        ],
      ),
    );
  }
}
