import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/role_provider.dart';
import '../../../core/providers/app_providers.dart';
import '../../../domain/entities/transaction_entity.dart';
import '../../../core/widgets/scale_on_tap.dart';

class TransactionListScreen extends ConsumerStatefulWidget {
  const TransactionListScreen({super.key});

  @override
  ConsumerState<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends ConsumerState<TransactionListScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final currentRole = ref.watch(roleProvider);
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final dateFormatter = DateFormat('dd/MM/yyyy');
    final primaryColor = Theme.of(context).colorScheme.primary;
    
    final transactionsAsync = ref.watch(transactionRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          currentRole == UserRole.financeManager
              ? 'Dòng tiền doanh nghiệp'
              : currentRole == UserRole.expenseAccountant
                  ? 'Giao dịch Chi phí'
                  : 'Giao dịch Doanh thu',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tìm kiếm theo ghi chú...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primaryColor, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.toLowerCase();
                });
              },
            ),
          ),
          
          Expanded(
            child: FutureBuilder<List<TransactionEntity>>(
              future: transactionsAsync.getAll(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Lỗi: ${snapshot.error}'));
                }
                
                var list = snapshot.data ?? [];
                
                // Filter by role scope
                if (currentRole == UserRole.expenseAccountant) {
                  list = list.where((tx) => tx.type == TransactionType.expense).toList();
                } else if (currentRole == UserRole.revenueAccountant) {
                  list = list.where((tx) => tx.type == TransactionType.income).toList();
                }

                // Filter by search query
                if (_searchQuery.isNotEmpty) {
                  list = list.where((tx) => (tx.note ?? '').toLowerCase().contains(_searchQuery)).toList();
                }

                if (list.isEmpty) {
                  return const Center(child: Text('Không tìm thấy giao dịch nào.'));
                }

                return ListView.builder(
                  itemCount: list.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemBuilder: (context, index) {
                    final tx = list[index];
                    final isIncome = tx.type == TransactionType.income;

                    return ScaleOnTap(
                      onTap: () {
                        if (currentRole.canEditTransactions) {
                          context.go('/transactions/form', extra: {'transactionId': tx.id});
                        }
                      },
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isIncome ? Colors.green.shade50 : Colors.red.shade50,
                            child: Icon(
                              isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                              color: isIncome ? Colors.green : Colors.red,
                            ),
                          ),
                          title: Text(
                            tx.note ?? 'Không có ghi chú',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Danh mục: ${tx.categoryId.replaceAll('cat_', '').toUpperCase()} • ${dateFormatter.format(tx.transactionDate)}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${isIncome ? '+' : '-'}${currencyFormatter.format(tx.amount)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isIncome ? Colors.green : Colors.red,
                                  fontSize: 16,
                                ),
                              ),
                              if (currentRole.canEditTransactions) ...[
                                const SizedBox(width: 8),
                                PopupMenuButton<String>(
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
                                        leading: Icon(Icons.edit),
                                        title: Text('Sửa'),
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: ListTile(
                                        leading: Icon(Icons.delete, color: Colors.red),
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
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: currentRole.canEditTransactions
          ? ScaleOnTap(
              onTap: () {
                context.go('/transactions/form');
              },
              child: FloatingActionButton(
                onPressed: null,
                backgroundColor: primaryColor,
                child: const Icon(Icons.add, color: Colors.white),
              ),
            )
          : null,
    );
  }
}
