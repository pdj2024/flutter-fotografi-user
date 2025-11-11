import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/constants/constants.dart';

import 'bayarCounter.dart';
import 'bayarQR.dart';
import 'bayarVa.dart';
import 'bayarCard.dart';

class DetilBayar extends StatefulWidget {
  const DetilBayar({super.key});

  @override
  State<DetilBayar> createState() => _DetilBayarState();
}

class _DetilBayarState extends State<DetilBayar> {
  final Color primaryColor = Constants.primaryColor;
  Duration remainingTime = const Duration(minutes: 5, seconds: 0);
  Timer? _timer;

  String _kodeMethod = 'QRIS';
  String _textMethod = 'QRIS';

  final int hargaPaket = 450000;
  // final int biayaLayananQRIS = 1000;
  // final int biayaLayananLain = 6000;

  final List<Map<String, dynamic>> promos = [
    {'label': 'Diskon 10K', 'amount': 10000, 'code': 'PROMO10', 'expiryDate': DateTime.now().add(Duration(days: 10))},
  {'label': 'Diskon 20K', 'amount': 20000, 'code': 'PROMO20', 'expiryDate': DateTime.now().add(Duration(days: 4))},
  {'label': 'Diskon 30K', 'amount': 30000, 'code': 'PROMO30', 'expiryDate': DateTime.now().add(Duration(days: 1))},
  {'label': 'Diskon 40K', 'amount': 40000, 'code': 'PROMO40', 'expiryDate': DateTime.now().add(Duration(days: 7))},
    ];

  // Promo
  bool _showPromo = false;
  Map<String, dynamic>? _selectedPromo;
   List<Map<String, dynamic>> _filteredPromos = [];

  @override
  void initState() {
    super.initState();
    _startCountdown();
     _filteredPromos = promos; // Initialize filteredPromos with all promos
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingTime.inSeconds == 0) {
        timer.cancel();
        if (mounted) {
          Navigator.of(context).maybePop();
        }
      } else {
        setState(() {
          remainingTime = remainingTime - const Duration(seconds: 1);
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // int get _biayaLayanan =>
  //     _selectedMethod == 'QRIS' ? biayaLayananQRIS : biayaLayananLain;
  
 
 
  int _biayaPembayaran = 0;

   int get _biayaLayanan => _biayaPembayaran; 
  

  int get _totalPembayaran =>
      hargaPaket + _biayaLayanan - (_selectedPromo?['amount'] as int? ?? 0);

  String _formatCurrency(int amount) {
    return "Rp${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}"; 
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F9F9),
        elevation: 0,
        title: const Text(
          "Detil Pembayaran",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      backgroundColor: const Color(0xFFF9F9F9),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  "Selesaikan pembayaran dalam ${_formatDuration(remainingTime)}",
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCardSection(
                    title: "Prewedding Session",
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.calendar_today_outlined, size: 18, color: Colors.black54),
                            SizedBox(width: 8),
                            Text("30 April 2024", style: TextStyle(fontSize: 14)),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.access_time, size: 18, color: Colors.black54),
                            SizedBox(width: 8),
                            Text("10:00 AM", style: TextStyle(fontSize: 14)),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.location_on_outlined, size: 18, color: Colors.black54),
                            SizedBox(width: 8),
                            Expanded(child: Text("Jl. Taman Bungkul", style: TextStyle(fontSize: 14))),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _buildCardSection(
                    title: "Ringkasan Pembayaran",
                    content: Column(
                      children: [
                        _buildPriceRow("Harga Paket", _formatCurrency(hargaPaket)),
                        const SizedBox(height: 8),
                        _buildPriceRow("Biaya Layanan", _formatCurrency(_biayaLayanan)),
                        if (_selectedPromo != null)
                          const SizedBox(height: 8),
                        if (_selectedPromo != null)
                          _buildPriceRow(
                            "${_selectedPromo!['code']}",
                            "-${_formatCurrency(_selectedPromo!['amount'])}",
                            valueColor: Colors.green,
                          ),
                        const Divider(height: 24),
                        _buildPriceRow(
                          "Total Pembayaran",
                          _formatCurrency(_totalPembayaran),
                          isBold: true,
                          valueColor: primaryColor,
                        ),
                      ],
                    ),
                  ),
                  _buildCardSection(
  title: "Gunakan Promo",
  content: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          const Icon(Icons.local_offer_outlined, size: 20, color: Colors.black54),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _selectedPromo != null
                  ? "${_selectedPromo!['code']}"
                  : "Pilih promo untuk diskon",
              style: const TextStyle(fontSize: 14),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _showPromo = !_showPromo;
              });
            },
            child: Text(
              _showPromo ? "Sembunyikan" : "Lihat Semua Promo",
              style: TextStyle(
                fontSize: 14,
                color: primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),

      // Search bar for promo section
      if (_showPromo)
        Padding(
  padding: const EdgeInsets.only(top: 8, bottom: 12),
  child: TextField(
    onChanged: (query) {
      setState(() {
        _filteredPromos = promos
            .where((promo) =>
                promo['label']
                    .toLowerCase()
                    .contains(query.toLowerCase()))
            .toList();
      });
    },
    decoration: InputDecoration(
      hintText: 'Cari promo...',
      prefixIcon: const Icon(Icons.search),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12), // Reduced padding
    ),
  ),
),


      if (_showPromo)
        _filteredPromos.isNotEmpty
            ? SizedBox(
                height: 50,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _filteredPromos.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final promo = _filteredPromos[index];
                    final selected = _selectedPromo?['code'] == promo['code'];
                    return ChoiceChip(
                      label: Text(
                        "${promo['code']} - ${_formatCurrency(promo['amount'])}",
                        style: TextStyle(
                          color: selected ? Colors.white : Colors.black87,
                        ),
                      ),
                      selected: selected,
                      onSelected: (_) {
                        setState(() {
                          _selectedPromo = selected ? null : promo;
                          _showPromo = false;
                        });
                      },
                      selectedColor: primaryColor,
                      backgroundColor: Colors.grey[200],
                      labelStyle: TextStyle(
                        color: selected ? Colors.white : Colors.black87,
                      ),
                    );
                  },
                ),
              )
            : Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                    "Belum ada promo tersedia.",
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                
              ),
    ],
  ),
),
                  // _buildCardSection(
                  //   title: "Metode Pembayaran",
                  //   content: Column(
                  //     children: [
                  //       _buildRadioListTile(
                  //         value: 'QRIS',
                  //         title: "QRIS",
                  //         icon: Icons.qr_code,
                  //       ),
                  //       _buildRadioListTile(
                  //         value: 'LAIN',
                  //         title: "Metode Lain",
                  //         icon: Icons.account_balance_wallet_outlined,
                  //       ),
                  //     ],
                  //   ),
                  // ),
                  _buildCardSection(
  title: "Metode Pembayaran",
  content: Column(
    children: [
      GestureDetector(
        onTap: _showPaymentMethodDialog,
        child: Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                     getMetodeIcon(_kodeMethod),
                    color: Colors.black87,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _textMethod,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    ],
  ),
),

                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            decoration: const BoxDecoration(
              color: Color(0xFFF9F9F9),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  offset: Offset(0, -2),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Text(
                      "Total Bayar",
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Text(
                      _formatCurrency(_totalPembayaran),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                   onPressed: () {
  final randomOrderId = Random().nextInt(9999) + 1;
  final metode = _kodeMethod.toUpperCase();

  Widget bayarPage;

 switch (metode.split(' ').first) {
  case "QRIS":
    bayarPage = BayarQR(
      orderId: randomOrderId.toString(),
      grossAmount: _totalPembayaran,
    );
    break;
  case "VA":
    bayarPage = BayarVA(
      orderId: randomOrderId.toString(),
      grossAmount: _totalPembayaran,
      bank: metode.split(' ').last.toLowerCase(),
    );
    break;
   case "COUNTER":
    bayarPage = BayarCounter(
      orderId: randomOrderId.toString(),
      grossAmount: _totalPembayaran,
      store: metode.split(' ').last.toLowerCase(),
    );
    break;
  case "CARD":
    bayarPage = BayarCard(
      orderId: randomOrderId.toString(),
      grossAmount: _totalPembayaran
    
    );
    break;
  default:
    bayarPage = BayarQR(
      orderId: randomOrderId.toString(),
      grossAmount: _totalPembayaran,
    );
    break;
}


  Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute(builder: (context) => bayarPage),
  );
},

                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      "Bayar Sekarang",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardSection({required String title, required Widget content}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value,
      {bool isBold = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }

  IconData getMetodeIcon(String metode) {
  switch (metode.split(' ').first) {
    case "QRIS":
      return Icons.qr_code;
    case "VA":
      return Icons.account_balance; // ikon bank
    case "COUNTER":
      return Icons.store; // ikon toko/gerai
    case "CARD":
      return Icons.credit_card; // ikon kartu kredit
    default:
      return Icons.payment; // ikon default
  }
}


void _showPaymentMethodDialog() {
  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        backgroundColor: Color(0xFFF9F9F9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        child: SizedBox(
          height: 350,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                alignment: Alignment.centerLeft,
                child: const Text(
                  "Pilih Metode Pembayaran",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(height: 1, color: Colors.grey),
              Expanded(
             child: Scrollbar(
  thumbVisibility: true,
  thickness: 8.0, // Lebih tebal dari default
  radius: Radius.circular(4.0), // Sedikit membulat, bisa juga Radius.zero
 
                  child: ListView(
                    children: [
                      _buildPaymentOption(
                     
                        title: "QRIS",
                        subtitle: "Gratis",
                        fee: 0,
                        method: "QRIS",
                      ),
                      _buildPaymentOption(
                     
                        title: "Indomaret",
                        subtitle: "Counter",
                        fee: 6000,
                        method: "COUNTER INDOMARET",
                      ),
                      _buildPaymentOption(
                       
                        title: "Alfamart",
                        subtitle: "Counter",
                        fee: 7500,
                        method: "COUNTER ALFAMART",
                      ),
                       _buildPaymentOption(
                      
                        title: "Kartu Debit / Credit",
                        subtitle: "Card",
                        fee: 5000,
                        method: "CARD",
                      ),
                      // _buildPaymentOption(
                      //   icon: Icons.account_balance_wallet_outlined,
                      //   title: "ShopeePay",
                      //   subtitle: "E-Wallet",
                      //   fee: 5000,
                      //   method: "ShopeePay",
                      // ),
                      // _buildPaymentOption(
                      //   icon: Icons.account_balance_wallet_outlined,
                      //   title: "LinkAja",
                      //   subtitle: "E-Wallet",
                      //   fee: 5000,
                      //   method: "LinkAja",
                      // ),
                      _buildPaymentOption(
                       
                        title: "BCA (VA)",
                        subtitle: "Bank Transfer",
                        fee: 5000,
                        method: "VA BCA",
                      ),
                      _buildPaymentOption(
                      
                        title: "Mandiri (VA)",
                        subtitle: "Bank Transfer",
                        fee: 5000,
                        method: "VA Mandiri",
                      ),
                     
                      _buildPaymentOption(
                      
                        title: "BNI (VA)",
                        subtitle: "Bank Transfer",
                        fee: 5000,
                        method: "VA BNI",
                      ),
                       _buildPaymentOption(
                     
                        title: "BRI (VA)",
                        subtitle: "Bank Transfer",
                        fee: 5000,
                        method: "VA BRI",
                      ),
                        _buildPaymentOption(
                       
                        title: "Permata (VA)",
                        subtitle: "Bank Transfer",
                        fee: 5000,
                        method: "VA Permata",
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _buildPaymentOption({

  required String title,
  required String subtitle,
  required int fee,
  required String method,
}) {
  bool isSelected = _kodeMethod == method;

  return ListTile(
    leading: Icon(getMetodeIcon(method), color: Colors.grey, size: 32),
    title: Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
    ),
    subtitle: Text(
      "$subtitle - Rp ${fee.toString()}",
      style: const TextStyle(fontSize: 14, color: Colors.black54),
    ),
    trailing: isSelected
        ? Icon(Icons.check_circle, color: primaryColor)
        : Icon(Icons.radio_button_unchecked, color: Colors.grey),
    onTap: () {
      setState(() {
        _kodeMethod = method;
        _textMethod = title;
        _biayaPembayaran = fee;
      });
      Navigator.of(context).pop(); // Tutup dialog
    },
  );
}


}

