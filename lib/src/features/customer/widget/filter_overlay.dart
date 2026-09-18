import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/routing/navigation_provider.dart';
import '../services/kategori_service.dart';
import '../services/kota_service.dart';
import '../services/vendor_service.dart';

class FilterOverlay extends StatefulWidget {
  final String? selectedCategory;
  final String? selectedLocation;
  final String? selectedPhotographer;
  final String? usernamePhotographer;
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
    required this.usernamePhotographer,
    required this.minPrice,
    required this.maxPrice,
    required this.onApply,
    required this.onReset,
    required this.onClose,
  });

  @override
  State<FilterOverlay> createState() => _FilterOverlayState();
}

class _FilterOverlayState extends State<FilterOverlay>
    with SingleTickerProviderStateMixin {
  // Filtered lists
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

  // Selected IDs
  String? selectedCategoryId;
  String? selectedLocationId;
  String? selectedPhotographerId;

  // Dropdown open state
  bool isCategoryOpen = false;
  bool isLocationOpen = false;
  bool isPhotographerOpen = false;

  // Loading state
  bool isCategoryLoading = false;
  bool isLocationLoading = false;
  bool isPhotographerLoading = false;

  // Debounce timers
  Timer? _locationDebounce;
  Timer? _categoryDebounce;
  Timer? _photographerDebounce;

  bool firstBuild = true;

  // Slide-in animation
  late AnimationController _animController;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    ));
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _animController.forward();

    minPriceController.text = widget.minPrice ?? '';
    maxPriceController.text = widget.maxPrice ?? '';

    // ── Listeners ──────────────────────────────────────
    locationController.addListener(() {
      if (firstBuild) return;
      _debounceLocation();
    });
    categoryController.addListener(() {
      if (firstBuild) return;
      _debounceCategory();
    });
    photographerController.addListener(() {
      if (firstBuild) return;
      _debouncePhotographer();
    });

    // ── Focus listeners ─────────────────────────────────
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

    // ── Post frame init fetch ───────────────────────────
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (widget.selectedLocation?.isNotEmpty ?? false) {
        await fetchLocationsFromApi(widget.selectedLocation!, null);
      }
      if (widget.selectedCategory?.isNotEmpty ?? false) {
        await fetchCategorysFromApi(widget.selectedCategory!, null);
      }
      if (widget.selectedPhotographer?.isNotEmpty ?? false) {
        await fetchPhotographersFromApi(widget.selectedPhotographer!, null);
      } else if (widget.usernamePhotographer?.isNotEmpty ?? false) {
        await fetchPhotographersFromApi(null, widget.usernamePhotographer!);
      }

      applySelectedIdsToController();
      firstBuild = false;
    });
  }

  // ── Debounce helpers ──────────────────────────────────

  void _debounceLocation() {
    _locationDebounce?.cancel();
    setState(() => isLocationLoading = true);
    _locationDebounce = Timer(const Duration(milliseconds: 500), () {
      fetchLocationsFromApi(null, locationController.text);
    });
  }

  void _debounceCategory() {
    _categoryDebounce?.cancel();
    setState(() => isCategoryLoading = true);
    _categoryDebounce = Timer(const Duration(milliseconds: 500), () {
      fetchCategorysFromApi(null, categoryController.text);
    });
  }

  void _debouncePhotographer() {
    _photographerDebounce?.cancel();
    setState(() => isPhotographerLoading = true);
    _photographerDebounce = Timer(const Duration(milliseconds: 500), () {
      fetchPhotographersFromApi(null, photographerController.text);
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

  // ── API fetch ─────────────────────────────────────────

  Future<void> fetchLocationsFromApi(String? noId, String? query) async {
    setState(() => isLocationLoading = true);
    try {
      final res = await KotaService()
          .getAll(orderBy: 'nama_kota', namaKota: query, noId: noId);
      final list = res.map((e) => {'id': e.noId, 'label': e.namaKota}).toList();
      setState(() {
        filteredLocations = list;
        locationHasError = list.isEmpty;
        isLocationLoading = false;
      });
    } catch (_) {
      setState(() {
        filteredLocations = [];
        locationHasError = true;
        isLocationLoading = false;
      });
    }
  }

  Future<void> fetchCategorysFromApi(String? noId, String? query) async {
    setState(() => isCategoryLoading = true);
    try {
      final res = await KategoriService().getAll(
        orderBy: 'nama_kategori',
        namaKategori: query,
        noId: noId,
        canSearch: 'ya',
      );
      final list =
          res.map((e) => {'id': e.no_id, 'label': e.nama_kategori}).toList();
      setState(() {
        filteredCategories = list;
        categoryHasError = list.isEmpty;
        isCategoryLoading = false;
      });
    } catch (_) {
      setState(() {
        filteredCategories = [];
        categoryHasError = true;
        isCategoryLoading = false;
      });
    }
  }


  Future<void> fetchPhotographersFromApi(String? noId, String? query) async {
    setState(() => isPhotographerLoading = true);
    try {
      final res = await VendorService().searchVendor(
        orderBy: 'username',
        status: 'aktif',
        filter: query,
        no_id: noId,
      );
      final list = res
          .map((e) => {
                'id': e.noId,
                'username': e.username,
                'name': e.namaDisplay,
                'avatar': e.idMedia,
              })
          .toList();
      setState(() {
        filteredPhotographers = list;
        photographerHasError = list.isEmpty;
        isPhotographerLoading = false;
      });
    } catch (_) {
      setState(() {
        filteredPhotographers = [];
        photographerHasError = true;
        isPhotographerLoading = false;
      });
    }
  }

  void applySelectedIdsToController() {
    if (widget.selectedCategory != null) {
      final match = filteredCategories.firstWhere(
        (item) => item['id'] == widget.selectedCategory,
        orElse: () => {'label': ''},
      );
      categoryController.text = match['label']!;
      selectedCategoryId = widget.selectedCategory;
    }
    if (widget.selectedLocation != null) {
      final match = filteredLocations.firstWhere(
        (item) => item['id'] == widget.selectedLocation,
        orElse: () => {'label': ''},
      );
      locationController.text = match['label']!;
      selectedLocationId = widget.selectedLocation;
    }
    if (widget.selectedPhotographer?.isNotEmpty ?? false) {
      final match = filteredPhotographers.firstWhere(
        (item) => item['id'] == widget.selectedPhotographer,
        orElse: () => {'username': ''},
      );
      photographerController.text = match['username'] ?? '';
      selectedPhotographerId = widget.selectedPhotographer;
    } else if (widget.usernamePhotographer?.isNotEmpty ?? false) {
      photographerController.text = widget.usernamePhotographer!;
    }
  }

  Map<String, String?> _buildFilterMap() => {
        'id_vendor': selectedPhotographerId,
        'username_vendor': photographerController.text.trim(),
        'id_kategori': selectedCategoryId,
        'nama_kategori': categoryController.text.trim(),
        'min_price': minPriceController.text.trim(),
        'max_price': maxPriceController.text.trim(),
        'id_lokasi': selectedLocationId,
        'nama_lokasi': locationController.text.trim(),
      };

  @override
  void dispose() {
    _animController.dispose();
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
    _categoryDebounce?.cancel();
    _photographerDebounce?.cancel();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        widget.onClose();
        return false;
      },
      child: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusScope.of(context).unfocus(),
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: Scaffold(
                backgroundColor: const Color(0xFFF7F7F5),
                body: Column(
                  children: [
                    _buildHeader(),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(10, 20, 10, 0),
                        children: [
                          _buildSection(
                            label: 'Kategori',
                            icon: Icons.grid_view_rounded,
                            child: _buildDropdown(
                              controller: categoryController,
                              focusNode: categoryFocusNode,
                              hint: 'Pilih kategori',
                              items: filteredCategories,
                              hasError: categoryHasError,
                              isLoading: isCategoryLoading,
                              onSelected: (value) {
                                selectedCategoryId = value['id'];
                              },
                              onClear: () =>
                                  setState(() => selectedCategoryId = null),
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildSection(
                            label: 'Lokasi',
                            icon: Icons.location_on_outlined,
                            child: _buildDropdown(
                              controller: locationController,
                              focusNode: locationFocusNode,
                              hint: 'Cari kota atau daerah',
                              items: filteredLocations,
                              hasError: locationHasError,
                              isLoading: isLocationLoading,
                              onSelected: (value) {
                                selectedLocationId = value['id'];
                              },
                              onClear: () =>
                                  setState(() => selectedLocationId = null),
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildSection(
                            label: 'Rentang Harga',
                            icon: Icons.payments_outlined,
                            child: Row(
                              children: [
                                Expanded(
                                  child: _buildPriceInput(
                                    controller: minPriceController,
                                    focusNode: minPriceFocusNode,
                                    hint: 'Minimum',
                                  ),
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 10),
                                  child: Container(
                                    width: 18,
                                    height: 1.5,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                                Expanded(
                                  child: _buildPriceInput(
                                    controller: maxPriceController,
                                    focusNode: maxPriceFocusNode,
                                    hint: 'Maksimum',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildSection(
                            label: 'Fotografer',
                            icon: Icons.person_search_outlined,
                            child: _buildPhotographerSearch(),
                          ),
                          const SizedBox(height: 100), // space before buttons
                        ],
                      ),
                    ),
                    _buildBottomActions(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  // Back / close button
                  IconButton(
                    icon:
                        const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                    color: Colors.black87,
                    onPressed: () async {
                      widget.onApply(_buildFilterMap());
                      final provider = Provider.of<NavigationProvider>(context,
                          listen: false);
                      bool allow = await provider.onWillPop(context);
                      if (allow) Navigator.of(context).pop();
                    },
                  ),
                  const Expanded(
                    child: Text(
                      'Filter Pencarian',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  // Active filter badge
                  if (_hasAnyFilter)
                    Container(
                      margin: const EdgeInsets.only(right: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Constants.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_activeFilterCount} aktif',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Constants.primaryColor,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Divider(height: 1, color: Colors.grey.shade200),
          ],
        ),
      ),
    );
  }

  bool get _hasAnyFilter =>
      selectedCategoryId != null ||
      selectedLocationId != null ||
      selectedPhotographerId != null ||
      minPriceController.text.isNotEmpty ||
      maxPriceController.text.isNotEmpty;

  int get _activeFilterCount {
    int count = 0;
    if (selectedCategoryId != null) count++;
    if (selectedLocationId != null) count++;
    if (selectedPhotographerId != null ||
        photographerController.text.isNotEmpty) count++;
    if (minPriceController.text.isNotEmpty ||
        maxPriceController.text.isNotEmpty) count++;
    return count;
  }

  // ── Section wrapper ────────────────────────────────────

  Widget _buildSection({
    required String label,
    required IconData icon,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 15, color: Colors.grey.shade600),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  // ── Generic dropdown ───────────────────────────────────

  Widget _buildDropdown({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    required List<Map<String, String>> items,
    required bool hasError,
    required bool isLoading,
    required ValueChanged<Map<String, String>> onSelected,
    required VoidCallback onClear,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          controller: controller,
          focusNode: focusNode,
          hint: hint,
          hasError: hasError,
          suffixIcon: controller.text.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    controller.clear();
                    focusNode.unfocus();
                    onClear();
                  },
                  child: Icon(Icons.close_rounded,
                      size: 18, color: Colors.grey.shade500),
                )
              : Icon(Icons.keyboard_arrow_down_rounded,
                  color: Colors.grey.shade400),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          child: focusNode.hasFocus
              ? _buildDropdownList(
                  isLoading: isLoading,
                  items: items,
                  onTap: (item) {
                    controller.text = item['label']!;
                    onSelected(item);
                    FocusScope.of(context).unfocus();
                  },
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildDropdownList({
    required bool isLoading,
    required List<Map<String, String>> items,
    required ValueChanged<Map<String, String>> onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      constraints: const BoxConstraints(maxHeight: 220),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: isLoading
          ? const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          : items.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Text(
                      'Tidak ada hasil',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: Colors.grey.shade100,
                  ),
                  itemBuilder: (_, i) {
                    final item = items[i];
                    return InkWell(
                      onTap: () => onTap(item),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Text(
                          item['label'] ?? '',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  // ── Photographer search ────────────────────────────────

  Widget _buildPhotographerSearch() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          controller: photographerController,
          focusNode: photographerFocusNode,
          hint: 'Cari username',
          hasError: false,
          suffixIcon: photographerController.text.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    photographerController.clear();
                    setState(() => selectedPhotographerId = null);
                    photographerFocusNode.unfocus();
                  },
                  child: Icon(Icons.close_rounded,
                      size: 18, color: Colors.grey.shade500),
                )
              : Icon(Icons.search_rounded, color: Colors.grey.shade400),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          child: photographerFocusNode.hasFocus
              ? _buildPhotographerList()
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildPhotographerList() {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      constraints: const BoxConstraints(maxHeight: 240),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: isPhotographerLoading
          ? const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          : filteredPhotographers.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off_rounded,
                            size: 36, color: Colors.grey.shade300),
                        const SizedBox(height: 8),
                        Text(
                          'Fotografer tidak ditemukan',
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  itemCount: filteredPhotographers.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    indent: 72,
                    color: Colors.grey.shade100,
                  ),
                  itemBuilder: (_, i) {
                    final p = filteredPhotographers[i];
                    final avatar = p['avatar'] ?? '';
                    final username = p['username'] ?? '';
                    final name = p['name'] ?? '';
                    final isSelected = selectedPhotographerId == p['id'];

                    return InkWell(
                      onTap: () {
                        setState(() {
                          photographerController.text = username;
                          selectedPhotographerId = p['id'];
                        });
                        FocusScope.of(context).unfocus();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        child: Row(
                          children: [
                            // Avatar
                            ClipRRect(
                              borderRadius: BorderRadius.circular(22),
                              child: avatar.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: avatar,
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) =>
                                          Shimmer.fromColors(
                                        baseColor: Colors.grey.shade200,
                                        highlightColor: Colors.grey.shade50,
                                        child: Container(
                                          width: 40,
                                          height: 40,
                                          color: Colors.white,
                                        ),
                                      ),
                                      errorWidget: (_, __, ___) =>
                                          _avatarFallback(),
                                    )
                                  : _avatarFallback(),
                            ),
                            const SizedBox(width: 12),
                            // Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    username,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? Constants.primaryColor
                                          : Colors.black87,
                                    ),
                                  ),
                                  if (name.isNotEmpty && name != username)
                                    Text(
                                      name,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            // Selected checkmark
                            if (isSelected)
                              Icon(
                                Icons.check_circle_rounded,
                                size: 18,
                                color: Constants.primaryColor,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _avatarFallback() => Container(
        width: 40,
        height: 40,
        color: Colors.grey.shade100,
        child: Icon(Icons.person, size: 20, color: Colors.grey.shade400),
      );

  // ── Price input ────────────────────────────────────────

  Widget _buildPriceInput({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
  }) {
    return _buildTextField(
      controller: controller,
      focusNode: focusNode,
      hint: hint,
      hasError: false,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      prefixText: 'Rp ',
      onChanged: (value) {
        if (value.isEmpty) return;
        final formatted = NumberFormat('#,###', 'id_ID')
            .format(int.parse(value))
            .replaceAll(',', '.');
        controller.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
      },
      onTap: () => _closeAllExcept(
          focusNode == minPriceFocusNode ? 'minPrice' : 'maxPrice'),
    );
  }

  // ── Generic text field ─────────────────────────────────

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    required bool hasError,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? prefixText,
    ValueChanged<String>? onChanged,
    VoidCallback? onTap,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      onTap: onTap,
      style: const TextStyle(
        fontSize: 14,
        color: Colors.black87,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: 14,
          color: Colors.grey.shade400,
        ),
        prefixText: prefixText,
        prefixStyle: TextStyle(
          fontSize: 14,
          color: Colors.grey.shade600,
        ),
        suffixIcon: suffixIcon != null
            ? Padding(
                padding: const EdgeInsets.only(right: 12),
                child: suffixIcon,
              )
            : null,
        suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: hasError ? Colors.red.shade300 : Colors.grey.shade200,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: hasError ? Colors.red.shade300 : Colors.grey.shade200,
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: hasError ? Colors.red.shade400 : Constants.primaryColor,
            width: 1.8,
          ),
        ),
      ),
    );
  }

  // ── Bottom action buttons ──────────────────────────────

  Widget _buildBottomActions() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              // Reset button
              OutlinedButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  categoryController.clear();
                  locationController.clear();
                  photographerController.clear();
                  minPriceController.clear();
                  maxPriceController.clear();
                  setState(() {
                    selectedCategoryId = null;
                    selectedLocationId = null;
                    selectedPhotographerId = null;
                  });
                  widget.onApply({
                    'id_vendor': '',
                    'username_vendor': '',
                    'id_kategori': '',
                    'nama_kategori': '',
                    'min_price': '',
                    'max_price': '',
                    'id_lokasi': '',
                    'nama_lokasi': '',
                  });
                },
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Atur Ulang'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black54,
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Apply button
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    widget.onApply(_buildFilterMap());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Constants.primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text('Terapkan Filter'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
