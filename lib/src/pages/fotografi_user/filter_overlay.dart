import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mpjnew/src/pages/providers/custom_back_button.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../providers/constants.dart';
import '../providers/navigation_provider.dart';
import 'services/kategori_service.dart';
import 'services/kota_service.dart';
import 'services/vendor_service.dart';

class FilterOverlay extends StatefulWidget {
  final String? selectedCategory;
  final String? selectedLocation;
  final String? selectedPhotographer;
  final String? minPrice;
  final String? maxPrice;
  final ValueChanged<Map<String, String?>> onApply;
  final ValueChanged<Map<String, String?>> onReset;
  final VoidCallback onClose;

  const FilterOverlay({
    super.key,
    required this.selectedCategory,
    required this.selectedLocation,
    required this.selectedPhotographer,
    required this.minPrice,
    required this.maxPrice,
    required this.onApply,
    required this.onReset,
    required this.onClose,
  });

  @override
  State<FilterOverlay> createState() => _FilterOverlayState();
}

class _FilterOverlayState extends State<FilterOverlay> {
  // List fetched dari API
  List<Map<String, String>> kategoriList = [];
  List<Map<String, String>> locationList = [];
  List<Map<String, String>> photographerList = [];

  // Filtered for autocomplete
  List<Map<String, String>> filteredCategories = [];
  List<Map<String, String>> filteredLocations = [];
  List<Map<String, String>> filteredPhotographers = [];

  // Controllers
  final TextEditingController categoryController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController photographerController = TextEditingController();
  final TextEditingController minPriceController = TextEditingController();
  final TextEditingController maxPriceController = TextEditingController();

  // Focus Nodes
  final FocusNode categoryFocusNode = FocusNode();
  final FocusNode locationFocusNode = FocusNode();
  final FocusNode photographerFocusNode = FocusNode();
  final FocusNode minPriceFocusNode = FocusNode();
  final FocusNode maxPriceFocusNode = FocusNode();

  // Error flags
  bool categoryHasError = false;
  bool locationHasError = false;
  bool photographerHasError = false;

  // Selected ID
  String? selectedCategoryId;
  String? selectedLocationId;
  String? selectedPhotographerId;

  // Error flags
  bool isCategoryOpen= false;
  bool isLocationOpen = false;
  bool isPhotographerOpen = false;

  bool isCategoryLoading = false;
bool isLocationLoading = false;
bool isPhotographerLoading = false;


  Timer? _locationDebounce;
  Timer? _categoryDebounce;
  Timer? _photographerDebounce;

  @override
void initState() {
  super.initState();

    print('🔍 selectedCategory: ${widget.selectedCategory}');
    print('📍 selectedLocation: ${widget.selectedLocation}');
    print('📸 selectedPhotographer: ${widget.selectedPhotographer}');
    print('💰 minPrice: ${widget.minPrice}');
    print('💎 maxPrice: ${widget.maxPrice}');

  // Set min/max price
  minPriceController.text = widget.minPrice ?? '';
  maxPriceController.text = widget.maxPrice ?? '';

  // Listeners untuk filter pencarian



locationController.addListener(() {
  if (_locationDebounce?.isActive ?? false) _locationDebounce!.cancel();

  setState(() {
    isLocationLoading = true; // ✅ langsung tampil spinner
  });

  _locationDebounce = Timer(const Duration(milliseconds: 500), () {
    final query = locationController.text.trim();
    fetchLocationsFromApi(query);
  });
});


categoryController.addListener(() {
  if (_categoryDebounce?.isActive ?? false) _categoryDebounce!.cancel();

  setState(() {
    isCategoryLoading = true; // ✅ langsung tampil spinner
  });

  _categoryDebounce = Timer(const Duration(milliseconds: 500), () {
    final query = categoryController.text.trim();
    fetchCategorysFromApi(query);
  });
});

photographerController.addListener(() {
  if (_photographerDebounce?.isActive ?? false) _photographerDebounce!.cancel();

  setState(() {
    isPhotographerLoading = true; // ✅ langsung tampil spinner
  });

  _photographerDebounce = Timer(const Duration(milliseconds: 500), () {
    final query = photographerController.text.trim();
    fetchPhotographersFromApi(query);
  });
});






  // ====== Tambah focus listener global ======
  categoryFocusNode.addListener(() {
    if (categoryFocusNode.hasFocus) {
      _closeAllExcept('category');
      setState(() => isCategoryOpen = true);
    } else {
      setState(() => isCategoryOpen = false);
    }
  });

  locationFocusNode.addListener(() {
    if (locationFocusNode.hasFocus) {
      _closeAllExcept('location');
      setState(() => isLocationOpen = true);
    } else {
      setState(() => isLocationOpen = false);
    }
  });

  photographerFocusNode.addListener(() {
    if (photographerFocusNode.hasFocus) {
      _closeAllExcept('photographer');
      setState(() => isPhotographerOpen = true);
    } else {
      setState(() => isPhotographerOpen = false);
    }
  });

  minPriceFocusNode.addListener(() {
    if (minPriceFocusNode.hasFocus) _closeAllExcept();
  });

  maxPriceFocusNode.addListener(() {
    if (maxPriceFocusNode.hasFocus) _closeAllExcept();
  });

  // Jalankan setelah frame build pertama
  WidgetsBinding.instance.addPostFrameCallback((_) async {


  // 3️⃣ Kalau ada selectedLocation dari awal, langsung fetch spesifik (supaya filtered list sesuai)
  if (widget.selectedLocation != null && locationController.text.isNotEmpty) {
    fetchLocationsFromApi(locationController.text.trim());
  }

  if (widget.selectedCategory != null && categoryController.text.isNotEmpty) {
    fetchCategorysFromApi(categoryController.text.trim());
  }

  if (widget.selectedPhotographer != null && photographerController.text.isNotEmpty) {
    fetchPhotographersFromApi(photographerController.text.trim());

  
  }

    applySelectedIdsToController();
});
}

void _closeAllExcept([String? except]) {
  if (except != 'category') categoryFocusNode.unfocus();
  if (except != 'location') locationFocusNode.unfocus();
  if (except != 'photographer') photographerFocusNode.unfocus();


  setState(() {
    if (except != 'category') isCategoryOpen = false;
    if (except != 'location') isLocationOpen = false;
    if (except != 'photographer') isPhotographerOpen = false;
  });
}

Future<void> fetchLocationsFromApi(String query) async {

  setState(() {
    isLocationLoading = true; // mulai loading
  });

  try {
    final locationRes = await KotaService().getAll(
      orderBy: 'nama_kota',
      namaKota: query.isEmpty ? null : query, // kalau kosong, kirim null
    );

    final lokasi = locationRes.map((e) => {
      'id': e.no_id,
      'label': e.nama_kota,
    }).toList();

    setState(() {
      filteredLocations = lokasi;
      locationHasError = lokasi.isEmpty;
       isLocationLoading = false; // selesai loading
    });
  } catch (e) {
    print('====== Error fetching lokasi: $e');
    setState(() {
      filteredLocations = [];
      locationHasError = true;
       isLocationLoading = false; // selesai loading
    });
  }
}

Future<void> fetchCategorysFromApi(String query) async {

  setState(() {
    isCategoryLoading = true; // mulai loading
  });

  try {
    final categoryRes = await KategoriService().getAll(
      orderBy: 'nama_kategori',
      namaKategori: query.isEmpty ? null : query, // kalau kosong, kirim null
    );

    final lokasi = categoryRes.map((e) => {
      'id': e.no_id,
      'label': e.nama_kategori,
    }).toList();

    setState(() {
      filteredCategories = lokasi;
      categoryHasError = lokasi.isEmpty;
       isCategoryLoading = false; // selesai loading
    });
  } catch (e) {
    print('====== Error fetching kategori: $e');
    setState(() {
      filteredCategories = [];
      categoryHasError = true;
       isCategoryLoading = false; // selesai loading
    });
  }
}

Future<void> fetchPhotographersFromApi(String query) async {

  setState(() {
    isPhotographerLoading = true; // mulai loading
  });

  try {
    final photographerRes = await VendorService().getAll(
      orderBy: 'username',
      username: query.isEmpty ? null : query, // kalau kosong, kirim null
    );

    final lokasi = photographerRes.map((e) => {
     'id': e.noId,              // "ven_1", "ven_2"
    'username': e.username,    // "vendA", "brandon.honanta"
    'name': e.namaDisplay,     // "Vendor A", "Brandon H"
    'avatar': e.id_media,       // URL avatar (nullable)
    }).toList();

    setState(() {
      filteredPhotographers = lokasi;
      photographerHasError = lokasi.isEmpty;
       isPhotographerLoading = false; // selesai loading
    });
  } catch (e) {
    print('====== Error fetching vendor: $e');
    setState(() {
      filteredPhotographers = [];
      photographerHasError = true;
       isPhotographerLoading = false; // selesai loading
    });
  }
}





  void applySelectedIdsToController() {
    if (widget.selectedCategory != null) {
      final match = kategoriList.firstWhere(
        (item) => item['id'] == widget.selectedCategory,
        orElse: () => {'label': ''},
      );
      categoryController.text = match['label']!;
      selectedCategoryId = widget.selectedCategory;
    }

    if (widget.selectedLocation != null) {
      final match = locationList.firstWhere(
        (item) => item['id'] == widget.selectedLocation,
        orElse: () => {'label': ''},
      );
      locationController.text = match['label']!;
      selectedLocationId = widget.selectedLocation;
    }

    if (widget.selectedPhotographer != null) {
      final match = photographerList.firstWhere(
        (item) => item['id'] == widget.selectedPhotographer,
        orElse: () => {'label': ''},
      );
      photographerController.text = match['label']!;
      selectedPhotographerId = widget.selectedPhotographer;
    }
  }




  @override
  void dispose() {
    categoryController.dispose();
    locationController.dispose();
    photographerController.dispose();
    minPriceController.dispose();
    maxPriceController.dispose();
    categoryFocusNode.dispose();
    locationFocusNode.dispose();
    photographerFocusNode.dispose();
    minPriceFocusNode.dispose();
    maxPriceFocusNode.dispose();
    filteredCategories.clear();
    filteredLocations.clear();
    filteredPhotographers.clear();

     _locationDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width - 40.0;

  
    return WillPopScope(
      onWillPop: () async {
        widget.onClose();
        return false;
      },
      child: GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        FocusScope.of(context).unfocus();
      },
        child: Scaffold(
          backgroundColor: Colors.white.withOpacity(0.96),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildHeader(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    buildLabel('Kategori'),
                    const SizedBox(height: 8),
                    buildSearchableDropdown(
                      controller: categoryController,
                      focusNode: categoryFocusNode,
                      hint: 'Pilih Kategori',
                      items: filteredCategories,
                      allItems: kategoriList,
                      hasError: categoryHasError,
                      isLoading: isCategoryLoading,
                      onSelected: (value) {
                        selectedCategoryId = value['id']; // ✅ simpan ID
                      },
                    ),
                    const SizedBox(height: 20),
                    buildLabel('Lokasi'),
                    const SizedBox(height: 8),
                    buildSearchableDropdown(
                      controller: locationController,
                      focusNode: locationFocusNode,
                      hint: 'Cari Lokasi',
                      items: filteredLocations,
                      allItems: locationList,
                      hasError: locationHasError,
                      isLoading: isLocationLoading,
                      onSelected: (value) {
                        selectedLocationId = value['id']; // ✅ simpan ID
                      },
                    ),
                    const SizedBox(height: 20),
                    buildLabel('Harga (Rp)'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: buildTextInput(
                            controller: minPriceController,
                            focusNode: minPriceFocusNode,
                            hint: 'Min',
                            onChanged: (value) => {} // tempMinPrice = value,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: buildTextInput(
                            controller: maxPriceController,
                            focusNode: maxPriceFocusNode,
                            hint: 'Max',
                            onChanged: (value) => {} // tempMaxPrice = value,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    buildLabel('Nama Fotografer'),
                    const SizedBox(height: 8),
                    buildPhotographerSearch(),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          widget.onApply({
    'id_vendor':  '',
    'username_vendor':  '',
    'id_kategori':  '',
    'nama_kategori': '',
    'min_price':  '',
    'max_price':  '',
    'id_lokasi':  '',
    'nama_lokasi':  '',
  });
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Constants.primaryColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Atur Ulang',
                            style: TextStyle(color: Constants.primaryColor)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          widget.onApply({
                            'id_vendor': selectedPhotographerId, // atau id vendor yang kamu ambil
                            'username_vendor': photographerController.text.trim(),
                            'id_kategori': selectedCategoryId,
                            'nama_kategori': categoryController.text.trim(),
                            'min_price': minPriceController.text.trim(),
                            'max_price': maxPriceController.text.trim(),
                            'id_lokasi': selectedLocationId,
                            'nama_lokasi': locationController.text.trim(),
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Constants.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Pakai',
                          style: TextStyle(color: Colors.white),
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
    );
  }

Widget buildHeader() {
  return Container(
    color: Constants.primaryColor,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    child: Row(
      children: [
        IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () async {
            // ✅ Jalankan logic apply filter sebelum pop
             widget.onApply({
                            'id_vendor': selectedPhotographerId, // atau id vendor yang kamu ambil
                            'username_vendor': photographerController.text.trim(),
                            'id_kategori': selectedCategoryId,
                            'nama_kategori': categoryController.text.trim(),
                            'min_price': minPriceController.text.trim(),
                            'max_price': maxPriceController.text.trim(),
                            'id_lokasi': selectedLocationId,
                            'nama_lokasi': locationController.text.trim(),
                          });

            // ✅ Navigasi tetap seperti CustomBackButton
            final provider = Provider.of<NavigationProvider>(context, listen: false);
            bool allowPop = await provider.onWillPop();
            if (allowPop) {
              Navigator.of(context).pop();
            }
          },
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            'Filter',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  );
}

  Widget buildLabel(String label) {
    return Text(
      label,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
    );
  }

  // Build functions (buildSearchableDropdown, buildPhotographerSearch, buildTextInput) aku lanjutkan di bawah (karena kepanjangan limit post)...
Widget buildSearchableDropdown({
  required TextEditingController controller,
  required FocusNode focusNode,
  required String hint,
  required List<Map<String, String>> items,
  required List<Map<String, String>> allItems,
  required bool hasError,
  required bool isLoading,
  required ValueChanged<Map<String, String>> onSelected,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      TextField(
        controller: controller,
        focusNode: focusNode,
        decoration: InputDecoration(
          hintText: hint,
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    controller.clear();
                    focusNode.unfocus();
                  },
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: hasError ? Colors.red : Colors.grey,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: hasError ? Colors.red : Colors.grey,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: hasError ? Colors.red : Constants.primaryColor,
              width: 2,
            ),
          ),
        ),
        style: TextStyle(
          color: hasError ? Colors.red : Colors.black,
        ),
      ),
      if (focusNode.hasFocus)
        Container(
          margin: const EdgeInsets.only(top: 4),
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: isLoading
              ? Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : items.isEmpty
              ? Text(
                  'Pencarian tidak ada',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                )
              : Scrollbar(
                  child: ListView(
                    shrinkWrap: true,
                    children: items.map((item) {
                      return ListTile(
                        title: Text(item['label'] ?? ''),
                        onTap: () {
                          controller.text = item['label']!;
                          onSelected(item); // return full map: {id, label}
                          FocusScope.of(context).unfocus();
                        },
                      );
                    }).toList(),
                  ),
                ),
        ),
    ],
  );
}


Widget buildPhotographerSearch() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      TextField(
        controller: photographerController,
        focusNode: photographerFocusNode,
        onChanged: (value) {
          
        },
        decoration: InputDecoration(
          hintText: 'Cari Nama Fotografer',
          suffixIcon: photographerController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    photographerController.clear();
                    // Reset filter juga kalau perlu
                    setState(() {
                      filteredPhotographers = List.from(photographerList);
                    });
                    photographerFocusNode.unfocus();
                  },
                )
              : null,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: photographerHasError ? Colors.red : Colors.grey,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: photographerHasError ? Colors.red : Colors.grey,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: photographerHasError ? Colors.red : Constants.primaryColor,
              width: 2,
            ),
          ),
        ),
        style: TextStyle(
          color: photographerHasError ? Colors.red : Colors.black,
        ),
      ),
      if (photographerFocusNode.hasFocus)
        Container(
          margin: const EdgeInsets.only(top: 4),
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          constraints: BoxConstraints(
            maxHeight: 200, // batas tinggi supaya list bisa scroll
          ),
          child: 
          
          isPhotographerLoading
              ? Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
           
              : filteredPhotographers.isEmpty
              ? Text(
                  'Pencarian tidak ada',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                )
              : Scrollbar(
                  thumbVisibility: true, // agar scrollbar selalu muncul saat scroll
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: filteredPhotographers.length,
                    itemBuilder: (context, index) {
                      final photographer = filteredPhotographers[index];
                      // Amanin null dengan ?? '' supaya gak error
                      final String avatarUrl = 
                         photographer['avatar'] ?? '';
                      final String name = photographer['username'] ?? '';

                      return ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: avatarUrl.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: avatarUrl,
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) =>
                                      Shimmer.fromColors(
                                    baseColor: Colors.grey.shade300,
                                    highlightColor: Colors.grey.shade100,
                                    child: Container(
                                      width: 40,
                                      height: 40,
                                      color: Colors.white,
                                    ),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      CircleAvatar(
                                    radius: 20,
                                    backgroundColor: Colors.grey.shade200,
                                    child: const Icon(Icons.person,
                                        color: Colors.grey),
                                  ),
                                )
                              : CircleAvatar(
                                  radius: 20,
                                  backgroundColor: Colors.grey.shade200,
                                  child:
                                      const Icon(Icons.person, color: Colors.grey),
                                ),
                        ),
                        title: Text(name),
                        onTap: () {
                           setState(() {
                              photographerController.text = name;
                              selectedPhotographerId = photographer['id']; // ✅ simpan ID di variabel state
                            });
                          FocusScope.of(context).unfocus();
                        },
                      );
                    },
                  ),
                ),
        ),
    ],
  );
}


Widget buildTextInput({
  required TextEditingController controller,
  required FocusNode focusNode,
  required String hint,
  required ValueChanged<String> onChanged,
}) {
  // Listener fokus: cuma untuk select all text
  focusNode.addListener(() {
    if (focusNode.hasFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.selection = TextSelection(
          baseOffset: 0,
          extentOffset: controller.text.length,
        );
      });
    }
  });

  return TextField(
    controller: controller,
    focusNode: focusNode,
    keyboardType: TextInputType.number,
   onTap: () => _closeAllExcept(
  focusNode == minPriceFocusNode ? 'minPrice' : 'maxPrice'
),
    decoration: InputDecoration(
      hintText: hint,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: Constants.primaryColor,
          width: 2,
        ),
      ),
    ),
    onChanged: (value) {
      // Hilangkan titik sebelum format ulang
      String numericValue = value.replaceAll('.', '');
      if (numericValue.isEmpty) {
        controller.text = '';
        onChanged('');
        return;
      }

      // Format ribuan pakai titik
      String formatted = NumberFormat('#,###', 'id_ID')
          .format(int.parse(numericValue))
          .replaceAll(',', '.');

      // Update text dan posisikan kursor di akhir
      controller.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );

      onChanged(numericValue); // kirim angka tanpa titik
    },
  );
}

}