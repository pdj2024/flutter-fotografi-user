import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/utils/shimmer_placeholder.dart';
import 'package:mpjnew/src/data/models/paket_model.dart';
import 'package:mpjnew/src/data/models/vendor_model.dart';
import 'package:mpjnew/src/features/customer/widget/offer_card.dart';
import 'package:mpjnew/src/features/customer/widget/vendor_bio_card.dart';
import 'package:mpjnew/src/features/customer/services/paket_service.dart';
import 'package:mpjnew/src/features/customer/widget/custom_back_button.dart';

class VendorListPackagePage extends StatefulWidget {
  final VendorModel vendor;

  const VendorListPackagePage({super.key, required this.vendor});

  @override
  State<VendorListPackagePage> createState() => _VendorListPackagePageState();
}

class _VendorListPackagePageState extends State<VendorListPackagePage> {
  bool isLoading = true;
  String? errorMessage;
  List<PaketModel> paketList = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final data = await PaketService().getAll(
        idVendor: widget.vendor.noId,
        status: 'aktif',
      );
      print("==== DATA PAKET: $data");
      setState(() {
        paketList = data;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F9F9),
        elevation: 1,
        leading: CustomBackButton(),
        title: Text(
          "Daftar Paket",
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      backgroundColor: const Color(0xfff9f9f9),
      body: RefreshIndicator(
        onRefresh: _fetchData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              VendorBioCard(
                vendor: widget.vendor,
                isListPackagePage: true,
              ),
              Divider(),
              SizedBox(
                height: 10,
              ),
              if (isLoading)
                Column(
                  children: List.generate(
                    4,
                    (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: ShimmerPlaceholder(
                        height: 150,
                        radius: 10,
                      ),
                    ),
                  ),
                )
              else if (errorMessage != null)
                Center(
                  child: Text(
                    "Gagal memuat paket: $errorMessage",
                    style: const TextStyle(color: Colors.red),
                  ),
                )
              else if (paketList.isEmpty)
                const Center(child: Text("Belum ada paket tersedia."))
              else
                Column(
                  children: paketList.map(
                    (paket) {
                      return OfferCard(
                        paket: paket,
                        vendorId: widget.vendor.noId,
                        userNameVendor: widget.vendor.username,
                        idMediaVendor: widget.vendor.idMedia,
                      );
                    },
                  ).toList(),
                ),
              SizedBox(
                height: 100,
              )
            ],
          ),
        ),
      ),
      floatingActionButton: paketList.length > 1
          ? FloatingActionButton(
              onPressed: _fetchData,
              backgroundColor: Constants.primaryColor,
              child: const Icon(Icons.refresh, color: Colors.white),
              tooltip: 'Refresh Paket',
            )
          : null,
    );
  }
}
