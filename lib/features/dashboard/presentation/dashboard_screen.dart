import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/providers/role_provider.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../domain/entities/transaction_entity.dart';
import '../../../domain/entities/category_entity.dart';
import '../../../data/models/user_model.dart';
import '../../../core/providers/transaction_providers.dart';
import '../../../core/providers/category_providers.dart';
import '../../../core/widgets/scale_on_tap.dart';
import '../../../core/services/offline_sync_service.dart';
import 'widgets/dashboard_charts.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String _timeFilter = 'monthly';
  DateTimeRange? _customDateRange;

  @override
  void initState() {
    super.initState();
    // Kích hoạt đồng bộ ngoại tuyến (Background Sync) cho ảnh hóa đơn bị kẹt
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(currentUserProvider);
      if (user != null) {
        ref.read(offlineSyncServiceProvider).syncOfflineImages(user.company);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentRole = ref.watch(roleProvider);
    final currentUser = ref.watch(currentUserProvider);
    final company = currentUser?.company ?? '';
    final budgetLimitAsync = ref.watch(companyBudgetLimitProvider);
    final revenueKpiAsync = ref.watch(companyRevenueKpiProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
    );
    final timeFormatter = DateFormat('HH:mm');
    final dateFormatter = DateFormat('dd/MM');
    final isDesktop = MediaQuery.sizeOf(context).width >= 800;

    final transactionsAsync = currentRole == UserRole.expenseAccountant
        ? ref.watch(expenseTransactionsProvider)
        : currentRole == UserRole.revenueAccountant
        ? ref.watch(incomeTransactionsProvider)
        : ref.watch(allTransactionsProvider);

    final categoriesAsync = ref.watch(allCategoriesProvider);

    if (transactionsAsync.isLoading ||
        categoriesAsync.isLoading ||
        budgetLimitAsync.isLoading ||
        revenueKpiAsync.isLoading) {
      return Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF06150F)
            : const Color(0xFFF4FAF7),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SpinKitWaveSpinner(
                color: const Color(0xFF00D09E),
                size: 100,
                trackColor: const Color(0xFF00D09E).withValues(alpha: 0.2),
                waveColor: const Color(0xFF00D09E).withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Đang tải dữ liệu...',
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (transactionsAsync.hasError) {
      return Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF06150F)
            : const Color(0xFFF4FAF7),
        body: Center(
          child: Text(
            'Lỗi tải dữ liệu giao dịch: ${transactionsAsync.error}',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    final allTxs = transactionsAsync.value ?? [];
    final allCats = categoriesAsync.value ?? [];

    // Create a quick lookup map for categories
    final catMap = {for (var c in allCats) c.id: c};

    // Filter by status (Confirmed only)
    var filteredTxs = allTxs
        .where((tx) => tx.status == TransactionStatus.confirmed)
        .toList();

    // Note: No need to filter by role again because the Provider already did it!

    // Apply selected time filter (Daily, Weekly, Monthly, All)
    final now = DateTime.now();
    filteredTxs = filteredTxs.where((tx) {
      if (_timeFilter == 'all') {
        return true;
      } else if (_timeFilter == 'daily') {
        return tx.transactionDate.year == now.year &&
            tx.transactionDate.month == now.month &&
            tx.transactionDate.day == now.day;
      } else if (_timeFilter == 'yearly') {
        return tx.transactionDate.year == now.year;
      } else if (_timeFilter == 'custom') {
        if (_customDateRange == null) return true;
        final start = DateTime(
          _customDateRange!.start.year,
          _customDateRange!.start.month,
          _customDateRange!.start.day,
        );
        final end = DateTime(
          _customDateRange!.end.year,
          _customDateRange!.end.month,
          _customDateRange!.end.day,
          23,
          59,
          59,
        );
        return tx.transactionDate.isAfter(
              start.subtract(const Duration(seconds: 1)),
            ) &&
            tx.transactionDate.isBefore(end.add(const Duration(seconds: 1)));
      } else {
        // Monthly (Calendar month)
        return tx.transactionDate.month == now.month &&
            tx.transactionDate.year == now.year;
      }
    }).toList();

    filteredTxs.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));

    // Calculations for balance and stats
    final incomeSum = filteredTxs
        .where((tx) => tx.type == TransactionType.income)
        .map((tx) => tx.amount)
        .fold(0, (sum, val) => sum + val);

    final expenseSum = filteredTxs
        .where((tx) => tx.type == TransactionType.expense)
        .map((tx) => tx.amount)
        .fold(0, (sum, val) => sum + val);

    final totalBalance = incomeSum - expenseSum;

    // Budget Analysis calculations (Always Monthly)
    final monthlyExpenseSum = allTxs
        .where(
          (tx) =>
              tx.status == TransactionStatus.confirmed &&
              tx.type == TransactionType.expense &&
              tx.transactionDate.month == now.month &&
              tx.transactionDate.year == now.year,
        )
        .map((tx) => tx.amount)
        .fold(0, (sum, val) => sum + val);

    final monthlyIncomeSum = allTxs
        .where(
          (tx) =>
              tx.status == TransactionStatus.confirmed &&
              tx.type == TransactionType.income &&
              tx.transactionDate.month == now.month &&
              tx.transactionDate.year == now.year,
        )
        .map((tx) => tx.amount)
        .fold(0, (sum, val) => sum + val);

    final double budgetLimit = (budgetLimitAsync.valueOrNull ?? 20000000)
        .toDouble();
    final double revenueKPI = (revenueKpiAsync.valueOrNull ?? 500000000)
        .toDouble();

    final double expensePercentage = monthlyExpenseSum / budgetLimit;
    final int expensePercentInt = (expensePercentage * 100).toInt();

    final double incomePercentage = monthlyIncomeSum / revenueKPI;
    final int incomePercentInt = (incomePercentage * 100).toInt();

    // Budget Insights
    final double remainingBudget = (budgetLimit - monthlyExpenseSum).toDouble();

    String highestExpenseCatName = 'chưa có dữ liệu';
    double highestExpenseAmount = 0;
    final expenseTxs = filteredTxs.where(
      (tx) => tx.type == TransactionType.expense,
    );
    if (expenseTxs.isNotEmpty) {
      final Map<String, double> catExpenses = {};
      for (var tx in expenseTxs) {
        catExpenses[tx.categoryId] =
            (catExpenses[tx.categoryId] ?? 0) + tx.amount;
      }
      final highestCatId = catExpenses.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
      highestExpenseAmount = catExpenses[highestCatId]!;
      highestExpenseCatName = (catMap[highestCatId]?.name ?? 'khác')
          .toLowerCase();
    }

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF06150F)
          : const Color(0xFFF4FAF7),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Top custom Teal/Mint header
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.only(
                top: 60,
                left: 24,
                right: 24,
                bottom: 20,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF00D09E), Color(0xFF00B78A)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Chào mừng trở lại',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(
                                  0xFF1E293B,
                                ), // Professional dark slate/black
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: currentRole.nameVi,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(
                                        0xFF064E3B,
                                      ), // Dark green highlight for readability on green background
                                    ),
                                  ),
                                  const TextSpan(
                                    text: ' • Buổi sáng tốt lành',
                                    style: TextStyle(
                                      color: Color(
                                        0xFF334155,
                                      ), // Muted dark slate
                                    ),
                                  ),
                                ],
                              ),
                              style: const TextStyle(
                                fontSize: 13,
                                overflow: TextOverflow.ellipsis,
                              ),
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      ScaleOnTap(
                        onTap: () => context.push('/notifications'),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.notifications_none_rounded,
                            color: Color(0xFF00A37B),
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0D281E)
                          : const Color(0xFFE6F4F0),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (currentRole == UserRole.financeManager) ...[
                          _buildHeaderFilter(),
                          const SizedBox(height: 12),
                          // Dòng tiền thuần (Net Cash Flow)
                          Text(
                            'DÒNG TIỀN THUẦN (Net Cash Flow)',
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark ? Colors.white70 : Colors.black87,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          ScaleOnTap(
                            onTap: () => _showCashFlowDetail(
                              context,
                              'net',
                              filteredTxs,
                              allCats,
                              isDark,
                              currencyFormatter,
                            ),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF0D281E)
                                    : const Color(0xFFE6F4F0),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: isDesktop
                                    ? Alignment.centerLeft
                                    : Alignment.center,
                                child: Text(
                                  currencyFormatter.format(totalBalance),
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: totalBalance >= 0
                                        ? (isDark
                                              ? const Color(0xFF86EFAC)
                                              : const Color(0xFF008060))
                                        : (isDark
                                              ? const Color(0xFFFCA5A5)
                                              : const Color(0xFFD32F2F)),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Divider(
                            color: isDark
                                ? Colors.white12
                                : Colors.black.withOpacity(0.08),
                            height: 1,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: ScaleOnTap(
                                  onTap: () => _showCashFlowDetail(
                                    context,
                                    'income',
                                    filteredTxs,
                                    allCats,
                                    isDark,
                                    currencyFormatter,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? const Color(0xFF0D281E)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.arrow_upward_rounded,
                                              size: 14,
                                              color: isDark
                                                  ? const Color(0xFF86EFAC)
                                                  : const Color(0xFF008060),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Tổng thu',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: isDark
                                                    ? Colors.white
                                                    : Colors.black,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            currencyFormatter.format(incomeSum),
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: isDark
                                                  ? const Color(0xFF86EFAC)
                                                  : const Color(0xFF008060),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                height: 28,
                                width: 1,
                                color: isDark
                                    ? Colors.white12
                                    : Colors.black.withOpacity(0.08),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ScaleOnTap(
                                  onTap: () => _showCashFlowDetail(
                                    context,
                                    'expense',
                                    filteredTxs,
                                    allCats,
                                    isDark,
                                    currencyFormatter,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? const Color(0xFF0D281E)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.arrow_downward_rounded,
                                              size: 14,
                                              color: isDark
                                                  ? const Color(0xFFFCA5A5)
                                                  : const Color(0xFFD32F2F),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Tổng chi',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: isDark
                                                    ? Colors.white
                                                    : Colors.black,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            currencyFormatter.format(
                                              expenseSum,
                                            ),
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: isDark
                                                  ? const Color(0xFFFCA5A5)
                                                  : const Color(0xFFD32F2F),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ] else if (currentRole ==
                            UserRole.expenseAccountant) ...[
                          // Tổng chi tiêu
                          Text(
                            _timeFilter == 'daily'
                                ? 'TỔNG CHI TIÊU HÔM NAY'
                                : _timeFilter == 'yearly'
                                ? 'TỔNG CHI TIÊU NĂM NAY'
                                : _timeFilter == 'all'
                                ? 'TỔNG CHI TIÊU TẤT CẢ'
                                : _timeFilter == 'custom'
                                ? 'TỔNG CHI TIÊU TÙY CHỈNH'
                                : 'TỔNG CHI TIÊU HÀNG THÁNG',
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark ? Colors.white70 : Colors.black87,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            width: double.infinity,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: isDesktop
                                  ? Alignment.centerLeft
                                  : Alignment.center,
                              child: Text(
                                currencyFormatter.format(expenseSum),
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? const Color(0xFFFCA5A5)
                                      : const Color(0xFFD32F2F),
                                ),
                              ),
                            ),
                          ),
                        ] else if (currentRole ==
                            UserRole.revenueAccountant) ...[
                          // Tổng doanh thu
                          Text(
                            'TỔNG DOANH THU HÀNG THÁNG',
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark ? Colors.white70 : Colors.black87,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            width: double.infinity,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: isDesktop
                                  ? Alignment.centerLeft
                                  : Alignment.center,
                              child: Text(
                                currencyFormatter.format(incomeSum),
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? const Color(0xFF86EFAC)
                                      : const Color(0xFF008060),
                                ),
                              ),
                            ),
                          ),
                        ],

                        if (currentRole == UserRole.financeManager ||
                            currentRole == UserRole.expenseAccountant) ...[
                          const SizedBox(height: 12),
                          _buildCompactBar(
                            label: 'Ngân sách hàng tháng',
                            percent: expensePercentInt,
                            used: monthlyExpenseSum,
                            target: budgetLimit,
                            remaining: remainingBudget,
                            currencyFormatter: currencyFormatter,
                            isDark: isDark,
                            fillColor: isDark
                                ? const Color(0xFF60A5FA)
                                : const Color(0xFF3B82F6),
                            accentColor: isDark
                                ? const Color(0xFF3B82F6)
                                : const Color(0xFF2563EB),
                            showEdit: currentRole == UserRole.financeManager,
                            onEdit: () => _showEditValueDialog(
                              context,
                              isDark,
                              'Ngân sách hàng tháng',
                              budgetLimitAsync.valueOrNull ?? 20000000,
                              (_) {},
                            ),
                          ),
                        ],
                        if (currentRole == UserRole.financeManager) ...[
                          const SizedBox(height: 12),
                          _buildCompactBar(
                            label: 'KPI hàng tháng',
                            percent: incomePercentInt,
                            used: monthlyIncomeSum,
                            target: revenueKPI,
                            remaining: revenueKPI - monthlyIncomeSum,
                            currencyFormatter: currencyFormatter,
                            isDark: isDark,
                            fillColor: isDark
                                ? const Color(0xFFFBBF24)
                                : const Color(0xFFF59E0B),
                            accentColor: isDark
                                ? const Color(0xFFF59E0B)
                                : const Color(0xFFD97706),
                            showEdit: true,
                            overIsBad: false,
                            onEdit: () => _showEditValueDialog(
                              context,
                              isDark,
                              'KPI hàng tháng',
                              revenueKpiAsync.valueOrNull ?? 500000000,
                              (_) {},
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Rest of body (white/light-green container overlay style)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Quick Action Row / Shortcuts or Charts for Finance Manager
                if (currentRole == UserRole.financeManager)
                  DashboardCharts(
                    allTxs: allTxs,
                    filteredTxs: filteredTxs,
                    allCats: allCats,
                    isDark: isDark,
                    currencyFormatter: currencyFormatter,
                    timeFilter: _timeFilter,
                    customDateRange: _customDateRange,
                  )
                else
                  _buildQuickActions(
                    context,
                    currentRole,
                    isDark,
                    const Color(0xFF00D09E),
                  ),
                if (currentRole != UserRole.financeManager) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0C2C1F) : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withOpacity(0.3)
                              : Colors.black.withOpacity(0.04),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.grey.shade100,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Column(
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 72,
                                  height: 72,
                                  child: CircularProgressIndicator(
                                    value:
                                        currentRole ==
                                            UserRole.revenueAccountant
                                        ? incomePercentage
                                        : expensePercentage,
                                    strokeWidth: 6,
                                    backgroundColor: isDark
                                        ? Colors.white.withOpacity(0.1)
                                        : const Color(0xFFE8F6F1),
                                    color:
                                        currentRole ==
                                            UserRole.revenueAccountant
                                        ? Colors.blueAccent
                                        : const Color(0xFF00D09E),
                                    strokeCap: StrokeCap.round,
                                  ),
                                ),
                                Icon(
                                  currentRole == UserRole.revenueAccountant
                                      ? Icons.emoji_events_rounded
                                      : Icons.savings_rounded,
                                  color:
                                      currentRole == UserRole.revenueAccountant
                                      ? Colors.blueAccent
                                      : const Color(0xFF00D09E),
                                  size: 28,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              currentRole == UserRole.revenueAccountant
                                  ? 'Tiến độ KPI'
                                  : 'Phân tích Ngân sách',
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white70
                                    : const Color(0xFF1E293B),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 20),
                        Container(
                          height: 80,
                          width: 1,
                          color: isDark
                              ? Colors.white.withOpacity(0.1)
                              : Colors.grey.shade200,
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentRole == UserRole.revenueAccountant
                                    ? 'Doanh thu'
                                    : 'Ngân sách còn lại',
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white60
                                      : Colors.grey.shade600,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                currentRole == UserRole.revenueAccountant
                                    ? currencyFormatter.format(monthlyIncomeSum)
                                    : currencyFormatter.format(remainingBudget),
                                style: TextStyle(
                                  color: remainingBudget < 0
                                      ? const Color(0xFFE11D48)
                                      : (isDark
                                            ? const Color(0xFF00D09E)
                                            : const Color(0xFF059669)),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: Divider(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.1)
                                      : Colors.grey.shade100,
                                  height: 1,
                                ),
                              ),
                              Text(
                                currentRole == UserRole.revenueAccountant
                                    ? 'KPI cần đạt mỗi tháng'
                                    : 'Chi trung bình/ngày',
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white60
                                      : Colors.grey.shade600,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                currentRole == UserRole.revenueAccountant
                                    ? currencyFormatter.format(revenueKPI)
                                    : currencyFormatter.format(
                                        monthlyExpenseSum /
                                            (DateTime.now().day > 0
                                                ? DateTime.now().day
                                                : 1),
                                      ),
                                style: TextStyle(
                                  color:
                                      currentRole == UserRole.revenueAccountant
                                      ? Colors.blueAccent
                                      : const Color(0xFFE11D48),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (currentRole != UserRole.financeManager) ...[
                  const SizedBox(height: 24),
                  // Filter selector (Daily, Monthly, Yearly, Custom)
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0C2C1F)
                          : const Color(0xFFE8F6F1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        _buildFilterTab(id: 'daily', label: 'Hàng ngày'),
                        _buildFilterTab(id: 'monthly', label: 'Hàng tháng'),
                        _buildFilterTab(id: 'yearly', label: 'Hàng năm'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Header for transaction list
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'GIAO DỊCH GẦN ĐÂY',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        letterSpacing: 1.1,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go('/transactions'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF00D09E),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            currentRole == UserRole.financeManager
                                ? 'Xem tất cả'
                                : currentRole == UserRole.expenseAccountant
                                ? 'Xem chi phí'
                                : 'Xem doanh thu',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 12),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Transaction list builder
                if (filteredTxs.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        Icon(
                          Icons.receipt_long_rounded,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Không có giao dịch nào trong khoảng thời gian này',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...filteredTxs.take(5).map((tx) {
                    final isIncome = tx.type == TransactionType.income;
                    final cat = catMap[tx.categoryId];
                    final catName = cat?.name ?? 'Khác';

                    IconData leadingIcon = cat?.type == 'income'
                        ? Icons.trending_up_rounded
                        : Icons.trending_down_rounded;
                    if (cat?.iconCode != null && cat!.iconCode!.isNotEmpty) {
                      final code = int.tryParse(cat.iconCode!);
                      if (code != null)
                        leadingIcon = IconData(
                          code,
                          fontFamily: 'MaterialIcons',
                        );
                    }
                    Color iconColor = cat?.colorHex != null
                        ? Color(
                            int.parse(cat!.colorHex!.replaceFirst('#', '0xFF')),
                          )
                        : (isIncome ? Colors.blue : Colors.red);
                    Color iconBgColor = iconColor.withOpacity(0.15);

                    return ScaleOnTap(
                      onTap: () {
                        context.push(
                          '/transactions/form',
                          extra: {'transactionId': tx.id, 'readOnly': true},
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF0C2C1F)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withOpacity(0.05)
                                : Colors.grey.shade100,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: iconBgColor,
                              radius: 22,
                              child: Icon(
                                leadingIcon,
                                color: iconColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tx.title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF1E293B),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 8,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      Text(
                                        '${timeFormatter.format(tx.transactionDate)} - ${dateFormatter.format(tx.transactionDate)}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: iconBgColor,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          catName,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: iconColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${isIncome ? '+' : '-'}${currencyFormatter.format(tx.amount)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: isIncome
                                    ? const Color(0xFF059669)
                                    : const Color(0xFFE11D48),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab({required String id, required String label}) {
    final isSelected = _timeFilter == id;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _timeFilter = id;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF00D09E) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderFilter() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF06150F) : const Color(0xFFE8F6F1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildFilterChip(id: 'all', label: 'Tất cả'),
          _buildFilterChip(id: 'daily', label: 'Ngày'),
          _buildFilterChip(id: 'monthly', label: 'Tháng'),
          _buildFilterChip(id: 'yearly', label: 'Năm'),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: _showCustomDatePicker,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _timeFilter == 'custom'
                    ? const Color(0xFF00D09E)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.calendar_today_rounded,
                size: 16,
                color: _timeFilter == 'custom'
                    ? Colors.white
                    : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({required String id, required String label}) {
    final isSelected = _timeFilter == id;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _timeFilter = id),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF00D09E) : Colors.transparent,
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
                  : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showCustomDatePicker() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF00D09E);
    final picked = await showDateRangePicker(
      context: context,
      locale: const Locale('vi', 'VN'),
      initialDateRange:
          _customDateRange ??
          DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 30)),
            end: DateTime.now(),
          ),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: ThemeData(
          useMaterial3: true,
          brightness: isDark ? Brightness.dark : Brightness.light,
          colorScheme: isDark
              ? ColorScheme.dark(
                  primary: primaryColor,
                  onPrimary: Colors.white,
                  surface: const Color(0xFF0D251C),
                  onSurface: Colors.white,
                )
              : ColorScheme.light(
                  primary: primaryColor,
                  onPrimary: Colors.white,
                  surface: Colors.white,
                  onSurface: const Color(0xFF1E293B),
                ),
          appBarTheme: AppBarTheme(
            backgroundColor: isDark ? const Color(0xFF0C2C1F) : primaryColor,
            foregroundColor: Colors.white,
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(foregroundColor: Colors.white),
          ),
          datePickerTheme: DatePickerThemeData(
            headerBackgroundColor: isDark
                ? const Color(0xFF0C2C1F)
                : primaryColor,
            headerForegroundColor: Colors.white,
            backgroundColor: isDark ? const Color(0xFF0D251C) : Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _customDateRange = picked;
        _timeFilter = 'custom';
      });
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
        : txs
              .where(
                (tx) =>
                    tx.type ==
                    (type == 'income'
                        ? TransactionType.income
                        : TransactionType.expense),
              )
              .toList();
    filtered.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));

    final total = filtered.fold<int>(0, (s, tx) => s + tx.amount);
    final title = type == 'net'
        ? 'Dòng tiền thuần'
        : type == 'income'
        ? 'Tổng thu'
        : 'Tổng chi';

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
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? Colors.white10 : Colors.grey.shade200,
                  ),
                ),
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
                            fontSize: 18,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${fmt.format(total)} • ${filtered.length} giao dịch',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white60 : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ScaleOnTap(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        'Không có giao dịch nào',
                        style: TextStyle(
                          color: isDark ? Colors.white38 : Colors.grey,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final tx = filtered[i];
                        final isInc = tx.type == TransactionType.income;
                        final cat = catMap[tx.categoryId];
                        return ScaleOnTap(
                          onTap: () => context.push(
                            '/transactions/form',
                            extra: {'transactionId': tx.id, 'readOnly': true},
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF06150F)
                                  : const Color(0xFFF4FAF7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor:
                                      (isInc
                                              ? const Color(0xFF00D09E)
                                              : const Color(0xFFEF4444))
                                          .withOpacity(0.15),
                                  child: Icon(
                                    isInc
                                        ? Icons.arrow_upward_rounded
                                        : Icons.arrow_downward_rounded,
                                    color: isInc
                                        ? const Color(0xFF00D09E)
                                        : const Color(0xFFEF4444),
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tx.title,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: isDark
                                              ? Colors.white
                                              : const Color(0xFF1E293B),
                                        ),
                                      ),
                                      if (cat != null)
                                        Text(
                                          cat.name,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDark
                                                ? Colors.white38
                                                : Colors.grey,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${isInc ? '+' : '-'}${fmt.format(tx.amount)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: isInc
                                        ? const Color(0xFF059669)
                                        : const Color(0xFFE11D48),
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

  Widget _buildQuickActions(
    BuildContext context,
    UserRole role,
    bool isDark,
    Color primaryColor,
  ) {
    final cardBgColor = isDark ? const Color(0xFF0C2C1F) : Colors.white;
    final borderColor = isDark
        ? Colors.white.withOpacity(0.05)
        : Colors.grey.shade100;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);

    List<Widget> actions = [];

    if (role == UserRole.expenseAccountant) {
      actions = [
        _buildShortcutCard(
          context: context,
          icon: Icons.qr_code_scanner_rounded,
          title: 'Quét hóa đơn OCR',
          subtitle: 'Nhập tự động',
          color: const Color(0xFF00D09E),
          onTap: () => context.push('/invoices/capture'),
          cardBgColor: cardBgColor,
          borderColor: borderColor,
          textColor: textColor,
        ),
        _buildShortcutCard(
          context: context,
          icon: Icons.add_circle_outline_rounded,
          title: 'Ghi nhận chi phí',
          subtitle: 'Nhập thủ công',
          color: Colors.redAccent,
          onTap: () => context.push('/transactions/form'),
          cardBgColor: cardBgColor,
          borderColor: borderColor,
          textColor: textColor,
        ),
      ];
    } else if (role == UserRole.revenueAccountant) {
      actions = [
        _buildShortcutCard(
          context: context,
          icon: Icons.add_box_rounded,
          title: 'Tạo hóa đơn đầu ra',
          subtitle: 'Xuất PDF nhanh',
          color: const Color(0xFF00D09E),
          onTap: () => context.push('/invoices/outgoing/new'),
          cardBgColor: cardBgColor,
          borderColor: borderColor,
          textColor: textColor,
        ),
        _buildShortcutCard(
          context: context,
          icon: Icons.add_circle_outline_rounded,
          title: 'Ghi nhận doanh thu',
          subtitle: 'Nhập thủ công',
          color: Colors.blueAccent,
          onTap: () => context.push('/transactions/form'),
          cardBgColor: cardBgColor,
          borderColor: borderColor,
          textColor: textColor,
        ),
      ];
    } else if (role == UserRole.financeManager) {
      actions = [
        _buildShortcutCard(
          context: context,
          icon: Icons.bar_chart_rounded,
          title: 'Báo cáo cơ cấu',
          subtitle: 'Xem phân tích sâu',
          color: const Color(0xFF00D09E),
          onTap: () => context.go('/reports'),
          cardBgColor: cardBgColor,
          borderColor: borderColor,
          textColor: textColor,
        ),
        _buildShortcutCard(
          context: context,
          icon: Icons.compare_arrows_rounded,
          title: 'Dòng tiền chi tiết',
          subtitle: 'Lịch sử giao dịch',
          color: Colors.orangeAccent,
          onTap: () => context.go('/transactions'),
          cardBgColor: cardBgColor,
          borderColor: borderColor,
          textColor: textColor,
        ),
      ];
    }

    if (actions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PHÍM TẮT NHANH',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: actions[0]),
            const SizedBox(width: 12),
            Expanded(child: actions[1]),
          ],
        ),
      ],
    );
  }

  Widget _buildShortcutCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    required Color cardBgColor,
    required Color borderColor,
    required Color textColor,
  }) {
    return ScaleOnTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.grey, fontSize: 9),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactBar({
    required String label,
    required int percent,
    required int used,
    required double target,
    required double remaining,
    required NumberFormat currencyFormatter,
    required bool isDark,
    required Color fillColor,
    required Color accentColor,
    required bool showEdit,
    bool overIsBad = true,
    VoidCallback? onEdit,
  }) {
    final displayPct = percent.clamp(0, 100);
    final curTarget = displayPct / 100.0;

    final usedFmt = currencyFormatter.format(used);
    final targetFmt = currencyFormatter.format(target);
    final isOver = remaining < 0;

    Color barColor;
    if (isOver && overIsBad) {
      barColor = const Color(0xFFE11D48);
    } else if (isOver && !overIsBad) {
      barColor = const Color(0xFF059669);
    } else {
      barColor = fillColor;
    }

    Color statusColor;
    IconData statusIcon;
    if (isOver && overIsBad) {
      statusColor = const Color(0xFFE11D48);
      statusIcon = Icons.warning_amber_rounded;
    } else if (isOver && !overIsBad) {
      statusColor = const Color(0xFF059669);
      statusIcon = Icons.emoji_events_rounded;
    } else {
      statusColor = isDark ? Colors.white60 : Colors.black54;
      statusIcon = Icons.check_circle_rounded;
    }

    String statusText;
    if (isOver && overIsBad) {
      statusText = 'Đã vượt ${currencyFormatter.format(remaining.abs())}';
    } else if (isOver && !overIsBad) {
      statusText = 'Xuất sắc! Vượt ${percent - 100}% chỉ tiêu!';
    } else {
      statusText = 'Còn ${currencyFormatter.format(remaining)}';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isDark ? Colors.white70 : const Color(0xFF1E293B),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$usedFmt / $targetFmt',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (showEdit && onEdit != null) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onEdit,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: fillColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.edit_square,
                    size: 16,
                    color: isDark ? Colors.white54 : fillColor,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          height: 24,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isDark ? const Color(0xFF06150F) : const Color(0xFFF1F5F9),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: curTarget),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => Stack(
                fit: StackFit.expand,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: value,
                      heightFactor: 1.0,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isOver && overIsBad
                                ? [
                                    const Color(0xFFE11D48),
                                    const Color(0xFFFB7185),
                                  ]
                                : isOver && !overIsBad
                                ? [
                                    const Color(0xFF059669),
                                    const Color(0xFF34D399),
                                  ]
                                : [fillColor, accentColor],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (percent > 0)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Text(
                          '$percent%',
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.visible,
                          style: TextStyle(
                            color: displayPct >= 12
                                ? Colors.white
                                : (isDark
                                      ? Colors.white
                                      : const Color(0xFF1E293B)),
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(statusIcon, color: statusColor, size: 14),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                statusText,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _showEditValueDialog(
    BuildContext context,
    bool isDark,
    String label,
    int currentValue,
    Function(int) onSave,
  ) async {
    const int maxValue = 99999999999;
    final controller = TextEditingController(text: currentValue.toString());
    String? error;

    final result = await showDialog<int>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: isDark ? const Color(0xFF0C2C1F) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF1E293B),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
                decoration: InputDecoration(
                  suffixText: '₫',
                  suffixStyle: TextStyle(
                    color: isDark ? Colors.white70 : const Color(0xFF64748B),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF00D09E),
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF06150F)
                      : const Color(0xFFF1F5F9),
                ),
                onChanged: (_) {
                  final v = int.tryParse(controller.text);
                  final err = (v != null && v > maxValue)
                      ? 'Số tiền tối đa là 99.999.999.999₫'
                      : null;
                  setDialogState(() => error = err);
                },
              ),
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(
                  error!,
                  style: const TextStyle(
                    color: Color(0xFFE11D48),
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Huỷ', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                final v = int.tryParse(controller.text);
                if (v == null || v <= 0) {
                  setDialogState(() => error = 'Vui lòng nhập số hợp lệ');
                  return;
                }
                if (v > maxValue) {
                  setDialogState(
                    () => error = 'Số tiền tối đa là 99.999.999.999₫',
                  );
                  return;
                }
                Navigator.pop(context, v);
              },
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF00D09E),
              ),
              child: const Text(
                'Lưu',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
    if (result != null) {
      final user = ref.read(currentUserProvider);
      final company = user?.company;
      if (company == null || company.isEmpty) return;
      final currentBudget =
          ref.read(companyBudgetLimitProvider).valueOrNull ?? 20000000;
      final currentKpi =
          ref.read(companyRevenueKpiProvider).valueOrNull ?? 500000000;

      await FirebaseFirestore.instance
          .collection('companySettings')
          .doc(company)
          .set({
            'budgetLimit': label == 'Ngân sách hàng tháng' ? result : currentBudget,
            'revenueKpi': label == 'KPI hàng tháng' ? result : currentKpi,
          });
      ref.invalidate(companyBudgetLimitProvider);
      ref.invalidate(companyRevenueKpiProvider);
    }
  }
}
