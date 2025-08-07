import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../providers/constants.dart';

class BayarCounter extends StatefulWidget {
  final String orderId;
  final int grossAmount;
  final String store; // 'alfamart', 'indomaret'

  const BayarCounter({
    super.key,
    required this.orderId,
    required this.grossAmount,
    required this.store,
  });

  @override
  State<BayarCounter> createState() => _BayarCounterState();
}

class _BayarCounterState extends State<BayarCounter> {
  String? paymentCode;
  String? merchantId;
  String? errorMessage;
  bool isLoading = true;
  String? transactionId;

  final Color primaryColor = Constants.primaryColor;

  @override
  void initState() {
    super.initState();
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

    Map<String, dynamic> body = {
      "transaction_details": {
        "order_id": widget.orderId,
        "gross_amount": widget.grossAmount,
      }
    };

    switch (widget.store.toLowerCase()) {
      case "alfamart":
        body["payment_type"] = "cstore";
        body["cstore"] = {
          "store": "alfamart",
        };
        break;
      case "indomaret":
        body["payment_type"] = "cstore";
        body["cstore"] = {
          "store": "indomaret",
        };
        break;
      default:
        setState(() {
          errorMessage = "Store tidak dikenali";
          isLoading = false;
        });
        return;
    }

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

      setState(() {
        paymentCode = json['payment_code'];
        merchantId = json['merchant_id'];
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

  String formatRupiah(int number) {
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    return formatter.format(number);
  }

  void copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text.replaceAll(' ', '')));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Disalin ke clipboard")),
    );
  }

  String formatPaymentCode(String? code) {
    if (code == null) return '-';
    final buffer = StringBuffer();
    for (int i = 0; i < code.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(code[i]);
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Text("Pembayaran Counter"),
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
                              const SizedBox(height: 24),
                             
                                Text(
                                  'Payment Code',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        formatPaymentCode(paymentCode),
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        if (paymentCode != null) {
                                          copyToClipboard(paymentCode!);
                                        }
                                      },
                                      icon: const Icon(Icons.copy, size: 20),
                                      tooltip: 'Salin',
                                    ),
                                  ],
                                ),
                                 widget.store.toLowerCase() == "indomaret" 
                                  ? Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                          const SizedBox(height: 24),
                                        Text(
                                          'Merchant ID',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                merchantId ?? '-',
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              onPressed: () {
                                                if (merchantId != null) {
                                                  copyToClipboard(merchantId!);
                                                }
                                              },
                                              icon: const Icon(Icons.copy, size: 20),
                                              tooltip: 'Salin',
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 14),
                                      ],
                                    )
                                  : Container(),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
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
