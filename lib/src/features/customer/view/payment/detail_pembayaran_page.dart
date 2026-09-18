import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/constants/custom_icons.dart';
import 'package:mpjnew/src/core/constants/helper.dart';
import 'package:mpjnew/src/core/routing/navigation_provider.dart';
import 'package:mpjnew/src/core/services/default_value_service.dart';
import 'package:mpjnew/src/core/utils/shimmer_placeholder.dart';
import 'package:mpjnew/src/data/hive_entity/penawaran_model.dart';
import 'package:mpjnew/src/data/models/chat_model.dart';
import 'package:mpjnew/src/data/models/default_value_model.dart';
import 'package:mpjnew/src/data/models/metode_pembayaran_model.dart';
import 'package:mpjnew/src/data/hive_entity/paket_model.dart';
import 'package:mpjnew/src/data/hive_entity/pesanan_model.dart';
import 'package:mpjnew/src/features/customer/services/history_order_service.dart';
import 'package:mpjnew/src/features/customer/services/metode_pembayaran_service.dart';
import 'package:mpjnew/src/features/customer/services/paket_service.dart';
import 'package:mpjnew/src/features/customer/services/penawaran_service.dart';
import 'package:mpjnew/src/features/customer/services/pesanan_service.dart';
import 'package:mpjnew/src/features/customer/view/history/webview_page.dart';
import 'package:mpjnew/src/features/customer/view/payment/waiting_payment_page.dart';
import 'package:mpjnew/src/features/customer/viewmodels/chat_provider.dart';
import 'package:mpjnew/src/features/customer/widget/dialog/custom_dialog.dart';
import 'package:mpjnew/src/features/customer/widget/dialog/custom_snackbar.dart';
import 'package:provider/provider.dart';

class DetailPembayaranPage extends StatefulWidget {
  final String? penawaranId;
  final ChatModel? message;

  /// Jika diisi, page bermode "ganti metode bayar" — skip fetch penawaran/paket.
  final String? existingNoBukti;

  const DetailPembayaranPage({
    super.key,
    this.penawaranId,
    this.message,
    this.existingNoBukti,
  });

  @override
  State<DetailPembayaranPage> createState() => _DetailPembayaranPageState();
}

class _DetailPembayaranPageState extends State<DetailPembayaranPage> {
  // ── Services ──────────────────────────────────────────────────
  final PenawaranService penawaranService = PenawaranService();
  final PaketService paketService = PaketService();
  final HistoryOrderService historyOrderService = HistoryOrderService();
  final PesananService pesananService = PesananService();
  final MetodePembayaranService metodePembayaranService =
      MetodePembayaranService();
  final DefaultValueService defaultValueService = DefaultValueService();

  // ── State ─────────────────────────────────────────────────────
  List<MetodePembayaranModel> metodePembayaran = [];
  bool isLoading = false;
  String? errorMessage;

  bool _isExpanded = true;
  bool isPackageExpanded = true;

  PenawaranModel? penawaran;
  PaketModel? paket;

  // PPN config — di-fetch dari server, bukan hardcode
  PpnModel? ppnModel;
  // Hasil kalkulasi lengkap dari PpnModel.hitungEstimasi()
  EstimasiBiaya? estimasi;

  String? kodeMetode;
  String? textMetode;
  int biayaPembayaran = 0; // biaya metode pembayaran (gateway fee)

  // ── Getters ringkas untuk UI ──────────────────────────────────
  int get hargaPaket => estimasi?.hargaDasar ?? 0;
  int get biayaPPN => estimasi?.biayaPpn ?? 0;
  int get biayaDPP => estimasi?.dpp ?? 0;
  bool get hasPpn => estimasi?.hasPpn ?? false;
  bool get inclPpn => estimasi?.inclPpn ?? false;

  /// Total yang dibayar customer = totalCustomer dari estimasi + biaya metode
  int get totalPembayaran => estimasi?.totalCustomer ?? 0;

  // ─────────────────────────────────────────────────────────────

  bool get _isChangeMode => widget.existingNoBukti != null;

  @override
  void initState() {
    super.initState();
    if (_isChangeMode) {
      _loadOnlyMetode();
    } else {
      getData(widget.penawaranId!);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadOnlyMetode() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      await getMetodePembayaran();
    } finally {
      setState(() => isLoading = false);
    }
  }

  // ══════════════════════════════════════════════════════════════
  // DATA LOADING
  // ══════════════════════════════════════════════════════════════

  Future<void> getData(String id) async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      // Fetch semua data secara paralel untuk efisiensi
      await Future.wait([
        getMetodePembayaran(),
        getPpn(),
      ]);

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

      _hitungHarga();
    } catch (e) {
      errorMessage = "Data penawaran tidak ditemukan atau sudah tidak aktif";
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  /// Fetch konfigurasi PPN dari server.
  /// Jika gagal, fallback ke PpnModel default (tanpa PPN, tanpa platform fee).
  Future<void> getPpn() async {
    try {
      ppnModel = await defaultValueService.getPpn();
    } catch (e) {
      debugPrint('[DetailPembayaran] Gagal fetch PPN, pakai default: $e');
      ppnModel = const PpnModel(ppn: 0, inclPpn: false, platform: 0);
    }
  }

  Future<void> getMetodePembayaran() async {
    try {
      final result = await metodePembayaranService.getAll(
          status: "aktif", orderBy: "cara_bayar", orderDir: "asc");

      if (result.isEmpty) {
        throw Exception("Metode pembayaran kosong");
      }

      metodePembayaran = result;

      // Pilih metode pembayaran default jika hanya ada 1
      if (metodePembayaran.length == 1) {
        kodeMetode = metodePembayaran[0].caraBayar;
        textMetode = metodePembayaran[0].display;
        biayaPembayaran = metodePembayaran[0].fee;
      }
    } catch (e) {
      errorMessage = "Metode pembayaran tidak ditemukan";
    }
  }

  void _hitungHarga() {
    if (penawaran == null || ppnModel == null) return;

    // ✅ Pass adminFee agar PPN mencakup biaya admin juga
    estimasi = ppnModel!.hitungEstimasi(
      penawaran!.harga,
      adminFee: biayaPembayaran,
    );
    setState(() {});
  }

  // ══════════════════════════════════════════════════════════════
  // CREATE PESANAN
  // ══════════════════════════════════════════════════════════════

  Future<void> createPesanan() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      debugPrint('═══════════════════════════════════════');
      debugPrint('📦 [createPesanan] START');
      debugPrint('═══════════════════════════════════════');

      if (penawaran == null) {
        debugPrint('❌ [createPesanan] penawaran == null → early return');
        return;
      }

      debugPrint('📋 [createPesanan] Penawaran data:');
      debugPrint('   noId         : ${penawaran!.noId}');
      debugPrint('   idVendor     : ${penawaran!.idVendor}');
      debugPrint('   idCustomer   : ${penawaran!.idCustomer}');
      debugPrint('   idPaket      : ${penawaran!.idPaket}');
      debugPrint('   namaPaket    : ${penawaran!.namaPaket}');
      debugPrint('   kota         : ${penawaran!.kota}');
      debugPrint('   lokasi       : ${penawaran!.lokasi}');
      debugPrint('   tglRealisasi : ${penawaran!.tglRealisasi}');
      debugPrint('   incld PPN    : $inclPpn - ${ppnModel!.ppn}%}');
      debugPrint('   harga raw    : ${penawaran!.harga}');
      debugPrint(
          '💰 [createPesanan] Estimasi totalPembayaran : $totalPembayaran');
      debugPrint(
          '💰 [createPesanan] Estimasi total harga create pesanan : ${penawaran!.harga}');
      debugPrint('💳 [createPesanan] kodeMetode      : $kodeMetode');

      final newPesanan = PesananModel(
          noBukti: "new",
          noPenawaran: penawaran!.noId,
          idVendor: penawaran!.idVendor,
          idCustomer: penawaran!.idCustomer,
          idPaket: penawaran!.idPaket,
          namaPaket: penawaran!.namaPaket,
          kota: penawaran!.kota,
          harga: inclPpn ? totalPembayaran : penawaran!.harga,
          lokasi: penawaran!.lokasi,
          tglRealisasi: penawaran!.tglRealisasi,
          status: "aktif",
          statusBayar: null,
          metodeBayar: kodeMetode,
          idPaymentGateway: null,
          subtotal: 0,
          grandTotal: 0,
          revisi: penawaran!.revisi,
          estimasiPengerjaan: penawaran!.estimasiPengerjaan,
          tglPengerjaanMax: penawaran!.tglRealisasi
              .add(Duration(hours: penawaran!.estimasiPengerjaan)));

      debugPrint(
          '✅ [createPesanan] PesananModel dibuat, memanggil service.create...');

      final result = await pesananService.create(newPesanan);
      debugPrint('✅ [createPesanan] service.create selesai');
      debugPrint('   result.noBukti : ${result.noBukti}');

      debugPrint(
          '🔍 [createPesanan] Memanggil service.getAll(noBukti: ${result.noBukti})...');
      final pesanan = await pesananService.getAll(noBukti: result.noBukti);
      debugPrint(
          '✅ [createPesanan] getAll selesai, jumlah data: ${pesanan.length}');

      if (pesanan.isEmpty) {
        debugPrint(
            '❌ [createPesanan] pesanan kosong setelah getAll → kemungkinan bug di service');
      } else {
        debugPrint('📄 [createPesanan] pesanan.first:');
        debugPrint('   noBukti    : ${pesanan.first.noBukti}');
        debugPrint('   idCustomer : ${pesanan.first.idCustomer}');
        debugPrint('   linkSnap   : ${pesanan.first.linkSnap}');
      }

      debugPrint('📝 [createPesanan] Membuat history menunggu bayar...');
      final historyMenungguBayar = HistoryOrderService.createMenungguPembayaran(
        noOrder: result.noBukti,
        senderId: pesanan.first.idCustomer,
      );
      debugPrint('   history.noOrder  : ${historyMenungguBayar.noOrder}');
      debugPrint('   history.senderId : ${historyMenungguBayar.senderId}');

      await historyOrderService.create(historyMenungguBayar);
      debugPrint('✅ [createPesanan] historyOrderService.create selesai');

      try {
        debugPrint('💬 [createPesanan] Mengupdate chat penawaran → pesanan...');
        debugPrint('   message.id  : ${widget.message!.messageId}');
        debugPrint('   pesananId   : ${pesanan.first.noBukti}');
        final chatUpdated =
            await context.read<ChatProvider>().updatePenawaranToPesanan(
                  message: widget.message!,
                  pesananId: pesanan.first.noBukti,
                );
        debugPrint(chatUpdated
            ? '✅ [createPesanan] Chat berhasil diupdate'
            : '⚠️  [createPesanan] Chat tidak berhasil diupdate');
      } catch (e) {
        debugPrint('❌ [createPesanan] Error updating chat: $e');
      }

      if (!context.mounted) {
        debugPrint(
            '⚠️  [createPesanan] context tidak mounted setelah chat update');
        return;
      }

      CustomSnackbar.showSuccessSnackbar(
        context,
        "Pesanan berhasil dibuat, segera selesaikan pembayaran",
      );

      context.read<NavigationProvider>().popAllToRoot();

      if (pesanan.first.linkSnap == null) {
        debugPrint(
            '🧭 [createPesanan] linkSnap null → navigasi ke WaitingPaymentPage');
        context.read<NavigationProvider>().navigateToPage(
              context,
              targetTabIndex: 2,
              WaitingPaymentPage(paymentData: pesanan.first),
            );
      } else {
        debugPrint('🧭 [createPesanan] linkSnap ada → navigasi ke WebviewPage');
        debugPrint('   url: ${pesanan.first.linkSnap}');
        context.read<NavigationProvider>().navigateToPage(
              context,
              targetTabIndex: 2,
              WebviewPage(
                url: pesanan.first.linkSnap!,
                paymentData: pesanan.first,
              ),
            );
      }

      debugPrint('═══════════════════════════════════════');
      debugPrint('✅ [createPesanan] END SUCCESS');
      debugPrint('═══════════════════════════════════════');
    } catch (e, stackTrace) {
      debugPrint('═══════════════════════════════════════');
      debugPrint('❌ [createPesanan] ERROR: $e');
      debugPrint('📍 StackTrace:\n$stackTrace');
      debugPrint('═══════════════════════════════════════');
      errorMessage = e.toString();
      if (context.mounted) {
        CustomSnackbar.showErrorSnackbar(context, errorMessage!);
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
      debugPrint('🏁 [createPesanan] FINALLY — isLoading = false');
    }
  }

  // ══════════════════════════════════════════════════════════════
  // CHANGE PAYMENT
  // ══════════════════════════════════════════════════════════════

  Future<void> changePayment() async {
    if (kodeMetode == null) return;
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      // 1. Panggil API — throws on error, noBukti tidak berubah
      await pesananService.changePayment(widget.existingNoBukti!, kodeMetode!);

      // 2. Load pesanan dengan noBukti yang sama
      final pesananList =
          await pesananService.getAll(noBukti: widget.existingNoBukti!);
      if (pesananList.isEmpty) throw Exception('Pesanan tidak ditemukan');
      final pesanan = pesananList.first;

      // 3. Buat history "menunggu bayar" dengan deskripsi ganti metode
      final history = HistoryOrderService.createMenungguPembayaran(
        noOrder: widget.existingNoBukti!,
        senderId: pesanan.idCustomer,
        deskripsi: 'Metode pembayaran berhasil diubah',
      );
      await historyOrderService.create(history);

      if (!context.mounted) return;

      CustomSnackbar.showSuccessSnackbar(
          context, 'Metode pembayaran berhasil diubah');
      context.read<NavigationProvider>().popAllToRoot();

      // 4. Navigasi berdasarkan linkSnap
      if (pesanan.linkSnap != null && pesanan.linkSnap!.isNotEmpty) {
        context.read<NavigationProvider>().navigateToPage(
              context,
              targetTabIndex: 2,
              WebviewPage(url: pesanan.linkSnap!, paymentData: pesanan),
            );
      } else {
        context.read<NavigationProvider>().navigateToPage(
              context,
              targetTabIndex: 2,
              WaitingPaymentPage(paymentData: pesanan),
            );
      }
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      errorMessage = msg;
      if (mounted) {
        final nav = context.read<NavigationProvider>();
        await CustomDialog.showWarningDialog(
          context: context,
          title: 'Ganti Metode Gagal',
          message: msg,
          buttonText: 'Kembali ke Pesanan',
          onConfirm: nav.popAllToRoot,
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ══════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xFFF9F9F9),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text(
            _isChangeMode ? "Ganti Metode Bayar" : "Detail Pembayaran",
            style:
                const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
        ),
        body: Builder(
          builder: (context) {
            /// 1️⃣ LOADING
            if (isLoading) {
              return Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  children: const [
                    ShimmerPlaceholder(
                        height: 140, width: double.infinity, radius: 12),
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
      
            /// 2️⃣ ERROR
            if (errorMessage != null) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 12),
                    Text(errorMessage!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _isChangeMode
                          ? _loadOnlyMetode()
                          : getData(widget.penawaranId!),
                      child: const Text("Coba Lagi"),
                    ),
                  ],
                ),
              );
            }
      
            /// 3️⃣ EMPTY
            if (!_isChangeMode && (penawaran == null || paket == null)) {
              return const Center(child: Text("Data penawaran tidak tersedia"));
            }
      
            /// 4️⃣ SUCCESS — Change Mode: hanya tampil metode picker
            if (_isChangeMode) {
              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(10, 20, 10, 20),
                      child: _buildCardSection(
                        title: "Metode Pembayaran Baru",
                        isRequired: true,
                        content: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pesanan lama akan dibatalkan dan pesanan baru akan dibuat dengan metode yang dipilih.',
                              style: TextStyle(
                                  fontSize: 13, color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 16),
                            GestureDetector(
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
                                },
                              ),
                              child: _buildMetodePicker(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  _buildExpandableBottomBar(),
                ],
              );
            }
      
            /// 4️⃣ SUCCESS — Create Mode
            final tanggal = DateFormat("dd MMM yyyy", "id_ID")
                .format(penawaran!.tglRealisasi);
            final waktu = Helper.toLocalTime(penawaran!.tglRealisasi);
      
            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(10, 20, 10, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Informasi Penawaran ──────────────────
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
      
                        // ── Metode Pembayaran ────────────────────
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
                                  _hitungHarga();
                                },
                              ),
                              child: _buildMetodePicker(),
                            ),
                          ),
      
                        // ── Detail Paket ─────────────────────────
                        _buildExpandableCard(
                          title: "Detail Paket",
                          isExpanded: isPackageExpanded,
                          onToggle: () => setState(
                              () => isPackageExpanded = !isPackageExpanded),
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
                              const SizedBox(height: 12),
                              _buildRevisiChip(penawaran!.revisi),
                              const SizedBox(height: 8),
                              _buildEstimasiPengerjaanChip(
                                  penawaran!.estimasiPengerjaan),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.info_outline_rounded,
                                        size: 13, color: Colors.grey.shade500),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        "Estimasi pengerjaan dihitung mulai tanggal dan waktu pertemuan.",
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade600,
                                            height: 1.4),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (paket!.rincian.isNotEmpty) ...[
                                const Divider(),
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
      
                        // ── Lokasi & Jadwal ──────────────────────
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
                                  const Icon(Icons.location_on_outlined,
                                      size: 20, color: Colors.black54),
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
                                              color: Colors.black54),
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
      
                // ── Bottom Bar ─────────────────────────────────
                _buildExpandableBottomBar(),
              ],
            );
          },
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // WIDGET BUILDERS
  // ══════════════════════════════════════════════════════════════

  Widget _buildMetodePicker() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kodeMetode == null ? Colors.grey.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: kodeMetode == null
              ? Colors.grey.shade300
              : Constants.primaryColor,
          width: kodeMetode == null ? 1 : 2,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kodeMetode == null
                      ? Colors.grey.shade200
                      : Constants.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  CustomIcons.getMetodeIcon(kodeMetode ?? ""),
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
          Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade600),
        ],
      ),
    );
  }

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
              Text(title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              if (isRequired) ...[
                const SizedBox(width: 4),
                const Text("*",
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red)),
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
        Icon(icon, size: 20, color: Colors.black54),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(fontSize: 12, color: Colors.black54)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500)),
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
    Color? labelColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: labelColor ?? Colors.black87,
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
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
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
                        child: Text(title,
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.bold))),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(Icons.keyboard_arrow_down_rounded,
                          color: Colors.grey.shade600),
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

  Widget _buildRevisiChip(int revisi) {
    final isUnlimited = revisi == 0;
    final label = isUnlimited ? 'Tidak terbatas' : '$revisi kali';
    final color = isUnlimited ? Colors.green.shade700 : Constants.primaryColor;
    final bgColor = isUnlimited
        ? Colors.green.shade50
        : Constants.primaryColor.withOpacity(0.08);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(Icons.replay_rounded, size: 16, color: Colors.black45),
        const SizedBox(width: 8),
        const Text(
          'Maks. Revisi',
          style: TextStyle(fontSize: 13, color: Colors.black54),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEstimasiPengerjaanChip(int estimasiPengerjaan) {
    final label = Helper.formatEstimasiPengerjaan(estimasiPengerjaan);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(Icons.hourglass_bottom_outlined, size: 16, color: Colors.black45),
        const SizedBox(width: 8),
        const Text(
          'Estimasi Pengerjaan',
          style: TextStyle(fontSize: 13, color: Colors.black54),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Constants.primaryColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Constants.primaryColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpandableBottomBar() {
    // ── Change mode: bottom bar sederhana tanpa ringkasan harga ──
    if (_isChangeMode) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kodeMetode == null
                  ? Colors.grey.shade300
                  : Constants.primaryColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: kodeMetode == null ? 0 : 2,
            ),
            onPressed: isLoading || kodeMetode == null
                ? null
                : () async => await changePayment(),
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : Text(
                    'Ganti Metode Bayar',
                    style: TextStyle(
                      color: kodeMetode == null
                          ? Colors.grey.shade600
                          : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
          ),
        ),
      );
    }

    // Untuk label, gunakan admin fee yang belum kena PPN (DPP admin)
    // agar customer paham berapa fee asli sebelum pajak
    final displayAdminFee = biayaPembayaran;

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
          // ── Header toggle ──────────────────────────────────
          GestureDetector(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isExpanded ? "Ringkasan Pembayaran" : "Total Pembayaran",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
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
                      child: const Icon(Icons.keyboard_arrow_up_rounded,
                          color: Colors.black54),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Detail harga (expandable) ──────────────────────
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children: [
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // ── Harga Paket ──────────────────────────────
                _buildPriceRow(
                  hasPpn
                      ? (inclPpn ? "Harga Paket (termasuk PPN)" : "Harga Paket")
                      : "Harga Paket",
                  Helper.formatCurrency(hargaPaket),
                ),

                // ── Biaya Pembayaran (admin fee) ─────────────
                if (kodeMetode != null) ...[
                  const SizedBox(height: 8),
                  _buildPriceRow(
                    "Biaya Admin",
                    Helper.formatCurrency(displayAdminFee),
                  ),
                ],

                // ── PPN ──────────────────────────────────────
                if (hasPpn && !inclPpn) ...[
                  const SizedBox(height: 8),
                  _buildPriceRow(
                    "PPN ${estimasi!.ppnPersen}%",
                    Helper.formatCurrency(biayaPPN),
                  ),
                ],

                // ── Keterangan incl PPN ──────────────────────
                if (hasPpn && inclPpn) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Harga sudah termasuk PPN ${estimasi!.ppnPersen}%'
                    '${kodeMetode != null ? ' (termasuk biaya pembayaran)' : ''}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],

                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // ── Total ────────────────────────────────────
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

          // ── Tombol Bayar / Ganti Metode ────────────────────
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kodeMetode == null
                    ? Colors.grey.shade300
                    : Constants.primaryColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: kodeMetode == null ? 0 : 2,
              ),
              onPressed: isLoading ||
                      kodeMetode == null ||
                      penawaran!.noPesanan.isNotEmpty
                  ? null
                  : () async => await createPesanan(),
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
