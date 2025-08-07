import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:saver_gallery/saver_gallery.dart';

import '../providers/constants.dart';

class BayarQR extends StatefulWidget {
  final String orderId;
  final int grossAmount;

  const BayarQR({super.key, required this.orderId, required this.grossAmount});

  @override
  State<BayarQR> createState() => _BayarQRState();
}

class _BayarQRState extends State<BayarQR> {
  String? qrCodeUrl;
  String? errorMessage;
  bool isLoading = true;
  String? transactionId;

  final Color primaryColor = Constants.primaryColor;

  @override
  void initState() {
    super.initState();
    print("============== ORDER ID: ${widget.orderId}");
    createTransaction();
  }

  Future<void> cekStatus() async {
    if (transactionId == null) return;

    final url = Uri.parse('http://43.228.212.41:15/api/purchaseorder/getStatus/$transactionId');

    try {
      final response = await http.get(url);
      final data = jsonDecode(response.body);

      final status = data['transaction_status'];

      if (status.toLowerCase() == "settlement") {
        Navigator.of(context).pop();
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status transaksi: $status')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengambil status transaksi')),
      );
    }
  }

  Future<void> createTransaction() async {
    final uri = Uri.parse("http://43.228.212.41:15/api/purchaseorder/core");

    final body = {
      "payment_type": "gopay",
      "transaction_details": {
        "order_id": widget.orderId,
        "gross_amount": widget.grossAmount,
      }
    };

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      final json = jsonDecode(response.body);

      if (json['status_code'] != "201") {
        setState(() {
          errorMessage = "Gagal memproses pembayaran: ${json['status_message']}";
          isLoading = false;
        });
        return;
      }

      final actions = json['actions'] as List;
      final qrAction = actions.firstWhere(
        (action) => action['name'] == 'generate-qr-code',
        orElse: () => null,
      );

      if (qrAction == null) {
        setState(() {
          errorMessage = "QR Code tidak ditemukan.";
          isLoading = false;
        });
        return;
      }

      setState(() {
        qrCodeUrl = qrAction['url'];
        transactionId = json['transaction_id'];
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = "Terjadi kesalahan";
        isLoading = false;
      });
    }
  }

  Future<void> saveQrToGallery() async {
    if (qrCodeUrl == null) return;

    // Request permission
    bool granted = false;
    if (Platform.isAndroid) {
      final deviceInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = deviceInfo.version.sdkInt;
      granted = sdkInt < 29
          ? await Permission.storage.request().isGranted
          : true; // Scoped Storage mulai Android 10
    } else {
      granted = await Permission.photosAddOnly.request().isGranted;
    }

    if (!granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Izin penyimpanan ditolak")),
      );
      return;
    }

    try {
      final response = await http.get(Uri.parse(qrCodeUrl!));
      Uint8List bytes = response.bodyBytes;

      final result = await SaverGallery.saveImage(
        bytes,
        fileName: 'qris_${DateTime.now().millisecondsSinceEpoch}.png',
        androidRelativePath: 'Pictures/QRIS',
        skipIfExists: false,
      );

      if (result.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("QRIS berhasil disimpan ke galeri")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gagal menyimpan QRIS")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Terjadi kesalahan saat menyimpan QRIS")),
      );
    }
  }
String formatRupiah(int number) {
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    return formatter.format(number);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Text("Pembayaran QRIS"),
        backgroundColor: const Color(0xFFF9F9F9),
        foregroundColor: Colors.black,
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage != null
                ? Center(child: Text(errorMessage!, style: const TextStyle(color: Colors.red)))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ORDER ID CARD
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Order ID',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                widget.orderId,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                                const SizedBox(height: 14),
                              Text(
                                'Total Pembayaran',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                formatRupiah(widget.grossAmount),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              
                        const SizedBox(height: 32),
                        // QR CODE IMAGE with LONG PRESS
                        Center(
                          child: GestureDetector(
                            onLongPress: saveQrToGallery,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.network(
                                qrCodeUrl!,
                                width: 280,
                                height: 280,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Text("Gagal memuat QR code"),
                              ),
                            ),
                          ),
                        ),
                         const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      
                       

                        // SIMPAN QRIS BUTTON
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: saveQrToGallery,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: primaryColor),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Text(
                              'Simpan QRIS',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: primaryColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // CEK STATUS BUTTON
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: cekStatus,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text(
                              'Cek Status',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
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
