import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../../domain/entities/transaction_entity.dart';
import '../../../../domain/entities/category_entity.dart';

final List<Color> _incomeColors = [
  const Color(0xFF00D09E),
  const Color(0xFF3B82F6),
  const Color(0xFF06B6D4),
  const Color(0xFF8B5CF6),
  const Color(0xFF10B981),
  const Color(0xFFF59E0B),
  const Color(0xFFEC4899),
  const Color(0xFF6366F1),
];

final List<Color> _expenseColors = [
  const Color(0xFFEF4444),
  const Color(0xFFF97316),
  const Color(0xFFF59E0B),
  const Color(0xFFEC4899),
  const Color(0xFF8B5CF6),
  const Color(0xFF06B6D4),
  const Color(0xFF14B8A6),
  const Color(0xFF78716C),
];

class DashboardCharts extends StatelessWidget {
  final List<TransactionEntity> allTxs;
  final List<TransactionEntity> filteredTxs;
  final List<CategoryEntity> allCats;
  final bool isDark;
  final NumberFormat currencyFormatter;
  final String timeFilter;
  final DateTimeRange? customDateRange;

  const DashboardCharts({
    super.key,
    required this.allTxs,
    required this.filteredTxs,
    required this.allCats,
    required this.isDark,
    required this.currencyFormatter,
    required this.timeFilter,
    this.customDateRange,
  });

  Color _cardBg() => isDark ? const Color(0xFF0C2C1F) : Colors.white;
  Color _borderColor() => isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100;
  Color _textColor() => isDark ? Colors.white : const Color(0xFF1E293B);
  Color _mutedText() => isDark ? Colors.white60 : Colors.grey.shade600;

  String _compact(int amount) {
    if (amount >= 1000000000) {
      final v = amount / 1000000000;
      return '${v == v.toInt() ? v.toInt() : v.toStringAsFixed(1)}Tỷ';
    } else if (amount >= 1000000) {
      final v = amount / 1000000;
      return '${v == v.toInt() ? v.toInt() : v.toStringAsFixed(1)}Tr';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return '$amount₫';
  }

  @override
  Widget build(BuildContext context) {
    final catMap = {for (var c in allCats) c.id: c};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PHÂN TÍCH CHI TIẾT',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 12),
        if (MediaQuery.of(context).size.width < 600) ...[
          _buildExpenseByCategory(catMap),
          const SizedBox(height: 12),
          _buildIncomeByCategory(catMap),
        ] else ...[
          Row(
            children: [
              Expanded(child: _buildExpenseByCategory(catMap)),
              const SizedBox(width: 12),
              Expanded(child: _buildIncomeByCategory(catMap)),
            ],
          ),
        ],
        const SizedBox(height: 12),
        _buildComparisonChart(),
        const SizedBox(height: 12),
        _buildCashFlowChart(),
      ],
    );
  }

  Widget _buildChartCard({
    required String title,
    required Widget child,
    double? height,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg(),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderColor()),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: _mutedText(),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: height ?? 180,
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildDonutWithLegend({
    required List<MapEntry<String, int>> data,
    required List<Color> colors,
    required int total,
  }) {
    if (data.isEmpty || total == 0) {
      return Center(
        child: Text(
          'Chưa có dữ liệu',
          style: TextStyle(color: _mutedText(), fontSize: 12),
        ),
      );
    }

    final sections = <PieChartSectionData>[];
    for (int i = 0; i < data.length; i++) {
      final pct = (data[i].value / total * 100);
      final bool showTitle = pct >= 5.0;
      
      String displayPct;
      if (pct > 0 && pct < 1.0) {
        displayPct = '<1%';
      } else {
        displayPct = '${pct.toStringAsFixed(1).replaceAll('.0', '')}%';
      }

      sections.add(
        PieChartSectionData(
          value: data[i].value.toDouble(),
          title: displayPct,
          showTitle: showTitle,
          color: colors[i % colors.length],
          radius: 35,
          titleStyle: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    return Row(
      children: [
        SizedBox(
          width: 100,
          height: 130,
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 24,
              sectionsSpace: 2,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(data.length, (i) {
                final pct = total > 0 ? (data[i].value / total * 100) : 0.0;
                String displayPct;
                if (pct > 0 && pct < 1.0) {
                  displayPct = '<1%';
                } else {
                  displayPct = '${pct.toStringAsFixed(1).replaceAll('.0', '')}%';
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: colors[i % colors.length],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          data[i].key,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            color: _textColor(),
                          ),
                        ),
                      ),
                      Text(
                        displayPct,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _textColor(),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpenseByCategory(Map<String, CategoryEntity> catMap) {
    final expenseTxs = filteredTxs.where(
      (tx) => tx.type == TransactionType.expense,
    );
    final Map<String, int> catTotals = {};
    int total = 0;
    for (var tx in expenseTxs) {
      final name = catMap[tx.categoryId]?.name ?? 'Khác';
      catTotals[name] = (catTotals[name] ?? 0) + tx.amount;
      total += tx.amount;
    }
    final sorted = catTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final List<MapEntry<String, int>> displayData = [];
    int otherSum = 0;
    for (int i = 0; i < sorted.length; i++) {
      if (i < 5) {
        displayData.add(sorted[i]);
      } else {
        otherSum += sorted[i].value;
      }
    }
    if (otherSum > 0) {
      displayData.add(MapEntry('Các mục khác', otherSum));
    }

    return _buildChartCard(
      title: 'CHI PHÍ THEO DANH MỤC',
      height: 160,
      child: _buildDonutWithLegend(
        data: displayData,
        colors: _expenseColors,
        total: total,
      ),
    );
  }

  Widget _buildIncomeByCategory(Map<String, CategoryEntity> catMap) {
    final incomeTxs = filteredTxs.where(
      (tx) => tx.type == TransactionType.income,
    );
    final Map<String, int> catTotals = {};
    int total = 0;
    for (var tx in incomeTxs) {
      final name = catMap[tx.categoryId]?.name ?? 'Khác';
      catTotals[name] = (catTotals[name] ?? 0) + tx.amount;
      total += tx.amount;
    }
    final sorted = catTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final List<MapEntry<String, int>> displayData = [];
    int otherSum = 0;
    for (int i = 0; i < sorted.length; i++) {
      if (i < 5) {
        displayData.add(sorted[i]);
      } else {
        otherSum += sorted[i].value;
      }
    }
    if (otherSum > 0) {
      displayData.add(MapEntry('Các mục khác', otherSum));
    }

    return _buildChartCard(
      title: 'DOANH THU THEO DANH MỤC',
      height: 160,
      child: _buildDonutWithLegend(
        data: displayData,
        colors: _incomeColors,
        total: total,
      ),
    );
  }

  List<_ComparisonBucket> _getComparisonData() {
    final now = DateTime.now();

    if (timeFilter == 'all') {
      if (allTxs.isEmpty) return [];
      int minYear = now.year;
      int maxYear = now.year;
      for (var tx in allTxs) {
        if (tx.status != TransactionStatus.confirmed) continue;
        if (tx.transactionDate.year < minYear) minYear = tx.transactionDate.year;
        if (tx.transactionDate.year > maxYear) maxYear = tx.transactionDate.year;
      }
      
      final buckets = <_ComparisonBucket>[];
      for (int y = minYear; y <= maxYear; y++) {
        int inc = 0, exp = 0;
        for (var tx in allTxs) {
          if (tx.status != TransactionStatus.confirmed) continue;
          if (tx.transactionDate.year == y) {
            if (tx.type == TransactionType.income) inc += tx.amount;
            else exp += tx.amount;
          }
        }
        buckets.add(_ComparisonBucket(
          label: 'Năm\n$y',
          income: inc,
          expense: exp,
        ));
      }
      return buckets;
    }

    if (timeFilter == 'daily') {
      final buckets = <_ComparisonBucket>[];
      for (int i = 6; i >= 0; i--) {
        final d = DateTime(now.year, now.month, now.day - i);
        int inc = 0, exp = 0;
        for (var tx in allTxs) {
          if (tx.status != TransactionStatus.confirmed) continue;
          if (tx.transactionDate.year == d.year &&
              tx.transactionDate.month == d.month &&
              tx.transactionDate.day == d.day) {
            if (tx.type == TransactionType.income) inc += tx.amount;
            else exp += tx.amount;
          }
        }
        final weekdays = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
        buckets.add(_ComparisonBucket(
          label: '${weekdays[d.weekday % 7]}\n${d.day}/${d.month}',
          income: inc,
          expense: exp,
        ));
      }
      return buckets;
    }

    if (timeFilter == 'yearly') {
      final buckets = <_ComparisonBucket>[];
      for (int m = 1; m <= 12; m++) {
        int inc = 0, exp = 0;
        for (var tx in allTxs) {
          if (tx.status != TransactionStatus.confirmed) continue;
          if (tx.transactionDate.year == now.year && tx.transactionDate.month == m) {
            if (tx.type == TransactionType.income) inc += tx.amount;
            else exp += tx.amount;
          }
        }
        buckets.add(_ComparisonBucket(
          label: 'T$m',
          income: inc,
          expense: exp,
        ));
      }
      return buckets;
    }

    if (timeFilter == 'custom' && customDateRange != null) {
      final range = customDateRange!;
      final days = range.end.difference(range.start).inDays;
      if (days <= 31) {
        final buckets = <_ComparisonBucket>[];
        for (int i = 0; i <= days; i++) {
          final d = DateTime(range.start.year, range.start.month, range.start.day + i);
          int inc = 0, exp = 0;
          for (var tx in allTxs) {
            if (tx.status != TransactionStatus.confirmed) continue;
            if (tx.transactionDate.year == d.year &&
                tx.transactionDate.month == d.month &&
                tx.transactionDate.day == d.day) {
              if (tx.type == TransactionType.income) inc += tx.amount;
              else exp += tx.amount;
            }
          }
          buckets.add(_ComparisonBucket(
            label: '${d.day}/${d.month}',
            income: inc,
            expense: exp,
          ));
        }
        return buckets;
      }
      final buckets = <_ComparisonBucket>[];
      final startMonth = range.start.month + range.start.year * 12;
      final endMonth = range.end.month + range.end.year * 12;
      final totalMonths = endMonth - startMonth + 1;
      for (int i = 0; i < totalMonths; i++) {
        final ym = startMonth + i;
        final y = (ym - 1) ~/ 12;
        final m = (ym - 1) % 12 + 1;
        int inc = 0, exp = 0;
        for (var tx in allTxs) {
          if (tx.status != TransactionStatus.confirmed) continue;
          if (tx.transactionDate.year == y && tx.transactionDate.month == m) {
            if (tx.type == TransactionType.income) inc += tx.amount;
            else exp += tx.amount;
          }
        }
        buckets.add(_ComparisonBucket(
          label: 'T$m\n${y % 100}',
          income: inc,
          expense: exp,
        ));
      }
      return buckets;
    }

    // monthly – last 6 months
    final buckets = <_ComparisonBucket>[];
    for (int i = 5; i >= 0; i--) {
      final d = DateTime(now.year, now.month - i, 1);
      int inc = 0, exp = 0;
      for (var tx in allTxs) {
        if (tx.status != TransactionStatus.confirmed) continue;
        if (tx.transactionDate.month == d.month &&
            tx.transactionDate.year == d.year) {
          if (tx.type == TransactionType.income) inc += tx.amount;
          else exp += tx.amount;
        }
      }
      buckets.add(_ComparisonBucket(
        label: 'T${d.month}\n${d.year % 100}',
        income: inc,
        expense: exp,
      ));
    }
    return buckets;
  }

  String _comparisonTitle() {
    switch (timeFilter) {
      case 'all': return 'SO SÁNH THU CHI TẤT CẢ';
      case 'daily': return 'SO SÁNH THU CHI TRONG TUẦN';
      case 'yearly': return 'SO SÁNH THU CHI TRONG NĂM';
      case 'custom': return 'SO SÁNH THU CHI';
      default: return 'SO SÁNH THU CHI 6 THÁNG';
    }
  }

  String _cashFlowTitle() {
    switch (timeFilter) {
      case 'all': return 'DÒNG TIỀN THUẦN TẤT CẢ';
      case 'daily': return 'DÒNG TIỀN THUẦN TRONG TUẦN';
      case 'yearly': return 'DÒNG TIỀN THUẦN TRONG NĂM';
      case 'custom': return 'DÒNG TIỀN THUẦN';
      default: return 'DÒNG TIỀN THUẦN 6 THÁNG';
    }
  }

  Widget _buildComparisonChart() {
    final data = _getComparisonData();
    if (data.isEmpty) {
      return _buildChartCard(
        title: _comparisonTitle(),
        child: Center(
          child: Text(
            'Chưa có dữ liệu',
            style: TextStyle(color: _mutedText(), fontSize: 12),
          ),
        ),
      );
    }

    final maxVal = data.fold<int>(0, (max, b) {
      final m = b.income > b.expense ? b.income : b.expense;
      return m > max ? m : max;
    });

    final groups = data.asMap().entries.map((e) {
      final idx = e.key;
      final bucket = e.value;
      return BarChartGroupData(
        x: idx,
        barRods: [
          BarChartRodData(
            toY: bucket.income.toDouble(),
            color: const Color(0xFF00D09E),
            width: 8,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
          BarChartRodData(
            toY: bucket.expense.toDouble(),
            color: const Color(0xFFEF4444),
            width: 8,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      );
    }).toList();

    final axisMax = maxVal > 0 ? maxVal * 1.3 : 1000000.0;

    return _buildChartCard(
      title: _comparisonTitle(),
      height: 220,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: axisMax,
          barGroups: groups,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: axisMax / 4,
            getDrawingHorizontalLine: (value) => FlLine(
              color: isDark ? Colors.white10 : Colors.grey.shade200,
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 48,
                getTitlesWidget: (value, meta) {
                  if (value == 0 || value == meta.max || value == meta.min) return const SizedBox.shrink();
                  return SideTitleWidget(
                    meta: meta,
                    space: 4,
                    child: Text(
                      _compact(value.toInt()),
                      style: TextStyle(
                        fontSize: 9,
                        color: _mutedText(),
                      ),
                    ),
                  );
                },
              ),
            ),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (value, _) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= data.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      data[idx].label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 9,
                        color: _mutedText(),
                        height: 1.2,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final bucket = data[group.x];
                final label = rodIndex == 0 ? 'Thu' : 'Chi';
                return BarTooltipItem(
                  '$label: ${currencyFormatter.format(rod.toY.toInt())}\n${bucket.label.replaceAll('\n', ' ')}',
                  TextStyle(
                    fontSize: 10,
                    color: rodIndex == 0 ? const Color(0xFF00D09E) : const Color(0xFFEF4444),
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }

  Widget _buildCashFlowChart() {
    final data = _getComparisonData();
    if (data.isEmpty) {
      return _buildChartCard(
        title: _cashFlowTitle(),
        child: Center(
          child: Text(
            'Chưa có dữ liệu',
            style: TextStyle(color: _mutedText(), fontSize: 12),
          ),
        ),
      );
    }

    final allNets = data.map((b) => b.income - b.expense).toList();
    final maxAbs = allNets.fold<int>(0, (max, n) => n.abs() > max ? n.abs() : max);
    final axisMax = maxAbs > 0 ? maxAbs * 1.4 : 1000000.0;

    final groups = data.asMap().entries.map((e) {
      final idx = e.key;
      final net = e.value.income - e.value.expense;
      return BarChartGroupData(
        x: idx,
        barRods: [
          BarChartRodData(
            toY: net.toDouble(),
            color: net >= 0
                ? const Color(0xFF00D09E)
                : const Color(0xFFEF4444),
            width: 16,
            borderRadius: net >= 0 
                ? const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4))
                : const BorderRadius.only(bottomLeft: Radius.circular(4), bottomRight: Radius.circular(4)),
          ),
        ],
      );
    }).toList();

    return _buildChartCard(
      title: _cashFlowTitle(),
      height: 220,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: axisMax,
          minY: -axisMax,
          barGroups: groups,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: axisMax / 3,
            getDrawingHorizontalLine: (value) {
              if (value == 0) {
                return FlLine(
                  color: isDark ? Colors.white30 : Colors.grey.shade400,
                  strokeWidth: 1.5,
                );
              }
              return FlLine(
                color: isDark ? Colors.white10 : Colors.grey.shade200,
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 48,
                getTitlesWidget: (value, meta) {
                  if (value == 0 || value == meta.max || value == meta.min) return const SizedBox.shrink();
                  return SideTitleWidget(
                    meta: meta,
                    space: 4,
                    child: Text(
                      _compact(value.abs().toInt()),
                      style: TextStyle(
                        fontSize: 9,
                        color: _mutedText(),
                      ),
                    ),
                  );
                },
              ),
            ),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (value, _) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= data.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      data[idx].label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 9,
                        color: _mutedText(),
                        height: 1.2,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final bucket = data[group.x];
                final net = bucket.income - bucket.expense;
                final sign = net >= 0 ? '+' : '';
                return BarTooltipItem(
                  '${sign}${currencyFormatter.format(net)}\n${bucket.label.replaceAll('\n', ' ')}',
                  TextStyle(
                    fontSize: 10,
                    color: net >= 0 ? const Color(0xFF00D09E) : const Color(0xFFEF4444),
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }
}

class _ComparisonBucket {
  final String label;
  final int income;
  final int expense;

  const _ComparisonBucket({
    required this.label,
    required this.income,
    required this.expense,
  });
}
