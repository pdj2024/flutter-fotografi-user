import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:provider/provider.dart';

import '../providers/navigation_provider.dart';
import 'biodata.dart';

class VendorStatus extends StatefulWidget {
  const VendorStatus({Key? key}) : super(key: key);

  @override
  State<VendorStatus> createState() => _VendorStatusState();
}

class _VendorStatusState extends State<VendorStatus> {
  Timer? _testTimer;

  @override
  void initState() {
    super.initState();

    // 🔄 Simulasi ganti status setelah 15 detik
    _testTimer = Timer(const Duration(seconds: 5), () {
      final nav = context.read<NavigationProvider>();
      final isAccepted = true; // Random().nextBool(); // true atau false secara acak
      // nav.setStatusUser(isAccepted ? 'accepted' : 'rejected');
    });
  }

  @override
  void dispose() {
    _testTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SafeArea(
        child: Consumer<NavigationProvider>(
          builder: (context, nav, _) {
            final statusUser = 'nonregistered';

            // 🚀 Auto-navigate jika status berubah jadi accepted
            if (statusUser == 'aktif') {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                nav.startNavigateVendor(context);
              });
            }

            String imageAsset = '';

            String titleText;
            String descriptionText;
            bool showRetryButton = false;

            switch (statusUser) {
              case 'pending':
                titleText = 'Pendaftaran Anda Sedang\nDiproses';
                descriptionText = 'Kami sedang meninjau pendaftaran Anda.\nMohon tunggu notifikasi selanjutnya.';
                imageAsset = 'assets/pending_illustration_transparent.png';
                break;
              case 'rejected':
                titleText = 'Pendaftaran Ditolak';
                descriptionText = 'Maaf, pendaftaran Anda ditolak.\nSilakan daftar ulang untuk melanjutkan.';
                showRetryButton = true;
                imageAsset = 'assets/rejected_illustration.png';
                break;
               case 'nonaktif':
                titleText = 'Pendaftaran Ditolak';
                descriptionText = 'Maaf, pendaftaran Anda ditolak.\nSilakan daftar ulang untuk melanjutkan.';
                showRetryButton = true;
                imageAsset = 'assets/rejected_illustration.png';
                break;
             case 'aktif':
              titleText = 'Pendaftaran Berhasil';
              descriptionText = 'Selamat! Pendaftaran Anda telah diterima.\nSilakan lanjutkan untuk menggunakan aplikasi.';
              showRetryButton = false; // atau mungkin jadi tombol "Lanjut"
              imageAsset = 'assets/accepted_illustration.png'; // pastikan gambar sesuai
              break;
              default: // nonaktif dan lainnya
               titleText = 'Pendaftaran Anda Sedang\nDiproses';
                descriptionText = 'Kami sedang meninjau pendaftaran Anda.\nMohon tunggu notifikasi selanjutnya.';
                imageAsset = 'assets/pending_illustration_transparent.png';
            }

            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(imageAsset, height: 200),
                    const SizedBox(height: 32),
                    Text(
                      titleText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      descriptionText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    if (showRetryButton) ...[
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {
                           Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => BiodataPage()),
      );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Constants.primaryColorVendor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Daftar Ulang',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
