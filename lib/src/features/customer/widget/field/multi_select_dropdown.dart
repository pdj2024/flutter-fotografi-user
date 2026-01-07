import 'package:flutter/material.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/utils/debouncer.dart';
import 'package:mpjnew/src/core/utils/dropdown_search_config.dart';
import 'package:mpjnew/src/core/utils/shimmer_placeholder.dart';
import 'package:mpjnew/src/features/customer/widget/field/chips_widget.dart';
import 'package:mpjnew/src/features/customer/widget/field/custom_model.dart';

class MultiSelectDropdown<T> extends StatefulWidget {
  final DropdownSearchConfig<T> config;
  final List<T>? selectedValues;
  final ValueChanged<List<T>>? onChanged;
  final ValueChanged<T>? onDelete;
  final bool readOnly; // ✅ TAMBAHAN

  const MultiSelectDropdown({
    super.key,
    required this.config,
    this.selectedValues,
    this.onChanged,
    this.onDelete,
    this.readOnly = false, // ✅ DEFAULT FALSE
  });

  @override
  State<MultiSelectDropdown<T>> createState() => _MultiSelectDropdownState<T>();
}

class _MultiSelectDropdownState<T> extends State<MultiSelectDropdown<T>> {
  late List<T> _selectedList;
  late Debouncer _debouncer;
  String _searchQuery = '';
  bool _isLoading = false;

  int? _hoveredIndex;
  int? _draggedIndex;

  @override
  void initState() {
    super.initState();
    _selectedList = List<T>.from(widget.selectedValues ?? []);
    _debouncer = Debouncer(milliseconds: widget.config.debounceDuration);
  }

  @override
  void didUpdateWidget(covariant MultiSelectDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedValues != widget.selectedValues) {
      _selectedList = List<T>.from(widget.selectedValues ?? []);
    }
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
          onTap: widget.readOnly
              ? null
              : _openModal, // ✅ DISABLE TAP JIKA READONLY
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      decoration: BoxDecoration(
        color: widget.readOnly // ✅ UBAH WARNA JIKA READONLY
            ? Colors.grey.shade100
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: _selectedList.isEmpty
          ? Text(
              "Pilih ${widget.config.label}",
              style: TextStyle(
                color: widget.readOnly // ✅ UBAH WARNA TEXT JIKA READONLY
                    ? Colors.grey.shade600
                    : Colors.grey,
                fontSize: 14,
              ),
            )
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _selectedList.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final chipId = widget.config.getValue(item);
                final isHovered = _hoveredIndex == index;
                final isDragged = _draggedIndex == index;

                // ✅ DISABLE DRAG & DROP JIKA READONLY
                if (widget.readOnly) {
                  return ChipsWidget(
                    idData: chipId,
                    label: widget.config.getDisplayText(item),
                    backgroundColor:
                        Colors.grey.shade400, // ✅ WARNA LEBIH REDUP
                    onDelete: (id) => _onDeleteChip(item), // ✅ DISABLE DELETE
                  );
                }

                return DragTarget<int>(
                  onWillAcceptWithDetails: (details) {
                    final draggedIdx = details.data;
                    if (draggedIdx == index) return false;

                    setState(() {
                      _hoveredIndex = index;
                    });
                    return true;
                  },
                  onLeave: (_) {
                    setState(() {
                      _hoveredIndex = null;
                    });
                  },
                  onAcceptWithDetails: (details) {
                    final draggedIdx = details.data;
                    _onReorder(draggedIdx, index);

                    setState(() {
                      _hoveredIndex = null;
                      _draggedIndex = null;
                    });
                  },
                  builder: (context, candidateData, rejectedData) {
                    return LongPressDraggable<int>(
                      data: index,
                      onDragStarted: () {
                        setState(() {
                          _draggedIndex = index;
                        });
                      },
                      onDragEnd: (_) {
                        setState(() {
                          _draggedIndex = null;
                          _hoveredIndex = null;
                        });
                      },
                      feedback: Material(
                        color: Colors.transparent,
                        elevation: 8,
                        borderRadius: BorderRadius.circular(20),
                        child: Transform.scale(
                          scale: 1.15,
                          child: Opacity(
                            opacity: 0.85,
                            child: ChipsWidget(
                              idData: chipId,
                              label: widget.config.getDisplayText(item),
                              backgroundColor: Colors.deepPurple.shade400,
                              onDelete: (id) => _onDeleteChip(item),
                            ),
                          ),
                        ),
                      ),
                      childWhenDragging: Opacity(
                        opacity: 0.3,
                        child: ChipsWidget(
                          idData: chipId,
                          label: widget.config.getDisplayText(item),
                          backgroundColor: Colors.grey.shade300,
                          onDelete: (id) => _onDeleteChip(item),
                        ),
                      ),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        padding: EdgeInsets.all(isHovered ? 4 : 0),
                        decoration: BoxDecoration(
                          color: isHovered
                              ? Colors.green.withOpacity(0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: isHovered
                              ? Border.all(
                                  color: Colors.green.shade400,
                                  width: 2,
                                )
                              : null,
                          boxShadow: isHovered
                              ? [
                                  BoxShadow(
                                    color: Colors.green.withOpacity(0.3),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : [],
                        ),
                        child: ChipsWidget(
                          idData: chipId,
                          label: widget.config.getDisplayText(item),
                          backgroundColor: isDragged
                              ? Colors.deepPurple.shade300
                              : isHovered
                                  ? Colors.green.shade600
                                  : Constants.primaryColorVendor,
                          onDelete: (id) => _onDeleteChip(item),
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
    );
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      final item = _selectedList.removeAt(oldIndex);
      _selectedList.insert(newIndex, item);
    });
    widget.onChanged?.call(_selectedList);
  }

  void _onDeleteChip(T item) {
    setState(() => _selectedList.remove(item));
    widget.onDelete?.call(item);
    widget.onChanged?.call(_selectedList);
  }

  Future<void> _openModal() async {
    _searchQuery = '';
    List<T> tempSelected = List<T>.from(_selectedList);

    await CustomModal.show(
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
                      await widget.config.fetchData(context, value);
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
                    : _buildSelectableList(
                        tempSelected, filteredData, setModalState),
              ),
            ],
          );
        },
      ),
      bottomButton: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Constants.primaryColorVendor,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () {
            setState(() => _selectedList = tempSelected);
            widget.onChanged?.call(_selectedList);
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
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView(
      children: List.generate(
        5,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: ShimmerPlaceholder(height: 50, radius: 15),
        ),
      ),
    );
  }

  Widget _buildSelectableList(
    List<T> tempSelected,
    List<T> data,
    StateSetter setModalState,
  ) {
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
        final isSelected = tempSelected.any(
          (selected) =>
              widget.config.getValue(selected) == widget.config.getValue(item),
        );

        return GestureDetector(
          onTap: () {
            setModalState(() {
              if (isSelected) {
                tempSelected.removeWhere((selected) =>
                    widget.config.getValue(selected) ==
                    widget.config.getValue(item));
              } else {
                tempSelected.add(item);
              }
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: isSelected
                  ? Constants.primaryColorVendor.withOpacity(0.1)
                  : Colors.white,
              border: Border.all(
                color: isSelected
                    ? Constants.primaryColorVendor
                    : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.config.getDisplayText(item),
                    style: TextStyle(
                      color: isSelected
                          ? Constants.primaryColorVendor
                          : Colors.black,
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: Constants.primaryColorVendor,
                    size: 20,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
