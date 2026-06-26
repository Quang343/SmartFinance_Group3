import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/role_provider.dart';
import '../../../core/providers/app_providers.dart';
import '../../../domain/entities/transaction_entity.dart';
import '../../../domain/entities/category_entity.dart';
import '../../../core/widgets/scale_on_tap.dart';

class TransactionListScreen extends ConsumerStatefulWidget {
  const TransactionListScreen({super.key});

  @override
  ConsumerState<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends ConsumerState<TransactionListScreen> {
  String _searchQuery = '';
  late Future<List<dynamic>> _dataFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadData();
  }

  void _loadData() {
    final transactionsAsync = ref.read(transactionRepositoryProvider);
    final categoriesAsync = ref.read(categoryRepositoryProvider);
    _dataFuture = Future.wait([
      transactionsAsync.getAll(),
      categoriesAsync.getAll(),
    ]);
  }

  void _refreshData() {
    setState(() {
      _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentRole = ref.watch(roleProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
    final dateFormatter = DateFormat('dd/MM/yyyy');
    final transactionsAsync = ref.watch(transactionRepositoryProvider);
    final primaryColor = const Color(0xFF00D09E);
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF06150F) : const Color(0xFFF4FAF7),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF06150F) : const Color(0xFFF4FAF7),
        elevation: 0,
        centerTitle: false,
        titleSpacing: 20,
        title: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [
                Color(0xFF00D09E),
                Color(0xFF34D399),
              ],
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
          Center(
            child: ScaleOnTap(
              onTap: _refreshData,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0D281E) : Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    if (!isDark)
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                  ],
                  border: Border.all(
                    color: isDark ? const Color(0xFF1E3A2F) : const Color(0xFFEDF2F7),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.refresh_rounded,
                  color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF00D09E),
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Center(
              child: ScaleOnTap(
                onTap: () => context.push('/notifications'),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0D281E) : Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      if (!isDark)
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                    ],
                    border: Border.all(
                      color: isDark ? const Color(0xFF1E3A2F) : const Color(0xFFEDF2F7),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.notifications_none_rounded,
                    color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF00D09E),
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF00D09E),
              ),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Lỗi: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final allTxs = (snapshot.data?[0] as List<TransactionEntity>?) ?? [];
          final allCats = (snapshot.data?[1] as List<CategoryEntity>?) ?? [];
          final catMap = {for (var c in allCats) c.id: c};

          // Filter by role scope
          var list = allTxs;
          if (currentRole == UserRole.expenseAccountant) {
            list = list.where((tx) => tx.type == TransactionType.expense).toList();
          } else if (currentRole == UserRole.revenueAccountant) {
            list = list.where((tx) => tx.type == TransactionType.income).toList();
          }

          // Filter by search query
          if (_searchQuery.isNotEmpty) {
            list = list.where((tx) {
              final note = (tx.note ?? '').toLowerCase();
              final catName = (catMap[tx.categoryId]?.name ?? '').toLowerCase();
              return note.contains(_searchQuery) || catName.contains(_searchQuery);
            }).toList();
          }

          // Calculate overview stats
          final totalIncome = list
              .where((tx) => tx.type == TransactionType.income)
              .fold<double>(0.0, (sum, item) => sum + item.amount);
          final totalExpense = list
              .where((tx) => tx.type == TransactionType.expense)
              .fold<double>(0.0, (sum, item) => sum + item.amount);
          final netBalance = totalIncome - totalExpense;

          return Column(
            children: [
              // Header balance layout matching the user request
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    // Total Balance Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0D251C) : Colors.white,
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
                          color: isDark ? const Color(0xFF1E3A2F) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.account_balance_wallet_rounded,
                                size: 16,
                                color: isDark ? const Color(0xFF00D09E).withOpacity(0.7) : const Color(0xFF093021).withOpacity(0.6),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Tổng Số Dư',
                                style: TextStyle(
                                  color: isDark ? Colors.white70 : Colors.black54,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.5,
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
                                color: isDark ? const Color(0xFF00D09E) : const Color(0xFF093021),
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Income & Expense Side by Side Cards
                    Row(
                      children: [
                        // Income Card
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0D251C) : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark ? const Color(0xFF1E3A2F) : const Color(0xFFE2E8F0),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isDark 
                                      ? Colors.black.withOpacity(0.15) 
                                      : Colors.black.withOpacity(0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
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
                                        color: const Color(0xFF00D09E).withOpacity(0.12),
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
                                      'Thu nhập',
                                      style: TextStyle(
                                        color: isDark ? Colors.white70 : Colors.black54,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    currencyFormatter.format(totalIncome),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Color(0xFF00D09E),
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Expense Card
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0D251C) : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark ? const Color(0xFF1E3A2F) : const Color(0xFFE2E8F0),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isDark 
                                      ? Colors.black.withOpacity(0.15) 
                                      : Colors.black.withOpacity(0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
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
                                        color: const Color(0xFFEF4444).withOpacity(0.12),
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
                                      'Chi tiêu',
                                      style: TextStyle(
                                        color: isDark ? Colors.white70 : Colors.black54,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    currencyFormatter.format(totalExpense),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Color(0xFFEF4444),
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm theo ghi chú, danh mục...',
                    hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
                    prefixIcon: Icon(Icons.search_rounded, color: isDark ? Colors.white38 : Colors.black38),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF0D251C) : Colors.white,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark ? const Color(0xFF1E3A2F) : const Color(0xFFE2E8F0),
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
                    : ListView.builder(
                        itemCount: list.length,
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                        itemBuilder: (context, index) {
                          final tx = list[index];
                          final isIncome = tx.type == TransactionType.income;
                          final cat = catMap[tx.categoryId];
                          final catName = cat?.name ?? 'Chưa phân loại';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0E2219) : Colors.white,
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
                                color: isDark ? const Color(0xFF1A382B) : const Color(0xFFEDF2F7),
                                width: 1,
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () {
                                  if (currentRole.canEditTransactions) {
                                    context.go('/transactions/form', extra: {'transactionId': tx.id});
                                  }
                                },
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  leading: Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: isIncome 
                                          ? const Color(0x1500D09E) 
                                          : const Color(0x15EF4444),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                                      color: isIncome ? const Color(0xFF00D09E) : const Color(0xFFEF4444),
                                      size: 18,
                                    ),
                                  ),
                                  title: Text(
                                    tx.note ?? 'Không có ghi chú',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isDark 
                                                ? const Color(0xFF152F23) 
                                                : const Color(0xFFEDF2F7),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            catName,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: isDark ? const Color(0xFF00D09E) : Colors.black54,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          dateFormatter.format(tx.transactionDate),
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: isDark ? Colors.white38 : Colors.black38,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '${isIncome ? '+' : '-'}${currencyFormatter.format(tx.amount)}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isIncome ? const Color(0xFF00D09E) : const Color(0xFFEF4444),
                                          fontSize: 14,
                                        ),
                                      ),
                                      if (currentRole.canEditTransactions) ...[
                                        const SizedBox(width: 4),
                                        PopupMenuButton<String>(
                                          icon: Icon(
                                            Icons.more_vert_rounded,
                                            size: 18,
                                            color: isDark ? Colors.white30 : Colors.black38,
                                          ),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          onSelected: (action) async {
                                            if (action == 'edit') {
                                              context.go('/transactions/form', extra: {'transactionId': tx.id});
                                            } else if (action == 'delete') {
                                              await transactionsAsync.softDelete(tx.id);
                                              setState(() {});
                                            }
                                          },
                                          itemBuilder: (context) => [
                                            const PopupMenuItem(
                                              value: 'edit',
                                              child: ListTile(
                                                dense: true,
                                                leading: Icon(Icons.edit_rounded, size: 20),
                                                title: Text('Sửa'),
                                              ),
                                            ),
                                            const PopupMenuItem(
                                              value: 'delete',
                                              child: ListTile(
                                                dense: true,
                                                leading: Icon(Icons.delete_rounded, color: Colors.red, size: 20),
                                                title: Text('Xóa', style: TextStyle(color: Colors.red)),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
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
}
