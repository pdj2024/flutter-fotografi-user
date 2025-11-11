import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mpjnew/src/core/constants/constants.dart';
import 'package:mpjnew/src/pages/fotografi_vendor/vendor_bio.dart';
import 'package:mpjnew/src/pages/fotografi_vendor/vendor_single_order.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../providers/navigation_provider.dart';

class VendorHome extends StatelessWidget {
  const VendorHome({super.key});

  @override
  Widget build(BuildContext context) {
    final pendingRequests = [
      {
        'clientName': 'Maria Roberts',
        'requestDate': '25 April 2025',
        'location': 'Jakarta',
        'eventDate': '20 Mei 2025',
        'message': 'Halo Jordan, kami ingin mengundangmu untuk acara pernikahan kami!',
      },
    ];

    final currentProjects = [
      {
        'clientName': 'Emily Johnson',
        'eventDate': '10 Mei 2025',
        'location': 'Bandung',
        'projectType': 'Pernikahan',
        'status': 'Jadwal Pemotretan',
      },
      {
        'clientName': 'Rizky Putra',
        'eventDate': '15 Juni 2025',
        'location': 'Surabaya',
        'projectType': 'Ulang Tahun',
        'status': 'Sedang Berlangsung',
      },
      {
        'clientName': 'Sari Dewi',
        'eventDate': '5 Juli 2025',
        'location': 'Yogyakarta',
        'projectType': 'Acara Kantor',
        'status': 'Jadwal Pemotretan',
      },
    ];

   final chatData = [
  {'date': '10 Mei 2025', 'chatCount': 5},
  {'date': '11 Mei 2025', 'chatCount': 3}, 
  {'date': '12 Mei 2025', 'chatCount': 8}, 
  {'date': '13 Mei 2025', 'chatCount': 2}, 
  {'date': '14 Mei 2025', 'chatCount': 6}, 
  {'date': '15 Mei 2025', 'chatCount': 6}, 
  {'date': '16 Mei 2025', 'chatCount': 6}, 
];

    final chatCounts = chatData.map((e) => e['chatCount'] as int).toList();
    final maxChatCount = chatData.map((e) => e['chatCount'] as int).reduce((a, b) => a > b ? a : b);

final double maxYValue = maxChatCount <= 5 ? 10 : (maxChatCount + 5 - maxChatCount % 5);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18,18,18,0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                      context.read<NavigationProvider>().vendorNavigateToPage(
                          context, VendorBio(), targetTabIndex:0, hrsLogin: false );

                  },
                  child: Row(
                    children: [
                    ClipOval(
  child: CachedNetworkImage(
    imageUrl: context.read<NavigationProvider>().ambilGambar('photographer_icon.png'),
    width: 64, // 2 * radius (32)
    height: 64,
    fit: BoxFit.cover,
    placeholder: (context, url) => Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        width: 64,
        height: 64,
        color: Colors.white,
      ),
    ),
    errorWidget: (context, url, error) => Container(
      width: 64,
      height: 64,
      decoration: const BoxDecoration(
        color: Colors.grey,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.error, color: Colors.red),
    ),
  ),
),

                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Jordan Langton',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 20,
                              letterSpacing: 0.2,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Fotografer',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          )
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                const Text(
                  'Jumlah Orang Bertanya',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),

Padding(
  padding: const EdgeInsets.only(right: 10),
  child: SizedBox(
    height: 200,
    child: LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= chatData.length) {
                  return const SizedBox.shrink();
                }
                final date = chatData[index]['date'] as String;
                final day = date.split(' ')[0];
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    day,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: 5,
              getTitlesWidget: (value, meta) {
                if (value % 5 != 0) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    value.toInt().toString(),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                );
              },
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true,
          border: const Border(
            bottom: BorderSide(color: Colors.grey, width: 1),
            left: BorderSide(color: Colors.grey, width: 1),
            right: BorderSide(color: Colors.transparent),
            top: BorderSide(color: Colors.transparent),
          ),
        ),
        minX: 0,
        maxX: (chatData.length - 1).toDouble(),
        minY: 0,
        maxY: maxYValue,
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(
              chatData.length,
              (index) => FlSpot(
                index.toDouble(),
                (chatData[index]['chatCount'] as int).toDouble(),
              ),
            ),
            isCurved: true,
            gradient: LinearGradient(
              colors: [
                Constants.primaryColorVendor.withOpacity(0.6),
                Constants.primaryColorVendor.withOpacity(0.3),
              ],
            ),
            barWidth: 3,
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  Constants.primaryColorVendor.withOpacity(0.4),
                  Constants.primaryColorVendor.withOpacity(0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            dotData: FlDotData(show: true),
          ),
        ],
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((touchedSpot) {
                final index = touchedSpot.x.toInt();
                final date = chatData[index]['date'];
                final count = touchedSpot.y.toInt();
                final textStyle = const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                );
                return LineTooltipItem(
                  '$date:\n$count chat',
                  textStyle,
                );
              }).toList();
            },
          ),
        ),
      ),
    ),
  ),
),



                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Order Berlangsung',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                currentProjects.isEmpty
                    ? _buildEmptyProjectState()
                    : Column(
                        children: currentProjects.map((project) => buildCard(
                          context: context,
                          clientName: project['clientName']!,
                          kategori: project['projectType']!,
                          dateValue: project['eventDate']!,
                          location: project['location']!,
                        )).toList(),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildCard({
    required BuildContext context,
    required String clientName,
    required String kategori,
    required String dateValue,
    required String location,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 7,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            clientName,
            style: const TextStyle(
           
              fontSize: 15,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    iconWithText(Icons.category_outlined, kategori),
                    const SizedBox(height: 6),
                    iconWithText(Icons.calendar_today_outlined, dateValue),
                    const SizedBox(height: 6),
                    iconWithText(Icons.location_on_outlined, location),
                  ],
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Constants.primaryColorVendor,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(40),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                onPressed: () {
 context.read<NavigationProvider>().vendorNavigateToPage(
                          context, VendorSingleOrder(), targetTabIndex:0, hrsLogin: true );

                },
                child: const Text(
                  'Detil',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget iconWithText(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyProjectState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Belum ada order berlangsung, Isi portofoliomu untuk meningkatkan daya tarik',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Constants.primaryColorVendor,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(40),
              ),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            child: const Text(
              'Edit bio',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
