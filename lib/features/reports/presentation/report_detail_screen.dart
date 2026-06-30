import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_finance/core/providers/app_providers.dart';
import 'package:smart_finance/domain/entities/transaction_entity.dart';
import 'package:smart_finance/domain/entities/category_entity.dart';
import 'package:smart_finance/core/widgets/scale_on_tap.dart';

class ReportDetailScreen extends ConsumerWidget {
  final String reportType; // 'income' or 'expense'
  final String period;
  final String? startDate;
  final String? endDate;

  const ReportDetailScreen({
    super.key, 
    required this.reportType,
    this.period = 'all',
    this.startDate,
    this.endDate,
  });

  bool _isWithinPeriod(DateTime date) {
    final now = DateTime.now();
    switch (period) {
      case 'today':
        return date.year == now.year && date.month == now.month && date.day == now.day;
      case 'month':
        return date.year == now.year && date.month == now.month;
      case 'year':
        return date.year == now.year;
      case 'custom':
        if (startDate == null || endDate == null) return true;
        final start = DateTime.parse(startDate!);
        final end = DateTime.parse(endDate!).add(const Duration(days: 1)).subtract(const Duration(seconds: 1));
        return date.isAfter(start.subtract(const Duration(seconds: 1))) && date.isBefore(end.add(const Duration(seconds: 1)));
      case 'all':
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
    final isIncome = reportType == 'income';
    final transactionsRepo = ref.watch(transactionRepositoryProvider);
    final categoriesRepo = ref.watch(categoryRepositoryProvider);

    // Fetch transactions and categories in parallel to map UUIDs
    final dataFuture = Future.wait([
      transactionsRepo.getAll(),
      categoriesRepo.getAll(),
    ]);

    // Curated color palette for sections
    final incomeColors = [
      const Color(0xFF00D09E),
      const Color(0xFF3B82F6),
      const Color(0xFF06B6D4),
      const Color(0xFF8B5CF6),
      const Color(0xFF10B981),
    ];

    final expenseColors = [
      const Color(0xFFEF4444),
      const Color(0xFFF97316),
      const Color(0xFFF59E0B),
      const Color(0xFFEC4899),
      const Color(0xFF8B5CF6),
    ];

    final colors = isIncome ? incomeColors : expenseColors;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF06150F) : const Color(0xFFF4FAF7),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF06150F) : const Color(0xFFF4FAF7),
        elevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        leading: Center(
          child: ScaleOnTap(
            onTap: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                context.go('/reports');
              }
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0D281E) : Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  if (!isDark)
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                ],
                border: Border.all(
                  color: isDark ? const Color(0xFF1E3A2F) : const Color(0xFFEDF2F7),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF00D09E),
                size: 16,
              ),
            ),
          ),
        ),
        title: ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: isIncome ? [const Color(0xFF00D09E), const Color(0xFF34D399)] : [const Color(0xFFEF4444), const Color(0xFFF87171)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: Text(
            isIncome ? 'Chi tiết Doanh thu' : 'Chi tiết Chi phí',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: Colors.white,
              fontSize: 22,
              letterSpacing: -0.5,
            ),
          ),
        ),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: isIncome ? const Color(0xFF00D09E) : const Color(0xFFEF4444)));
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Text(
                'Đã xảy ra lỗi khi tải dữ liệu.',
                style: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
              ),
            );
          }

          final allTxs = snapshot.data![0] as List<TransactionEntity>;
          final allCats = snapshot.data![1] as List<CategoryEntity>;
          
          final categoryMap = {for (var c in allCats) c.id: c.name};

          final list = allTxs
              .where((tx) =>
                  tx.type == (isIncome ? TransactionType.income : TransactionType.expense) &&
                  tx.status == TransactionStatus.confirmed &&
                  _isWithinPeriod(tx.transactionDate))
              .toList();

          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bar_chart_rounded,
                    size: 64,
                    color: isDark ? Colors.white24 : Colors.black12,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Không có dữ liệu giao dịch.',
                    style: TextStyle(color: isDark ? Colors.white38 : Colors.black45, fontSize: 15),
                  ),
                ],
              ),
            );
          }

          // Calculate totals per category
          final Map<String, int> categoryTotals = {};
          int totalSum = 0;
          for (var tx in list) {
            final catName = categoryMap[tx.categoryId] ?? 'Chưa phân loại';
            categoryTotals[catName] = (categoryTotals[catName] ?? 0) + tx.amount.toInt();
            totalSum += tx.amount.toInt();
          }

          int colorIndex = 0;
          final List<PieChartSectionData> pieSections = [];
          final Map<String, Color> categoryColorMap = {};
          
          categoryTotals.forEach((catName, amount) {
            final percentage = totalSum > 0 ? (amount / totalSum * 100) : 0;
            final color = colors[colorIndex % colors.length];
            categoryColorMap[catName] = color;
            colorIndex++;

            pieSections.add(
              PieChartSectionData(
                value: amount.toDouble(),
                title: '${percentage.toStringAsFixed(1)}%',
                color: color,
                radius: 40, // Slightly thinner donut
                titleStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            );
          });

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Chart Card
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0D251C) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? const Color(0xFF1E3A2F) : const Color(0xFFE2E8F0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: SizedBox(
                  height: 200,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sections: pieSections,
                          centerSpaceRadius: 60, // Increase space for center text
                          sectionsSpace: 3,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Tổng ${isIncome ? "doanh thu" : "chi phí"}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white70 : const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currencyFormatter.format(totalSum),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isDark ? Colors.white : const Color(0xFF093021),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              Text(
                'Tổng quan theo Danh mục',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: isDark ? Colors.white : const Color(0xFF093021),
                ),
              ),
              const SizedBox(height: 8),
              Divider(color: isDark ? const Color(0xFF1E3A2F) : const Color(0xFFE2E8F0)),
              const SizedBox(height: 8),

              // Category item lists in styled containers
              ...categoryTotals.entries.map((entry) {
                final catName = entry.key;
                final percentage = totalSum > 0 ? (entry.value / totalSum * 100) : 0.0;
                final itemColor = categoryColorMap[catName] ?? (isIncome ? const Color(0xFF00D09E) : const Color(0xFFEF4444));

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0D251C) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? const Color(0xFF1E3A2F) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: itemColor.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isIncome ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                          color: itemColor,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              catName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF093021),
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Chiếm ${percentage.toStringAsFixed(1)}%',
                              style: TextStyle(
                                color: isDark ? Colors.white38 : Colors.black45,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        currencyFormatter.format(entry.value),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: itemColor,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
