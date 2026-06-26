import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/providers/role_provider.dart';
import '../../../core/providers/app_providers.dart';
import '../../../domain/entities/transaction_entity.dart';
import '../../../core/widgets/scale_on_tap.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentRole = ref.watch(roleProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    
    final transactionsAsync = ref.watch(transactionRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tổng quan'),
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
 
          final allTxs = snapshot.data ?? [];
          final confirmedTxs = allTxs.where((tx) => tx.status == TransactionStatus.confirmed).toList();
 
          final incomeSum = confirmedTxs
              .where((tx) => tx.type == TransactionType.income)
              .map((tx) => tx.amount)
              .fold(0, (sum, val) => sum + val);
 
          final expenseSum = confirmedTxs
              .where((tx) => tx.type == TransactionType.expense)
              .map((tx) => tx.amount)
              .fold(0, (sum, val) => sum + val);
 
          final netCashFlow = incomeSum - expenseSum;
 
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Welcome header section showing role
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Xin chào 👋',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currentRole.nameVi,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.admin_panel_settings_rounded,
                        color: Colors.blueAccent,
                        size: 22,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Display different widgets depending on the role
                if (currentRole == UserRole.financeManager) ...[
                  _buildFinanceManagerOverview(context, incomeSum, expenseSum, netCashFlow, currencyFormatter),
                ] else if (currentRole == UserRole.expenseAccountant) ...[
                  _buildExpenseAccountantOverview(context, expenseSum, currencyFormatter),
                ] else ...[
                  _buildRevenueAccountantOverview(context, incomeSum, currencyFormatter),
                ],
                const SizedBox(height: 24),
                
                // Charts Card
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Xu hướng tài chính tuần này',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 200,
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: (incomeSum > expenseSum ? incomeSum : expenseSum).toDouble() * 1.2,
                              barGroups: [
                                BarChartGroupData(
                                  x: 0,
                                  barRods: [
                                    BarChartRodData(
                                      toY: incomeSum.toDouble(),
                                      color: Colors.green,
                                      width: 24,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ],
                                ),
                                BarChartGroupData(
                                  x: 1,
                                  barRods: [
                                    BarChartRodData(
                                      toY: expenseSum.toDouble(),
                                      color: Colors.red,
                                      width: 24,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 24,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            _buildLegendItem('Doanh thu (Thu)', Colors.green),
                            _buildLegendItem('Chi phí (Chi)', Colors.red),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildFinanceManagerOverview(
      BuildContext context, int income, int expense, int net, NumberFormat fmt) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final Color primaryGreen = theme.colorScheme.primary;
    final Color bgDarkForest = const Color(0xFF06150F);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Hero Card: Net Cash Flow (Dòng tiền thuần) with Premium Green Gradient
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF0C2C1F), bgDarkForest] 
                  : [const Color(0xFF00D09E), const Color(0xFF008B6B)], 
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: primaryGreen.withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark 
                    ? Colors.black.withOpacity(0.5) 
                    : const Color(0xFF00D09E).withOpacity(0.25),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'DÒNG TIỀN THUẦN (NET CASH)',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Icon(
                    Icons.account_balance_wallet_rounded,
                    color: Colors.white.withOpacity(0.9),
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                fmt.format(net),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    net >= 0 ? Icons.trending_up : Icons.trending_down,
                    color: net >= 0 ? primaryGreen : const Color(0xFFF87171), // neon emerald / red
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    net >= 0 ? 'Thặng dư ngân sách' : 'Thâm hụt ngân sách',
                    style: TextStyle(
                      color: net >= 0 ? primaryGreen : const Color(0xFFF87171),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 2. Row of 2 Cards: Doanh thu & Chi phí with ScaleOnTap Animations
        Row(
          children: [
            // Doanh Thu Card (Soft Green Gradient + Click Animation)
            Expanded(
              child: ScaleOnTap(
                onTap: () => context.go('/transactions'),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF0E1F16), bgDarkForest] // Deep slate green to dark obsidian
                          : [Colors.white, const Color(0xFFECFDF5)], // White to light mint
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: primaryGreen.withOpacity(0.18),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primaryGreen.withOpacity(0.11),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.arrow_downward_rounded, color: primaryGreen, size: 16),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Doanh thu',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 6),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          fmt.format(income),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Chi Phí Card (Soft Red Gradient + Click Animation)
            Expanded(
              child: ScaleOnTap(
                onTap: () => context.go('/transactions'),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF220D0D), bgDarkForest] // Deep dark ruby red to dark obsidian
                          : [Colors.white, const Color(0xFFFEF2F2)], // White to light rose
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark 
                          ? Colors.red.withOpacity(0.2) 
                          : Colors.red.withOpacity(0.15),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_upward_rounded, color: Colors.red, size: 16),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Chi phí',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 6),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          fmt.format(expense),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        
        // 3. Quick Actions row
        const SizedBox(height: 20),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'THAO TÁC NHANH',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildActionButton(context, Icons.receipt_long, 'Hóa đơn', () => context.go('/invoices/incoming')),
            _buildActionButton(context, Icons.insert_chart_outlined_rounded, 'Báo cáo', () => context.go('/reports')),
            _buildActionButton(context, Icons.category_outlined, 'Danh mục', () => context.go('/categories')),
            _buildActionButton(context, Icons.settings_outlined, 'Cài đặt', () => context.go('/settings')),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final Color primaryGreen = theme.colorScheme.primary;
    
    return ScaleOnTap(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark 
                  ? const Color(0xFF0E1F16) 
                  : primaryGreen.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: isDark 
                  ? Border.all(color: primaryGreen.withOpacity(0.15), width: 1)
                  : null,
            ),
            child: Icon(
              icon, 
              color: primaryGreen, 
              size: 20
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseAccountantOverview(BuildContext context, int expense, NumberFormat fmt) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildStatCard(
          context,
          title: 'Tổng Chi phí Đã ghi nhận',
          value: fmt.format(expense),
          icon: Icons.payments_outlined,
          color: Colors.red,
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: () {
            context.go('/invoices/scan');
          },
          icon: const Icon(Icons.qr_code_scanner),
          label: const Text('Quét hóa đơn mới', style: TextStyle(fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildRevenueAccountantOverview(BuildContext context, int income, NumberFormat fmt) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildStatCard(
          context,
          title: 'Tổng Doanh thu Đã ghi nhận',
          value: fmt.format(income),
          icon: Icons.account_balance_wallet_outlined,
          color: Colors.green,
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: () {
            context.go('/invoices/outgoing/new');
          },
          icon: const Icon(Icons.add),
          label: const Text('Tạo Hóa đơn mới', style: TextStyle(fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context,
      {required String title, required String value, required IconData icon, required Color color}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
