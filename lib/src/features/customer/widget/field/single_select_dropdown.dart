// lib/src/core/widgets/dropdown_search/single_select_dropdown.dart

import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/utils/debouncer.dart';
import 'package:mpjnew/src/core/utils/dropdown_search_config.dart';
import 'package:mpjnew/src/core/utils/shimmer_placeholder.dart';
import 'package:mpjnew/src/features/customer/widget/field/custom_model.dart';

class SingleSelectDropdown<T> extends StatefulWidget {
  final DropdownSearchConfig<T> config;
  final T? selectedValue;
  final ValueChanged<T?>? onChanged;
  final bool readOnly; // ✅ TAMBAHAN

  const SingleSelectDropdown({
    super.key,
    required this.config,
    this.selectedValue,
    this.onChanged,
    this.readOnly = false, // ✅ DEFAULT FALSE
  });

  @override
  State<SingleSelectDropdown<T>> createState() =>
      _SingleSelectDropdownState<T>();
}

class _SingleSelectDropdownState<T> extends State<SingleSelectDropdown<T>> {
  late Debouncer _debouncer;
  String _searchQuery = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _debouncer = Debouncer(milliseconds: widget.config.debounceDuration);
  }

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.config.label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: widget.readOnly ? null : _openModal, // ✅ DISABLE TAP JIKA READONLY
          child: _buildDropdownBox(),
        ),
        if (widget.config.errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 5),
            child: Text(
              widget.config.errorMessage!,
              style: const TextStyle(color: Colors.red, fontSize: 14),
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDropdownBox() {
    final displayText = widget.selectedValue != null
        ? widget.config.getDisplayText(widget.selectedValue as T)
        : "Pilih ${widget.config.label}";

    final isPlaceholder = widget.selectedValue == null;

    return Container(
      width: double.infinity,
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: widget.readOnly // ✅ UBAH WARNA JIKA READONLY
            ? Colors.grey.shade100
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              displayText,
              style: TextStyle(
                color: widget.readOnly // ✅ UBAH WARNA TEXT JIKA READONLY
                    ? Colors.grey.shade600
                    : (isPlaceholder ? Colors.grey : Colors.black),
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // ✅ TAMPILKAN ICON HANYA JIKA TIDAK READONLY
          if (!widget.readOnly)
            Icon(
              Icons.arrow_drop_down,
              color: Colors.grey.shade600,
            ),
        ],
      ),
    );
  }

  Future<void> _openModal() async {
    _searchQuery = '';

    final result = await CustomModal.show<T>(
      context: context,
      title: "Pilih ${widget.config.label}",
      height: MediaQuery.of(context).size.height * 0.6,
      body: StatefulBuilder(
        builder: (context, setModalState) {
          final cachedData = widget.config.getCachedData(context);
          final filteredData = cachedData
              .where((item) => widget.config.filterItem(item, _searchQuery))
              .toList();

          return Column(
            children: [
              CustomSearchBar(
                hintText: "Cari ${widget.config.label}...",
                onChanged: (value) {
                  _searchQuery = value;

                  if (widget.config.enableRemoteSearch) {
                    setModalState(() => _isLoading = true);

                    _debouncer.run(() async {
                      await widget.config.fetchData(context, value.trim());
                      if (mounted) {
                        setModalState(() => _isLoading = false);
                      }
                    });
                  } else {
                    setModalState(() {});
                  }
                },
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _isLoading
                    ? _buildLoadingState()
                    : _buildListView(filteredData),
              ),
            ],
          );
        },
      ),
    );

    if (result != null && mounted) {
      widget.onChanged?.call(result);
    }
  }

  Widget _buildLoadingState() {
    return Column(
      children: List.generate(
        5,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: ShimmerPlaceholder(
            height: 50,
            radius: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildListView(List<T> data) {
    if (data.isEmpty) {
      return Center(
        child: Text(
          'Tidak ada data ditemukan',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      );
    }

    return ListView.builder(
      itemCount: data.length,
      itemBuilder: (context, index) {
        final item = data[index];
        final isSelected = widget.selectedValue != null &&
            widget.config.getValue(widget.selectedValue as T) ==
                widget.config.getValue(item);

        return ListTile(
          title: Text(widget.config.getDisplayText(item)),
          trailing: isSelected
              ? Icon(Icons.check, color: Constants.primaryColorVendor)
              : null,
          onTap: () => Navigator.pop(context, item),
        );
      },
    );
  }
}