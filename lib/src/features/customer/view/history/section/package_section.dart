import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/constants/helper.dart';
import 'package:mpjnew/src/data/hive_entity/paket_model.dart';
import 'package:mpjnew/src/data/hive_entity/penawaran_model.dart';
import 'package:mpjnew/src/data/hive_entity/pesanan_model.dart';

class PackageSection extends StatelessWidget {
  const PackageSection({super.key, this.paket, this.pesanan, this.penawaran});

  final PaketModel? paket;
  final PesananModel? pesanan;
  final PenawaranModel? penawaran;

  // Paket adalah nilai default (template) — penawaran yang disepakati vendor
  // & customer bisa mengubah nama/harga/revisi/rincian dari default itu, dan
  // pesanan (order yang sudah jadi) membawa nilai final hasil kesepakatan.
  // Prioritas tampil: pesanan (final) > penawaran (hasil negosiasi) > paket
  // (default) — supaya order lama yang belum sempat menyalin nilai dari
  // penawaran tetap fallback ke data penawaran, bukan langsung ke default.
  String get _namaPaket {
    if (penawaran?.namaPaket.isNotEmpty == true) return penawaran!.namaPaket;
    return paket!.nama_paket;
  }

  int get _harga {
    if (pesanan != null) return pesanan!.harga;
    if (penawaran != null) return penawaran!.harga;
    return paket!.harga;
  }

  int get _revisi {
    if (pesanan != null) return pesanan!.revisi;
    if (penawaran != null) return penawaran!.revisi;
    return paket!.revisi;
  }

  String get _rincian {
    if (penawaran?.deskripsi.isNotEmpty == true) return penawaran!.deskripsi;
    return paket!.rincian;
  }

  @override
  Widget build(BuildContext context) {
    if (paket == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: Constants.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.card_giftcard,
                  color: Constants.primaryColor, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_namaPaket,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(Helper.formatCurrency(_harga),
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Constants.primaryColorVendor)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.loop_rounded,
                          size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        _revisi == 0 ? 'Tanpa revisi' : '$_revisi× revisi',
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        if (_rincian.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 10),
          const Text('Rincian Paket',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 6),
          Text(_rincian,
              style: const TextStyle(
                  fontSize: 13, color: Colors.black87, height: 1.5)),
        ],
      ],
    );
  }
}
