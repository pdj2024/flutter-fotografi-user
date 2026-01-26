import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/core/constants/helper.dart';
import 'package:mpjnew/src/core/constants/status_progres_constant.dart';
import 'package:mpjnew/src/core/routing/navigation_provider.dart';
import 'package:mpjnew/src/data/hive_entity/pesanan_model.dart';
import 'package:mpjnew/src/features/customer/view/chat/room_chat_page.dart';
import 'package:mpjnew/src/features/customer/view/history/detail_order_page.dart';
import 'package:mpjnew/src/features/customer/viewmodels/pesanan_provider.dart';
import 'package:mpjnew/src/features/customer/widget/pesanan_card.dart';
import 'package:provider/provider.dart';

class ProgressOrderSection extends StatefulWidget {
  const ProgressOrderSection({super.key});

  @override
  State<ProgressOrderSection> createState() => _ProgressOrderSectionState();
}

class _ProgressOrderSectionState extends State<ProgressOrderSection> {
  String _selectedFilter = 'all';

  final List<Map<String, dynamic>> _filterOptions = [
    {
      'value': 'all',
      'label': 'Semua',
      'icon': Icons.apps_rounded,
      'color': Colors.grey.shade700,
    },
    ...StatusProgresConstant.statusOptions.where(
      (s) => ['persiapan', 'proses', 'review', 'revisi'].contains(s['value']),
    ),
  ];

  List<PesananModel> _filterOrders(List<PesananModel> orders) {
    if (_selectedFilter == 'all') return orders;
    return orders
        .where((o) => o.statusProgresPesanan == _selectedFilter)
        .toList();
  }

  Map<String, List<PesananModel>> _groupByStatus(List<PesananModel> list) {
    final Map<String, List<PesananModel>> grouped = {};
    for (final item in list) {
      final status = item.statusProgresPesanan ?? 'lainnya';
      grouped.putIfAbsent(status, () => []);
      grouped[status]!.add(item);
    }
    return grouped;
  }

  String _statusLabel(String status) {
    final found = StatusProgresConstant.statusOptions.firstWhere(
      (s) => s['value'] == status,
      orElse: () => {'label': status},
    );
    return found['label'] ?? status;
  }

  Color _statusColor(String status) {
    final found = StatusProgresConstant.statusOptions.firstWhere(
      (s) => s['value'] == status,
      orElse: () => {'color': Colors.grey},
    );
    return found['color'] ?? Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final progressOrder = context.watch<PesananProvider>().pesananProgress;
    final filteredOrders = _filterOrders(progressOrder);
    final groupedOrders = _groupByStatus(filteredOrders);
    final statusKeys = groupedOrders.keys.toList();

    return Column(
      children: [
        // ✅ CHIP FILTER
        _buildChipFilter(progressOrder),

        // ✅ LIST ORDER
        Expanded(
          child: filteredOrders.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 20),
                  itemCount: statusKeys.length,
                  itemBuilder: (context, index) {
                    final status = statusKeys[index];
                    final items = groupedOrders[status]!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Label status (hanya tampil jika filter = all)
                        if (_selectedFilter == 'all')
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 20,
                              top: 16,
                              bottom: 4,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: _statusColor(status),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _statusLabel(status),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _statusColor(status),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '(${items.length})',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // List order
                        ...items.map(
                          (item) => Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            child: PesananCard(
                              clientName: item.namaVendor ?? "Vendor",
                              imgUrl: item.idMediaVendor ?? "",
                              kategori: item.namaPaket,
                              dateValue: DateFormat("dd MMMM yyyy")
                                  .format(item.tglRealisasi),
                              timeValue: Helper.toLocalTime(item.tglRealisasi),
                              location: item.lokasi,
                              statusProgress:
                                  item.statusProgresPesanan ?? "proses",
                              deskripsiProgress:
                                  item.deskripsiProgresPesanan ?? "",
                              onTap: () {
                                context
                                    .read<NavigationProvider>()
                                    .navigateToPage(
                                      context,
                                      targetTabIndex: 2,
                                      DetailOrderPage(pesananModel: item),
                                    );
                              },
                              onChatTap: () {
                                print("Chat tap");
                                context
                                    .read<NavigationProvider>()
                                    .navigateToPage(
                                      context,
                                      RoomChatPage(
                                        partnerId: item.idVendor,
                                      ),
                                      targetTabIndex: 1,
                                      targetPage: 'RoomChatPage',
                                    );
                              },
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ✅ Chip filter - clean & minimal
  Widget _buildChipFilter(List<PesananModel> allOrders) {
    // Hitung jumlah per status
    Map<String, int> countByStatus = {'all': allOrders.length};
    for (var order in allOrders) {
      final status = order.statusProgresPesanan ?? '';
      countByStatus[status] = (countByStatus[status] ?? 0) + 1;
    }

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filterOptions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final option = _filterOptions[index];
          final value = option['value'] as String;
          final label = option['label'] as String;
          final color = option['color'] as Color;
          final count = countByStatus[value] ?? 0;
          final isSelected = _selectedFilter == value;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedFilter = value;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isSelected ? color : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? color : Colors.grey.shade300,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? Colors.white : Colors.grey.shade700,
                    ),
                  ),
                  if (count > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withOpacity(0.25)
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color:
                              isSelected ? Colors.white : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ✅ Empty state
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            size: 100,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            _selectedFilter == 'all'
                ? 'Belum ada pesanan'
                : 'Tidak ada pesanan ${_statusLabel(_selectedFilter).toLowerCase()}',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          if (_selectedFilter != 'all') ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                setState(() {
                  _selectedFilter = 'all';
                });
              },
              child: Text(
                'Lihat semua',
                style: TextStyle(
                  fontSize: 14,
                  color: Constants.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
