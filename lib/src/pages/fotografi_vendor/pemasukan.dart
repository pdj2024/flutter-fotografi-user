import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:mpjnew/src/core/constants/constants.dart';

/// ==============================
///  PemasukanPage (mingguan)
/// ==============================
class PemasukanPage extends StatelessWidget {
  PemasukanPage({Key? key}) : super(key: key) {
    // ───────── Dummy data harian (Rupiah) ─────────
    //  ➜ Ganti dengan data real dari backend agar grafik akurat
    _dailyIncome = {
      DateTime(2025, 5, 1): 500000,
      DateTime(2025, 5, 2): 350000,
      DateTime(2025, 5, 4): 420000,
      DateTime(2025, 5, 6): 380000,
      DateTime(2025, 5, 8): 900000,
      DateTime(2025, 5, 12): 720000,
      DateTime(2025, 5, 15): 610000,
      DateTime(2025, 5, 18): 950000,
      DateTime(2025, 5, 20): 430000,
      DateTime(2025, 5, 21): 800000,
    };

    // ───────── Build label & value per-minggu ─────────
    final today = DateTime.now(); // 21-05-2025
    final ranges = _generateWeeklyRanges(today);

    revenueValues = ranges
        .map((r) => _sumIncome(r[0], r[1], _dailyIncome))
        .toList();

    revenueLabels =
        ranges.map((r) => _formatRange(r[0], r[1])).toList();

    // ───────── Data lain (dummy) ─────────
    currentBalance = 8155000;
    totalIncomeThisMonth =
        (revenueValues.fold<double>(0, (p, e) => p + e)) *
            1e6; // balik ke rupiah
    incomePercentChange = -10;
    totalReservations = 428;
    reservationPercentChange = 25;
  }

  // ──────────────────────────────────────────
  //  STATE / DATA
  // ──────────────────────────────────────────
  late final Map<DateTime, double> _dailyIncome;

  late final List<double> revenueValues; // dalam juta
  late final List<String> revenueLabels;

  late final double currentBalance; // rupiah
  late final double totalIncomeThisMonth; // rupiah
  late final double incomePercentChange; // %
  late final int totalReservations;
  late final double reservationPercentChange; // %

  final _currency = NumberFormat.currency(
      locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  // ──────────────────────────────────────────
  //  BUILD
  // ──────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final maxY =
        (revenueValues.reduce((a, b) => a > b ? a : b)).ceil().toDouble();

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F9F9),
        elevation: 1,
        title: const Text(
          'Pemasukan',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ───────── Saldo saat ini ─────────
                _buildBalanceCard(),
                const SizedBox(height: 28),

                // ───────── Statistik Bulan Ini ─────────
                const Text(
                  'Statistik Bulan Ini',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    _buildStatisticBox(
                      title: 'Pendapatan',
                      value: _currency.format(totalIncomeThisMonth),
                      percent: incomePercentChange,
                    ),
                    const SizedBox(width: 22),
                    _buildStatisticBox(
                      title: 'Jumlah Order',
                      value: totalReservations.toString(),
                      percent: reservationPercentChange,
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // ───────── Grafik Tren Pendapatan ─────────
                SizedBox(
                  height: 280,  // dinaikkan supaya label bawah tidak overflow
                  child: Padding(
                   padding: const EdgeInsets.only(right: 16),
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(show: false),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 56,  // dinaikkan dari 42
                              interval: 1,
                              getTitlesWidget: (value, meta) {
                                final i = value.toInt();
                                if (i < 0 || i >= revenueLabels.length) {
                                  return const SizedBox.shrink();
                                }
                                final parts = revenueLabels[i].split('\n');
                                return SideTitleWidget(
                                  axisSide: meta.axisSide,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        parts[0], // ex: "1–7"
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        parts[1], // ex: "MEI"
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                    
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              interval: 1,
                              getTitlesWidget: (value, meta) {
                                if (value % 1 != 0) {
                                  return const SizedBox.shrink();
                                }
                                return Padding(
                                  padding:
                                      const EdgeInsets.only(right: 4.0),
                                  child: Text(
                                    '${value.toInt()} Jt',
                                    style: TextStyle(
                                        color: Colors.grey.shade600),
                                  ),
                                );
                              },
                            ),
                          ),
                          rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: const Border(
                            bottom: BorderSide(color: Colors.grey),
                            left: BorderSide(color: Colors.grey),
                            right: BorderSide(color: Colors.transparent),
                            top: BorderSide(color: Colors.transparent),
                          ),
                        ),
                        minX: 0,
                        maxX: (revenueValues.length - 1).toDouble(),
                        minY: 0,
                        maxY: maxY,
                        lineBarsData: [
                          LineChartBarData(
                            spots: List.generate(
                              revenueValues.length,
                              (i) =>
                                  FlSpot(i.toDouble(), revenueValues[i]),
                            ),
                            isCurved: true,
                            gradient: LinearGradient(
                              colors: [
                                Constants.primaryColorVendor
                                    .withOpacity(.8),
                                Constants.primaryColorVendor
                                    .withOpacity(.4),
                              ],
                            ),
                            barWidth: 3,
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Constants.primaryColorVendor
                                      .withOpacity(.3),
                                  Constants.primaryColorVendor
                                      .withOpacity(.05),
                                ],
                              ),
                            ),
                            dotData: FlDotData(show: true),
                          ),
                        ],
                        lineTouchData: LineTouchData(
                          handleBuiltInTouches: true,
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipItems: (spots) => spots.map((e) {
                              final idx = e.x.toInt();
                              return LineTooltipItem(
                                '${revenueLabels[idx]}\n${e.y.toStringAsFixed(1)} Jt',
                                const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────
  //  WIDGETS
  // ──────────────────────────────────────────
  Widget _buildBalanceCard() => Container(
        width: double.infinity,
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: Constants.primaryColorVendor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Saldo saat ini',
                style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            Text(
              _currency.format(currentBalance),
              style: const TextStyle(
                fontSize: 24,
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );

  Widget _buildStatisticBox({
    required String title,
    required String value,
    required double percent,
  }) {
    final isPositive = percent >= 0;
    final icon =
        isPositive ? Icons.arrow_upward : Icons.arrow_downward;
    final color = isPositive ? Colors.green : Colors.red;

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 2),
              Text('${percent.abs().toStringAsFixed(0)}%',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: color)),
              const SizedBox(width: 4),
              Text('dari bulan lalu',
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600)),
            ],
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────
  //  HELPERS
  // ──────────────────────────────────────────
  /// Buat rentang minggu ("1-7", "8-14", dst.) untuk bulan berjalan.
  List<List<DateTime>> _generateWeeklyRanges(DateTime today) {
    final monthStart = DateTime(today.year, today.month, 1);
    final ranges = <List<DateTime>>[];

    DateTime start = monthStart;
    while (!start.isAfter(today)) {
      DateTime end = start.add(const Duration(days: 6));
      if (end.month != start.month || end.isAfter(today)) {
        end = today; // potong di hari ini
      }
      ranges.add([start, end]);
      start = end.add(const Duration(days: 1));
    }
    return ranges;
  }

  /// Contoh: 1-7 Apr  |  15-21 Mei
  String _formatRange(DateTime start, DateTime end) {
    final rangeStr = '${start.day}-${end.day}';
    final monthStr = DateFormat('MMM', 'id_ID').format(end).toUpperCase();
    return '$rangeStr\n$monthStr'; // pisahkan baris
  }

  /// Jumlahkan pendapatan dalam rentang [start..end] (kembali juta).
  double _sumIncome(DateTime start, DateTime end,
      Map<DateTime, double> data) {
    double total = 0;
    for (final e in data.entries) {
      if (!e.key.isBefore(start) && !e.key.isAfter(end)) {
        total += e.value;
      }
    }
    return total / 1e6; // ke juta
  }
}
