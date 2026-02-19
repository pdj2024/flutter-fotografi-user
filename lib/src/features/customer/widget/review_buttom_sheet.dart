import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/data/hive_entity/pesanan_model.dart';

// ═══════════════════════════════════════════════════════════════
// REVIEW BOTTOM SHEET
//
// Penggunaan:
//   showModalBottomSheet(
//     context: context,
//     isScrollControlled: true,
//     backgroundColor: Colors.transparent,
//     builder: (_) => ReviewBottomSheet(pesanan: order),
//   );
// ═══════════════════════════════════════════════════════════════

class ReviewBottomSheet extends StatefulWidget {
  final PesananModel pesanan;

  const ReviewBottomSheet({super.key, required this.pesanan});

  @override
  State<ReviewBottomSheet> createState() => _ReviewBottomSheetState();
}

class _ReviewBottomSheetState extends State<ReviewBottomSheet> {
  int _selectedRating = 0;
  final TextEditingController _reviewCtrl = TextEditingController();
  bool _isSubmitting = false;

  static const _ratingLabels = [
    '',
    'Sangat Buruk',
    'Buruk',
    'Cukup',
    'Bagus',
    'Luar Biasa!',
  ];

  @override
  void dispose() {
    _reviewCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih rating terlebih dahulu'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    HapticFeedback.lightImpact();
    setState(() => _isSubmitting = true);

    try {
      // TODO: Panggil service review
      // await ReviewService().submitReview(
      //   noOrder: widget.pesanan.noBukti,
      //   idVendor: widget.pesanan.idVendor,
      //   rating: _selectedRating,
      //   ulasan: _reviewCtrl.text.trim(),
      // );

      // Simulasi delay
      await Future.delayed(const Duration(milliseconds: 1200));

      if (!mounted) return;

      HapticFeedback.mediumImpact();
      Navigator.pop(context, true); // true = submitted

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Ulasan berhasil dikirim!'),
            ],
          ),
          backgroundColor: const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengirim ulasan: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + bottomInset),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title
              const Text(
                'Beri Ulasan',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F0F0F),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.pesanan.namaVendor ?? 'Vendor',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 28),

              // Star rating
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final starVal = i + 1;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedRating = starVal);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: AnimatedScale(
                        scale: _selectedRating >= starVal ? 1.15 : 1.0,
                        duration: const Duration(milliseconds: 150),
                        child: Icon(
                          _selectedRating >= starVal
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: 44,
                          color: _selectedRating >= starVal
                              ? const Color(0xFFF9A825)
                              : Colors.grey.shade300,
                        ),
                      ),
                    ),
                  );
                }),
              ),

              // Rating label
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _selectedRating > 0
                    ? Padding(
                        key: ValueKey(_selectedRating),
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _ratingLabels[_selectedRating],
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFF9A825),
                          ),
                        ),
                      )
                    : Padding(
                        key: const ValueKey(0),
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Tap bintang untuk memberi rating',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ),
              ),

              const SizedBox(height: 24),

              // Text input
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: TextField(
                  controller: _reviewCtrl,
                  maxLines: 4,
                  maxLength: 300,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF0F0F0F),
                  ),
                  decoration: InputDecoration(
                    hintText:
                        'Ceritakan pengalamanmu bekerja sama dengan fotografer ini...',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade400,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(14),
                    counterStyle: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Submit button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedRating > 0
                        ? const Color(0xFFF9A825)
                        : Colors.grey.shade300,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Kirim Ulasan',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 8),

              // Cancel
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Batal',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}