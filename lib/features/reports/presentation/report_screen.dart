import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/providers/role_provider.dart';
import '../../../core/providers/app_providers.dart';
import '../../../domain/entities/transaction_entity.dart';
import '../../../domain/entities/category_entity.dart';
import '../../../core/widgets/scale_on_tap.dart';
import '../utils/report_pdf_generator.dart';

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

  String _periodLabel() {
    switch (_selectedPeriod) {
      case 'today':
        return 'Hôm nay';
      case 'month':
        return 'Tháng này';
      case 'year':
        return 'Năm nay';
      case 'custom':
        return 'Tùy chỉnh';
      case 'all':
      default:
        return 'Tất cả';
    }
  }

  void _showCashFlowDetail(
    BuildContext context,
    String type,
    List<TransactionEntity> txs,
    List<CategoryEntity> allCats,
    bool isDark,
    NumberFormat fmt,
  ) {
    final catMap = {for (var c in allCats) c.id: c};
    final filtered = type == 'net'
        ? List<TransactionEntity>.from(txs)
        : txs.where((tx) => tx.type == (type == 'income' ? TransactionType.income : TransactionType.expense)).toList();
    filtered.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));

    final total = filtered.fold<int>(0, (s, tx) => s + tx.amount);
    final title = type == 'net' ? 'Dòng tiền thuần' : type == 'income' ? 'Tổng thu' : 'Tổng chi';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.7,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0C2C1F) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isDark ? Colors.white : const Color(0xFF1E293B))),
                        const SizedBox(height: 2),
                        Text('${fmt.format(total)} • ${filtered.length} giao dịch', style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.grey)),
                      ],
                    ),
                  ),
                  ScaleOnTap(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.grey.shade100, shape: BoxShape.circle),
                      child: const Icon(Icons.close_rounded, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? Center(child: Text('Không có giao dịch nào', style: TextStyle(color: isDark ? Colors.white38 : Colors.grey)))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final tx = filtered[i];
                        final isInc = tx.type == TransactionType.income;
                        final cat = catMap[tx.categoryId];
                        return ScaleOnTap(
                          onTap: () => context.push('/transactions/form', extra: {'transactionId': tx.id, 'readOnly': true}),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF06150F) : const Color(0xFFF4FAF7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: (isInc ? const Color(0xFF00D09E) : const Color(0xFFEF4444)).withOpacity(0.15),
                                  child: Icon(isInc ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                                      color: isInc ? const Color(0xFF00D09E) : const Color(0xFFEF4444), size: 16),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        cat?.name ?? 'Chưa phân loại',
                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF1E293B)),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        DateFormat('dd/MM/yyyy').format(tx.transactionDate),
                                        style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${isInc ? '+' : '-'}${fmt.format(tx.amount)}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isInc ? const Color(0xFF00D09E) : const Color(0xFFEF4444),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
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

          // Calculate itemized sums based on categories
          final Map<String, double> incomeCategorySums = {};
          final Map<String, double> expenseCategorySums = {};
          
          final incomes = filtered.where((tx) => tx.type == TransactionType.income);
          for (var tx in incomes) {
            final cat = catMap[tx.categoryId];
            final label = cat?.name ?? 'Chưa phân loại';
            incomeCategorySums[label] = (incomeCategorySums[label] ?? 0.0) + tx.amount;
          }
          
          final expenses = filtered.where((tx) => tx.type == TransactionType.expense);
          for (var tx in expenses) {
            final cat = catMap[tx.categoryId];
            final label = cat?.name ?? 'Chưa phân loại';
            expenseCategorySums[label] = (expenseCategorySums[label] ?? 0.0) + tx.amount;
          }

          final sortedIncomeCategories = incomeCategorySums.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
          final sortedExpenseCategories = expenseCategorySums.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

          // Retain `categorySums` for existing logic of accountants
          final Map<String, double> categorySums = currentRole == UserRole.expenseAccountant 
              ? expenseCategorySums 
              : incomeCategorySums;

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
            displayCategories.add(MapEntry('Các mục khác', otherSum));
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
                                          percentage: incomeRatio * 100 < 1 && incomeRatio > 0 ? '<1%' : '${(incomeRatio * 100).toStringAsFixed(1).replaceAll('.0', '')}%',
                                          value: currencyFormatter.format(totalIncome),
                                          color: const Color(0xFF00D09E),
                                          isDark: isDark,
                                        ),
                                        const SizedBox(height: 14),
                                        _buildLegendItem(
                                          label: 'Chi phí',
                                          percentage: expenseRatio * 100 < 1 && expenseRatio > 0 ? '<1%' : '${(expenseRatio * 100).toStringAsFixed(1).replaceAll('.0', '')}%',
                                          value: currencyFormatter.format(totalExpense),
                                          color: const Color(0xFFEF4444),
                                          isDark: isDark,
                                        ),
                                      ] else ...[
                                        for (int i = 0; i < displayCategories.length; i++) ...[
                                          if (i > 0) const SizedBox(height: 10),
                                          _buildLegendItem(
                                            label: displayCategories[i].key,
                                            percentage: (displayCategories[i].value / roleTotal * 100) > 0 && (displayCategories[i].value / roleTotal * 100) < 1 
                                                ? '<1%' 
                                                : '${(displayCategories[i].value / roleTotal * 100).toStringAsFixed(1).replaceAll('.0', '')}%',
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
                          String url = '/reports/detail?type=income&period=$_selectedPeriod';
                          if (_selectedPeriod == 'custom' && _customDateRange != null) {
                            url += '&startDate=${_customDateRange!.start.toIso8601String()}&endDate=${_customDateRange!.end.toIso8601String()}';
                          }
                          context.go(url);
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
                          String url = '/reports/detail?type=expense&period=$_selectedPeriod';
                          if (_selectedPeriod == 'custom' && _customDateRange != null) {
                            url += '&startDate=${_customDateRange!.start.toIso8601String()}&endDate=${_customDateRange!.end.toIso8601String()}';
                          }
                          context.go(url);
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (currentRole == UserRole.financeManager) ...[
                      // Admin Detailed Metrics
                      _buildAdminDetailedMetrics(
                        totalIncome: totalIncome.toDouble(),
                        totalExpense: totalExpense.toDouble(),
                        netBalance: netBalance.toDouble(),
                        txCount: filtered.length,
                        sortedIncomeCats: sortedIncomeCategories,
                        sortedExpenseCats: sortedExpenseCategories,
                        transactions: filtered,
                        period: _selectedPeriod,
                        isDark: isDark,
                        fmt: currencyFormatter,
                      ),
                      const SizedBox(height: 16),

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
                            ScaleOnTap(
                              onTap: () => _showCashFlowDetail(context, 'net', filtered, categories, isDark, currencyFormatter),
                              child: Container(
                                width: double.infinity,
                                color: Colors.transparent,
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
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Divider(color: isDark ? const Color(0xFF1E3A2F) : const Color(0xFFE2E8F0)),
                            const SizedBox(height: 12),
                            ScaleOnTap(
                              onTap: () async {
                                try {
                                  final doc = await ReportPdfGenerator.buildReportPdf(
                                    totalIncome: totalIncome,
                                    totalExpense: totalExpense,
                                    netBalance: netBalance,
                                    incomeCategories: sortedIncomeCategories,
                                    expenseCategories: sortedExpenseCategories,
                                    transactionCount: filtered.length,
                                    periodLabel: _periodLabel(),
                                  );
                                  final bytes = await doc.save();
                                  await Printing.sharePdf(
                                    bytes: bytes,
                                    filename: 'BaoCaoTaiChinh_$_selectedPeriod.pdf',
                                  );
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Xuất PDF thất bại: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
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

  Widget _buildAdminDetailedMetrics({
    required double totalIncome,
    required double totalExpense,
    required double netBalance,
    required int txCount,
    required List<MapEntry<String, double>> sortedIncomeCats,
    required List<MapEntry<String, double>> sortedExpenseCats,
    required List<TransactionEntity> transactions,
    required String period,
    required bool isDark,
    required NumberFormat fmt,
  }) {
    final profitMargin = totalIncome > 0 ? (netBalance / totalIncome) * 100 : 0.0;
    final expenseRatio = totalIncome > 0 ? (totalExpense / totalIncome) * 100 : 0.0;
    final avgPerTx = txCount > 0 ? (totalIncome + totalExpense) / txCount : 0.0;

    // Trend calculation
    final Map<int, double> incomeByGroup = {};
    final Map<int, double> expenseByGroup = {};

    for (var tx in transactions) {
      final int key = period == 'year' ? tx.transactionDate.month : tx.transactionDate.day;

      if (tx.type == TransactionType.income) {
        incomeByGroup[key] = (incomeByGroup[key] ?? 0) + tx.amount.toDouble();
      } else {
        expenseByGroup[key] = (expenseByGroup[key] ?? 0) + tx.amount.toDouble();
      }
    }

    List<FlSpot> incomeSpots = [];
    List<FlSpot> expenseSpots = [];
    double maxVal = 1000;
    
    final keys = {...incomeByGroup.keys, ...expenseByGroup.keys}.toList()..sort();
    if (keys.isNotEmpty) {
      for (var k in keys) {
        final inc = incomeByGroup[k] ?? 0.0;
        final exp = expenseByGroup[k] ?? 0.0;
        if (inc > maxVal) maxVal = inc;
        if (exp > maxVal) maxVal = exp;
        incomeSpots.add(FlSpot(k.toDouble(), inc));
        expenseSpots.add(FlSpot(k.toDouble(), exp));
      }
    } else {
      incomeSpots = [const FlSpot(0, 0)];
      expenseSpots = [const FlSpot(0, 0)];
    }

    Widget _buildTrendChart() {
      return Container(
        height: 220,
        margin: const EdgeInsets.only(top: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0D251C) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? const Color(0xFF1E3A2F) : const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Biểu đồ xu hướng Thu / Chi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : Colors.black87)),
                ),
                Icon(Icons.circle, size: 10, color: const Color(0xFF00D09E)),
                const SizedBox(width: 4),
                Text('Thu', style: TextStyle(fontSize: 10, color: isDark ? Colors.white70 : Colors.black54)),
                const SizedBox(width: 12),
                Icon(Icons.circle, size: 10, color: const Color(0xFFEF4444)),
                const SizedBox(width: 4),
                Text('Chi', style: TextStyle(fontSize: 10, color: isDark ? Colors.white70 : Colors.black54)),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: maxVal * 1.2,
                  gridData: FlGridData(
                    show: true, 
                    drawVerticalLine: false, 
                    getDrawingHorizontalLine: (v) => FlLine(color: isDark ? Colors.white10 : Colors.black12, strokeWidth: 1)
                  ),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        getTitlesWidget: (val, meta) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(val.toInt().toString(), style: TextStyle(fontSize: 10, color: isDark ? Colors.white54 : Colors.black54)),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (val, meta) {
                          if (val == 0) return const SizedBox.shrink();
                          return Text(NumberFormat.compactCurrency(locale: 'vi_VN', symbol: '').format(val), style: TextStyle(fontSize: 10, color: isDark ? Colors.white54 : Colors.black54));
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: incomeSpots,
                      isCurved: true,
                      color: const Color(0xFF00D09E),
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(show: true, color: const Color(0xFF00D09E).withValues(alpha: 0.1)),
                    ),
                    LineChartBarData(
                      spots: expenseSpots,
                      isCurved: true,
                      color: const Color(0xFFEF4444),
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(show: true, color: const Color(0xFFEF4444).withValues(alpha: 0.1)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    Widget _buildStatBox(String title, String value, Color color, IconData icon) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0D251C) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? const Color(0xFF1E3A2F) : const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 14, color: color),
                  const SizedBox(width: 4),
                  Expanded(child: Text(title, style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : Colors.black54))),
                ],
              ),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
              ),
            ],
          ),
        ),
      );
    }

    Widget _buildCatList(String title, List<MapEntry<String, double>> cats, Color color, double total) {
      if (cats.isEmpty) return const SizedBox.shrink();
      return Container(
        margin: const EdgeInsets.only(top: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0D251C) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? const Color(0xFF1E3A2F) : const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : Colors.black87)),
            const SizedBox(height: 12),
            ...cats.take(3).map((e) {
              final pct = total > 0 ? (e.value / total) * 100 : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(e.key, style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(fmt.format(e.value), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: pct / 100,
                            backgroundColor: color.withValues(alpha: 0.1),
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                            minHeight: 4,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildStatBox('Biên lợi nhuận', '${profitMargin.toStringAsFixed(1)}%', profitMargin >= 0 ? const Color(0xFF00D09E) : const Color(0xFFEF4444), Icons.show_chart_rounded),
            const SizedBox(width: 8),
            _buildStatBox('Tỷ lệ chi / thu', '${expenseRatio.toStringAsFixed(1)}%', const Color(0xFFF59E0B), Icons.pie_chart_outline_rounded),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildStatBox('Tổng số giao dịch', txCount.toString(), Colors.blue, Icons.receipt_long_rounded),
            const SizedBox(width: 8),
            _buildStatBox('Trung bình / GD', fmt.format(avgPerTx), const Color(0xFF8B5CF6), Icons.calculate_outlined),
          ],
        ),
        _buildTrendChart(),
        _buildCatList('Cơ cấu nguồn thu (Top 3)', sortedIncomeCats, const Color(0xFF00D09E), totalIncome),
        _buildCatList('Cơ cấu khoản chi (Top 3)', sortedExpenseCats, const Color(0xFFEF4444), totalExpense),
      ],
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
