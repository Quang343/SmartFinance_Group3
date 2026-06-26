import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:smart_finance/core/providers/app_providers.dart';
import 'package:smart_finance/domain/entities/transaction_entity.dart';

class ReportDetailScreen extends ConsumerWidget {
  final String reportType; // 'income' or 'expense'

  const ReportDetailScreen({super.key, required this.reportType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final isIncome = reportType == 'income';
    final transactionsAsync = ref.watch(transactionRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(isIncome ? 'Breakdown Doanh thu' : 'Breakdown Chi phí'),
      ),
      body: FutureBuilder<List<TransactionEntity>>(
        future: transactionsAsync.getAll(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('Đã xảy ra lỗi khi tải dữ liệu.'));
          }

          final list = snapshot.data!
              .where((tx) =>
                  tx.type == (isIncome ? TransactionType.income : TransactionType.expense) &&
                  tx.status == TransactionStatus.confirmed)
              .toList();

          if (list.isEmpty) {
            return const Center(child: Text('Không có dữ liệu giao dịch.'));
          }

          // Calculate totals per category
          final Map<String, int> categoryTotals = {};
          int totalSum = 0;
          for (var tx in list) {
            categoryTotals[tx.categoryId] = (categoryTotals[tx.categoryId] ?? 0) + tx.amount;
            totalSum += tx.amount;
          }

          final pieSections = categoryTotals.entries.map((entry) {
            final percentage = totalSum > 0 ? (entry.value / totalSum * 100) : 0;
            return PieChartSectionData(
              value: entry.value.toDouble(),
              title: '${percentage.toStringAsFixed(1)}%',
              color: isIncome
                  ? Colors.greenAccent.shade700.withBlue(100 + entry.key.hashCode % 100)
                  : Colors.redAccent.withGreen(100 + entry.key.hashCode % 100),
              radius: 60,
              titleStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            );
          }).toList();

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              SizedBox(
                height: 220,
                child: PieChart(
                  PieChartData(
                    sections: pieSections,
                    centerSpaceRadius: 40,
                    sectionsSpace: 2,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Tổng quan theo Danh mục',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Divider(height: 24),
              ...categoryTotals.entries.map((entry) {
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isIncome ? Colors.green.shade50 : Colors.red.shade50,
                    child: Icon(
                      isIncome ? Icons.trending_up : Icons.trending_down,
                      color: isIncome ? Colors.green : Colors.red,
                    ),
                  ),
                  title: Text(entry.key.replaceAll('cat_', '').toUpperCase()),
                  trailing: Text(
                    currencyFormatter.format(entry.value),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
