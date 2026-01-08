import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/constants/helper.dart';
import 'package:mpjnew/src/core/routing/navigation_provider.dart';
import 'package:mpjnew/src/data/models/history_order_model.dart';
import 'package:mpjnew/src/data/models/paket_model.dart';
import 'package:mpjnew/src/data/models/pesanan_model.dart';
import 'package:mpjnew/src/data/models/vendor_model.dart';
import 'package:mpjnew/src/features/auth/services/user_provider.dart';
import 'package:mpjnew/src/features/customer/services/history_order_service.dart';
import 'package:mpjnew/src/features/customer/services/paket_service.dart';
import 'package:mpjnew/src/features/customer/services/pesanan_service.dart';
import 'package:mpjnew/src/features/customer/services/vendor_service.dart';
import 'package:mpjnew/src/features/customer/view/chat/room_chat_page.dart';
import 'package:mpjnew/src/features/customer/view/history/detail_order_shimmer.dart';
import 'package:mpjnew/src/features/customer/viewmodels/pesanan_provider.dart';
import 'package:mpjnew/src/features/customer/widget/custom_back_button.dart';
import 'package:mpjnew/src/features/customer/widget/dialog/custom_snackbar.dart';
import 'package:mpjnew/src/features/customer/widget/dialog/revisi_dialog.dart';
import 'package:mpjnew/src/features/customer/widget/dialog/selesaikan_dialog.dart';
import 'package:provider/provider.dart';

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
  PesananModel? pesanan;

  bool isLoading = false;
  String error = '';

  // State untuk expand/collapse
  bool isPaymentExpanded = false;
  bool isPackageExpanded = false;
  bool isProgressExpanded = true;

  // Fetch data histori order
  Future<void> fetchData() async {
    try {
      setState(() {
        isLoading = true;
        error = '';
      });

      pesanan = widget.pesananModel;

      historyOrder = await historyOrderService.getAll(
        noOrder: widget.pesananModel.noBukti,
        orderBy: 'Tgl_Progress',
        orderDir: 'desc',
      );

      paket = (await PaketService().getAll(noId: widget.pesananModel.idPaket))
          .first;

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

  Future<void> fetchUpdatePesanan() async {
    try {
      setState(() {
        isLoading = true;
        error = '';
      });

      pesanan =
          (await PesananService().getAll(noBukti: pesanan!.noBukti)).first;
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

  // =====================================================
  // 📝 SHOW REVISI DIALOG
  // =====================================================
  void _showRevisiDialog() {
    showDialog(
      context: context,
      builder: (context) => RevisiDialog(
        pesanan: pesanan!,
        onSuccess: () async {
          await fetchData();
          await fetchUpdatePesanan();
        },
      ),
    );
  }

  // =====================================================
  // ✅ SHOW SELESAIKAN DIALOG
  // =====================================================
  void _showSelesaikanDialog() {
    showDialog(
      context: context,
      builder: (context) => SelesaikanDialog(
        pesanan: pesanan!,
        onSuccess: () async {
          await fetchData();
          await context
              .read<PesananProvider>()
              .loadOrder(userId: context.read<UserProvider>().userId ?? '');
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  @override
  Widget build(BuildContext context) {
    final tanggal =
        DateFormat("dd MMM yyyy", "id_ID").format(pesanan!.tglRealisasi);
    final waktu = Helper.toLocalTime(pesanan!.tglRealisasi);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F9F9),
        elevation: 0,
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
            onRefresh: () async {
              await fetchData();
              await fetchUpdatePesanan();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Card dengan Chat Button
                  _buildProfileCard(),

                  const SizedBox(height: 16),

                  /// =======================
                  /// 📍 LOKASI & JADWAL
                  /// =======================
                  _buildCardSection(
                    title: "Lokasi & Jadwal",
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow(
                          icon: Icons.calendar_today_outlined,
                          label: "Tanggal",
                          value: tanggal,
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          icon: Icons.access_time,
                          label: "Waktu",
                          value: waktu,
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          icon: Icons.location_city_outlined,
                          label: "Kota",
                          value: pesanan!.namaKota ?? "-",
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 20,
                              color: Colors.black54,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Alamat Lengkap",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    pesanan!.lokasi,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  /// =======================
                  /// 📦 DETAIL PAKET (Expandable)
                  /// =======================
                  _buildExpandableCard(
                    title: "Detail Paket",
                    isExpanded: isPackageExpanded,
                    onToggle: () {
                      setState(() {
                        isPackageExpanded = !isPackageExpanded;
                      });
                    },
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Constants.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.card_giftcard,
                                color: Constants.primaryColor,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    paket!.nama_paket,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    Helper.formatCurrency(pesanan!.harga),
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Constants.primaryColorVendor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (paket!.rincian.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 12),
                          const Text(
                            "Rincian Paket:",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            paket!.rincian,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  /// =======================
                  /// 💳 INFORMASI & RINGKASAN PEMBAYARAN (Expandable)
                  /// =======================
                  _buildExpandableCard(
                    title: "Pembayaran",
                    isExpanded: isPaymentExpanded,
                    onToggle: () {
                      setState(() {
                        isPaymentExpanded = !isPaymentExpanded;
                      });
                    },
                    summaryWidget: !isPaymentExpanded
                        ? Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            pesanan!.statusBayar == "settlement"
                                                ? Colors.green.shade50
                                                : Colors.orange.shade50,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: pesanan!.statusBayar ==
                                                  "settlement"
                                              ? Colors.green.shade200
                                              : Colors.orange.shade200,
                                        ),
                                      ),
                                      child: Text(
                                        pesanan!.statusBayar == "settlement"
                                            ? "Sudah Bayar"
                                            : "Belum Bayar",
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: pesanan!.statusBayar ==
                                                  "settlement"
                                              ? Colors.green.shade700
                                              : Colors.orange.shade700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  Helper.formatCurrency(pesanan!.grandTotal),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Constants.primaryColorVendor,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : null,
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Informasi Pembayaran
                        const Text(
                          "Informasi Pembayaran",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          label: "No. Tracking",
                          value: pesanan!.noTrackingPesanan ?? "-",
                          icon: Icons.local_shipping_outlined,
                          copyable: true,
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          label: "Metode Pembayaran",
                          value: pesanan!.metodeBayar != null
                              ? pesanan!.metodeBayar!
                              : "-",
                          icon: Icons.account_balance_wallet_outlined,
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          label: "Status Pembayaran",
                          icon: Icons.schedule_outlined,
                          value: pesanan!.statusBayar == "settlement"
                              ? "Sudah Bayar"
                              : "Belum Bayar",
                          valueColor: pesanan!.statusBayar == "settlement"
                              ? Colors.green
                              : Colors.orange,
                        ),

                        const SizedBox(height: 20),
                        const Divider(),
                        const SizedBox(height: 16),

                        // Ringkasan Pembayaran
                        const Text(
                          "Ringkasan Pembayaran",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildPriceRow(
                          "Subtotal",
                          Helper.formatCurrency(pesanan!.subtotal),
                        ),
                        const SizedBox(height: 8),
                        _buildPriceRow(
                          "DPP (Dasar Pengenaan Pajak)",
                          Helper.formatCurrency(pesanan!.totDpp?.toInt() ?? 0),
                        ),
                        const SizedBox(height: 8),
                        _buildPriceRow(
                          "PPN ${pesanan!.ppn ?? 11}%",
                          Helper.formatCurrency(pesanan!.totPpn ?? 0),
                        ),
                        const Divider(height: 24),
                        _buildPriceRow(
                          "Total Pembayaran",
                          Helper.formatCurrency(pesanan!.grandTotal),
                          isBold: true,
                          valueColor: Constants.primaryColorVendor,
                        ),
                      ],
                    ),
                  ),

                  /// =======================
                  /// 📊 PROGRESS PESANAN (Expandable)
                  /// =======================
                  _buildExpandableCard(
                    title: "Progress Pesanan",
                    isExpanded: isProgressExpanded,
                    onToggle: () {
                      setState(() {
                        isProgressExpanded = !isProgressExpanded;
                      });
                    },
                    summaryWidget:
                        !isProgressExpanded && historyOrder.isNotEmpty
                            ? Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: Constants.primaryColorVendor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        historyOrder.first.deskripsi,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade700,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : null,
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
                              const SizedBox(height: 10),
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
                                  isLast: index == historyOrder.length - 1,
                                );
                              },
                            ),
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildExpandableCard({
    required String title,
    required bool isExpanded,
    required VoidCallback onToggle,
    required Widget content,
    Widget? summaryWidget,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                if (!isExpanded && summaryWidget != null) summaryWidget,
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: content,
                  ),
                  crossFadeState: isExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 200),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    final hasLinkUrl = pesanan!.linkUrl != null && pesanan!.linkUrl!.isNotEmpty;
    final isReviewStatus =
        pesanan!.statusProgresPesanan?.toLowerCase() == 'review';

    return Container(
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
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Constants.primaryColorVendor,
                      Constants.primaryColorVendor.withOpacity(0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    (pesanan!.namaVendor!.isEmpty
                            ? "V"
                            : pesanan!.namaVendor![0])
                        .toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
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
                      pesanan!.namaVendor ?? "Vendor",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Constants.primaryColorVendor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        Helper.capitalizeFirst(
                          pesanan!.statusProgresPesanan ?? '',
                        ),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Constants.primaryColorVendor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
                    context.read<NavigationProvider>().navigateToPage(
                          context,
                          RoomChatPage(partnerId: pesanan!.idCustomer),
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
          if (hasLinkUrl) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Constants.primaryColorVendor.withOpacity(0.1),
                    Constants.primaryColorVendor.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Constants.primaryColorVendor.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Constants.primaryColorVendor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.link_rounded,
                          size: 16,
                          color: Constants.primaryColorVendor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Link Hasil Kerja',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.grey.shade300,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pesanan!.linkUrl!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Constants.primaryColorVendor,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Helper.copyToClipboard(
                                    context,
                                    pesanan!.linkUrl!,
                                    'Link URL',
                                  );
                                },
                                icon: Icon(
                                  Icons.content_copy_rounded,
                                  size: 16,
                                  color: Constants.primaryColorVendor,
                                ),
                                label: const Text(
                                  'Salin',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Constants.primaryColorVendor,
                                  side: BorderSide(
                                    color: Constants.primaryColorVendor,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                    horizontal: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 12,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Link hasil kerja yang telah Anda upload',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          // ✅ TAMBAHAN: Review Actions
          if (isReviewStatus && hasLinkUrl) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),

            // Info Review
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: Colors.blue.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Silakan review hasil pekerjaan vendor',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Action Buttons
            Row(
              children: [
                // Button Revisi
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showRevisiDialog(),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text(
                      'Revisi',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Constants.primaryColorVendor,
                      side: BorderSide(
                          color: Constants.primaryColorVendor, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Button Selesaikan
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showSelesaikanDialog(),
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text(
                      'Selesaikan',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Constants.primaryColorVendor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCardSection({
    required String title,
    required Widget content,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color valueColor = Colors.black,
    bool copyable = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.black54,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                  if (copyable) ...[
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () =>
                          Helper.copyToClipboard(context, value, label),
                      child: Icon(
                        Icons.copy_rounded,
                        size: 20,
                        color: Constants.primaryColorVendor,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: valueColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget buildTimelineItem(
    String time,
    String description,
    bool isActive, {
    bool isLast = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
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
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            time,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                        if (onTap != null)
                          Icon(
                            Icons.more_vert_rounded,
                            size: 16,
                            color: Colors.grey.shade400,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: isActive
                            ? Constants.primaryColorVendor
                            : Colors.black54,
                        fontWeight:
                            isActive ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
