import 'package:flutter/material.dart';

class OfferCardShimmer extends StatelessWidget {
  const OfferCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            spreadRadius: 1,
            offset: const Offset(1, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: Nama Paket & Harga ──────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _box(double.infinity, 16),
                    const SizedBox(height: 6),
                    _box(140, 16),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _box(80, 16),
            ],
          ),

          const SizedBox(height: 10),
          Divider(color: Colors.grey.shade300),
          const SizedBox(height: 10),

          // ── Rincian: 3 baris bullet ──────────────────────
          ..._buildRincianShimmer(),

          const SizedBox(height: 12),

          // ── Ulasan section ───────────────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200, width: 1.5),
            ),
            child: Row(
              children: [
                _box(40, 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _box(80, 13),
                      const SizedBox(height: 6),
                      _box(150, 11),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // ── Button Lihat Paket ───────────────────────────
          _box(double.infinity, 44),
        ],
      ),
    );
  }

  Widget _box(double width, double height) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(6),
        ),
      );

  List<Widget> _buildRincianShimmer() {
    final widths = [double.infinity, 200.0, 160.0];
    return widths
        .map(
          (w) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                _box(8, 8),
                const SizedBox(width: 8),
                Expanded(child: _box(w, 14)),
              ],
            ),
          ),
        )
        .toList();
  }
}