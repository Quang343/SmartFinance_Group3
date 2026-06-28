import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/role_provider.dart';
import '../../../core/providers/app_providers.dart';
import '../../../domain/entities/transaction_entity.dart';
import '../../../domain/entities/category_entity.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
    );
    final timeFormatter = DateFormat('HH:mm');
    final dateFormatter = DateFormat('dd/MM');

    final transactionsAsync = ref.watch(transactionRepositoryProvider);
    final categoriesAsync = ref.watch(categoryRepositoryProvider);

    // Fetch transactions and categories in parallel, with artificial 1s delay for the loading animation
    final dataFuture = Future.wait([
      transactionsAsync.getAll(),
      categoriesAsync.getAll(),
      Future.delayed(const Duration(seconds: 1)),
    ]);

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF06150F)
          : const Color(0xFFF4FAF7),
      body: FutureBuilder<List<dynamic>>(
        future: dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Image.asset(
                'assets/images/loadingGif.gif',
                width: 80,
                fit: BoxFit.contain,
              ),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Lỗi tải dữ liệu: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final allTxs = (snapshot.data?[0] as List<TransactionEntity>?) ?? [];
          final allCats = (snapshot.data?[1] as List<CategoryEntity>?) ?? [];

          // Create a quick lookup map for categories
          final catMap = {for (var c in allCats) c.id: c};

          // Filter by status and role
          var filteredTxs = allTxs
              .where((tx) => tx.status == TransactionStatus.confirmed)
              .toList();

          if (currentRole == UserRole.expenseAccountant) {
            filteredTxs = filteredTxs
                .where((tx) => tx.type == TransactionType.expense)
                .toList();
          } else if (currentRole == UserRole.revenueAccountant) {
            filteredTxs = filteredTxs
                .where((tx) => tx.type == TransactionType.income)
                .toList();
          }

          // Apply selected time filter (Daily, Weekly, Monthly)
          final now = DateTime.now();
          filteredTxs = filteredTxs.where((tx) {
            final difference = now.difference(tx.transactionDate).inDays;
            if (_timeFilter == 'daily') {
              return difference == 0 && tx.transactionDate.day == now.day;
            } else if (_timeFilter == 'weekly') {
              return difference <= 7;
            } else {
              // Monthly (last 30 days)
              return difference <= 30;
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

          // Compute budget progress percentage (Mocked budget max: 20,000,000 ₫)
          const double budgetLimit = 20000000;
          final double expensePercentage = (expenseSum / budgetLimit).clamp(
            0.0,
            1.0,
          );
          final int expensePercentInt = (expensePercentage * 100).toInt();

          return CustomScrollView(
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
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0D281E) : const Color(0xFFE6F4F0),
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
                                        ? (isDark ? const Color(0xFF86EFAC) : const Color(0xFF008060))
                                        : (isDark ? const Color(0xFFFCA5A5) : const Color(0xFFD32F2F)),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Divider(
                                color: isDark ? Colors.white12 : Colors.black.withOpacity(0.08),
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
                                              color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF008060),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Tổng thu',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: isDark ? Colors.white : Colors.black,
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
                                              color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF008060),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    height: 28,
                                    width: 1,
                                    color: isDark ? Colors.white12 : Colors.black.withOpacity(0.08),
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
                                              color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFD32F2F),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Tổng chi',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: isDark ? Colors.white : Colors.black,
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
                                              color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFD32F2F),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ] else if (currentRole == UserRole.expenseAccountant) ...[
                              // Tổng chi tiêu
                              Text(
                                'TỔNG CHI TIÊU HÀNG THÁNG',
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
                                    color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFD32F2F),
                                  ),
                                ),
                              ),
                            ] else if (currentRole == UserRole.revenueAccountant) ...[
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
                                    color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF008060),
                                  ),
                                ),
                              ),
                            ],

                            // Budget progress bar (Only show for FM and EA roles, as RA doesn't manage expense budgets)
                            if (currentRole == UserRole.financeManager || currentRole == UserRole.expenseAccountant) ...[
                              const SizedBox(height: 12),
                              // Custom split progress bar (Stadium pill style)
                              Container(
                                height: 28,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  color: isDark ? const Color(0xFF06150F) : const Color(0xFFF1F5F9),
                                  border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.04)),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Row(
                                    children: [
                                      if (expensePercentInt > 0)
                                        Expanded(
                                          flex: expensePercentInt,
                                          child: Container(
                                            color: const Color(0xFF1E293B), // Dark slate
                                            alignment: Alignment.center,
                                            child: Text(
                                              '$expensePercentInt%',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      Expanded(
                                        flex: (100 - expensePercentInt).clamp(1, 100),
                                        child: Container(
                                          alignment: Alignment.centerRight,
                                          padding: const EdgeInsets.only(right: 12),
                                          child: Text(
                                            currencyFormatter.format(budgetLimit),
                                            style: TextStyle(
                                              color: isDark ? Colors.white70 : const Color(0xFF1E293B),
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.check_circle_rounded,
                                    color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF008060),
                                    size: 15,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Đã sử dụng $expensePercentInt% ngân sách tháng, trạng thái tốt.',
                                      style: TextStyle(
                                        color: isDark ? Colors.white70 : Colors.black87,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Quick Action Row / Shortcuts
                    _buildQuickActions(context, currentRole, isDark, const Color(0xFF00D09E)),
                    const SizedBox(height: 24),

                    // Savings & Goal progress card
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
                          // Left Circular indicator with car icon
                          Column(
                            children: [
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    width: 72,
                                    height: 72,
                                    child: CircularProgressIndicator(
                                      value: 0.65, // example target progress
                                      strokeWidth: 6,
                                      backgroundColor: isDark
                                          ? Colors.white.withOpacity(0.1)
                                          : const Color(0xFFE8F6F1),
                                      color: const Color(0xFF00D09E),
                                      strokeCap: StrokeCap.round,
                                    ),
                                  ),
                                  const Icon(
                                    Icons
                                        .savings_rounded, // Piggy bank icon for Savings Goal
                                    color: Color(0xFF00D09E),
                                    size: 28,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tiết kiệm mục tiêu',
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
                          // Vertical divider
                          Container(
                            height: 80,
                            width: 1,
                            color: isDark
                                ? Colors.white.withOpacity(0.1)
                                : Colors.grey.shade200,
                          ),
                          const SizedBox(width: 20),
                          // Right text stats
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Doanh thu tuần trước',
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
                                  currencyFormatter.format(
                                    4000000,
                                  ), // static representation for UI layout
                                  style: TextStyle(
                                    color: isDark
                                        ? const Color(0xFF00D09E)
                                        : const Color(0xFF059669),
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
                                  'Chi ăn uống tuần trước',
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
                                  '-${currencyFormatter.format(100000)}',
                                  style: const TextStyle(
                                    color: Color(
                                      0xFFE11D48,
                                    ), // Rose/red for negative expenses
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
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'GIAO DỊCH GẦN ĐÂY',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                            letterSpacing: 1.1,
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
                      ...filteredTxs.map((tx) {
                        final isIncome = tx.type == TransactionType.income;
                        final cat = catMap[tx.categoryId];
                        final catName = cat?.name ?? 'Khác';

                        // Custom styling map for categories to make it extremely clean and professional
                        IconData leadingIcon = Icons.category_rounded;
                        Color iconBgColor = isIncome
                            ? const Color(0xFFE0F2FE)
                            : const Color(0xFFFEE2E2);
                        Color iconColor = isIncome ? Colors.blue : Colors.red;

                        if (catName.contains('Lương')) {
                          leadingIcon = Icons.account_balance_wallet_rounded;
                          iconBgColor = const Color(0xFFE0F2FE); // light blue
                          iconColor = const Color(0xFF0284C7);
                        } else if (catName.contains('Mặt bằng') ||
                            catName.contains('Điện nước')) {
                          leadingIcon = Icons.home_work_rounded;
                          iconBgColor = const Color(0xFFEEF2FF); // indigo
                          iconColor = const Color(0xFF4F46E5);
                        } else if (catName.contains('bán hàng') ||
                            catName.contains('dịch vụ')) {
                          leadingIcon = Icons.storefront_rounded;
                          iconBgColor = const Color(0xFFECFDF5); // light green
                          iconColor = const Color(0xFF059669);
                        } else if (catName.contains('Mua hàng') ||
                            catName.contains('Vận hành')) {
                          leadingIcon = Icons.shopping_bag_rounded;
                          iconBgColor = const Color(0xFFFFF7ED); // orange
                          iconColor = const Color(0xFFEA580C);
                        } else if (catName.contains('Marketing')) {
                          leadingIcon = Icons.campaign_rounded;
                          iconBgColor = const Color(0xFFFAF5FF); // purple
                          iconColor = const Color(0xFF9333EA);
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
          );
        },
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

  Widget _buildQuickActions(BuildContext context, UserRole role, bool isDark, Color primaryColor) {
    final cardBgColor = isDark ? const Color(0xFF0C2C1F) : Colors.white;
    final borderColor = isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100;
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
          onTap: () => context.go('/invoices/scan'),
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
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 9,
                    ),
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
