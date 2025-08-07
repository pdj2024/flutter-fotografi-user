import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mpjnew/src/pages/providers/custom_back_button.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../providers/constants.dart';
import '../providers/navigation_provider.dart';

class FilterOverlay extends StatefulWidget {
  final List<String> categories;
  final List<Map<String, String>> photographers;
  final List<String> locations;

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
    required this.categories,
    required this.photographers,
    required this.locations,
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
  final List<String> categories = ['Keluarga', 'Wisuda', 'Wedding', 'Korporat'];
  final List<String> locations = [
    'Jakarta',
    'Bandung',
    'Surabaya',
    'Yogyakarta'
  ];

  final List<Map<String, String>> photographers = [
    {
      'image': 'portfolio_wedding1.jpeg',
      'name': 'michaelwilliams',
      'avatar': '68e66acd-c1ce-47ad-93ac-e09b9d494258-photographer_icon.png'
    },
    {
      'image': 'portfolio_wedding2.jpg',
      'name': 'emilybphotos',
      'avatar': 'b874a816-3b91-4bb1-b383-deaebd63b105-photographer_icon2.png'
    },
    {
      'image': 'portfolio_wedding3.jpg',
      'name': 'davismiller',
      'avatar': 'a84116aa-eab1-43cf-97c4-1d31966f2c90-photographer_icon3.png'
    },
    {
      'image': 'portfolio_wedding4.jpg',
      'name': 'amandareedphoto',
      'avatar': '46befe65-bdd8-4f4e-a6ba-bb77e0a39d9f-photographer_icon4.jpg'
    },
    {
      'image': 'portfolio_wedding5.jpg',
      'name': 'sarahleephoto',
      'avatar': 'b874a816-3b91-4bb1-b383-deaebd63b105-photographer_icon2.png'
    },
  ];

  String? tempCategory;
  String? tempLocation;
  String? tempPhotographer;
  String? tempMinPrice;
  String? tempMaxPrice;

  final TextEditingController categoryController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController photographerController = TextEditingController();
  final TextEditingController minPriceController = TextEditingController();
  final TextEditingController maxPriceController = TextEditingController();

  List<String> filteredCategories = [];
  List<String> filteredLocations = [];
  List<Map<String, String>> filteredPhotographers = [];

  bool categoryHasError = false;
  bool locationHasError = false;
  bool photographerHasError = false;

  FocusNode categoryFocusNode = FocusNode();
  FocusNode locationFocusNode = FocusNode();
  FocusNode photographerFocusNode = FocusNode();
  FocusNode minPriceFocusNode = FocusNode();
  FocusNode maxPriceFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    tempCategory = widget.selectedCategory?.isEmpty ?? true
        ? null
        : widget.selectedCategory;
    tempLocation = widget.selectedLocation?.isEmpty ?? true
        ? null
        : widget.selectedLocation;
    tempPhotographer = widget.selectedPhotographer?.isEmpty ?? true
        ? null
        : widget.selectedPhotographer;
    tempMinPrice = widget.minPrice;
    tempMaxPrice = widget.maxPrice;

    //print("temp category: " + widget.selectedCategory!);

    minPriceController.text = tempMinPrice ?? '';
    maxPriceController.text = tempMaxPrice ?? '';

    categoryController.text = tempCategory ?? '';
    locationController.text = tempLocation ?? '';
    photographerController.text = tempPhotographer ?? '';

    photographerController.addListener(filterPhotographers);
    categoryController.addListener(filterCategories);
    locationController.addListener(filterLocations);

    photographerFocusNode.addListener(() {
      if (!photographerFocusNode.hasFocus) {
        if (photographerController.text.isNotEmpty &&
            filteredPhotographers.isNotEmpty) {
          photographerController.text = filteredPhotographers.first['name']!;
          tempPhotographer = filteredPhotographers.first['name']!;
          photographerHasError = false;
        }
        tempPhotographer ??= '';
        setState(() {});
      }
    });

    // categoryFocusNode.addListener(() {
    //   if (!categoryFocusNode.hasFocus && categoryController.text.isNotEmpty) {
    //     if (filteredCategories.isNotEmpty) {
    //       categoryController.text = filteredCategories.first;
    //       tempCategory = filteredCategories.first;
    //       categoryHasError = false;
    //     }
    //     setState(() {});
    //   }
    // });
    categoryFocusNode.addListener(() {
      if (!categoryFocusNode.hasFocus) {
        if (categoryController.text.isNotEmpty &&
            filteredCategories.isNotEmpty) {
          categoryController.text = filteredCategories.first;
          tempCategory = filteredCategories.first;
          categoryHasError = false;
        }
        tempCategory ??= '';
        setState(() {});
      }
    });

    minPriceFocusNode.addListener(() {
      if (!minPriceFocusNode.hasFocus) {
        setState(() {});
      }
    });

    maxPriceFocusNode.addListener(() {
      if (!maxPriceFocusNode.hasFocus) {
        setState(() {});
      }
    });

    locationFocusNode.addListener(() {
      if (!locationFocusNode.hasFocus) {
        if (locationController.text.isNotEmpty &&
            filteredLocations.isNotEmpty) {
          locationController.text = filteredLocations.first;
          tempLocation = filteredLocations.first;
          locationHasError = false;
        }
        tempLocation ??= '';
        setState(() {});
      }
    });

    filterPhotographers();
    filterCategories();
    filterLocations();
  }

  void filterPhotographers() {
    final query = photographerController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredPhotographers = widget.photographers.toList();
        photographerHasError = false;
      } else {
        filteredPhotographers = widget.photographers
            .where((item) => item['name']!.toLowerCase().contains(query))
            .toList();
        photographerHasError = filteredPhotographers.isEmpty;
      }
    });
  }

  void filterCategories() {
    final query = categoryController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredCategories = widget.categories.toList();
        categoryHasError = false;
      } else {
        filteredCategories = widget.categories
            .where((item) => item.toLowerCase().contains(query))
            .toList();
        categoryHasError = filteredCategories.isEmpty;
      }
    });
  }

  void filterLocations() {
    final query = locationController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredLocations = widget.locations.toList();
        locationHasError = false;
      } else {
        filteredLocations = widget.locations
            .where((item) => item.toLowerCase().contains(query))
            .toList();
        locationHasError = filteredLocations.isEmpty;
      }
    });
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width - 40.0;

    // return WillPopScope(
    //   onWillPop: () async {
    //     widget.onClose();
    //     return false;
    //   },
    //   child: Scaffold(
    //     backgroundColor: Colors.white.withOpacity(0.96),
    //     body: Column(
    //       crossAxisAlignment: CrossAxisAlignment.start,
    //       children: [
    //         buildHeader(),
    //         Expanded(
    //           child: ListView(
    //             padding: const EdgeInsets.all(20),
    //             children: [
    //               buildLabel('Kategori'),
    //               const SizedBox(height: 8),
    //               buildSearchableDropdown(
    //                 controller: categoryController,
    //                 focusNode: categoryFocusNode,
    //                 hint: 'Pilih Kategori',
    //                 items: filteredCategories,
    //                 allItems: categories,
    //                 hasError: categoryHasError,
    //                 onSelected: (value) {
    //                   tempCategory = value;
    //                 },
    //               ),
    //               const SizedBox(height: 20),
    //               buildLabel('Lokasi'),
    //               const SizedBox(height: 8),
    //               buildSearchableDropdown(
    //                 controller: locationController,
    //                 focusNode: locationFocusNode,
    //                 hint: 'Cari Lokasi',
    //                 items: filteredLocations,
    //                 allItems: locations,
    //                 hasError: locationHasError,
    //                 onSelected: (value) {
    //                   tempLocation = value;
    //                 },
    //               ),
    //               const SizedBox(height: 20),
    //               buildLabel('Harga (Rp)'),
    //               const SizedBox(height: 8),
    //               Row(
    //                 children: [
    //                   Expanded(
    //                     child: buildTextInput(
    //                       controller: minPriceController,
    //                       focusNode: minPriceFocusNode,
    //                       hint: 'Min',
    //                       onChanged: (value) => tempMinPrice = value,
    //                     ),
    //                   ),
    //                   const SizedBox(width: 10),
    //                   Expanded(
    //                     child: buildTextInput(
    //                       controller: maxPriceController,
    //                       focusNode:
    //                           maxPriceFocusNode, // <-- ini yang harus kamu tambah
    //                       hint: 'Max',
    //                       onChanged: (value) => tempMaxPrice = value,
    //                     ),
    //                   ),
    //                 ],
    //               ),
    //               const SizedBox(height: 20),
    //               buildLabel('Nama Fotografer'),
    //               const SizedBox(height: 8),
    //               buildPhotographerSearch(),
    //             ],
    //           ),
    //         ),
    //         Padding(
    //           padding: const EdgeInsets.all(20),
    //           child: Row(
    //             children: [
    //               Expanded(
    //                 child: OutlinedButton(
    //                   onPressed: () {
    //                     widget.onApply({
    //                       'category': '',
    //                       'location': '',
    //                       'photographer': '',
    //                       'minPrice': '',
    //                       'maxPrice': '',
    //                     });
    //                   },
    //                   style: OutlinedButton.styleFrom(
    //                     side: const BorderSide(color: Constants.primaryColor),
    //                     shape: RoundedRectangleBorder(
    //                       borderRadius: BorderRadius.circular(12),
    //                     ),
    //                   ),
    //                   child: const Text('Atur Ulang',
    //                       style: TextStyle(color: Constants.primaryColor)),
    //                 ),
    //               ),
    //               const SizedBox(width: 10),
    //               Expanded(
    //                 child: ElevatedButton(
    //                   onPressed: () {
    //                     widget.onApply({
    //                       'category': tempCategory,
    //                       'location': tempLocation,
    //                       'photographer': tempPhotographer,
    //                       'minPrice': tempMinPrice,
    //                       'maxPrice': tempMaxPrice,
    //                     });
    //                   },
    //                   style: ElevatedButton.styleFrom(
    //                     backgroundColor: Constants.primaryColor,
    //                     shape: RoundedRectangleBorder(
    //                       borderRadius: BorderRadius.circular(12),
    //                     ),
    //                   ),
    //                   child: const Text(
    //                     'Pakai',
    //                     style: TextStyle(color: Colors.white),
    //                   ),
    //                 ),
    //               ),
    //             ],
    //           ),
    //         ),
    //       ],
    //     ),
    //   ),
    // );
    return WillPopScope(
      onWillPop: () async {
        widget.onClose();
        return false;
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
                    allItems: widget.categories,
                    hasError: categoryHasError,
                    onSelected: (value) {
                      tempCategory = value;
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
                    allItems: widget.locations,
                    hasError: locationHasError,
                    onSelected: (value) {
                      tempLocation = value;
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
                          onChanged: (value) => tempMinPrice = value,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: buildTextInput(
                          controller: maxPriceController,
                          focusNode: maxPriceFocusNode,
                          hint: 'Max',
                          onChanged: (value) => tempMaxPrice = value,
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
                          'category': '',
                          'location': '',
                          'photographer': '',
                          'minPrice': '',
                          'maxPrice': '',
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
                          'category': tempCategory,
                          'location': tempLocation,
                          'photographer': tempPhotographer,
                          'minPrice': tempMinPrice,
                          'maxPrice': tempMaxPrice,
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
    );
  }

  Widget buildHeader() {
    return Container(
      color: Constants.primaryColor,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          CustomBackButton(color: Colors.white),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Filter',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
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
  Widget buildSearchableDropdown(
      {required TextEditingController controller,
      required FocusNode focusNode,
      required String hint,
      required List<String> items,
      required List<String> allItems,
      required bool hasError,
      required ValueChanged<String> onSelected}) {
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
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
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
            child: items.isEmpty
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
                          title: Text(item),
                          onTap: () {
                            controller.text = item;
                            onSelected(item);
                            FocusScope.of(context).unfocus();
                          },
                        );
                      }).toList(),
                    ),
                  ),
            // Column(
            //   crossAxisAlignment: CrossAxisAlignment.start,
            //   children: items.map((item) {
            //     return ListTile(
            //       title: Text(item),
            //       onTap: () {
            //         controller.text = item;
            //         onSelected(item);
            //         FocusScope.of(context).unfocus();
            //       },
            //     );
            //   }).toList(),
            // ),
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
          decoration: InputDecoration(
            hintText: 'Cari Nama Fotografer',
            suffixIcon: photographerController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      photographerController.clear();
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
                color:
                    photographerHasError ? Colors.red : Constants.primaryColor,
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
            child: filteredPhotographers.isEmpty
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
                      children: filteredPhotographers.map((photographer) {
                        final String avatarUrl = context
                            .read<NavigationProvider>()
                            .ambilGambar(photographer['avatar']!);
                        return ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: CachedNetworkImage(
                              imageUrl: avatarUrl,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Shimmer.fromColors(
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
                            ),
                          ),
                          title: Text(photographer['name']!),
                          onTap: () {
                            photographerController.text = photographer['name']!;
                            tempPhotographer = photographer['name']!;
                            FocusScope.of(context).unfocus();
                          },
                        );
                      }).toList(),
                    ),
                  ),
            // Column(
            //   crossAxisAlignment: CrossAxisAlignment.start,
            //   children: filteredPhotographers.map((photographer) {
            //     final String avatarUrl = context
            //         .read<NavigationProvider>()
            //         .ambilGambar(photographer['avatar']!);
            //     return ListTile(
            //       leading: ClipRRect(
            //         borderRadius: BorderRadius.circular(20),
            //         child: CachedNetworkImage(
            //           imageUrl: avatarUrl,
            //           width: 40,
            //           height: 40,
            //           fit: BoxFit.cover,
            //           placeholder: (context, url) => Shimmer.fromColors(
            //             baseColor: Colors.grey.shade300,
            //             highlightColor: Colors.grey.shade100,
            //             child: Container(
            //               width: 40,
            //               height: 40,
            //               color: Colors.white,
            //             ),
            //           ),
            //           errorWidget: (context, url, error) => CircleAvatar(
            //             radius: 20,
            //             backgroundColor: Colors.grey.shade200,
            //             child: const Icon(Icons.person, color: Colors.grey),
            //           ),
            //         ),
            //       ),
            //       title: Text(photographer['name']!),
            //       onTap: () {
            //         photographerController.text = photographer['name']!;
            //         tempPhotographer = photographer['name']!;
            //         FocusScope.of(context).unfocus();
            //       },
            //     );
            //   }).toList(),
            // ),
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
    focusNode.addListener(() {
      if (focusNode.hasFocus) {
        controller.selection =
            TextSelection(baseOffset: 0, extentOffset: controller.text.length);
      }
    });

    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        hintText: hint,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
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
      onChanged: onChanged,
    );
  }
}
