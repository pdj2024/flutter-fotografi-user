import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:midtrans_sdk/midtrans_sdk.dart';
import 'package:intl/intl.dart';

import '../providers/constants.dart';

class BayarCard extends StatefulWidget {
  final String orderId;
  final int grossAmount;

  const BayarCard({
    super.key,
    required this.orderId,
    required this.grossAmount,
  });

  @override
  _BayarCardState createState() => _BayarCardState();
}

class _BayarCardState extends State<BayarCard> {
  MidtransSDK? _midtrans;
  String? _token;
  String? transactionId;
  String? _status;
  final Color primaryColor =
      Constants.primaryColor; // Gunakan warna utama jika berbeda

  @override
  void initState() {
    super.initState();
    initSDKAndCheckStatus();
  }

  void initSDKAndCheckStatus() async {
    await initMidtransSDK();
    await cekStatus(
        firstTime: true); // Cek status dulu, jika capture tidak lanjut bayar
  }

 Future<void> initMidtransSDK() async {
  _midtrans = await MidtransSDK.init(
    config: MidtransConfig(
      clientKey: "SB-Mid-client-uELU3WfiXUxgYouj",
      merchantBaseUrl: "https://instagram.com", // Bisa diganti ke server kamu
      colorTheme: ColorTheme(
        colorPrimary: primaryColor,
        colorPrimaryDark: primaryColor,
        colorSecondary: primaryColor,
      ),
    ),
  );

  _midtrans?.setTransactionFinishedCallback((result) {
    // ✅ Callback ketika transaksi selesai
    cekStatus();
  });
}


  Future<void> _startPayment() async {
    if (_token != null) {
      _midtrans?.startPaymentUiFlow(token: _token!);
      return;
    }

    final String apiUrl = 'http://43.228.212.41:88/api/PurchaseOrder/charge';
    final Map<String, dynamic> body = {
      "transaction_details": {
        "order_id": widget.orderId,
        "gross_amount": widget.grossAmount
      },
      "item_details": [
        {
          "id": "gross",
          "price": widget.grossAmount,
          "quantity": 1,
          "name": "Pembayaran Total"
        }
      ],
      "customer_details": {
        "email": "tester@example.com",
        "first_name": "Budi",
        "last_name": "Khannedy",
        "phone": "628112341234"
      }
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        String? token = data['token'];

        if (token != null && token.isNotEmpty) {
          _token = token;
          _midtrans?.startPaymentUiFlow(token: token);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Gagal mendapatkan token pembayaran")),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Error ${response.statusCode}: ${response.body}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Terjadi kesalahan saat memulai pembayaran")),
      );
    }
  }

  Future<void> cekStatus({bool firstTime = false}) async {
    final url = Uri.parse(
        'http://43.228.212.41:15/api/purchaseorder/getStatus/${widget.orderId}');

    try {
      final response = await http.get(url);
      final data = jsonDecode(response.body);
      if (data['status_code'] == '200') {
        final status = data['transaction_status']?.toString().toLowerCase();

        setState(() {
          _status = status != null ? "Status: $status" : null;
        });

        if (status == 'capture') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Transaksi berhasil!")),
          );
          Future.delayed(const Duration(milliseconds: 500), () {
            Navigator.of(context).pop();
            Navigator.of(context).pop();
          });
        }
      } else {
        if (!firstTime) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Silakan lakukan pembayaran")),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengambil status transaksi')),
      );
    }
  }

  String formatCurrency(int amount) {
    return NumberFormat("#,###", "id_ID").format(amount).replaceAll(",", ".");
  }

  @override
  void dispose() {
    _midtrans?.removeTransactionFinishedCallback();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F9F9),
        elevation: 0,
        foregroundColor: Colors.black,
        title: const Text(
          "Pembayaran Kartu",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
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
                      "Rp ${formatCurrency(widget.grossAmount)}",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    if (_status != null) ...[
                      const SizedBox(height: 14),
                      Text(
                        _status!,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (_status?.toLowerCase() != 'status: capture') ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _startPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      "Bayar Sekarang",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
              ],

              //   const SizedBox(height: 12),
              // if (_token != null && _token!.isNotEmpty)
              //  SizedBox(
              //     width: double.infinity,
              //     child: OutlinedButton(
              //       onPressed: cekStatus,
              //       style: OutlinedButton.styleFrom(
              //         side: BorderSide(color: primaryColor),
              //         shape: RoundedRectangleBorder(
              //           borderRadius: BorderRadius.circular(30),
              //         ),
              //         padding: const EdgeInsets.symmetric(vertical: 14),
              //       ),
              //       child: Text(
              //         'Cek Status',
              //         style: TextStyle(
              //           fontSize: 16,
              //           fontWeight: FontWeight.w600,
              //           color: primaryColor,
              //         ),
              //       ),
              //     ),
              //   ),
            ],
          ),
        ),
      ),
    );
  }
}
