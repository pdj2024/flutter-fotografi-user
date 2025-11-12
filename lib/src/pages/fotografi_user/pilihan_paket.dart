import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/constants/helper.dart';
import 'package:mpjnew/src/features/customer/view/vendor_bio_page.dart';
import 'package:shimmer/shimmer.dart';

import '../providers/custom_back_button.dart';
import '../../core/routing/navigation_provider.dart';
import 'package:mpjnew/src/data/models/paket_model.dart';
import 'package:mpjnew/src/pages/fotografi_user/services/paket_service.dart';

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
  bool isLoading = true;
  String? errorMessage;
  List<PaketModel> paketList = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final data = await PaketService().getAll(
        idVendor: widget.idVendor,
        status: 'aktif',
      );
      setState(() {
        paketList = data;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget _shimmerBox({double? w, double? h, double r = 0}) => Shimmer.fromColors(
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F9F9),
        elevation: 1,
        leading: CustomBackButton(),
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
              _buildVendorHeader(),
              const SizedBox(height: 16),
              if (isLoading)
                const Center(child: CircularProgressIndicator())
              else if (errorMessage != null)
                Center(
                  child: Text(
                    "Gagal memuat paket: $errorMessage",
                    style: const TextStyle(color: Colors.red),
                  ),
                )
              else if (paketList.isEmpty)
                const Center(child: Text("Belum ada paket tersedia."))
              else
                Column(
                  children: paketList.map((paket) {
                    return buildPackageCard(
                      context: context,
                      title: paket.nama_paket,
                      price: Helper.formatCurrency(paket.harga),
                      rincian: paket.rincian
                     
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: paketList.length > 1
          ? FloatingActionButton(
              onPressed: _fetchData,
              backgroundColor: Constants.primaryColor,
              child: const Icon(Icons.refresh, color: Colors.white),
              tooltip: 'Refresh Paket',
            )
          : null,
    );
  }

  Widget _buildVendorHeader() {
    return Container(
      margin: const EdgeInsets.only(top: 20, bottom: 16),
      child: GestureDetector(
        onTap: () => NavigationProvider().navigateToPage(
          context,
          VendorBioPage(idVendor: widget.idVendor),
          targetTabIndex: 0,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.grey.shade300,
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl: widget.fotoProfil,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => _shimmerBox(w: 60, h: 60, r: 30),
                  errorWidget: (context, url, error) => const Icon(Icons.error, size: 30, color: Colors.red),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.namaVendor, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  const Text('Photographer', style: TextStyle(fontSize: 13)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(widget.kotaVendor, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (widget.ratingVendor != null && widget.ratingVendor > 0) 
                Row(
                  children: [
                    const Icon(Icons.star, size: 20, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(widget.ratingVendor.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),

                
                const SizedBox(height: 10),
                SizedBox(
                  height: 44,
                  width: 44,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Constants.primaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    onPressed: () {
                      // NavigationProvider().navigateToPage(
                      //   context,
                      //   SingleChat(
                      //     receiverUserName: widget.userName,
                      //     receiverEmail: "hello@gmail.com",
                      //     receiverID: widget.idVendor,
                      //   ),
                      //   targetTabIndex: 1,
                      // );
                    },
                    child: const Icon(Icons.chat_outlined, size: 20, color: Constants.primaryColor),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildPackageCard({
  required BuildContext context,
  required String title,
  required String price,
  required String rincian,
}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: const [
        BoxShadow(
          color: Colors.black12,
          blurRadius: 4,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Baris judul & harga
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Judul paket - bisa wrap
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
                softWrap: true,
              ),
            ),
            const SizedBox(width: 8),
            // Harga - tetap kanan, tidak wrap
            Text(
              price,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.right,
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Rincian paket - auto wrap & multi-line
        Text(
          rincian,
          style: const TextStyle(fontSize: 13),
          softWrap: true,
        ),

        const SizedBox(height: 12),

        // Tombol di kanan bawah
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Constants.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            onPressed: () {
              // NavigationProvider().navigateToPage(
              //   context,
              //   SingleChat(
              //     receiverUserName: widget.userName,
              //     receiverEmail: "hello@gmail.com",
              //     receiverID: widget.idVendor,
              //   ),
              //   targetTabIndex: 1,
              // );
            },
            child: const Text(
              'Atur Jadwal',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ],
    ),
  );
}

}