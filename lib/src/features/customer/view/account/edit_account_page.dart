import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/data/models/customer_model.dart';
import 'package:mpjnew/src/data/repositories/kota_provider.dart';
import 'package:mpjnew/src/features/auth/services/user_provider.dart';
import 'package:mpjnew/src/features/customer/services/customer_service.dart';
import 'package:mpjnew/src/features/customer/widget/avatar_circle.dart';
import 'package:mpjnew/src/features/customer/widget/custom_back_button.dart';
import 'package:mpjnew/src/features/customer/widget/dialog/custom_snackbar.dart';
import 'package:mpjnew/src/features/customer/widget/field/custom_dropdown_search.dart';
import 'package:mpjnew/src/features/customer/widget/field/custom_text_field.dart';
import 'package:provider/provider.dart';

class EditAccountPage extends StatefulWidget {
  const EditAccountPage({super.key});

  @override
  State<EditAccountPage> createState() => _EditAccountPageState();
}

class _EditAccountPageState extends State<EditAccountPage> {
  CustomerService customerService = CustomerService();

  final _formKey = GlobalKey<FormState>();
  TextEditingController nameController = TextEditingController();
  TextEditingController usernameController = TextEditingController();
  String? selectedKota;

  // Error Message
  String? nameError;
  String? usernameError;
  String? kotaError;

  Future<void> update(BuildContext context) async {
    final userProvider = context.read<UserProvider>();
    final kotaId = context.read<KotaProvider>().getKota(selectedKota!).noId;
    final customer = userProvider.customer!;
    try {
      final updatedCustomer = customer.copyWith(
        namaDisplay: nameController.text.trim().isNotEmpty
            ? nameController.text.trim()
            : customer.namaDisplay,
        userName: usernameController.text.trim().isNotEmpty
            ? usernameController.text.trim()
            : customer.userName,
        kota: kotaId,
      );

      final result = await customerService.update(updatedCustomer);

      print(result);
      context
          .read<UserProvider>()
          .checkLoginGoogle(role: 'customer', silent: true);

      CustomSnackbar.showSuccessSnackbar(context, "Berhasil memperbarui data");
      Navigator.of(context).pop();
    } catch (e) {
      print('Error updating customer: $e');
      CustomSnackbar.showErrorSnackbar(context, "Gagal memperbarui data");
    }
  }

  void loadData(CustomerModel customer) {
    setState(() {
      nameController.text = customer.namaDisplay;
      usernameController.text = customer.userName;
      selectedKota = customer.namaKota;
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    final userProvider = context.read<UserProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadData(userProvider.customer!);
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final customer = userProvider.customer!;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F9F9),
        leading: CustomBackButton(),
        elevation: 1,
        title: Text(
          "Edit Profile",
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
          child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Alert
              if (customer.userName == "" || customer.namaDisplay == "")
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    shape: BoxShape.rectangle,
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.orange.shade300),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orange.shade800,
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          "Demi keamanan dan pengalaman yang lebih baik, mohon lengkapi data profil Anda sebelum melanjutkan.",
                          maxLines: null,
                          overflow: TextOverflow.visible,
                          style: TextStyle(color: Colors.orange.shade800),
                        ),
                      ),
                    ],
                  ),
                ),

              // Foto Section
              userProvider.photoUrl == null
                  ? Container(
                      width: 82,
                      height: 82,
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.person),
                    )
                  : AvatarCircle(
                      size: 82,
                      imgUrl: userProvider.photoUrl,
                    ),
              SizedBox(
                height: 10,
              ),
              // GestureDetector(
              //   onTap: () {
              //     context.read<NavigationProvider>().navigateToPage(
              //           context,
              //           ImageUploadPage(
              //             type: "profile",
              //           ),
              //           targetTabIndex: 3,
              //           targetPage: "ImageUploadPage",
              //         );
              //     print("Ubah Foto Profil");
              //   },
              //   child: Text(
              //     "Ubah foto Profil",
              //     style: TextStyle(
              //       fontWeight: FontWeight.bold,
              //       color: Constants.primaryColor,
              //     ),
              //   ),
              // ),
              SizedBox(
                height: 30,
              ),
              // Form Section
              CustomTextField(
                label: "Nama Lengkap",
                controller: nameController,
                placeholder: "Nama Lengkap",
                keyboardType: TextInputType.text,
                errorMessage: nameError,
              ),
              CustomTextField(
                label: "Username",
                controller: usernameController,
                placeholder: "Username",
                keyboardType: TextInputType.text,
                errorMessage: usernameError,
              ),
              CustomDropdownSearch(
                selectedValue: selectedKota,
                label: 'Kota Domisili',
                errorMessage: kotaError,
                data: "kota",
                onChanged: (value) {
                  setState(() {
                    selectedKota = value;
                  });
                },
              ),

              // Button Section
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 50),
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    backgroundColor: Constants.primaryColorVendor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () async {
                    var isValid = validateForm();
                    if (!isValid) return;
                    await update(context);
                  },
                  child: Text(
                    "Simpan",
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      )),
    );
  }

  bool validateForm() {
    bool result = true;

    final nama = nameController.text.trim();
    final username = usernameController.text.trim();
    final kota = selectedKota;

    // Reset Error Variable
    nameError = null;
    usernameError = null;
    kotaError = null;

    // =============================
    // VALIDASI NAMA
    // =============================
    if (nama.isEmpty) {
      nameError = "Nama lengkap tidak boleh kosong";
      result = false;
    } else if (nama.length < 3) {
      nameError = "Nama terlalu pendek";
      result = false;
    } else {
      nameError = null;
    }

    // =============================
    // VALIDASI USERNAME
    // =============================
    if (username.isEmpty) {
      usernameError = "Username lengkap tidak boleh kosong";
      result = false;
    } else if (username.length < 3) {
      usernameError = "Username terlalu pendek";
      result = false;
    } else {
      usernameError = null;
    }

    // =============================
    // VALIDASI KOTA
    // =============================
    if (kota == null || kota == "") {
      kotaError = "Kota domisili wajib dipilih";
      result = false;
    } else {
      kotaError = null;
    }

    // =============================
    // UPDATE UI
    // =============================
    setState(() {});

    print("==============================");
    print("Hasil Validasi: $result");
    print("==============================");

    return result;
  }
}
