import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/constants/helper.dart';
import 'package:mpjnew/src/core/utils/shimmer_placeholder.dart';
import 'package:mpjnew/src/data/hive_entity/paket_model.dart';
import 'package:mpjnew/src/data/models/ulasan_model.dart';
import 'package:mpjnew/src/features/customer/services/ulasan_service.dart';

class PaketUlasanListPage extends StatefulWidget {
  final PaketModel paket;
  final List<UlasanModel>? initialUlasanList; // ✅ Optional initial data

  const PaketUlasanListPage({
    super.key,
    required this.paket,
    this.initialUlasanList,
  });

  @override
  State<PaketUlasanListPage> createState() => _PaketUlasanListPageState();
}

class _PaketUlasanListPageState extends State<PaketUlasanListPage> {
  final UlasanService _ulasanService = UlasanService();

  bool isLoading = true;
  String? errorMessage;
  List<UlasanModel> ulasanList = [];

  // Filter
  int? selectedRatingFilter;

  @override
  void initState() {
    super.initState();

    // ✅ Use initial data if available
    if (widget.initialUlasanList != null) {
      ulasanList = widget.initialUlasanList!;
      isLoading = false;
    } else {
      _fetchUlasan();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _fetchUlasan() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      debugPrint(
          '[PaketUlasanList] 📥 Fetching ulasan for paket: ${widget.paket.no_id}');

      // ✅ Fetch ulasan yang memiliki idPaket yang sesuai
      final allUlasan = await _ulasanService.getAll(
        status: 'aktif',
        orderBy: 'Tgl_Ulasan',
        orderDir: 'DESC',
      );

      debugPrint(
          '[PaketUlasanList] ✅ Total ulasan from API: ${allUlasan.length}');

      // ✅ Filter ulasan untuk paket ini
      final filteredUlasan = allUlasan.where((ulasan) {
        if (ulasan.idPaket == null || ulasan.idPaket.isEmpty) {
          return false;
        }

        // idPaket bisa berupa comma-separated values
        final paketIds =
            ulasan.idPaket.split(',').map((e) => e.trim()).toList();
        return paketIds.contains(widget.paket.no_id);
      }).toList();

      debugPrint(
          '[PaketUlasanList] ✅ Filtered ulasan for this paket: ${filteredUlasan.length}');

      setState(() {
        ulasanList = filteredUlasan;
        isLoading = false;
      });
    } catch (e, stackTrace) {
      debugPrint('[PaketUlasanList] ❌ Error: $e');
      debugPrint('[PaketUlasanList] Stack: $stackTrace');

      setState(() {
        errorMessage = 'Gagal memuat ulasan: $e';
        isLoading = false;
      });
    }
  }

  List<UlasanModel> get filteredUlasan {
    if (selectedRatingFilter == null) return ulasanList;
    return ulasanList.where((u) => u.rating == selectedRatingFilter).toList();
  }

  // ✅ Calculate average rating
  double get averageRating {
    if (ulasanList.isEmpty) return 0.0;

    final totalRating = ulasanList.fold<int>(
      0,
      (sum, ulasan) => sum + ulasan.rating,
    );

    return totalRating / ulasanList.length;
  }

  @override
  Widget build(BuildContext context) {
    final displayedUlasan = filteredUlasan;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          "Ulasan Paket",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      backgroundColor: const Color(0xFFF9F9F9),
      body: Column(
        children: [
          // Header Info Paket
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.paket.nama_paket,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  Helper.formatCurrency(widget.paket.harga),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Constants.primaryColor,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.star_rounded,
                      color: Colors.amber,
                      size: 28,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      averageRating
                          .toStringAsFixed(1), // ✅ Use calculated rating
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "dari ${ulasanList.length} ulasan", // ✅ Use actual count
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
    
          // Filter Rating
          if (!isLoading && ulasanList.isNotEmpty)
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.white,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('Semua', null),
                    const SizedBox(width: 8),
                    _buildFilterChip('⭐ 5', 5),
                    const SizedBox(width: 8),
                    _buildFilterChip('⭐ 4', 4),
                    const SizedBox(width: 8),
                    _buildFilterChip('⭐ 3', 3),
                    const SizedBox(width: 8),
                    _buildFilterChip('⭐ 2', 2),
                    const SizedBox(width: 8),
                    _buildFilterChip('⭐ 1', 1),
                  ],
                ),
              ),
            ),
    
          const Divider(height: 1),
    
          // List Ulasan
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchUlasan,
              child: isLoading
                  ? ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: 5,
                      itemBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: const ShimmerPlaceholder(
                          height: 180,
                          radius: 12,
                        ),
                      ),
                    )
                  : errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 64,
                                color: Colors.red.shade300,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "Gagal memuat ulasan",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 32),
                                child: Text(
                                  errorMessage!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _fetchUlasan,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Coba Lagi'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Constants.primaryColor,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        )
                      : displayedUlasan.isEmpty
                          ? ListView(
                              children: [
                                SizedBox(
                                  height: MediaQuery.of(context).size.height *
                                      0.5,
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.rate_review_outlined,
                                          size: 64,
                                          color: Colors.grey.shade300,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          selectedRatingFilter == null
                                              ? "Belum ada ulasan"
                                              : "Tidak ada ulasan dengan rating ini",
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: displayedUlasan.length,
                              itemBuilder: (context, index) {
                                final ulasan = displayedUlasan[index];
                                return _buildUlasanCard(ulasan);
                              },
                            ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, int? rating) {
    final isSelected = selectedRatingFilter == rating;

    // ✅ Count ulasan for this rating
    final count = rating == null
        ? ulasanList.length
        : ulasanList.where((u) => u.rating == rating).length;

    return FilterChip(
      label: Text('$label${count > 0 ? ' ($count)' : ''}'),
      selected: isSelected,
      onSelected: count > 0
          ? (selected) {
              setState(() {
                selectedRatingFilter = selected ? rating : null;
              });
            }
          : null,
      backgroundColor: Colors.white,
      selectedColor: Constants.primaryColor.withOpacity(0.2),
      checkmarkColor: Constants.primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? Constants.primaryColor : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        fontSize: 13,
      ),
      side: BorderSide(
        color: isSelected ? Constants.primaryColor : Colors.grey.shade300,
      ),
    );
  }

  Widget _buildUlasanCard(UlasanModel ulasan) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
          // Header - Customer Info
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Constants.primaryColor.withOpacity(0.1),
                child: Text(
                  ulasan.namaCustomer.substring(0, 1),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Constants.primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ulasan
                          .namaCustomer, // ✅ Could show actual name if available
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      Helper.formatTanggal(ulasan.tglUlasan),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Rating Stars
          Row(
            children: [
              ...List.generate(5, (index) {
                return Icon(
                  index < ulasan.rating
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  color: index < ulasan.rating
                      ? Colors.amber
                      : Colors.grey.shade300,
                  size: 20,
                );
              }),
              const SizedBox(width: 8),
              Text(
                Helper.getRatingText(ulasan.rating),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Helper.getRatingColor(ulasan.rating),
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
              ulasan.isiUlasan,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade800,
                height: 1.5,
              ),
            ),
          ),

          // Balasan Vendor (jika ada)
          if (ulasan.adaBalasan == true &&
              ulasan.isiBalasan != null &&
              ulasan.isiBalasan!.isNotEmpty) ...[
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
                        'Balasan dari Vendor',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      const Spacer(),
                      if (ulasan.tglBalasan != null)
                        Text(
                          Helper.formatTanggal(ulasan.tglBalasan!),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.blue.shade600,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ulasan.isiBalasan!,
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
}
