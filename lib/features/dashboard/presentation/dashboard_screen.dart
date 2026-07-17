import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  // Filter state: 'daily' | 'weekly' | 'monthly'
  String _timeFilter = 'monthly';

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

    final transactionsAsync = currentRole == UserRole.expenseAccountant
        ? ref.watch(expenseTransactionsProvider)
        : currentRole == UserRole.revenueAccountant
        ? ref.watch(incomeTransactionsProvider)
        : ref.watch(allTransactionsProvider);

    final categoriesAsync = ref.watch(allCategoriesProvider);

    if (transactionsAsync.isLoading || categoriesAsync.isLoading) {
      return Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF06150F)
            : const Color(0xFFF4FAF7),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipOval(
                child: Image.asset(
                  'assets/images/loadingGif.gif',
                  width: 150,
                  height: 150,
                  fit: BoxFit.cover,
                ),
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

    // Apply selected time filter (Daily, Weekly, Monthly)
    final now = DateTime.now();
    filteredTxs = filteredTxs.where((tx) {
      final difference = now.difference(tx.transactionDate).inDays;
      if (_timeFilter == 'daily') {
        return difference == 0 && tx.transactionDate.day == now.day;
      } else if (_timeFilter == 'weekly') {
        return difference <= 7;
      } else {
        // Monthly (Calendar month)
        return tx.transactionDate.month == now.month &&
            tx.transactionDate.year == now.year;
      }
    }).toList();

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

    final double budgetLimit = (budgetLimitAsync.valueOrNull ?? 20000000).toDouble();
    final double revenueKPI = (revenueKpiAsync.valueOrNull ?? 500000000).toDouble();

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
                          FittedBox(
                            fit: BoxFit.scaleDown,
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
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                              Container(
                                height: 28,
                                width: 1,
                                color: isDark
                                    ? Colors.white12
                                    : Colors.black.withOpacity(0.08),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                        currencyFormatter.format(expenseSum),
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
                            ],
                          ),
                        ] else if (currentRole ==
                            UserRole.expenseAccountant) ...[
                          // Tổng chi tiêu
                          Text(
                            _timeFilter == 'daily'
                                ? 'TỔNG CHI TIÊU HÔM NAY'
                                : _timeFilter == 'weekly'
                                ? 'TỔNG CHI TIÊU TUẦN NÀY'
                                : 'TỔNG CHI TIÊU HÀNG THÁNG',
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark ? Colors.white70 : Colors.black87,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          FittedBox(
                            fit: BoxFit.scaleDown,
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
                          FittedBox(
                            fit: BoxFit.scaleDown,
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
                        ],

                        if (currentRole == UserRole.financeManager ||
                            currentRole == UserRole.expenseAccountant) ...[
                          const SizedBox(height: 12),
                          _buildCompactBar(
                            label: 'Ngân sách chi tiêu',
                            percent: expensePercentInt,
                            used: monthlyExpenseSum,
                            target: budgetLimit,
                            remaining: remainingBudget,
                            currencyFormatter: currencyFormatter,
                            isDark: isDark,
                            fillColor: const Color(0xFF1E293B),
                            accentColor: const Color(0xFF059669),
                            showEdit: currentRole == UserRole.financeManager,
                            onEdit: () => _showEditValueDialog(context, isDark, 'Ngân sách tháng', budgetLimitAsync.valueOrNull ?? 20000000, (_) {}),
                          ),
                        ],
                        if (currentRole == UserRole.financeManager) ...[
                          const SizedBox(height: 12),
                          _buildCompactBar(
                            label: 'KPI doanh thu',
                            percent: incomePercentInt,
                            used: monthlyIncomeSum,
                            target: revenueKPI,
                            remaining: revenueKPI - monthlyIncomeSum,
                            currencyFormatter: currencyFormatter,
                            isDark: isDark,
                            fillColor: Colors.blueAccent,
                            accentColor: Colors.amber,
                            showEdit: true,
                            overIsBad: false,
                            onEdit: () => _showEditValueDialog(context, isDark, 'KPI doanh thu', revenueKpiAsync.valueOrNull ?? 500000000, (_) {}),
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
                // Quick Action Row / Shortcuts
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
                          color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.04),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                      border: Border.all(
                        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
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
                                    value: currentRole == UserRole.revenueAccountant ? incomePercentage : expensePercentage,
                                    strokeWidth: 6,
                                    backgroundColor: isDark ? Colors.white.withOpacity(0.1) : const Color(0xFFE8F6F1),
                                    color: currentRole == UserRole.revenueAccountant ? Colors.blueAccent : const Color(0xFF00D09E),
                                    strokeCap: StrokeCap.round,
                                  ),
                                ),
                                Icon(
                                  currentRole == UserRole.revenueAccountant ? Icons.emoji_events_rounded : Icons.savings_rounded,
                                  color: currentRole == UserRole.revenueAccountant ? Colors.blueAccent : const Color(0xFF00D09E),
                                  size: 28,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              currentRole == UserRole.revenueAccountant ? 'Tiến độ KPI' : 'Phân tích Ngân sách',
                              style: TextStyle(
                                color: isDark ? Colors.white70 : const Color(0xFF1E293B),
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
                          color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200,
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentRole == UserRole.revenueAccountant ? 'Doanh thu' : 'Ngân sách còn lại',
                                style: TextStyle(
                                  color: isDark ? Colors.white60 : Colors.grey.shade600,
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
                                      : (isDark ? const Color(0xFF00D09E) : const Color(0xFF059669)),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Divider(
                                  color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade100,
                                  height: 1,
                                ),
                              ),
                              Text(
                                currentRole == UserRole.revenueAccountant ? 'KPI cần đạt mỗi tháng' : 'Chi trung bình/ngày',
                                style: TextStyle(
                                  color: isDark ? Colors.white60 : Colors.grey.shade600,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                currentRole == UserRole.revenueAccountant
                                    ? currencyFormatter.format(revenueKPI)
                                    : currencyFormatter.format(monthlyExpenseSum / (DateTime.now().day > 0 ? DateTime.now().day : 1)),
                                style: TextStyle(
                                  color: currentRole == UserRole.revenueAccountant ? Colors.blueAccent : const Color(0xFFE11D48),
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

                const SizedBox(height: 24),

                // Filter selector (Daily, Weekly, Monthly)
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
                      _buildFilterTab(id: 'weekly', label: 'Hàng tuần'),
                      _buildFilterTab(id: 'monthly', label: 'Hàng tháng'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

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

                    // Custom styling map for categories to make it extremely clean and professional
                    IconData leadingIcon = Icons.category_rounded;
                    Color iconColor = cat?.colorHex != null ? Color(int.parse(cat!.colorHex!.replaceFirst('#', '0xFF'))) : (isIncome ? Colors.blue : Colors.red);
                    Color iconBgColor = iconColor.withOpacity(0.15);
                    
                    if (catName.contains('Lương')) {
                      leadingIcon = Icons.account_balance_wallet_rounded;
                    } else if (catName.contains('Mặt bằng') ||
                        catName.contains('Điện nước')) {
                      leadingIcon = Icons.home_work_rounded;
                    } else if (catName.contains('bán hàng') ||
                        catName.contains('dịch vụ')) {
                      leadingIcon = Icons.storefront_rounded;
                    } else if (catName.contains('Mua hàng') ||
                        catName.contains('Vận hành')) {
                      leadingIcon = Icons.shopping_bag_rounded;
                    } else if (catName.contains('Marketing')) {
                      leadingIcon = Icons.campaign_rounded;
                    }

                    return ScaleOnTap(
                      onTap: () {
                        if (currentRole.canEditTransactions) {
                          context.go(
                            '/transactions/form',
                            extra: {'transactionId': tx.id},
                          );
                        }
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
                                    tx.note ?? catName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF1E293B),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${timeFormatter.format(tx.transactionDate)} - ${dateFormatter.format(tx.transactionDate)} | $catName',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade500,
                                    ),
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
          onTap: () => context.go('/invoices/capture'),
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
          onTap: () => context.go('/transactions/form'),
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
          onTap: () => context.go('/invoices/outgoing/new'),
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
          onTap: () => context.go('/transactions/form'),
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
            Text(
              label,
              style: TextStyle(
                color: isDark ? Colors.white70 : const Color(0xFF1E293B),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '$usedFmt / $targetFmt',
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
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
                  child: Icon(Icons.edit_square, size: 16, color: isDark ? Colors.white54 : fillColor),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        Container(
          height: 24,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isDark ? const Color(0xFF06150F) : const Color(0xFFF1F5F9),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: displayPct / 100),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => Stack(
                children: [
                  FractionallySizedBox(
                    widthFactor: value,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isOver && overIsBad
                              ? [const Color(0xFFE11D48), const Color(0xFFFB7185)]
                              : isOver && !overIsBad
                                  ? [const Color(0xFF059669), const Color(0xFF34D399)]
                                  : [fillColor, fillColor.withValues(alpha: 0.7)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                      ),
                    ),
                  ),
                  if (percent > 0)
                    Positioned.fill(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: Text(
                            '$percent%',
                            style: TextStyle(
                              color: displayPct > 20 ? Colors.white : (isDark ? Colors.white54 : const Color(0xFF64748B)),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B)),
                decoration: InputDecoration(
                  suffixText: '₫',
                  suffixStyle: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF64748B)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF00D09E), width: 2),
                  ),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF06150F) : const Color(0xFFF1F5F9),
                ),
                onChanged: (_) {
                  final v = int.tryParse(controller.text);
                  final err = (v != null && v > maxValue) ? 'Số tiền tối đa là 99.999.999.999₫' : null;
                  setDialogState(() => error = err);
                },
              ),
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(error!, style: const TextStyle(color: Color(0xFFE11D48), fontSize: 11)),
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
                  setDialogState(() => error = 'Số tiền tối đa là 99.999.999.999₫');
                  return;
                }
                Navigator.pop(context, v);
              },
              style: TextButton.styleFrom(foregroundColor: const Color(0xFF00D09E)),
              child: const Text('Lưu', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
    if (result != null) {
      final user = ref.read(currentUserProvider);
      final company = user?.company;
      if (company == null || company.isEmpty) return;
      final currentBudget = ref.read(companyBudgetLimitProvider).valueOrNull ?? 20000000;
      final currentKpi = ref.read(companyRevenueKpiProvider).valueOrNull ?? 500000000;

      await FirebaseFirestore.instance.collection('companySettings').doc(company).set({
        'budgetLimit': label == 'Ngân sách tháng' ? result : currentBudget,
        'revenueKpi': label == 'KPI doanh thu' ? result : currentKpi,
      });
      ref.invalidate(companyBudgetLimitProvider);
      ref.invalidate(companyRevenueKpiProvider);
    }
  }
}
