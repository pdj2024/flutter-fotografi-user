import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:shimmer/shimmer.dart';
import 'package:mpjnew/src/pages/fotografi_user/single_order.dart';
import 'package:provider/provider.dart';

import '../providers/custom_back_button.dart';
import '../../core/routing/navigation_provider.dart';

class AllOrder extends StatefulWidget {
  const AllOrder({super.key});

  @override
  State<AllOrder> createState() => _AllOrderState();
}

class _AllOrderState extends State<AllOrder>
    with SingleTickerProviderStateMixin {
  final List<Map<String, dynamic>> orders = [
    {
      "image": "49baa83d-c292-4cc8-a45e-3d618abca608-image_cropper_1748682537107.jpg",
      "title": "Wedding",
      "date": "2024-05-21",
      "name": "Jordan Williams",
      "price": "IDR 150,000"
    },
    {
      "image": "2116a1aa-414b-49c7-ad92-5d59b3030e85-image_cropper_1748682546612.jpg",
      "title": "Prewedding Session",
      "date": "2024-04-30",
      "name": "michaelwilliams_",
      "price": "IDR 600,000"
    },
    {
      "image": "aea19edb-3c95-4421-83a0-214912a92d17-image_cropper_1748682553654.jpg",
      "title": "Portrait",
      "date": "2024-03-18",
      "name": "Amanda Reed",
      "price": "IDR 300,000"
    },
    {
      "image": "49baa83d-c292-4cc8-a45e-3d618abca608-image_cropper_1748682537107.jpg",
      "title": "Engagement",
      "date": "2024-02-14",
      "name": "Laura Wilson",
      "price": "IDR 8,000,000"
    },
    {
      "image": "aea19edb-3c95-4421-83a0-214912a92d17-image_cropper_1748682553654.jpg",
      "title": "Event",
      "date": "2024-02-14",
      "name": "Gerald Smith",
      "price": "IDR 2,000,000"
    },
  ];

  final List<Map<String, dynamic>> order_Selesai = [
    {
      "image": "49baa83d-c292-4cc8-a45e-3d618abca608-image_cropper_1748682537107.jpg",
      "title": "Prewedding Session",
      "date": "2024-04-30",
      "name": "michaelwilliams_",
      "price": "IDR 600,000"
    },
    {
      "image": "2116a1aa-414b-49c7-ad92-5d59b3030e85-image_cropper_1748682546612.jpg",
      "title": "Portrait",
      "date": "2024-03-18",
      "name": "Amanda Reed",
      "price": "IDR 300,000"
    },
    {
      "image": "aea19edb-3c95-4421-83a0-214912a92d17-image_cropper_1748682553654.jpg",
      "title": "Engagement",
      "date": "2024-02-14",
      "name": "Laura Wilson",
      "price": "IDR 8,000,000"
    },
    {
      "image": "49baa83d-c292-4cc8-a45e-3d618abca608-image_cropper_1748682537107.jpg",
      "title": "Event",
      "date": "2024-02-14",
      "name": "Gerald Smith",
      "price": "IDR 2,000,000"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF9F9F9),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF9F9F9),
          elevation: 0,
          title: const Text(
            "Semua Order",
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          leading: CustomBackButton(),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(58),
            child: Container(
              alignment: Alignment.centerLeft,
              child: const TabBar(
                labelColor: Colors.black,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Constants.primaryColor,
                indicatorWeight: 2.5,
                isScrollable: false,
                indicatorSize: TabBarIndicatorSize.label,
                indicatorPadding: EdgeInsets.zero,
                tabs: [
                  Tab(
                    child: Text("Progress",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  Tab(
                    child: Text("Selesai",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ],
                overlayColor: WidgetStatePropertyAll(Colors.transparent),
                dividerColor: Color(0xFFDDDDDD),
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            ListView.builder(
              itemCount: orders.length,
              itemBuilder: (context, index) {
                return OrderCard(order: orders[index]);
              },
            ),
            ListView.builder(
              itemCount: order_Selesai.length,
              itemBuilder: (context, index) {
                return OrderCard(order: order_Selesai[index]);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final void Function()? onDetailPressed;

  const OrderCard({
    super.key,
    required this.order,
    this.onDetailPressed,
  });

  String formatTanggal(String tanggal) {
    final dateTime = DateTime.parse(tanggal);
    final formatter = DateFormat("dd MMM yyyy", "id_ID");
    return formatter.format(dateTime);
  }

  Widget _shimmerBox(double size) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: size,
        height: size,
        color: Colors.white,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String imgUrl =
        context.read<NavigationProvider>().ambilGambar(order["image"]);

    return GestureDetector(
      onTap: () => context
          .read<NavigationProvider>()
          .navigateToPage(context, SingleOrder(), targetTabIndex: 2),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.transparent),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: imgUrl,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                placeholder: (context, url) => _shimmerBox(60),
                errorWidget: (context, url, error) => Container(
                  width: 60,
                  height: 60,
                  color: Colors.grey[200],
                  alignment: Alignment.center,
                  child: const Icon(Icons.broken_image_outlined, size: 30),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(order["title"],
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(order["name"], style: const TextStyle(fontSize: 14)),
                  Text(order["price"],
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatTanggal(order["date"]),
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 32,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Constants.primaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(40),
                      ),
                    ),
                    onPressed: onDetailPressed ??
                        () {
                          context.read<NavigationProvider>().navigateToPage(
                                context,
                                SingleOrder(),
                                targetTabIndex: 2,
                              );
                        },
                    child: const Text("Detil",
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
