import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../domain/entities/transaction_entity.dart';

final allTransactionsProvider = FutureProvider.autoDispose<List<TransactionEntity>>((ref) async {
  return ref.watch(transactionRepositoryProvider).getAll();
});

final expenseTransactionsProvider = FutureProvider.autoDispose<List<TransactionEntity>>((ref) async {
  return ref.watch(transactionRepositoryProvider).getByType(TransactionType.expense);
});

final incomeTransactionsProvider = FutureProvider.autoDispose<List<TransactionEntity>>((ref) async {
  return ref.watch(transactionRepositoryProvider).getByType(TransactionType.income);
});

final transactionByIdProvider = FutureProvider.autoDispose.family<TransactionEntity?, String>((ref, id) async {
  return ref.watch(transactionRepositoryProvider).getById(id);
});
