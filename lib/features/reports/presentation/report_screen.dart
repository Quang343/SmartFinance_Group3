import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/role_provider.dart';
import '../../../core/providers/app_providers.dart';
import '../../../domain/entities/transaction_entity.dart';
import '../../../domain/entities/category_entity.dart';
import '../../../core/widgets/scale_on_tap.dart';

class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key});

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  String _selectedPeriod = 'all'; // 'all', 'today', 'month', 'year', 'custom'
  DateTimeRange? _customDateRange;

  bool _isWithinPeriod(DateTime date) {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'today':
        return date.year == now.year && date.month == now.month && date.day == now.day;
      case 'month':
        return date.year == now.year && date.month == now.month;
      case 'year':
        return date.year == now.year;
      case 'custom':
        if (_customDateRange == null) return true;
        final start = DateTime(_customDateRange!.start.year, _customDateRange!.start.month, _customDateRange!.start.day);
        final end = DateTime(_customDateRange!.end.year, _customDateRange!.end.month, _customDateRange!.end.day, 23, 59, 59);
        return date.isAfter(start.subtract(const Duration(seconds: 1))) && date.isBefore(end.add(const Duration(seconds: 1)));
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
      body: FutureBuilder<List<dynamic>>(
        future: Future.wait([
          transactionsAsync.getAll(),
          ref.read(categoryRepositoryProvider).getAll(),
        ]),
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

          final list = snapshot.data![0] as List<TransactionEntity>;
          final categories = snapshot.data![1] as List<CategoryEntity>;
          final catMap = {for (var c in categories) c.id: c};
          
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

          // Calculate itemized sums based on transaction notes (with category fallback)
          final Map<String, double> categorySums = {};
          if (currentRole == UserRole.expenseAccountant) {
            final expenses = filtered.where((tx) => tx.type == TransactionType.expense);
            for (var tx in expenses) {
              final cat = catMap[tx.categoryId];
              final label = (tx.note != null && tx.note!.trim().isNotEmpty)
                  ? tx.note!.trim()
                  : (cat?.name ?? 'Khác');
              categorySums[label] = (categorySums[label] ?? 0.0) + tx.amount;
            }
          } else if (currentRole == UserRole.revenueAccountant) {
            final incomes = filtered.where((tx) => tx.type == TransactionType.income);
            for (var tx in incomes) {
              final cat = catMap[tx.categoryId];
              final label = (tx.note != null && tx.note!.trim().isNotEmpty)
                  ? tx.note!.trim()
                  : (cat?.name ?? 'Khác');
              categorySums[label] = (categorySums[label] ?? 0.0) + tx.amount;
            }
          }

          final sortedCategories = categorySums.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          final double roleTotal = currentRole == UserRole.expenseAccountant 
              ? totalExpense.toDouble() 
              : totalIncome.toDouble();

          final List<MapEntry<String, double>> displayCategories = [];
          double otherSum = 0.0;
          for (int i = 0; i < sortedCategories.length; i++) {
            if (i < 3) {
              displayCategories.add(sortedCategories[i]);
            } else {
              otherSum += sortedCategories[i].value;
            }
          }
          if (otherSum > 0) {
            displayCategories.add(MapEntry('Khác', otherSum));
          }

          final bool hasData = currentRole == UserRole.financeManager 
              ? (totalIncome + totalExpense > 0)
              : currentRole == UserRole.expenseAccountant 
                  ? (totalExpense > 0)
                  : (totalIncome > 0);

          // Get chart colors and segments
          final List<double> segmentRatios = [];
          final List<Color> segmentColors = [];
          
          final List<Color> expenseColors = [
            const Color(0xFFEF4444),
            const Color(0xFFF97316),
            const Color(0xFFF59E0B),
            const Color(0xFFEC4899),
            const Color(0xFF8B5CF6),
          ];
          
          final List<Color> incomeColors = [
            const Color(0xFF00D09E),
            const Color(0xFF3B82F6),
            const Color(0xFF06B6D4),
            const Color(0xFF8B5CF6),
            const Color(0xFF10B981),
          ];

          if (currentRole == UserRole.financeManager) {
            segmentRatios.add(totalIncome.toDouble());
            segmentRatios.add(totalExpense.toDouble());
            segmentColors.add(const Color(0xFF00D09E));
            segmentColors.add(const Color(0xFFEF4444));
          } else if (currentRole == UserRole.expenseAccountant) {
            for (int i = 0; i < displayCategories.length; i++) {
              segmentRatios.add(displayCategories[i].value);
              segmentColors.add(expenseColors[i % expenseColors.length]);
            }
          } else {
            for (int i = 0; i < displayCategories.length; i++) {
              segmentRatios.add(displayCategories[i].value);
              segmentColors.add(incomeColors[i % incomeColors.length]);
            }
          }

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
                      Container(
                        height: 20,
                        width: 1,
                        color: isDark ? Colors.white12 : Colors.black.withOpacity(0.08),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                      GestureDetector(
                        onTap: () async {
                          final picked = await showDateRangePicker(
                            context: context,
                            locale: const Locale('vi', 'VN'),
                            initialDateRange: _customDateRange ?? DateTimeRange(
                              start: DateTime.now().subtract(const Duration(days: 7)),
                              end: DateTime.now(),
                            ),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                            builder: (context, child) {
                              const primaryColor = Color(0xFF00D09E);
                              return Theme(
                                data: ThemeData(
                                  useMaterial3: true,
                                  brightness: isDark ? Brightness.dark : Brightness.light,
                                  colorScheme: isDark
                                      ? const ColorScheme.dark(
                                          primary: primaryColor,
                                          onPrimary: Colors.white,
                                          surface: Color(0xFF0D251C),
                                          onSurface: Colors.white,
                                        )
                                      : const ColorScheme.light(
                                          primary: primaryColor,
                                          onPrimary: Colors.white,
                                          surface: Colors.white,
                                          onSurface: Color(0xFF1E293B),
                                        ),
                                  appBarTheme: AppBarTheme(
                                    backgroundColor: isDark ? const Color(0xFF0C2C1F) : primaryColor,
                                    foregroundColor: Colors.white,
                                    iconTheme: const IconThemeData(color: Colors.white),
                                    actionsIconTheme: const IconThemeData(color: Colors.white),
                                    titleTextStyle: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                    toolbarTextStyle: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                  textButtonTheme: TextButtonThemeData(
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                  ),
                                  datePickerTheme: DatePickerThemeData(
                                    headerBackgroundColor: isDark ? const Color(0xFF0C2C1F) : primaryColor,
                                    headerForegroundColor: Colors.white,
                                    backgroundColor: isDark ? const Color(0xFF0D251C) : Colors.white,
                                    headerHeadlineStyle: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                    headerHelpStyle: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            setState(() {
                              _customDateRange = picked;
                              _selectedPeriod = 'custom';
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: _selectedPeriod == 'custom' ? const Color(0xFF00D09E) : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.calendar_today_rounded,
                            size: 16,
                            color: _selectedPeriod == 'custom' 
                                ? Colors.white 
                                : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Report content
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  children: [
                    if (hasData) ...[
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
                              currentRole == UserRole.financeManager 
                                  ? 'Cơ cấu dòng tiền'
                                  : currentRole == UserRole.expenseAccountant
                                      ? 'Cơ cấu chi phí'
                                      : 'Cơ cấu doanh thu',
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
                                        painter: MultiSegmentDonutPainter(
                                          ratios: segmentRatios,
                                          colors: segmentColors,
                                          isDark: isDark,
                                        ),
                                      ),
                                      Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            if (currentRole == UserRole.financeManager) ...[
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
                                            ] else if (currentRole == UserRole.expenseAccountant) ...[
                                              const Icon(
                                                Icons.arrow_upward_rounded,
                                                color: Color(0xFFEF4444),
                                                size: 20,
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'Chi phí',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: isDark ? Colors.white : const Color(0xFF093021),
                                                ),
                                              ),
                                            ] else ...[
                                              const Icon(
                                                Icons.arrow_downward_rounded,
                                                color: Color(0xFF00D09E),
                                                size: 20,
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'Doanh thu',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: isDark ? Colors.white : const Color(0xFF093021),
                                                ),
                                              ),
                                            ],
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
                                      if (currentRole == UserRole.financeManager) ...[
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
                                      ] else ...[
                                        for (int i = 0; i < displayCategories.length; i++) ...[
                                          if (i > 0) const SizedBox(height: 10),
                                          _buildLegendItem(
                                            label: displayCategories[i].key,
                                            percentage: '${(displayCategories[i].value / roleTotal * 100).toStringAsFixed(0)}%',
                                            value: currencyFormatter.format(displayCategories[i].value),
                                            color: segmentColors[i],
                                            isDark: isDark,
                                          ),
                                        ],
                                      ],
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
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white60 : Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
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

class MultiSegmentDonutPainter extends CustomPainter {
  final List<double> ratios;
  final List<Color> colors;
  final bool isDark;

  MultiSegmentDonutPainter({
    required this.ratios,
    required this.colors,
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

    final double sum = ratios.fold(0, (s, r) => s + r);
    if (sum == 0) return;

    double startAngle = -3.14159 / 2;
    for (int i = 0; i < ratios.length; i++) {
      if (ratios[i] <= 0) continue;
      final sweepAngle = (ratios[i] / sum) * 2 * 3.14159;
      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle - 0.08,
        false,
        paint,
      );
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
