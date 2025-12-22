import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/constants/helper.dart';
import 'package:mpjnew/src/core/routing/navigation_provider.dart';
import 'package:mpjnew/src/data/models/history_order_model.dart';
import 'package:mpjnew/src/data/models/paket_model.dart';
import 'package:mpjnew/src/data/models/pesanan_model.dart';
import 'package:mpjnew/src/data/models/vendor_model.dart';
import 'package:mpjnew/src/features/customer/services/history_order_service.dart';
import 'package:mpjnew/src/features/customer/services/vendor_service.dart';
import 'package:mpjnew/src/features/customer/view/vendor_bio_page.dart';
import 'package:mpjnew/src/features/customer/widget/custom_back_button.dart';
import 'package:mpjnew/src/features/customer/widget/dialog/custom_snackbar.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

class DetailOrderPage extends StatefulWidget {
  final PesananModel pesananModel;
  const DetailOrderPage({super.key, required this.pesananModel});

  @override
  State<DetailOrderPage> createState() => _DetailOrderPageState();
}

class _DetailOrderPageState extends State<DetailOrderPage> {
  HistoryOrderService historyOrderService = HistoryOrderService();
  VendorService vendorService = VendorService();

  List<HistoryOrderModel> historyOrder = [];
  VendorModel? vendor;
  PaketModel? paket;

  bool isLoading = false;
  String error = '';

  // Fetch data histori order
  Future<void> fetchData() async {
    try {
      setState(() {
        isLoading = true;
        error = '';
      });

      // get data histori
      historyOrder = await historyOrderService.getAll(
        noOrder: widget.pesananModel.noBukti,
        orderBy: 'Tgl_Progress',
        orderDir: 'desc',
      );

      // get data vendor
      vendor = (await vendorService.getAll(no_id: widget.pesananModel.idVendor))
          .first;
    } catch (e) {
      print(e);
      setState(() {
        error = e.toString();
      });
      CustomSnackbar.showErrorSnackbar(context, e.toString());
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // init state page

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F9F9),
        elevation: 1,
        leading: CustomBackButton(),
        title: const Text(
          "Detail Pesanan",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
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
                          context.read<NavigationProvider>().navigateToPage(
                                context,
                                VendorBioPage(
                                  idVendor: vendor?.noId ?? '',
                                ),
                                targetTabIndex: 0,
                              ); //Ubah idVendor agar sesuai dengan data yang ada
                          // Navigasi ke profil atau lainnya bisa ditaruh di sini
                        },
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.grey.shade300,
                              child: ClipOval(
                                child: CachedNetworkImage(
                                  imageUrl: vendor?.idMedia ?? '',
                                  width: 60, // radius * 2
                                  height: 60,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) =>
                                      Shimmer.fromColors(
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
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  vendor?.username ?? "Vendor",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  vendor?.namaDisplay ?? "Nama Vendor",
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
                            side:
                                const BorderSide(color: Constants.primaryColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          onPressed: () {
                            // context.read<NavigationProvider>().navigateToPage(
                            //   context,
                            //   SingleChat(receiverUserName: 'helooo', receiverEmail:"hello@gmail.com", receiverID: '123'),
                            //   targetTabIndex: 1,
                            // );
                          },
                          child: const Icon(
                            Icons.chat_outlined,
                            color: Constants.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  Text(
                    paket?.nama_paket ?? "Paket",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          size: 18, color: Colors.black54),
                      SizedBox(width: 8),
                      Text(
                        DateFormat('dd MMM yyyy')
                            .format(widget.pesananModel.tglRealisasi),
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 18, color: Colors.black54),
                      SizedBox(width: 8),
                      Text(
                        Helper.toLocalTime(widget.pesananModel.tglRealisasi),
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 18, color: Colors.black54),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "${widget.pesananModel.lokasi} - ${widget.pesananModel.namaKota}",
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 10),
                  // Timeline progress
                  buildTimelineItem(
                      "6 Mei 2024 13:00", "Pesanan diterima", true),
                  buildTimelineItem(
                      "7 Mei 2024 10:00", "Pemotretan dilakukan", true),
                  buildTimelineItem("7 Mei 2024 12:00",
                      "Pemotretan selesai dan file dikumpulkan", false),
                  buildTimelineItem("8 Mei 2024 09:00",
                      "Proses editing dimulai oleh tim desain", false),
                  buildTimelineItem("9 Mei 2024 17:00",
                      "Review internal hasil edit selesai", false),
                  buildTimelineItem("10 Mei 2024 11:00",
                      "Preview dikirim ke pelanggan untuk review", false),
                  buildTimelineItem("10 Mei 2024 14:00",
                      "Revisi diminta oleh pelanggan", false),
                  buildTimelineItem("11 Mei 2024 16:00",
                      "Revisi selesai dan diverifikasi", false),
                  buildTimelineItem("12 Mei 2024 10:00",
                      "File akhir disiapkan untuk dikirim", false),
                  buildTimelineItem("12 Mei 2024 15:00",
                      "Hasil akhir dikirim melalui email", false),
                  buildTimelineItem("13 Mei 2024 09:00",
                      "Pelanggan mengonfirmasi penerimaan hasil", false),
                  buildTimelineItem("13 Mei 2024 12:00",
                      "Feedback pelanggan diterima", false),
                  buildTimelineItem("14 Mei 2024 10:00",
                      "Testimoni pelanggan dipublikasikan", false),
                  buildTimelineItem(
                      "14 Mei 2024 12:00", "Project dinyatakan selesai", false,
                      isLast: true),
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
                      side: BorderSide(color: Constants.primaryColorVendor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                    child: Text(
                      'Ajukan Banding',
                      style: TextStyle(color: Constants.primaryColorVendor),
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
                      backgroundColor: Constants.primaryColorVendor,
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
                color: isActive
                    ? Constants.primaryColorVendor
                    : Colors.grey.shade400,
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
                    color: isActive
                        ? Constants.primaryColorVendor
                        : Colors.black54,
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
}
