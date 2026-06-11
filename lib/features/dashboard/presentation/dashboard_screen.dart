import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_finance/core/providers/app_providers.dart';
import 'package:smart_finance/domain/entities/transaction_entity.dart';
import 'package:uuid/uuid.dart';

int _testCounter = 0;

final tempTransactionsProvider = FutureProvider((ref) async {
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.getAll(); // Fetch all transactions from Isar
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(tempTransactionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Seed Data (Isar)')),
      body: transactionsAsync.when(
        data: (transactions) {
          if (transactions.isEmpty) {
            return const Center(child: Text('No data found in Isar.'));
          }
          return ListView.builder(
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final tx = transactions[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: tx.type.name == 'income' ? Colors.green : Colors.red,
                  child: Icon(
                    tx.type.name == 'income' ? Icons.arrow_downward : Icons.arrow_upward,
                    color: Colors.white,
                  ),
                ),
                title: Text(tx.note ?? 'No note'),
                subtitle: Text('Category: \${tx.categoryId} • Status: \${tx.status.name}'),
                trailing: Text(
                  '\${tx.amount} VND',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: \$err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          _testCounter++;
          final repo = ref.read(transactionRepositoryProvider);
          await repo.create(
            TransactionEntity(
              id: const Uuid().v4(),
              amount: 500000 + (_testCounter * 1000), // Change amount slightly
              categoryId: 'cat_test',
              transactionDate: DateTime.now(),
              type: TransactionType.income,
              note: 'Test Income $_testCounter',
              status: TransactionStatus.confirmed,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
          // Refresh the list
          ref.invalidate(tempTransactionsProvider);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
