import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/constants/custom_icons.dart';
import 'package:mpjnew/src/core/constants/helper.dart';
import 'package:mpjnew/src/core/routing/navigation_provider.dart';
import 'package:mpjnew/src/core/utils/shimmer_placeholder.dart';
import 'package:mpjnew/src/data/models/metode_pembayaran_model.dart';
import 'package:mpjnew/src/data/models/penawaran_model.dart';
import 'package:mpjnew/src/data/models/pesanan_model.dart';
import 'package:mpjnew/src/features/customer/services/metode_pembayaran_service.dart';
import 'package:mpjnew/src/features/customer/services/penawaran_service.dart';
import 'package:mpjnew/src/features/customer/services/pesanan_service.dart';
import 'package:mpjnew/src/features/customer/view/payment/waiting_payment_page.dart';
import 'package:mpjnew/src/features/customer/widget/custom_back_button.dart';
import 'package:mpjnew/src/features/customer/widget/dialog/custom_dialog.dart';
import 'package:mpjnew/src/features/customer/widget/dialog/custom_snackbar.dart';
import 'package:provider/provider.dart';

class DetailPembayaranPage extends StatefulWidget {
  final String penawaranId;
  const DetailPembayaranPage({super.key, required this.penawaranId});

  @override
  State<DetailPembayaranPage> createState() => _DetailPembayaranPageState();
}

class _DetailPembayaranPageState extends State<DetailPembayaranPage> {
  PenawaranService penawaranService = PenawaranService();
  PesananService pesananService = PesananService();
  MetodePembayaranService metodePembayaranService = MetodePembayaranService();
  PenawaranModel? penawaran;
  List<MetodePembayaranModel> metodePembayaran = [];
  bool isLoading = false;
  String? errorMessage;

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
    getPenawaran(widget.penawaranId);
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> getPenawaran(String id) async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      await getMetodePembayaran();

      final result = await penawaranService.getAll(noId: id);

      if (result.isEmpty) {
        throw Exception("Penawaran kosong");
      }

      penawaran = result.first;

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

      CustomSnackbar.showSuccessSnackbar(
        context,
        "Pesanan berhasil dibuat, segera selesaikan pembayaran",
      );

      /// 🔥 NAVIGASI DARI DATA NYATA
      context.read<NavigationProvider>().navigateToPage(
            context,
            targetTabIndex: 2,
            WaitingPaymentPage(paymentData: pesanan.first),
          );
    } catch (e) {
      errorMessage = e.toString();
      CustomSnackbar.showErrorSnackbar(context, errorMessage!);
    } finally {
      setState(() {
        isLoading = false; // ✅ FIX
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F9F9),
        elevation: 0,
        leading: CustomBackButton(),
        title: const Text(
          "Detail Penawaran",
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
                    onPressed: () => getPenawaran(widget.penawaranId),
                    child: const Text("Coba Lagi"),
                  )
                ],
              ),
            );
          }

          /// =======================
          /// 3️⃣ EMPTY STATE
          /// =======================
          if (penawaran == null) {
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
                      _buildCardSection(
                        title: penawaran!.namaPaket,
                        content: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today_outlined,
                                    size: 18, color: Colors.black54),
                                const SizedBox(width: 8),
                                Text(tanggal),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.access_time,
                                    size: 18, color: Colors.black54),
                                const SizedBox(width: 8),
                                Text(waktu),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.location_on_outlined,
                                    size: 18, color: Colors.black54),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "${penawaran!.lokasi}, ${penawaran!.namaKota}",
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      penawaran!.noPesanan == ""
                          ? _buildCardSection(
                              title: "Metode Pembayaran",
                              isRequired: true,
                              content: GestureDetector(
                                onTap: () =>
                                    CustomDialog.showPaymentMethodDialog(
                                  context: context,
                                  metodePembayaran:
                                      metodePembayaran, // List dari model Anda
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
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      )
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            CustomIcons.getMetodeIcon(
                                                kodeMetode ?? ""),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            textMetode ??
                                                "Pilih Metode Pembayaran",
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                      const Icon(Icons.arrow_forward_ios,
                                          size: 16),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          : SizedBox(),
                      _buildCardSection(
                        title: "Ringkasan Pembayaran",
                        content: Column(
                          children: [
                            _buildPriceRow(
                              "Harga Paket (termasuk PPN)",
                              Helper.formatCurrency(hargaPaket),
                            ),
                            (kodeMetode != null)
                                ? Column(
                                    children: [
                                      const SizedBox(height: 8),
                                      _buildPriceRow(
                                        "Biaya Pembayaran",
                                        Helper.formatCurrency(biayaPembayaran),
                                      ),
                                    ],
                                  )
                                : Container(),
                            const SizedBox(height: 8),
                            _buildPriceRow(
                              "PPN 11%",
                              Helper.formatCurrency(biayaPPN),
                            ),
                            const Divider(height: 24),
                            _buildPriceRow(
                              "Total Pembayaran",
                              Helper.formatCurrency(totalPembayaran),
                              isBold: true,
                              valueColor: Constants.primaryColorVendor,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              /// =======================
              /// BOTTOM BAR
              /// =======================
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                decoration: const BoxDecoration(
                  color: Color(0xFFF9F9F9),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      offset: Offset(0, -2),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Text(
                          "Total Bayar",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        Text(
                          Helper.formatCurrency(totalPembayaran),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Constants.primaryColorVendor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kodeMetode == null
                              ? Colors.grey.shade300
                              : Constants.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: kodeMetode == null ? 0 : 2,
                        ),
                        onPressed: kodeMetode == null
                            ? null
                            : () async {
                                // Action bayar sekarang
                                await createPesanan();
                              },
                        child: Text(
                          penawaran!.noPesanan != ""
                              ? "Penawaran ini sudah ditutup"
                              : "Bayar Sekarang",
                          style: TextStyle(
                            color: kodeMetode == null
                                ? Colors.grey.shade600
                                : Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCardSection(
      {required String title,
      required Widget content,
      bool isRequired = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          isRequired
              ? Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(
                      width: 2,
                    ),
                    Text(
                      "*",
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.red),
                    ),
                  ],
                )
              : Text(
                  title,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold),
                ),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value,
      {bool isBold = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal),
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
}
