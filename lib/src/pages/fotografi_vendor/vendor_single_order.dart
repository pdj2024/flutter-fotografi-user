import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/pages/fotografi_vendor/vendor_bio.dart';
import 'package:mpjnew/src/pages/fotografi_vendor/vendor_single_chat.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../providers/custom_back_button.dart';
import '../providers/navigation_provider.dart';


class VendorSingleOrder extends StatelessWidget {
  const VendorSingleOrder({super.key});

  @override
  Widget build(BuildContext context) {
    final Color primaryColorVendor = Constants.primaryColorVendor;

    Widget buildTimelineItem(String time, String description, bool isActive,
        {bool isLast = false}) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: isActive ? primaryColorVendor : Colors.grey.shade400,
                  shape: BoxShape.circle,
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 50,
                  color: Colors.grey.shade400,
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: isActive ? primaryColorVendor : Colors.black54,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F9F9),
        elevation: 1,
        leading: CustomBackButton(),
        title: const Text(
          "Detil Progress",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      backgroundColor: const Color(0xFFF9F9F9),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile + chat button
                Row(
  children: [
    GestureDetector(
      onTap: () {
        // Aksi saat klik avatar + nama
       context.read<NavigationProvider>().vendorNavigateToPage(
                          context, VendorBio(), targetTabIndex:0, );
        // Navigasi ke profil atau lainnya bisa ditaruh di sini
      },
      child: Row(
        children: [
         CircleAvatar(
  radius: 30,
  backgroundColor: Colors.grey.shade300,
  child: ClipOval(
    child: CachedNetworkImage(
      imageUrl: context.read<NavigationProvider>().ambilGambar('photographer_icon6.jpg'),
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
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "michaelwilliams_",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 4),
              Text(
                "Michael Williams",
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
    const Spacer(),
    SizedBox(
      height: 44,
      width: 44,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Constants.primaryColorVendor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: EdgeInsets.zero,
        ),
        onPressed: () {
          context.read<NavigationProvider>().vendorNavigateToPage(
            context,
            VendorSingleChat(),
            targetTabIndex: 1,
          );
        },
        child: const Icon(
          Icons.chat_outlined,
          color: Constants.primaryColorVendor,
        ),
      ),
    ),
  ],
),

                  const SizedBox(height: 20),
                  const Text(
                    "Prewedding Session",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: const [
                      Icon(Icons.calendar_today_outlined,
                          size: 18, color: Colors.black54),
                      SizedBox(width: 8),
                      Text(
                        "30 April 2024",
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: const [
                      Icon(Icons.access_time,
                          size: 18, color: Colors.black54),
                      SizedBox(width: 8),
                      Text(
                        "10:00 AM",
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Icon(Icons.location_on_outlined,
                          size: 18, color: Colors.black54),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Jl. Taman Bungkul",
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 10),
                  // Timeline progress
                  buildTimelineItem("6 Mei 2024 13:00", "Pesanan diterima", true),
                  buildTimelineItem("7 Mei 2024 10:00", "Pemotretan dilakukan", true),
                  buildTimelineItem("7 Mei 2024 12:00", "Pemotretan selesai dan file dikumpulkan", false),
                  buildTimelineItem("8 Mei 2024 09:00", "Proses editing dimulai oleh tim desain", false),
                  buildTimelineItem("9 Mei 2024 17:00", "Review internal hasil edit selesai", false),
                  buildTimelineItem("10 Mei 2024 11:00", "Preview dikirim ke pelanggan untuk review", false),
                  buildTimelineItem("10 Mei 2024 14:00", "Revisi diminta oleh pelanggan", false),
                  buildTimelineItem("11 Mei 2024 16:00", "Revisi selesai dan diverifikasi", false),
                  buildTimelineItem("12 Mei 2024 10:00", "File akhir disiapkan untuk dikirim", false),
                  buildTimelineItem("12 Mei 2024 15:00", "Hasil akhir dikirim melalui email", false),
                  buildTimelineItem("13 Mei 2024 09:00", "Pelanggan mengonfirmasi penerimaan hasil", false),
                  buildTimelineItem("13 Mei 2024 12:00", "Feedback pelanggan diterima", false),
                  buildTimelineItem("14 Mei 2024 10:00", "Testimoni pelanggan dipublikasikan", false),
                  buildTimelineItem("14 Mei 2024 12:00", "Project dinyatakan selesai", false, isLast: true),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 5, 20, 20),
            color: const Color(0xFFF9F9F9),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // Aksi Ajukan Banding
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: primaryColorVendor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                    child: Text(
                      'Ajukan Banding',
                      style: TextStyle(color: primaryColorVendor),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Aksi Pesanan Selesai
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColorVendor,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      'Pesanan Selesai',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
