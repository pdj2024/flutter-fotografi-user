import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:provider/provider.dart';
import '../providers/custom_back_button.dart';
import '../providers/navigation_provider.dart';

class BiodataPage extends StatefulWidget {
  const BiodataPage({super.key});

  @override
  State<BiodataPage> createState() => _BiodataPageState();
}

class _BiodataPageState extends State<BiodataPage> {
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _ktpController = TextEditingController();

  String? _selectedKota;

  File? _fotoKtp;
  File? _fotoPegangKtp;

  final ImagePicker _picker = ImagePicker();

  final List<String> kotaList = [
    "Jakarta",
    "Bandung",
    "Surabaya",
    "Yogyakarta",
    "Semarang",
    "Medan",
    "Bali",
    "Makassar",
  ];

  Future<void> _pickImageFromCamera(bool isPegangKtp) async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.camera);
    if (picked != null) {
      setState(() {
        if (isPegangKtp) {
          _fotoPegangKtp = File(picked.path);
        } else {
          _fotoKtp = File(picked.path);
        }
      });
    }
  }
   Future<void> _pickImageFromGallery(bool isPegangKtp) async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        if (isPegangKtp) {
          _fotoPegangKtp = File(picked.path);
        } else {
          _fotoKtp = File(picked.path);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F9F9),
        elevation: 0,
        title: const Text(
          "Biodata Fotografer",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: true // context.read<NavigationProvider>().statusUser == 'accepted'
      ? const CustomBackButton()
      : null,
      ),
      backgroundColor: const Color(0xfff9f9f9),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField(label: "Nama Lengkap", controller: _namaController),
            _buildDropdownSearch(),
            _buildTextField(
              label: "Nomor KTP",
              controller: _ktpController,
              keyboardType: TextInputType.number,
            ),
           _buildImageUploadSection(
              label: "Upload Foto KTP",
              file: _fotoKtp,
              onTap: () => _pickImageFromGallery(false),
              icon: Icons.photo_library
            ),
            _buildImageUploadSection(
              label: "Upload Foto Sambil Memegang KTP (Ambil Foto)",
              file: _fotoPegangKtp,
              onTap: () => _pickImageFromCamera(true),
               icon: Icons.camera_alt
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                String nama = _namaController.text.trim();
                String? kota = _selectedKota;
                String ktp = _ktpController.text.trim();

                if (nama.isEmpty || kota == null || ktp.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Harap isi semua data dengan lengkap")),
                  );
                  return;
                }

                if (_fotoKtp == null || _fotoPegangKtp == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Harap upload kedua foto KTP")),
                  );
                  return;
                }

                // ✅ Perhatikan bagian ini: tambahkan async-await
                // await context.read<NavigationProvider>().setStatusUser("pending");
                context.read<NavigationProvider>().startNavigateVendor(context);

                // lanjutkan simpan data sesuai kebutuhan
              },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Constants.primaryColorVendor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Simpan Biodata",
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
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  BorderSide(color: Constants.primaryColorVendor, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDropdownSearch() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Kota Domisili",
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
       DropdownSearch<String>(
  items: kotaList,
  selectedItem: _selectedKota,
  onChanged: (value) {
    setState(() {
      _selectedKota = value;
    });
  },
  popupProps: PopupProps.bottomSheet(
    showSearchBox: true,
  ),
  dropdownDecoratorProps: DropDownDecoratorProps(
    dropdownSearchDecoration: InputDecoration(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
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
),

        const SizedBox(height: 16),
      ],
    );
  }

Widget _buildImageUploadSection({
  required String label,
  required File? file,
  required VoidCallback onTap,
  required IconData icon,  // pastikan bukan Icon, dan bukan nullable
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          height: 180,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: Constants.primaryColorVendor,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: file != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    file,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                )
              : Center(
                  child: Icon(
                    icon,
                    size: 40,
                    color: Colors.grey,
                  ),
                ),
        ),
      ),
      const SizedBox(height: 16),
    ],
  );
}

}