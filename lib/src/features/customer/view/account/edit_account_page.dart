import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/utils/dropdown_search_config.dart';
import 'package:mpjnew/src/data/models/customer_model.dart';
import 'package:mpjnew/src/data/models/kota_model.dart';
import 'package:mpjnew/src/features/auth/services/user_provider.dart';
import 'package:mpjnew/src/features/customer/services/customer_service.dart';
import 'package:mpjnew/src/features/customer/widget/avatar_circle.dart';
import 'package:mpjnew/src/features/customer/widget/custom_back_button.dart';
import 'package:mpjnew/src/features/customer/widget/dialog/custom_snackbar.dart';
import 'package:mpjnew/src/features/customer/widget/field/custom_text_field.dart';
import 'package:mpjnew/src/features/customer/widget/field/single_select_dropdown.dart';
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
  TextEditingController emailController = TextEditingController();
  KotaModel? selectedKota;

  // Error Message
  String? nameError;
  String? usernameError;
  String? kotaError;
  String? emailError;

  Future<void> update(BuildContext context) async {
    final userProvider = context.read<UserProvider>();
    final kotaId = selectedKota?.noId;
    final customer = userProvider.customer!;
    try {
      final updatedCustomer = customer.copyWith(
        namaDisplay: nameController.text.trim().isNotEmpty
            ? nameController.text.trim()
            : customer.namaDisplay,
        userName: usernameController.text.trim().isNotEmpty
            ? usernameController.text.trim()
            : customer.userName,
        email: emailController.text.trim().isNotEmpty
            ? emailController.text.trim()
            : customer.email,
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
      emailController.text = customer.email;
      selectedKota = KotaModel(
        noId: customer.kota,
        namaKota: customer.namaKota,
        keterangan: "",
        status: "",
      );
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
              CustomTextField(
                label: "Email",
                controller: emailController,
                readOnly: true,
                placeholder: "Email",
                keyboardType: TextInputType.text,
                errorMessage: emailError,
              ),
              SingleSelectDropdown<KotaModel>(
                config: KotaDropdownConfig(
                  label: 'Kota Domisili',
                  errorMessage: kotaError,
                  debounceDuration: 500, // Custom debounce
                  enableRemoteSearch: true, // Enable remote API call
                ),
                selectedValue: selectedKota,
                onChanged: (value) {
                  setState(() => selectedKota = value);
                  print('Selected kota: ${value?.namaKota}');
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
      usernameError = "Username tidak boleh kosong";
      result = false;
    } else if (username.length < 3) {
      usernameError = "Username minimal 3 karakter";
      result = false;
    } else if (username.contains(' ')) {
      usernameError = "Username tidak boleh mengandung spasi";
      result = false;
    } else if (username != username.toLowerCase()) {
      usernameError = "Username harus menggunakan huruf kecil";
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
