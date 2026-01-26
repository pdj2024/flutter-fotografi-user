import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/constants/custom_icons.dart';
import 'package:mpjnew/src/core/constants/helper.dart';
import 'package:mpjnew/src/core/routing/navigation_provider.dart';
import 'package:mpjnew/src/core/utils/shimmer_placeholder.dart';
import 'package:mpjnew/src/data/hive_entity/penawaran_model.dart';
import 'package:mpjnew/src/data/models/metode_pembayaran_model.dart';
import 'package:mpjnew/src/data/hive_entity/paket_model.dart';
import 'package:mpjnew/src/data/hive_entity/pesanan_model.dart';
import 'package:mpjnew/src/features/customer/services/history_order_service.dart';
import 'package:mpjnew/src/features/customer/services/metode_pembayaran_service.dart';
import 'package:mpjnew/src/features/customer/services/paket_service.dart';
import 'package:mpjnew/src/features/customer/services/penawaran_service.dart';
import 'package:mpjnew/src/features/customer/services/pesanan_service.dart';
import 'package:mpjnew/src/features/customer/view/page_wrapper.dart';
import 'package:mpjnew/src/features/customer/view/payment/waiting_payment_page.dart';
import 'package:mpjnew/src/features/customer/viewmodels/chat_provider.dart';
import 'package:mpjnew/src/features/customer/widget/custom_back_button.dart';
import 'package:mpjnew/src/features/customer/widget/dialog/custom_dialog.dart';
import 'package:mpjnew/src/features/customer/widget/dialog/custom_snackbar.dart';
import 'package:provider/provider.dart';

class DetailPembayaranPage extends StatefulWidget {
  final String penawaranId;
  final String chatId;
  const DetailPembayaranPage(
      {super.key, required this.penawaranId, required this.chatId});

  @override
  State<DetailPembayaranPage> createState() => _DetailPembayaranPageState();
}

class _DetailPembayaranPageState extends State<DetailPembayaranPage> {
  PenawaranService penawaranService = PenawaranService();
  PaketService paketService = PaketService();
  HistoryOrderService historyOrderService = HistoryOrderService();
  PesananService pesananService = PesananService();
  MetodePembayaranService metodePembayaranService = MetodePembayaranService();
  List<MetodePembayaranModel> metodePembayaran = [];
  bool isLoading = false;
  String? errorMessage;

  bool _isExpanded = true;
  bool isPackageExpanded = true;

  PenawaranModel? penawaran;
  PaketModel? paket;

  String? kodeMetode;
  String? textMetode;
  int hargaPaket = 0;
  int biayaPembayaran = 0;
  int biayaPPN = 0;
  int biayaDPP = 0;
  int totalPembayaran = 0;

  @override
  void initState() {
    super.initState();
    getData(widget.penawaranId);
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> getData(String id) async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      await getMetodePembayaran();

      final resultPenawaran = await penawaranService.getAll(noId: id);
      if (resultPenawaran.isEmpty) {
        throw Exception("Penawaran kosong");
      }
      penawaran = resultPenawaran.first;

      final resultPaket = await paketService.getAll(noId: penawaran!.idPaket);
      if (resultPaket.isEmpty) {
        throw Exception("Paket kosong");
      }
      paket = resultPaket.first;

      setHarga();
    } catch (e) {
      errorMessage = "Data penawaran tidak ditemukan atau sudah tidak aktif";
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void setHarga() {
    biayaDPP = (penawaran!.harga / 1.11).round();
    hargaPaket = penawaran!.harga;
    totalPembayaran = hargaPaket + biayaPembayaran;
    biayaPPN = totalPembayaran - biayaDPP;
    setState(() {});
  }

  Future<void> getMetodePembayaran() async {
    try {
      final result = await metodePembayaranService.getAll(
          status: "aktif", orderBy: "cara_bayar", orderDir: "asc");

      if (result.isEmpty) {
        throw Exception("Metode pembayaran kosong");
      }

      metodePembayaran = result;
      setState(() {});
    } catch (e) {
      errorMessage = "Metode pembayaran tidak ditemukan";
    }
  }

  Future<void> createPesanan() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      if (penawaran == null) return;

      final newPesanan = PesananModel(
        noBukti: "new",
        noPenawaran: penawaran!.noId,
        idVendor: penawaran!.idVendor,
        idCustomer: penawaran!.idCustomer,
        idPaket: penawaran!.idPaket,
        namaPaket: penawaran!.namaPaket,
        kota: penawaran!.kota,
        harga: totalPembayaran,
        lokasi: penawaran!.lokasi,
        tglRealisasi: penawaran!.tglRealisasi,
        status: "aktif",
        statusBayar: null,
        metodeBayar: kodeMetode,
        idPaymentGateway: null,
        subtotal: 0,
        grandTotal: 0,
      );

      final result = await pesananService.create(newPesanan);

      final pesanan = await pesananService.getAll(noBukti: result.noBukti);

      final historyMenungguBayar = HistoryOrderService.createMenungguPembayaran(
        noOrder: result.noBukti,
        senderId: pesanan.first.idCustomer,
      );

      // await context.read<ChatProvider>().updatePenawaranToPesanan(roomId, noPenawaran, noPesanan);

      await historyOrderService.create(historyMenungguBayar);

      CustomSnackbar.showSuccessSnackbar(
        context,
        "Pesanan berhasil dibuat, segera selesaikan pembayaran",
      );

      /// 🔥 NAVIGASI DARI DATA NYATA
      context.read<NavigationProvider>().navigateToPage(
            context,
            targetTabIndex: 2,
            WaitingPaymentPage(
              paymentData: pesanan.first,
            ),
          );
    } catch (e) {
      errorMessage = e.toString();
      CustomSnackbar.showErrorSnackbar(context, errorMessage!);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FullScreenPage(
      child: Scaffold(
        backgroundColor: const Color(0xFFF9F9F9),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            "Detail Pembayaran",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
        ),
        body: Builder(
          builder: (context) {
            /// =======================
            /// 1️⃣ LOADING STATE
            /// =======================
            if (isLoading) {
              return Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: const [
                    ShimmerPlaceholder(
                      height: 140,
                      width: double.infinity,
                      radius: 12,
                    ),
                    SizedBox(height: 16),
                    ShimmerPlaceholder(
                        height: 100, width: double.infinity, radius: 12),
                    SizedBox(height: 16),
                    ShimmerPlaceholder(
                        height: 80, width: double.infinity, radius: 12),
                  ],
                ),
              );
            }
      
            /// =======================
            /// 2️⃣ ERROR STATE
            /// =======================
            if (errorMessage != null) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 12),
                    Text(
                      errorMessage!,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => getData(widget.penawaranId),
                      child: const Text("Coba Lagi"),
                    )
                  ],
                ),
              );
            }
      
            /// =======================
            /// 3️⃣ EMPTY STATE
            /// =======================
            if (penawaran == null || paket == null) {
              return const Center(
                child: Text("Data penawaran tidak tersedia"),
              );
            }
      
            /// =======================
            /// 4️⃣ SUCCESS STATE
            /// =======================
            final tanggal = DateFormat("dd MMM yyyy", "id_ID")
                .format(penawaran!.tglRealisasi);
            final waktu = Helper.toLocalTime(penawaran!.tglRealisasi);
      
            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// =======================
                        /// 📋 INFORMASI PENAWARAN
                        /// =======================
                        _buildCardSection(
                          title: "Informasi Penawaran",
                          content: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInfoRow(
                                icon: Icons.confirmation_number_outlined,
                                label: "No. Tracking",
                                value: penawaran!.noTrackingPenawaran,
                              ),
                              const SizedBox(height: 12),
                              _buildInfoRow(
                                icon: Icons.person_outline,
                                label: "Customer",
                                value: penawaran!.namaCustomer,
                              ),
                              const SizedBox(height: 12),
                              _buildInfoRow(
                                icon: Icons.store_outlined,
                                label: "Vendor",
                                value: penawaran!.namaVendor,
                              ),
                              const SizedBox(height: 12),
                              _buildInfoRow(
                                icon: Icons.notes_outlined,
                                label: "Deskripsi",
                                value: penawaran!.deskripsi,
                              ),
                            ],
                          ),
                        ),
      
                        /// =======================
                        /// 💳 METODE PEMBAYARAN
                        /// =======================
                        if (penawaran!.noPesanan.isEmpty)
                          _buildCardSection(
                            title: "Metode Pembayaran",
                            isRequired: true,
                            content: GestureDetector(
                              onTap: () => CustomDialog.showPaymentMethodDialog(
                                context: context,
                                metodePembayaran: metodePembayaran,
                                currentKodeMetode: kodeMetode,
                                onSelected: (kode, text, fee) {
                                  setState(() {
                                    kodeMetode = kode;
                                    textMetode = text;
                                    biayaPembayaran = fee;
                                  });
                                  setHarga();
                                },
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: kodeMetode == null
                                      ? Colors.grey.shade50
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: kodeMetode == null
                                        ? Colors.grey.shade300
                                        : Constants.primaryColor,
                                    width: kodeMetode == null ? 1 : 2,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: kodeMetode == null
                                                ? Colors.grey.shade200
                                                : Constants.primaryColor
                                                    .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            CustomIcons.getMetodeIcon(
                                                kodeMetode ?? ""),
                                            size: 24,
                                            color: kodeMetode == null
                                                ? Colors.grey.shade600
                                                : Constants.primaryColor,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          textMetode ?? "Pilih Metode Pembayaran",
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: kodeMetode == null
                                                ? Colors.grey.shade600
                                                : Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      size: 16,
                                      color: Colors.grey.shade600,
                                    ),
                                  ],
                                ),
                              ),
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                          Helper.formatCurrency(penawaran!.harga),
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
                                value: penawaran!.namaKota,
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                          penawaran!.lokasi,
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
                      ],
                    ),
                  ),
                ),
      
                /// =======================
                /// 💰 BOTTOM BAR - RINGKASAN
                /// =======================
      
                _buildExpandableBottomBar(),
              ],
            );
          },
        ),
      ),
    );
  }

  /// =======================
  /// 🎨 WIDGET BUILDERS
  /// =======================

  Widget _buildCardSection({
    required String title,
    required Widget content,
    bool isRequired = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isRequired) ...[
                const SizedBox(width: 4),
                const Text(
                  "*",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
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
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
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
            color: Colors.black87,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
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

  /// =======================
  /// 🔽 EXPANDABLE BOTTOM BAR
  /// =======================
  Widget _buildExpandableBottomBar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -2),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// =======================
          /// Header dengan Toggle Button
          /// =======================
          GestureDetector(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isExpanded ? "Ringkasan Pembayaran" : "Total Pembayaran",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Row(
                  children: [
                    if (!_isExpanded)
                      Text(
                        Helper.formatCurrency(totalPembayaran),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Constants.primaryColorVendor,
                        ),
                      ),
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      duration: const Duration(milliseconds: 300),
                      turns: _isExpanded ? 0.5 : 0,
                      child: Icon(
                        Icons.keyboard_arrow_up_rounded,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          /// =======================
          /// Detail Pembayaran (Expandable)
          /// =======================
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children: [
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 12),
                _buildPriceRow(
                  "Harga Paket (Termasuk PPN)",
                  Helper.formatCurrency(hargaPaket),
                ),
                if (kodeMetode != null) ...[
                  const SizedBox(height: 8),
                  _buildPriceRow(
                    "Biaya Pembayaran",
                    Helper.formatCurrency(biayaPembayaran),
                  ),
                ],
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                _buildPriceRow(
                  "Total Pembayaran",
                  Helper.formatCurrency(totalPembayaran),
                  isBold: true,
                  valueColor: Constants.primaryColorVendor,
                ),
              ],
            ),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),

          /// =======================
          /// Button Bayar Sekarang
          /// =======================
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kodeMetode == null
                    ? Colors.grey.shade300
                    : Constants.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: kodeMetode == null ? 0 : 2,
              ),
              onPressed: penawaran!.noPesanan.isNotEmpty
                  ? null
                  : kodeMetode == null
                      ? null
                      : () async {
                          await createPesanan();
                        },
              child: Text(
                penawaran!.noPesanan.isNotEmpty
                    ? "Penawaran Sudah Ditutup"
                    : "Bayar Sekarang",
                style: TextStyle(
                  color:
                      kodeMetode == null ? Colors.grey.shade600 : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
