import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/data/repositories/kota_provider.dart';
import 'package:mpjnew/src/features/customer/viewmodels/kategori_provider.dart';
import 'package:mpjnew/src/features/customer/viewmodels/paket_provider.dart';
import 'package:mpjnew/src/features/customer/widget/field/chips_widget.dart';
import 'package:provider/provider.dart';

class CustomDropdownSearch extends StatefulWidget {
  final String label;
  final String data; // kota
  final bool multiSelect; // single or multi
  final List<String>? selectedValues; // for multi selection
  final String? selectedValue; // for single
  final Function(dynamic)? onChanged; // returns String or List<String>
  final String? errorMessage;
  final Function(dynamic)? onDelete; // Multi Selection

  const CustomDropdownSearch({
    super.key,
    required this.label,
    required this.data,
    required this.onChanged,
    this.multiSelect = false,
    this.selectedValues,
    this.selectedValue,
    this.errorMessage,
    this.onDelete,
  });

  @override
  State<CustomDropdownSearch> createState() => _CustomDropdownSearchState();
}

class _CustomDropdownSearchState extends State<CustomDropdownSearch> {
  String search = "";
  String? selected;
  List<String> selectedList = [];

  @override
  void initState() {
    super.initState();
    selected = widget.selectedValue;
    selectedList = widget.selectedValues ?? [];
  }

  @override
  void didUpdateWidget(covariant CustomDropdownSearch oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.selectedValue != oldWidget.selectedValue) {
      setState(() {
        selected = widget.selectedValue;
      });
    }

    if (widget.selectedValues != oldWidget.selectedValues) {
      setState(() {
        selectedList = widget.selectedValues ?? [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = _getListData();
    final isMulti = widget.multiSelect;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: const TextStyle(fontSize: 14)),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () => isMulti ? _openMultiModal(list) : _openSingleModal(list),
          child: _dropdownBox(isMulti),
        ),
        if (widget.errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 5),
            child: Text(widget.errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 14)),
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  // =========================================================
  // UI DROPDOWN BOX
  // =========================================================
  Widget _dropdownBox(bool isMulti) {
    if (isMulti) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: widget.selectedValues!.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Text(
                    "Pilih ${widget.data}",
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                )
              : Wrap(
                  spacing: 8,
                  children: widget.selectedValues!.map(
                    (item) {
                      return ChipsWidget(
                        idData: item,
                        label: item,
                        onDelete: (id) {
                          selectedList.remove(id);
                          widget.onDelete!(id);
                        },
                      );
                    },
                  ).toList(),
                ),
        ),
      );
    }

    // --- SINGLE SELECT ---
    String text = selected != null && selected! != ""
        ? selected!
        : "Pilih ${widget.data}";

    return Container(
      width: double.infinity,
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: TextStyle(
            color: text.contains("Pilih") ? Colors.grey : Colors.black,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  // =========================================================
  // FETCH LIST BASED ON TYPE
  // =========================================================
  List<String> _getListData() {
    switch (widget.data.toLowerCase()) {
      case "kota":
        return context
            .watch<KotaProvider>()
            .kotaList
            .map((e) => e.namaKota)
            .toList();
      case "kategori":
        return context
            .watch<KategoriProvider>()
            .kategoriList
            .map((e) => e.nama_kategori)
            .toList();
      default:
        return context
            .watch<PaketProvider>()
            .paketList
            .map((e) => e.nama_paket)
            .toList();
    }
  }

  // =========================================================
  // SINGLE SELECT MODAL
  // =========================================================
  Future<void> _openSingleModal(List<String> list) async {
    search = "";

    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      backgroundColor: Colors.transparent, // wajib agar blur terlihat

      builder: (_) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.pop(context), // klik luar → close ✔

          child: Stack(
            children: [
              /// ---- Blur Background ----
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: Container(color: Colors.black.withOpacity(0.2)),
              ),

              /// ---- Bottom Sheet ----
              Align(
                alignment: Alignment.bottomCenter,
                child: _modalBase(
                  title: "Pilih ${widget.data}",
                  height: MediaQuery.of(context).size.height * 0.60,
                  body: StatefulBuilder(
                    builder: (_, setState_) => Column(
                      children: [
                        _searchBar((v) => setState_(() => search = v)),
                        const SizedBox(height: 12),
                        Expanded(
                          child: ListView(
                            children: list
                                .where(_filter)
                                .map((v) => ListTile(
                                      title: Text(v),
                                      onTap: () => Navigator.pop(context, v),
                                    ))
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (result != null) {
      setState(() => selected = result);
      widget.onChanged?.call(result);
    }
  }

  // =========================================================
  // MULTI SELECT MODAL
  // =========================================================
  void _openMultiModal(List<String> list) {
    search = "";
    List<String> temp = List.from(selectedList);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black12,
      builder: (_) => Stack(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context), // <-- close modal
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                color: Colors.black.withOpacity(0.2), // opsional gelap
              ),
            ),
          ),
          StatefulBuilder(builder: (_, setM) {
            return _modalBase(
              height: 350,
              title: "Pilih ${widget.data}",
              body: Column(
                children: [
                  _searchBar((v) => setM(() => search = v)),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView(
                      children: list.where(_filter).map((v) {
                        final pick = temp.contains(v);
                        return GestureDetector(
                          onTap: () {
                            setM(() => pick ? temp.remove(v) : temp.add(v));
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                vertical: 10, horizontal: 20),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5),
                              color: pick
                                  ? Constants.primaryColorVendor.withAlpha(50)
                                  : Colors.white,
                            ),
                            child: Text(
                              v,
                              style: TextStyle(
                                  color: pick
                                      ? Constants.primaryColorVendor
                                      : Colors.black,
                                  fontSize: 14),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Constants.primaryColorVendor,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 22, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        setState(() => selectedList = temp);
                        widget.onChanged?.call(selectedList);
                        Navigator.pop(context);
                      },
                      child: const Text(
                        "Simpan",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // =========================================================
  // SHARED MODAL BUILDER
  // =========================================================
  Widget _modalBase(
      {required String title, required Widget body, double height = 480}) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Material(
        color: Colors.transparent,
        child: Container(
          height: height,
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: Column(children: [
            Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.only(bottom: 15),
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(20))),
            Text(title,
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            Expanded(child: body),
          ]),
        ),
      ),
    );
  }

  bool _filter(String e) => e.toLowerCase().contains(search.toLowerCase());
  Widget _searchBar(Function(String) onChange) => TextField(
        decoration: _input("Cari ${widget.data}..."),
        onChanged: onChange,
      );
  InputDecoration _input(String h) => InputDecoration(
        hintText: h,
        filled: true,
        fillColor: Colors.grey.shade100,
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none),
      );
}
