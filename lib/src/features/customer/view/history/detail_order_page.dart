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
import 'package:mpjnew/src/features/customer/view/chat/room_chat_page.dart';
import 'package:mpjnew/src/features/customer/view/history/detail_order_shimmer.dart';
import 'package:mpjnew/src/features/customer/view/vendor_bio_page.dart';
import 'package:mpjnew/src/features/customer/widget/custom_back_button.dart';
import 'package:mpjnew/src/features/customer/widget/dialog/confirm_dialog.dart';
import 'package:mpjnew/src/features/customer/widget/dialog/custom_dialog.dart';
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
      error = e.toString();
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
    print("Jumlah History Order: ${historyOrder.length}");

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
      body: Builder(
        builder: (context) {
          if (isLoading) {
            return DetailOrderShimmer(fetchData: fetchData);
          }

          return RefreshIndicator(
            onRefresh: fetchData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Column(
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
                                      errorWidget: (context, url, error) =>
                                          Icon(
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
                                      RoomChatPage(
                                        partnerId: vendor?.noId,
                                      ),
                                      targetTabIndex: 1,
                                    );
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

                      _buildCardSection(
                        title: "Detail Pesanan",
                        icon: Icons.receipt_long_rounded,
                        content: Column(
                          children: [
                            _buildDetailRow(
                              "No. Pesanan",
                              widget.pesananModel.noBukti,
                              copyable: true,
                            ),
                            const SizedBox(height: 12),
                            _buildDetailRow(
                              "No. Tracking",
                              widget.pesananModel.noTrackingPesanan ?? "",
                              copyable: true,
                            ),
                            const SizedBox(height: 12),
                            _buildDetailRow(
                              "Paket",
                              widget.pesananModel.namaPaket,
                            ),
                            const SizedBox(height: 12),
                            _buildDetailRow(
                              "Tanggal Realisasi",
                              DateFormat("dd MMM yyyy", "id_ID")
                                  .format(widget.pesananModel.tglRealisasi),
                            ),
                            const SizedBox(height: 12),
                            _buildDetailRow(
                              "Lokasi",
                              "${widget.pesananModel.lokasi}, ${widget.pesananModel.namaKota}",
                            ),
                            const SizedBox(height: 12),
                            _buildDetailRow(
                                "Total (termasuk PPN)",
                                Helper.formatCurrency(
                                    widget.pesananModel.harga)),
                            const SizedBox(height: 12),
                            // Action Buttons
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () {
                                      // Aksi Ajukan Banding
                                    },
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(
                                          color: Constants.primaryColorVendor),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14),
                                    ),
                                    child: Text(
                                      'Ajukan Banding',
                                      style: TextStyle(
                                        color: Constants.primaryColorVendor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      // Aksi Pesanan Selesai

                                      ConfirmDialog.showSelesaikanPesananDialog(
                                        context: context,
                                        onConfirm: () async {
                                          final historySelesaikanPesanan =
                                              HistoryOrderService.createSelesai(
                                            noOrder:
                                                widget.pesananModel.noBukti,
                                            senderId:
                                                widget.pesananModel.idCustomer,
                                          );

                                          await historyOrderService
                                              .create(historySelesaikanPesanan);

                                          if (!mounted) return;

                                          Navigator.pop(context);
                                        },
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          Constants.primaryColorVendor,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: const Text(
                                      'Selesaikan',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      _buildCardSection(
                        title: "Progress Pesanan",
                        icon: Icons.history_edu_rounded,
                        content: historyOrder.isEmpty
                            ? Column(
                                children: [
                                  Icon(
                                    Icons.timeline_rounded,
                                    size: 100,
                                    color: Colors.grey.shade400,
                                  ),
                                  Center(
                                    child: Text(
                                      "Belum ada history progress pesanan",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                ],
                              )
                            : Column(
                                children: List.generate(
                                  historyOrder.length,
                                  (index) {
                                    final history = historyOrder[index];

                                    return buildTimelineItem(
                                      DateFormat("dd MMM yyyy")
                                          .format(history.tglProgress),
                                      history.deskripsi,
                                      index == 0,
                                    );
                                  },
                                ),
                              ),
                      )
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCardSection({
    required String title,
    required IconData icon,
    required Widget content,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 22, color: Constants.primaryColorVendor),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool copyable = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (copyable)
                InkWell(
                  onTap: () => Helper.copyToClipboard(context, value, label),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.copy_rounded,
                      size: 18,
                      color: Constants.primaryColorVendor,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
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
