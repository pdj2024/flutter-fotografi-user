import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:mpjnew/src/core/constants/constants.dart';

class BayarVA extends StatefulWidget {
  final String orderId;
  final int grossAmount;
  final String bank; // 'bca', 'bri', 'bni', 'mandiri', 'permata'

  const BayarVA({
    super.key,
    required this.orderId,
    required this.grossAmount,
    required this.bank,
  });

  @override
  State<BayarVA> createState() => _BayarVAState();
}

class _BayarVAState extends State<BayarVA> {
  String? vaNumber;
  String? billerCode;
  String? billKey;
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

  switch (widget.bank.toLowerCase()) {
    case "mandiri":
      body["payment_type"] = "echannel";
      body["echannel"] = {
        "bill_info1": "Payment:",
        "bill_info2": "Online purchase",
      };
      break;

    case "permata":
      body["payment_type"] = "permata";
      break;

    default:
      body["payment_type"] = "bank_transfer";
      body["bank_transfer"] = {
        "bank": widget.bank.toLowerCase(),
      };
      break;
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

    if (widget.bank.toLowerCase() == "mandiri") {
      // Handle Mandiri
      setState(() {
        billKey = json['bill_key'];  // Bill Key untuk Mandiri
        billerCode = json['biller_code']; // Biller Code untuk Mandiri
        transactionId = json['transaction_id'];
        isLoading = false;
      });
    } else if (widget.bank.toLowerCase() == "permata") {
      // Handle Permata
      setState(() {
        vaNumber = json['permata_va_number']; // VA Number untuk Permata
        transactionId = json['transaction_id'];
        isLoading = false;
      });
    } else {
      // Handle Bank Lainnya
      final vaList = json['va_numbers'] as List? ?? [];
      final va = vaList.firstWhere(
        (item) => item['bank'].toLowerCase() == widget.bank.toLowerCase(),
        orElse: () => null,
      );

      setState(() {
        vaNumber = va?['va_number'] ?? json['va_number'];  // Nomor VA untuk bank lainnya
        transactionId = json['transaction_id'];
        isLoading = false;
      });
    }
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
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Disalin ke clipboard")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Text("Pembayaran Bank"),
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
                              widget.bank.toLowerCase() == "mandiri" 
                                  ? Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Biller Code',
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
                                                billerCode ?? '-',
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              onPressed: () {
                                                if (billerCode != null) {
                                                  copyToClipboard(billerCode!);
                                                }
                                              },
                                              icon: const Icon(Icons.copy, size: 20),
                                              tooltip: 'Salin',
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 14),
                                        Text(
                                          'Bill Key',
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
                                                billKey ?? '-',
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              onPressed: () {
                                                if (billKey != null) {
                                                  copyToClipboard(billKey!);
                                                }
                                              },
                                              icon: const Icon(Icons.copy, size: 20),
                                              tooltip: 'Salin',
                                            ),
                                          ],
                                        ),
                                      ],
                                    )
                                  : Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Virtual Account (${widget.bank.toUpperCase()})',
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
                                                vaNumber ?? '-',
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              onPressed: () {
                                                if (vaNumber != null) {
                                                  copyToClipboard(vaNumber!);
                                                }
                                              },
                                              icon: const Icon(Icons.copy, size: 20),
                                              tooltip: 'Salin',
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
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
