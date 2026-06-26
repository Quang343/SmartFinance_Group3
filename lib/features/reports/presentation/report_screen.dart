import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/role_provider.dart';
import '../../../core/providers/app_providers.dart';
import '../../../domain/entities/transaction_entity.dart';
import '../../../core/widgets/scale_on_tap.dart';

class ReportScreen extends ConsumerWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentRole = ref.watch(roleProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    
    final transactionsAsync = ref.watch(transactionRepositoryProvider);

    final showIncome = currentRole == UserRole.financeManager || currentRole == UserRole.revenueAccountant;
    final showExpense = currentRole == UserRole.financeManager || currentRole == UserRole.expenseAccountant;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo cáo Tài chính'),
      ),
      body: FutureBuilder<List<TransactionEntity>>(
        future: transactionsAsync.getAll(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }

          final list = snapshot.data ?? [];
          final confirmed = list.where((tx) => tx.status == TransactionStatus.confirmed).toList();

          final totalIncome = confirmed
              .where((tx) => tx.type == TransactionType.income)
              .map((tx) => tx.amount)
              .fold(0, (sum, val) => sum + val);

          final totalExpense = confirmed
              .where((tx) => tx.type == TransactionType.expense)
              .map((tx) => tx.amount)
              .fold(0, (sum, val) => sum + val);

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              if (showIncome) ...[
                _buildReportCard(
                  context,
                  title: 'Báo cáo Doanh thu',
                  subtitle: 'Chi tiết các khoản thu nhập bán hàng, dịch vụ...',
                  amount: totalIncome,
                  color: Colors.green,
                  onTap: () {
                    context.go('/reports/detail?type=income');
                  },
                ),
                const SizedBox(height: 20),
              ],
              if (showExpense) ...[
                _buildReportCard(
                  context,
                  title: 'Báo cáo Chi phí',
                  subtitle: 'Theo dõi chi phí lương, mặt bằng, marketing...',
                  amount: totalExpense,
                  color: Colors.red,
                  onTap: () {
                    context.go('/reports/detail?type=expense');
                  },
                ),
                const SizedBox(height: 20),
              ],
              if (currentRole == UserRole.financeManager) ...[
                // Net cash flow
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF0A231A), const Color(0xFF06150F)]
                            : [const Color(0xFFECFDF5), Colors.white],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Dòng tiền thuần doanh nghiệp',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          currencyFormatter.format(totalIncome - totalExpense),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                            color: (totalIncome - totalExpense) >= 0 ? Colors.green : Colors.red,
                          ),
                        ),
                        const Divider(height: 24),
                        ScaleOnTap(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Đang tạo báo cáo PDF tổng hợp...'),
                                backgroundColor: theme.colorScheme.primary,
                              ),
                            );
                          },
                          child: ElevatedButton.icon(
                            onPressed: null,
                            icon: const Icon(Icons.picture_as_pdf),
                            label: const Text('Xuất báo cáo PDF'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: theme.colorScheme.primary,
                              disabledForegroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildReportCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required int amount,
    required Color color,
    required VoidCallback onTap,
  }) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return ScaleOnTap(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ListTile(
          onTap: null,
          contentPadding: const EdgeInsets.all(20),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(subtitle),
                const SizedBox(height: 8),
                Text(
                  currencyFormatter.format(amount),
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: color),
                ),
              ],
            ),
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 18),
        ),
      ),
    );
  }
}
