import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/constants/helper.dart';
import 'package:mpjnew/src/core/constants/status_progres_constant.dart';
import 'package:mpjnew/src/core/routing/navigation_provider.dart';
import 'package:mpjnew/src/core/utils/shimmer_placeholder.dart';
import 'package:mpjnew/src/data/models/metode_pembayaran_model.dart';
import 'package:mpjnew/src/data/hive_entity/paket_model.dart';
import 'package:mpjnew/src/data/hive_entity/pesanan_model.dart';
import 'package:mpjnew/src/data/models/ulasan_model.dart';
import 'package:mpjnew/src/features/auth/services/user_provider.dart';
import 'package:mpjnew/src/features/customer/services/metode_pembayaran_service.dart';
import 'package:mpjnew/src/features/customer/services/paket_service.dart';
import 'package:mpjnew/src/features/customer/services/pesanan_service.dart';
import 'package:mpjnew/src/features/customer/services/ulasan_service.dart';
import 'package:mpjnew/src/features/customer/view/chat/room_chat_page.dart';
import 'package:mpjnew/src/features/customer/view/history/detail_order_shimmer.dart';
import 'package:mpjnew/src/features/customer/view/history/webview_page.dart';
import 'package:mpjnew/src/features/customer/viewmodels/history_order_provider.dart';
import 'package:mpjnew/src/features/customer/viewmodels/pesanan_provider.dart';
import 'package:mpjnew/src/features/customer/widget/custom_back_button.dart';
import 'package:mpjnew/src/features/customer/widget/dialog/custom_snackbar.dart';
import 'package:mpjnew/src/features/customer/widget/dialog/revisi_dialog.dart';
import 'package:mpjnew/src/features/customer/widget/dialog/selesaikan_dialog.dart';
import 'package:mpjnew/src/features/customer/widget/dialog/ulasan_dialog.dart';
import 'package:provider/provider.dart';

class DetailOrderPage extends StatefulWidget {
  final PesananModel pesananModel;
  const DetailOrderPage({super.key, required this.pesananModel});

  @override
  State<DetailOrderPage> createState() => _DetailOrderPageState();
}

class _DetailOrderPageState extends State<DetailOrderPage> {
  UlasanModel? ulasan;
  PaketModel? paket;
  PesananModel? pesanan;
  MetodePembayaranModel? metodePembayaran;

  bool isLoading = false;
  String error = '';

  // State untuk expand/collapse
  bool isPaymentExpanded = false;
  bool isPackageExpanded = false;
  bool isProgressExpanded = true;

  int _previousHistoryCount = 0;

  // =========================================
  // 🆕 CALLBACK SAAT HISTORY BERUBAH
  // =========================================
  void _onHistoryChanged() {
    if (!mounted) return;
    final historyProvider = context.read<HistoryOrderProvider>();
    final currentHistory =
        historyProvider.getHistoryForOrder(widget.pesananModel.noBukti);

    debugPrint(
        '[DetailOrderPage] 🔔 History count changed: $_previousHistoryCount → ${currentHistory.length}');

    // 🔥 FETCH ULANG DATA
    debugPrint('[DetailOrderPage] 🔄 Fetching updated data...');
    _fetchUpdatedData();

    // Optional: Show notification to user
    // if (currentHistory.isNotEmpty) {
    //   final latestProgress = currentHistory.first;

    //   // Use WidgetsBinding to ensure we're not in build phase
    //   WidgetsBinding.instance.addPostFrameCallback((_) {
    //     if (mounted) {
    //       CustomSnackbar.showSuccessSnackbar(
    //           context, 'Progress baru: ${latestProgress.deskripsi}');
    //     }
    //   });
    // }
  }

  // 🆕 Separate method untuk fetch updated data
  Future<void> _fetchUpdatedData() async {
    if (!mounted) return;

    try {
      debugPrint('[DetailOrderPage] 📥 Fetching updated pesanan...');

      final updatedPesanan =
          await PesananService().getAll(noBukti: pesanan!.noBukti);

      if (updatedPesanan.isNotEmpty && mounted) {
        setState(() {
          pesanan = updatedPesanan.first;
        });

        debugPrint(
            '[DetailOrderPage] ✅ Pesanan updated: ${pesanan!.statusProgresPesanan}');

        // Jika status selesai, fetch ulasan baru
        if (pesanan!.statusProgresPesanan?.toLowerCase() == 'selesai') {
          debugPrint('[DetailOrderPage] 📝 Fetching ulasan...');
          final ulasanList =
              await UlasanService().getAll(noOrder: pesanan!.noBukti);

          if (mounted) {
            setState(() {
              ulasan = ulasanList.isNotEmpty ? ulasanList.first : null;
            });

            if (ulasan != null) {
              debugPrint('[DetailOrderPage] ✅ Ulasan loaded');
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[DetailOrderPage] ❌ Error fetching updated data: $e');
      if (mounted) {
        CustomSnackbar.showErrorSnackbar(context, 'Gagal memuat data terbaru');
      }
    }
  }

  // Fetch data histori order
  Future<void> fetchData() async {
    try {
      setState(() {
        isLoading = true;
        error = '';
      });

      final historyProvider = context.read<HistoryOrderProvider>();
      pesanan = widget.pesananModel;

      // Fetch history (ini akan otomatis dipanggil setelah join berhasil di provider,
      // tapi kita tetap panggil untuk memastikan)
      if (pesanan != null) {
        await historyProvider.fetchHistoryForOrder(pesanan!.noBukti);

        paket = (await PaketService().getAll(noId: pesanan!.idPaket)).first;

        final ulasanList =
            await UlasanService().getAll(noOrder: pesanan!.noBukti);
        ulasan = ulasanList.isNotEmpty ? ulasanList.first : null;

        final metodePembayaranList = await MetodePembayaranService()
            .getAll(caraBayar: pesanan!.metodeBayar);
        metodePembayaran =
            metodePembayaranList.isNotEmpty ? metodePembayaranList.first : null;
      }
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
    final pesananProvider = context.read<PesananProvider>();
    showDialog(
      context: context,
      builder: (context) => SelesaikanDialog(
        pesanan: pesanan!,
        onSuccess: () async {
          await fetchData();
          await pesananProvider.loadOrder(
              userId: context.read<UserProvider>().userId ?? '');
          Navigator.pop(context);
        },
      ),
    );
  }

  // =====================================================
  // 📝 SHOW REVISI DIALOG
  // =====================================================
  void _showUlasanDialog() {
    showDialog(
      context: context,
      builder: (context) => UlasanDialog(
        pesanan: pesanan!,
        onSuccess: () async {
          final ulasanList =
              await UlasanService().getAll(noOrder: pesanan!.noBukti);
          ulasan = ulasanList.isNotEmpty ? ulasanList.first : null;
          fetchUpdatePesanan();
          setState(() {});
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchData();
    });
  }

  @override
  void dispose() {
    if (pesanan != null) {
      // Gunakan Provider.of dengan listen: false
      try {
        final historyProvider =
            Provider.of<HistoryOrderProvider>(context, listen: false);
        historyProvider.leaveOrder(pesanan!.noBukti);
      } catch (e) {
        debugPrint('Error leaving order: $e');
      }
    }
    super.dispose();
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
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: pesanan!.statusBayar ==
                                                "settlement"
                                            ? Colors.green.shade50
                                            : Colors.orange.shade50,
                                        borderRadius:
                                            BorderRadius.circular(6),
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
                          label: "Nomor Bukti",
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
                          Helper.formatCurrency(pesanan!.subtotal -
                              (metodePembayaran?.fee ?? 0)),
                        ),
                        const SizedBox(height: 6),
                        _buildPriceRow(
                          "Biaya admin",
                          Helper.formatCurrency(metodePembayaran?.fee ?? 0),
                        ),
                        const SizedBox(height: 8),
                        // _buildPriceRow(
                        //   "DPP (Dasar Pengenaan Pajak)",
                        //   Helper.formatCurrency(pesanan!.totDpp?.toInt() ?? 0),
                        // ),
                        // const SizedBox(height: 8),
                        // _buildPriceRow(
                        //   "PPN ${pesanan!.ppn ?? 11}%",
                        //   Helper.formatCurrency(pesanan!.totPpn ?? 0),
                        // ),
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
                  /// 📊 PROGRESS PESANAN (Expandable) - 🆕 REAL-TIME
                  /// =======================
                  _buildProgressSection(),
    
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
                                color:
                                    Constants.primaryColor.withOpacity(0.1),
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
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // =========================================
  // 🆕 REAL-TIME PROGRESS SECTION
  // =========================================
  Widget _buildProgressSection() {
    return Consumer<HistoryOrderProvider>(
      builder: (context, historyProvider, child) {
        final historyOrder =
            historyProvider.getHistoryForOrder(pesanan!.noBukti);
        final isLoadingHistory =
            historyProvider.isLoadingOrder(pesanan!.noBukti);
        final error = historyProvider.getErrorForOrder(pesanan!.noBukti);

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (historyOrder.length != _previousHistoryCount) {
            debugPrint('[DetailOrderPage] 🔔 History changed in Consumer');
            _previousHistoryCount = historyOrder.length;

            if (historyOrder.isNotEmpty) {
              _onHistoryChanged();
            }
          }
        });

        // Show shimmer while loading initial data
        if (isLoadingHistory && historyOrder.isEmpty) {
          return _buildProgressShimmer();
        }

        // Show error if any
        if (error != null && historyOrder.isEmpty) {
          return _buildProgressError(error);
        }

        return _buildExpandableCard(
          title: "Progress Pesanan",
          isExpanded: isProgressExpanded,
          onToggle: () {
            setState(() {
              isProgressExpanded = !isProgressExpanded;
            });
          },
          summaryWidget: !isProgressExpanded && historyOrder.isNotEmpty
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
                      // 🆕 Real-time indicator
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: Colors.green.shade200,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Live',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
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
                        "${Helper.formatTanggal(history.tglProgress)}, ${Helper.toLocalTime(history.tglProgress)}",
                        history.deskripsi,
                        history.statusProgressPesanan,
                        index == 0,
                        isLast: index == historyOrder.length - 1,
                      );
                    },
                  ),
                ),
        );
      },
    );
  }

  // =========================================
  // 🆕 PROGRESS SHIMMER
  // =========================================
  Widget _buildProgressShimmer() {
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
          Container(
            height: 20,
            width: 150,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(3, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 12,
                          width: 80,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // =========================================
  // 🆕 PROGRESS ERROR
  // =========================================
  Widget _buildProgressError(String errorMessage) {
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
        children: [
          Icon(
            Icons.error_outline,
            size: 60,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            "Gagal memuat progress",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            errorMessage,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              context.read<HistoryOrderProvider>().fetchHistoryForOrder(
                    pesanan!.noBukti,
                  );
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Constants.primaryColorVendor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
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
    final isFinishStatus =
        pesanan!.statusProgresPesanan?.toLowerCase() == 'selesai';

    final currentStatus = pesanan!.statusProgresPesanan?.toLowerCase() ?? '';
    final statusData = StatusProgresConstant.statusOptions.firstWhere(
      (s) => s['value'] == currentStatus,
      orElse: () => {
        'color': Constants.primaryColorVendor,
        'icon': Icons.hourglass_empty_rounded,
      },
    );
    final Color statusColor = statusData['color'] as Color;
    final IconData statusIcon = statusData['icon'] as IconData;

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
              (pesanan!.idMediaVendor != null && pesanan!.idMediaVendor != "")
                  ? CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.grey.shade300,
                      child: CachedNetworkImage(
                        imageUrl: pesanan!.idMediaVendor!,
                        imageBuilder: (context, imageProvider) => CircleAvatar(
                          radius: 36,
                          backgroundImage: imageProvider,
                        ),
                        placeholder: (context, url) => ShimmerPlaceholder(
                          radius: 36,
                        ),
                        errorWidget: (context, url, error) =>
                            const CircleAvatar(
                          radius: 36,
                          backgroundColor: Colors.grey,
                          child:
                              Icon(Icons.person, color: Colors.white, size: 18),
                        ),
                      ),
                    )
                  : Container(
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
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: statusColor, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            statusIcon,
                            size: 14,
                            color: statusColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            Helper.capitalizeFirst(
                              pesanan!.statusProgresPesanan ?? '',
                            ),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
                          ),
                        ],
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
                          RoomChatPage(
                            partnerId: pesanan!.idVendor,
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
                        SizedBox(
                          width: double.infinity,
                          child: InkWell(
                            onTap: () {
                              context.read<NavigationProvider>().navigateToPage(
                                    context,
                                    targetTabIndex: 2,
                                    WebviewPage(
                                      url: pesanan!.linkUrl!,
                                    ),
                                  );
                            },
                            child: Text(
                              pesanan!.linkUrl!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: Constants.primaryColorVendor,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
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

          if (isFinishStatus) ...[
            const SizedBox(height: 10),
            const Divider(),
            const SizedBox(height: 6),

            // Cek apakah sudah ada ulasan atau belum
            if (ulasan != null)
              _buildUlasanCard()
            else
              _buildBeriUlasanButton(),
          ],
        ],
      ),
    );
  }

  Widget _buildBeriUlasanButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _showUlasanDialog(),
        icon: const Icon(Icons.rate_review_outlined, size: 18),
        label: const Text(
          'Berikan Ulasan',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: Constants.primaryColor,
          side: BorderSide(color: Constants.primaryColor, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Widget _buildUlasanCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Constants.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.rate_review_rounded,
                  color: Constants.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ulasan Anda',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${Helper.formatTanggal(ulasan!.tglUlasan)}, ${Helper.toLocalTime(ulasan!.tglUlasan)}",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Rating Stars
          Row(
            children: [
              ...List.generate(5, (index) {
                return Icon(
                  index < ulasan!.rating
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  color: index < ulasan!.rating
                      ? Colors.amber
                      : Colors.grey.shade300,
                  size: 24,
                );
              }),
              const SizedBox(width: 8),
              Text(
                Helper.getRatingText(ulasan!.rating),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Helper.getRatingColor(ulasan!.rating),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Isi Ulasan
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              ulasan!.isiUlasan,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade800,
                height: 1.5,
              ),
            ),
          ),

          // Balasan Vendor (jika ada)
          if (ulasan!.adaBalasan == true &&
              ulasan!.isiBalasan != null &&
              ulasan!.isiBalasan!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.reply_rounded,
                        size: 16,
                        color: Colors.blue.shade700,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Balasan Vendor',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      const Spacer(),
                      if (ulasan!.tglBalasan != null)
                        Text(
                          Helper.formatTanggal(ulasan!.tglBalasan!),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blue.shade600,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ulasan!.isiBalasan!,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blue.shade800,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
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
    String status,
    bool isActive, {
    bool isLast = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Timeline indicator
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
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: Colors.grey.shade300,
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
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
                    // Content
                    if (status.toLowerCase() == "revisi")
                      _buildRevisionCard(description)
                    else
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

  // ✅ Revision card - clean & simple
  Widget _buildRevisionCard(String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Row(
          children: [
            Icon(
              Icons.edit_outlined,
              size: 14,
              color: Colors.orange.shade600,
            ),
            const SizedBox(width: 4),
            Text(
              "Catatan revisi anda:",
              style: TextStyle(
                fontSize: 13,
                color: Colors.orange.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Content box
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border(
              left: BorderSide(
                color: Colors.orange.shade400,
                width: 3,
              ),
            ),
          ),
          child: Text(
            description,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade800,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
