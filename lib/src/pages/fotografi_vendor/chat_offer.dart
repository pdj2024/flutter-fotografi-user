import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/constants.dart';
import '../providers/custom_back_button.dart';

class ChatOffer extends StatefulWidget {
  const ChatOffer({super.key});

  @override
  State<ChatOffer> createState() => _ChatOfferState();
}

class _ChatOfferState extends State<ChatOffer> {
  final TextEditingController _namaPaketController = TextEditingController();
  final TextEditingController _hargaController = TextEditingController();
  final TextEditingController _tanggalController = TextEditingController();
final TextEditingController _jamMulaiController = TextEditingController();
final TextEditingController _menitMulaiController = TextEditingController();
  final TextEditingController _lokasiController = TextEditingController();
  final TextEditingController _durasiJamController = TextEditingController();
  final TextEditingController _durasiMenitController = TextEditingController();
  final TextEditingController rincianController = TextEditingController();

 
  final NumberFormat _currencyFormat = NumberFormat("#,##0", "id_ID");

  String _selectedZonaWaktu = 'WIB';

  @override
  void initState() {
    super.initState();
    _hargaController.text = _currencyFormat.format(0);
    _durasiJamController.text = "1";
    _durasiMenitController.text = "0";
    _jamMulaiController.text = "09";
     _menitMulaiController.text = "00";

    _hargaController.addListener(() {
      final text = _hargaController.text.replaceAll('.', '').replaceAll(',', '');
      final value = int.tryParse(text) ?? 0;
      final formatted = _currencyFormat.format(value);
      if (_hargaController.text != formatted) {
        _hargaController.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F9F9),
        elevation: 0,
        title: const Text(
          "Penawaran Kustom",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: const CustomBackButton(),
      ),
      backgroundColor: const Color(0xfff9f9f9),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // const Text(
            //   "Buat Penawaran",
            //   style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            // ),
            // const SizedBox(height: 24),

            _buildTextField(label: "Nama Paket", controller: _namaPaketController),

            _buildHargaField(),

            _buildTanggalField(context),

            _buildJamMulaiField(context),

            _buildTextField(label: "Lokasi", controller: _lokasiController),

            _buildDurasiField(),

            _buildMultilineField(label: "Rincian", controller: rincianController),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Aksi saat tombol ditekan
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Constants.primaryColorVendor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Kirim",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              // borderSide: BorderSide(color: Constants.primaryColorVendor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Constants.primaryColorVendor, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
  Widget _buildMultilineField({
  required String label,
  required TextEditingController controller,
  int minLines = 3,
  int maxLines = 6,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 6),
      TextField(
        controller: controller,
        keyboardType: TextInputType.multiline,
        minLines: minLines,
        maxLines: maxLines,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            // borderSide: BorderSide(color: Constants.primaryColorVendor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Constants.primaryColorVendor, width: 2),
          ),
        ),
      ),
      const SizedBox(height: 16),
    ],
  );
}


  Widget _buildHargaField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Harga", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: _hargaController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            prefixText: "IDR ",
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              // borderSide: BorderSide(color: Constants.primaryColorVendor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Constants.primaryColorVendor, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTanggalField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Tanggal", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: _tanggalController,
          readOnly: true,
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime(2100),
              locale: const Locale('id', 'ID'),
            );
            if (picked != null) {
              final formatted = DateFormat("EEEE, d MMMM yyyy", "id_ID").format(picked);
              _tanggalController.text = formatted;
            }
          },
          decoration: InputDecoration(
            hintText: "Pilih tanggal",
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              // borderSide: BorderSide(color: Constants.primaryColorVendor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Constants.primaryColorVendor, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }


Widget _buildJamMulaiField(BuildContext context) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text("Jam Mulai", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      Row(
        children: [
          // Input Jam:Menit
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 35,
                  child: TextField(
                    controller: _jamMulaiController,
                    keyboardType: TextInputType.number,
                    maxLength: 2,
                    textAlign: TextAlign.center,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(2),
                    ],
                    onTap: () => _jamMulaiController.selection = TextSelection(
                      baseOffset: 0,
                      extentOffset: _jamMulaiController.text.length,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: 'HH',
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Constants.primaryColorVendor, width: 1.5),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                       borderSide: const BorderSide(color: Colors.grey),
                      ),
                    ),
                  ),
                ),
                const Text(":", style: TextStyle(fontSize: 16)),
                SizedBox(
                  width: 35,
                  child: TextField(
                    controller: _menitMulaiController,
                    keyboardType: TextInputType.number,
                    maxLength: 2,
                    textAlign: TextAlign.center,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(2),
                    ],
                    onTap: () => _menitMulaiController.selection = TextSelection(
                      baseOffset: 0,
                      extentOffset: _menitMulaiController.text.length,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: 'MM',
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Constants.primaryColorVendor, width: 1.5),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Dropdown Zona Waktu
          DropdownButton<String>(
            value: _selectedZonaWaktu,
            items: ['WIB', 'WITA', 'WIT']
                .map((zona) => DropdownMenuItem(value: zona, child: Text(zona)))
                .toList(),
            onChanged: (newValue) {
              setState(() {
                _selectedZonaWaktu = newValue!;
              });
            },
          ),
        ],
      ),
      const SizedBox(height: 16),
    ],
  );
}












  Widget _buildDurasiField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Durasi", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                label: "Jam",
                controller: _durasiJamController,
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                label: "Menit",
                controller: _durasiMenitController,
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
