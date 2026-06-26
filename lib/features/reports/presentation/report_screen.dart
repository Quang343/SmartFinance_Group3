import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/role_provider.dart';
import '../../../core/providers/app_providers.dart';
import '../../../domain/entities/transaction_entity.dart';
import '../../../core/widgets/scale_on_tap.dart';

class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key});

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  String _selectedPeriod = 'all'; // 'all', 'today', 'month', 'year'

  bool _isWithinPeriod(DateTime date) {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'today':
        return date.year == now.year && date.month == now.month && date.day == now.day;
      case 'month':
        return date.year == now.year && date.month == now.month;
      case 'year':
        return date.year == now.year;
      case 'all':
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentRole = ref.watch(roleProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
    
    final transactionsAsync = ref.watch(transactionRepositoryProvider);

    final showIncome = currentRole == UserRole.financeManager || currentRole == UserRole.revenueAccountant;
    final showExpense = currentRole == UserRole.financeManager || currentRole == UserRole.expenseAccountant;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF06150F) : const Color(0xFFF4FAF7),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF06150F) : const Color(0xFFF4FAF7),
        elevation: 0,
        centerTitle: false,
        titleSpacing: 20,
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF00D09E), Color(0xFF34D399)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: const Text(
            'Báo cáo Tài chính',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: Colors.white,
              fontSize: 22,
              letterSpacing: -0.5,
            ),
          ),
        ),
      ),
      body: FutureBuilder<List<TransactionEntity>>(
        future: transactionsAsync.getAll(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF00D09E)));
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Lỗi: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final list = snapshot.data ?? [];
          
          // Apply time period filter & confirmed status filter
          final filtered = list.where((tx) => 
            tx.status == TransactionStatus.confirmed && 
            _isWithinPeriod(tx.transactionDate)
          ).toList();

          final totalIncome = filtered
              .where((tx) => tx.type == TransactionType.income)
              .map((tx) => tx.amount)
              .fold(0, (sum, val) => sum + val);

          final totalExpense = filtered
              .where((tx) => tx.type == TransactionType.expense)
              .map((tx) => tx.amount)
              .fold(0, (sum, val) => sum + val);

          final netBalance = totalIncome - totalExpense;
          final double totalSum = (totalIncome + totalExpense).toDouble();
          
          final double incomeRatio = totalSum > 0 ? totalIncome / totalSum : 0.5;
          final double expenseRatio = totalSum > 0 ? totalExpense / totalSum : 0.5;
          final double savingRate = totalIncome > 0 ? (netBalance / totalIncome) * 100 : 0.0;

          return Column(
            children: [
              // Period Filter Tabs
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0D251C) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? const Color(0xFF1E3A2F) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: [
                      _buildPeriodTab('all', 'Tất cả'),
                      _buildPeriodTab('today', 'Hôm nay'),
                      _buildPeriodTab('month', 'Tháng này'),
                      _buildPeriodTab('year', 'Năm nay'),
                    ],
                  ),
                ),
              ),
              
              // Report content
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  children: [
                    if (totalSum > 0) ...[
                      // Modern Chart Card
                      Container(
                        padding: const EdgeInsets.all(20),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cơ cấu dòng tiền',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isDark ? Colors.white : const Color(0xFF093021),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                // Custom Donut Chart on Left
                                SizedBox(
                                  width: 110,
                                  height: 110,
                                  child: Stack(
                                    children: [
                                      CustomPaint(
                                        size: const Size(110, 110),
                                        painter: FinancialRatioPainter(
                                          incomeRatio: incomeRatio,
                                          expenseRatio: expenseRatio,
                                          isDark: isDark,
                                        ),
                                      ),
                                      Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              savingRate >= 0 ? 'Thặng dư' : 'Thâm hụt',
                                              style: TextStyle(
                                                fontSize: 9,
                                                color: isDark ? Colors.white60 : Colors.black45,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${savingRate.abs().toStringAsFixed(0)}%',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: savingRate >= 0 ? const Color(0xFF00D09E) : const Color(0xFFEF4444),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 24),
                                // Legend on Right
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildLegendItem(
                                        label: 'Doanh thu',
                                        percentage: '${(incomeRatio * 100).toStringAsFixed(0)}%',
                                        value: currencyFormatter.format(totalIncome),
                                        color: const Color(0xFF00D09E),
                                        isDark: isDark,
                                      ),
                                      const SizedBox(height: 14),
                                      _buildLegendItem(
                                        label: 'Chi phí',
                                        percentage: '${(expenseRatio * 100).toStringAsFixed(0)}%',
                                        value: currencyFormatter.format(totalExpense),
                                        color: const Color(0xFFEF4444),
                                        isDark: isDark,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ] else ...[
                      // Empty state for selected filter
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0D251C) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark ? const Color(0xFF1E3A2F) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 48,
                              color: isDark ? Colors.white24 : Colors.black12,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Không có giao dịch nào trong khoảng thời gian này.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isDark ? Colors.white38 : Colors.black45,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Reports Cards list
                    if (showIncome) ...[
                      _buildReportCard(
                        context,
                        title: 'Báo cáo Doanh thu',
                        subtitle: 'Chi tiết các khoản thu nhập bán hàng, dịch vụ...',
                        amount: totalIncome,
                        color: const Color(0xFF00D09E),
                        isDark: isDark,
                        onTap: () {
                          context.go('/reports/detail?type=income');
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (showExpense) ...[
                      _buildReportCard(
                        context,
                        title: 'Báo cáo Chi phí',
                        subtitle: 'Theo dõi chi phí lương, mặt bằng, marketing...',
                        amount: totalExpense,
                        color: const Color(0xFFEF4444),
                        isDark: isDark,
                        onTap: () {
                          context.go('/reports/detail?type=expense');
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (currentRole == UserRole.financeManager) ...[
                      // Net cash flow card
                      Container(
                        padding: const EdgeInsets.all(20),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dòng tiền thuần doanh nghiệp',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isDark ? Colors.white : const Color(0xFF093021),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              currencyFormatter.format(netBalance),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                                color: netBalance >= 0 ? const Color(0xFF00D09E) : const Color(0xFFEF4444),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Divider(color: isDark ? const Color(0xFF1E3A2F) : const Color(0xFFE2E8F0)),
                            const SizedBox(height: 12),
                            ScaleOnTap(
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Đang tạo báo cáo PDF tổng hợp...'),
                                    backgroundColor: Color(0xFF00D09E),
                                  ),
                                );
                              },
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00D09E),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Xuất báo cáo PDF',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPeriodTab(String period, String label) {
    final isSelected = _selectedPeriod == period;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedPeriod = period;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected 
                ? (isDark ? const Color(0xFF00D09E) : const Color(0xFF00D09E)) 
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected 
                  ? Colors.white 
                  : (isDark ? Colors.white60 : Colors.black54),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem({
    required String label,
    required String percentage,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white60 : Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Text(
              percentage,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF093021),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReportCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required int amount,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);

    return ScaleOnTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
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
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold, 
                      fontSize: 17,
                      color: isDark ? Colors.white : const Color(0xFF093021),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    currencyFormatter.format(amount),
                    style: TextStyle(
                      fontWeight: FontWeight.bold, 
                      fontSize: 20, 
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              Icons.arrow_forward_ios_rounded, 
              size: 16,
              color: isDark ? Colors.white30 : Colors.black38,
            ),
          ],
        ),
      ),
    );
  }
}

class FinancialRatioPainter extends CustomPainter {
  final double incomeRatio;
  final double expenseRatio;
  final bool isDark;

  FinancialRatioPainter({
    required this.incomeRatio,
    required this.expenseRatio,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const strokeWidth = 10.0;

    final basePaint = Paint()
      ..color = isDark ? const Color(0xFF1E3A2F) : const Color(0xFFEDF2F7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, basePaint);

    if (incomeRatio + expenseRatio == 0) return;

    const double startAngle = -3.14159 / 2; // Start at top
    final double incomeSweep = incomeRatio * 2 * 3.14159;
    final double expenseSweep = expenseRatio * 2 * 3.14159;

    // Draw Income (Teal/Green)
    final incomePaint = Paint()
      ..color = const Color(0xFF00D09E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    if (incomeRatio > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        incomeSweep - (expenseRatio > 0 ? 0.12 : 0),
        false,
        incomePaint,
      );
    }

    // Draw Expense (Red)
    final expensePaint = Paint()
      ..color = const Color(0xFFEF4444)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    if (expenseRatio > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle + incomeSweep + (incomeRatio > 0 ? 0.06 : 0),
        expenseSweep - (incomeRatio > 0 ? 0.12 : 0),
        false,
        expensePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
