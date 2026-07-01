import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/role_provider.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/transaction_providers.dart';
import '../../../core/providers/category_providers.dart';
import '../../../domain/entities/transaction_entity.dart';
import '../../../domain/entities/category_entity.dart';
import '../../../core/widgets/scale_on_tap.dart';

class TransactionListScreen extends ConsumerStatefulWidget {
  const TransactionListScreen({super.key});

  @override
  ConsumerState<TransactionListScreen> createState() =>
      _TransactionListScreenState();
}

class _TransactionListScreenState extends ConsumerState<TransactionListScreen> {
  String _searchQuery = '';
  String _selectedPeriod = 'all'; // 'all', 'today', 'month', 'year', 'custom'
  String _selectedStatus = 'confirmed'; // 'all', 'confirmed', 'draft'
  DateTimeRange? _customDateRange;
  int _displayLimit = 15;

  @override
  void initState() {
    super.initState();
    // Auto cleanup old deleted transactions once on mount
    Future.microtask(
      () =>
          ref.read(transactionRepositoryProvider).cleanupDeletedTransactions(),
    );
  }

  void _refreshData({bool showLoading = false}) {
    final currentRole = ref.read(roleProvider);
    if (currentRole == UserRole.expenseAccountant) {
      ref.invalidate(expenseTransactionsProvider);
    } else if (currentRole == UserRole.revenueAccountant) {
      ref.invalidate(incomeTransactionsProvider);
    } else {
      ref.invalidate(allTransactionsProvider);
    }
    ref.invalidate(allCategoriesProvider);
  }

  void _confirmDeleteFromList(TransactionEntity tx) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa giao dịch?'),
        content: const Text(
          'Bạn có chắc chắn muốn xóa giao dịch này không? Dữ liệu thống kê sẽ được cập nhật lại.',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final repo = ref.read(transactionRepositoryProvider);
              await repo.softDelete(tx.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã xóa giao dịch thành công!'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
                _refreshData();
              }
            },
            child: const Text(
              'Xóa',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmRestoreFromList(TransactionEntity tx) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Khôi phục giao dịch?'),
        content: const Text(
          'Giao dịch này sẽ được khôi phục về trạng thái Bản nháp để bạn kiểm tra lại trước khi xác nhận.',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final repo = ref.read(transactionRepositoryProvider);
              await repo.restore(tx.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã khôi phục giao dịch thành Bản nháp!'),
                    backgroundColor: Colors.green,
                  ),
                );
                _refreshData();
              }
            },
            child: const Text(
              'Khôi phục',
              style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String value, String label, bool isDark) {
    final isSelected = _selectedStatus == value;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedStatus = value;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF00D09E)
              : (isDark ? const Color(0xFF152F23) : const Color(0xFFEDF2F7)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark ? const Color(0xFF00D09E) : Colors.black54),
          ),
        ),
      ),
    );
  }

  Widget _buildTrashChip(bool isDark) {
    final isSelected = _selectedStatus == 'deleted';
    return InkWell(
      onTap: () {
        setState(() {
          _selectedStatus = 'deleted';
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.red
              : (isDark ? const Color(0xFF3B1515) : const Color(0xFFFDE8E8)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.delete_outline_rounded,
              size: 14,
              color: isSelected ? Colors.white : Colors.red,
            ),
            const SizedBox(width: 4),
            Text(
              'Thùng rác',
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : Colors.red,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );
    final dateFormatter = DateFormat('dd/MM/yyyy');
    final primaryColor = const Color(0xFF00D09E);

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF06150F)
          : const Color(0xFFF4FAF7),
      appBar: AppBar(
        backgroundColor: isDark
            ? const Color(0xFF06150F)
            : const Color(0xFFF4FAF7),
        elevation: 0,
        centerTitle: false,
        titleSpacing: 20,
        title: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFF00D09E), Color(0xFF34D399)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds),
            child: Text(
              currentRole == UserRole.financeManager
                  ? 'Dòng tiền doanh nghiệp'
                  : currentRole == UserRole.expenseAccountant
                  ? 'Giao dịch Chi phí'
                  : 'Giao dịch Doanh thu',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: Colors.white,
                fontSize: 22,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E382B)
                      : const Color(0xFFE8F6F1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF00D09E).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF00D09E),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      currentRole == UserRole.expenseAccountant
                          ? 'Kế toán Chi phí'
                          : currentRole == UserRole.revenueAccountant
                          ? 'Kế toán Doanh thu'
                          : 'Quản lý',
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF00D09E),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          final transactionsAsync = currentRole == UserRole.expenseAccountant
              ? ref.watch(expenseTransactionsProvider)
              : currentRole == UserRole.revenueAccountant
              ? ref.watch(incomeTransactionsProvider)
              : ref.watch(allTransactionsProvider);
          final categoriesAsync = ref.watch(allCategoriesProvider);

          if (transactionsAsync.isLoading || categoriesAsync.isLoading) {
            return Center(
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
            );
          }
          if (transactionsAsync.hasError) {
            return Center(
              child: Text(
                'Lỗi: ${transactionsAsync.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final allTxs = transactionsAsync.value ?? [];
          final allCats = categoriesAsync.value ?? [];

          final catMap = {for (var c in allCats) c.id: c};

          // Filter by status and handle 'deleted' explicitly
          var list = allTxs;
          if (_selectedStatus == 'deleted') {
            list = list
                .where((tx) => tx.status == TransactionStatus.deleted)
                .toList();
          } else {
            // Normal flow: hide completely deleted transactions
            list = list
                .where((tx) => tx.status != TransactionStatus.deleted)
                .toList();
          }

          // Note: No need to filter by role here because the Provider already filtered it!

          // Filter by time period
          list = list
              .where((tx) => _isWithinPeriod(tx.transactionDate))
              .toList();

          // Filter by status
          if (_selectedStatus == 'confirmed') {
            list = list
                .where((tx) => tx.status == TransactionStatus.confirmed)
                .toList();
          } else if (_selectedStatus == 'draft') {
            list = list
                .where((tx) => tx.status == TransactionStatus.draft)
                .toList();
          }

          // Filter by search query
          if (_searchQuery.isNotEmpty) {
            list = list.where((tx) {
              final note = (tx.note ?? '').toLowerCase();
              final catName = (catMap[tx.categoryId]?.name ?? '').toLowerCase();
              return note.contains(_searchQuery) ||
                  catName.contains(_searchQuery);
            }).toList();
          }

          // Sort by date descending
          list.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));

          // Calculate overview stats based on current filter
          final totalIncome = list
              .where((tx) => tx.type == TransactionType.income)
              .fold<double>(0.0, (sum, item) => sum + item.amount);
          final totalExpense = list
              .where((tx) => tx.type == TransactionType.expense)
              .fold<double>(0.0, (sum, item) => sum + item.amount);
          final netBalance = totalIncome - totalExpense;

          return Column(
            children: [
              // Period Filter Tabs
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0D251C) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF1E3A2F)
                          : const Color(0xFFE2E8F0),
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
                        color: isDark
                            ? Colors.white12
                            : Colors.black.withOpacity(0.08),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                      GestureDetector(
                        onTap: () async {
                          final picked = await showDateRangePicker(
                            context: context,
                            locale: const Locale('vi', 'VN'),
                            initialDateRange:
                                _customDateRange ??
                                DateTimeRange(
                                  start: DateTime.now().subtract(
                                    const Duration(days: 7),
                                  ),
                                  end: DateTime.now(),
                                ),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                            builder: (context, child) {
                              return Theme(
                                data: ThemeData(
                                  useMaterial3: true,
                                  brightness: isDark
                                      ? Brightness.dark
                                      : Brightness.light,
                                  colorScheme: isDark
                                      ? const ColorScheme.dark(
                                          primary: Color(0xFF00D09E),
                                          onPrimary: Colors.white,
                                          surface: Color(0xFF0D251C),
                                          onSurface: Colors.white,
                                        )
                                      : const ColorScheme.light(
                                          primary: Color(0xFF00D09E),
                                          onPrimary: Colors.white,
                                          surface: Colors.white,
                                          onSurface: Color(0xFF1E293B),
                                        ),
                                  appBarTheme: AppBarTheme(
                                    backgroundColor: isDark
                                        ? const Color(0xFF0C2C1F)
                                        : const Color(0xFF00D09E),
                                    foregroundColor: Colors.white,
                                    iconTheme: const IconThemeData(
                                      color: Colors.white,
                                    ),
                                    actionsIconTheme: const IconThemeData(
                                      color: Colors.white,
                                    ),
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
                                      textStyle: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  datePickerTheme: DatePickerThemeData(
                                    headerBackgroundColor: isDark
                                        ? const Color(0xFF0C2C1F)
                                        : const Color(0xFF00D09E),
                                    headerForegroundColor: Colors.white,
                                    backgroundColor: isDark
                                        ? const Color(0xFF0D251C)
                                        : Colors.white,
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _selectedPeriod == 'custom'
                                ? const Color(0xFF00D09E)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.calendar_today_rounded,
                            size: 16,
                            color: _selectedPeriod == 'custom'
                                ? Colors.white
                                : (isDark
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Header balance layout matching the user request
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Column(
                  children: [
                    if (currentRole == UserRole.financeManager) ...[
                      // Consolidated Compact Card for Finance Manager
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 14,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF0D251C)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: isDark
                                  ? Colors.black.withOpacity(0.2)
                                  : Colors.black.withOpacity(0.04),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF1E3A2F)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Left side: Total Balance
                            Expanded(
                              flex: 5,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.account_balance_wallet_rounded,
                                        size: 14,
                                        color: isDark
                                            ? const Color(
                                                0xFF00D09E,
                                              ).withOpacity(0.7)
                                            : const Color(
                                                0xFF093021,
                                              ).withOpacity(0.8),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _getPeriodTitle('Tổng Số Dư'),
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.white70
                                              : Colors.black54,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      currencyFormatter.format(netBalance),
                                      style: TextStyle(
                                        color: isDark
                                            ? const Color(0xFF00D09E)
                                            : const Color(0xFF093021),
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Vertical divider
                            Container(
                              height: 36,
                              width: 1,
                              color: isDark
                                  ? Colors.white12
                                  : Colors.black.withOpacity(0.08),
                              margin: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                            ),
                            // Right side: Income & Expense (Compact)
                            Expanded(
                              flex: 4,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      'Thu nhập: +${currencyFormatter.format(totalIncome)}',
                                      style: const TextStyle(
                                        color: Color(0xFF00D09E),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      'Chi tiêu: -${currencyFormatter.format(totalExpense)}',
                                      style: const TextStyle(
                                        color: Color(0xFFEF4444),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else if (currentRole == UserRole.expenseAccountant) ...[
                      // Single card for Total Expenses
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF0D251C)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF1E3A2F)
                                : const Color(0xFFE2E8F0),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isDark
                                  ? Colors.black.withOpacity(0.2)
                                  : Colors.black.withOpacity(0.04),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFEF4444,
                                    ).withOpacity(0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.arrow_upward_rounded,
                                    color: Color(0xFFEF4444),
                                    size: 14,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _getPeriodTitle('Tổng Chi Tiêu'),
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.black54,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                currencyFormatter.format(totalExpense),
                                style: const TextStyle(
                                  color: Color(0xFFEF4444),
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else if (currentRole == UserRole.revenueAccountant) ...[
                      // Single card for Total Revenue
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF0D251C)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF1E3A2F)
                                : const Color(0xFFE2E8F0),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isDark
                                  ? Colors.black.withOpacity(0.2)
                                  : Colors.black.withOpacity(0.04),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF00D09E,
                                    ).withOpacity(0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.arrow_downward_rounded,
                                    color: Color(0xFF00D09E),
                                    size: 14,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _getPeriodTitle('Tổng Doanh Thu'),
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.black54,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                currencyFormatter.format(totalIncome),
                                style: const TextStyle(
                                  color: Color(0xFF00D09E),
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
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

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: TextField(
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm theo ghi chú, danh mục...',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF0D251C) : Colors.white,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark
                            ? const Color(0xFF1E3A2F)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: primaryColor, width: 1.5),
                    ),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.toLowerCase();
                    });
                  },
                ),
              ),

              const SizedBox(height: 8),
              // Status Filter
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      'Trạng thái: ',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black54,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildStatusChip('all', 'Tất cả', isDark),
                            const SizedBox(width: 8),
                            _buildStatusChip(
                              'confirmed',
                              'Đã xác nhận',
                              isDark,
                            ),
                            const SizedBox(width: 8),
                            _buildStatusChip('draft', 'Bản nháp', isDark),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildTrashChip(isDark),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              if (_selectedStatus == 'deleted')
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: Colors.orange,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Giao dịch trong Thùng rác sẽ bị tự động xóa vĩnh viễn sau 30 ngày.',
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black87,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // List area
              Expanded(
                child: list.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long_rounded,
                              size: 64,
                              color: isDark ? Colors.white24 : Colors.black12,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Không tìm thấy giao dịch nào',
                              style: TextStyle(
                                color: isDark ? Colors.white38 : Colors.black45,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        color: primaryColor,
                        onRefresh: () async {
                          _refreshData(showLoading: false);
                          // Riverpod will rebuild automatically when invalidated
                        },
                        child: NotificationListener<ScrollNotification>(
                          onNotification: (ScrollNotification scrollInfo) {
                            if (scrollInfo.metrics.pixels ==
                                    scrollInfo.metrics.maxScrollExtent &&
                                list.length > _displayLimit) {
                              setState(() {
                                _displayLimit += 15;
                              });
                              return true;
                            }
                            return false;
                          },
                          child: ListView.builder(
                            itemCount:
                                min(_displayLimit, list.length) +
                                (list.length > _displayLimit ? 1 : 0),
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                            itemBuilder: (context, index) {
                              if (index == _displayLimit) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16.0,
                                  ),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: primaryColor,
                                    ),
                                  ),
                                );
                              }
                              final tx = list[index];
                              final isIncome =
                                  tx.type == TransactionType.income;
                              final cat = catMap[tx.categoryId];
                              final catName = cat?.name ?? 'Chưa phân loại';

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF0E2219)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    if (!isDark)
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.03),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                  ],
                                  border: Border.all(
                                    color: isDark
                                        ? const Color(0xFF1A382B)
                                        : const Color(0xFFEDF2F7),
                                    width: 1,
                                  ),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () {
                                      if (currentRole.canEditTransactions) {
                                        context.go(
                                          '/transactions/form',
                                          extra: {'transactionId': tx.id},
                                        );
                                      }
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 12,
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Container(
                                            width: 42,
                                            height: 42,
                                            decoration: BoxDecoration(
                                              color: isIncome
                                                  ? const Color(0x1500D09E)
                                                  : const Color(0x15EF4444),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              isIncome
                                                  ? Icons.arrow_downward_rounded
                                                  : Icons.arrow_upward_rounded,
                                              color: isIncome
                                                  ? const Color(0xFF00D09E)
                                                  : const Color(0xFFEF4444),
                                              size: 18,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  tx.note ?? 'Không có ghi chú',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15,
                                                    color: isDark
                                                        ? Colors.white
                                                        : Colors.black87,
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                Wrap(
                                                  spacing: 6,
                                                  runSpacing: 4,
                                                  crossAxisAlignment:
                                                      WrapCrossAlignment.center,
                                                  children: [
                                                    if (tx.status ==
                                                        TransactionStatus.draft)
                                                      Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 6,
                                                              vertical: 2,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: Colors.orange
                                                              .withOpacity(
                                                                0.15,
                                                              ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                4,
                                                              ),
                                                          border: Border.all(
                                                            color: Colors.orange
                                                                .withOpacity(
                                                                  0.5,
                                                                ),
                                                          ),
                                                        ),
                                                        child: const Text(
                                                          'Bản nháp',
                                                          style: TextStyle(
                                                            fontSize: 9,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color:
                                                                Colors.orange,
                                                          ),
                                                        ),
                                                      ),
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 2,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: isDark
                                                            ? const Color(
                                                                0xFF152F23,
                                                              )
                                                            : const Color(
                                                                0xFFEDF2F7,
                                                              ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              6,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        catName,
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: isDark
                                                              ? const Color(
                                                                  0xFF00D09E,
                                                                )
                                                              : Colors.black54,
                                                        ),
                                                      ),
                                                    ),
                                                    Text(
                                                      dateFormatter.format(
                                                        tx.transactionDate,
                                                      ),
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        color: isDark
                                                            ? Colors.white38
                                                            : Colors.black38,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                '${isIncome ? '+' : '-'}${currencyFormatter.format(tx.amount)}',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: isIncome
                                                      ? const Color(0xFF00D09E)
                                                      : const Color(0xFFEF4444),
                                                  fontSize: 14,
                                                ),
                                              ),
                                              if (currentRole
                                                  .canEditTransactions) ...[
                                                const SizedBox(width: 4),
                                                PopupMenuButton<String>(
                                                  icon: Icon(
                                                    Icons.more_vert_rounded,
                                                    size: 18,
                                                    color: isDark
                                                        ? Colors.white30
                                                        : Colors.black38,
                                                  ),
                                                  padding: EdgeInsets.zero,
                                                  constraints:
                                                      const BoxConstraints(),
                                                  onSelected: (action) async {
                                                    if (action == 'edit') {
                                                      context.go(
                                                        '/transactions/form',
                                                        extra: {
                                                          'transactionId':
                                                              tx.id,
                                                        },
                                                      );
                                                    } else if (action ==
                                                        'delete') {
                                                      _confirmDeleteFromList(
                                                        tx,
                                                      );
                                                    } else if (action ==
                                                        'restore') {
                                                      _confirmRestoreFromList(
                                                        tx,
                                                      );
                                                    } else if (action ==
                                                        'hard_delete') {
                                                      final repo = ref.read(
                                                        transactionRepositoryProvider,
                                                      );
                                                      await repo.hardDelete(
                                                        tx.id,
                                                      );
                                                      if (context.mounted) {
                                                        ScaffoldMessenger.of(
                                                          context,
                                                        ).showSnackBar(
                                                          const SnackBar(
                                                            content: Text(
                                                              'Đã xóa vĩnh viễn giao dịch',
                                                            ),
                                                            backgroundColor:
                                                                Colors.red,
                                                          ),
                                                        );
                                                        _refreshData();
                                                      }
                                                    }
                                                  },
                                                  itemBuilder: (context) {
                                                    if (tx.status ==
                                                        TransactionStatus
                                                            .deleted) {
                                                      return [
                                                        const PopupMenuItem(
                                                          value: 'restore',
                                                          child: ListTile(
                                                            dense: true,
                                                            leading: Icon(
                                                              Icons
                                                                  .restore_rounded,
                                                              color:
                                                                  Colors.blue,
                                                              size: 20,
                                                            ),
                                                            title: Text(
                                                              'Khôi phục',
                                                              style: TextStyle(
                                                                color:
                                                                    Colors.blue,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                        const PopupMenuItem(
                                                          value: 'hard_delete',
                                                          child: ListTile(
                                                            dense: true,
                                                            leading: Icon(
                                                              Icons
                                                                  .delete_forever_rounded,
                                                              color: Colors.red,
                                                              size: 20,
                                                            ),
                                                            title: Text(
                                                              'Xóa vĩnh viễn',
                                                              style: TextStyle(
                                                                color:
                                                                    Colors.red,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ];
                                                    } else {
                                                      return [
                                                        const PopupMenuItem(
                                                          value: 'edit',
                                                          child: ListTile(
                                                            dense: true,
                                                            leading: Icon(
                                                              Icons
                                                                  .edit_rounded,
                                                              size: 20,
                                                            ),
                                                            title: Text('Sửa'),
                                                          ),
                                                        ),
                                                        const PopupMenuItem(
                                                          value: 'delete',
                                                          child: ListTile(
                                                            dense: true,
                                                            leading: Icon(
                                                              Icons
                                                                  .delete_rounded,
                                                              color: Colors.red,
                                                              size: 20,
                                                            ),
                                                            title: Text(
                                                              'Xóa',
                                                              style: TextStyle(
                                                                color:
                                                                    Colors.red,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ];
                                                    }
                                                  },
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: currentRole.canEditTransactions
          ? ScaleOnTap(
              onTap: () {
                context.go('/transactions/form');
              },
              child: FloatingActionButton(
                onPressed: null,
                backgroundColor: primaryColor,
                child: const Icon(Icons.add, color: Colors.white, size: 28),
              ),
            )
          : null,
    );
  }

  bool _isWithinPeriod(DateTime date) {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'today':
        return date.year == now.year &&
            date.month == now.month &&
            date.day == now.day;
      case 'month':
        return date.year == now.year && date.month == now.month;
      case 'year':
        return date.year == now.year;
      case 'custom':
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
        return date.isAfter(start.subtract(const Duration(seconds: 1))) &&
            date.isBefore(end.add(const Duration(seconds: 1)));
      case 'all':
      default:
        return true;
    }
  }

  String _getPeriodTitle(String prefix) {
    switch (_selectedPeriod) {
      case 'today':
        return '$prefix Hôm Nay';
      case 'month':
        return '$prefix Tháng Này';
      case 'year':
        return '$prefix Năm Nay';
      case 'custom':
        if (_customDateRange != null) {
          final df = DateFormat('dd/MM');
          return '$prefix (${df.format(_customDateRange!.start)} - ${df.format(_customDateRange!.end)})';
        }
        return '$prefix Tùy Chọn';
      case 'all':
      default:
        return prefix;
    }
  }

  Widget _buildPeriodTab(String id, String label) {
    final isSelected = _selectedPeriod == id;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedPeriod = id;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF00D09E) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 11,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
