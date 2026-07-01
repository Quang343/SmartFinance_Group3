import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/transaction_entity.dart';
import 'app_providers.dart';

/// Provider lấy tất cả danh sách giao dịch chi phí (Expense Transactions)
/// Có thể tự động refresh khi invalidate
final expenseTransactionsProvider = FutureProvider.autoDispose<List<TransactionEntity>>((ref) async {
  final repo = ref.watch(transactionRepositoryProvider);
  // Sử dụng query getByType để Isar xử lý việc filter trực tiếp dưới DB thay vì kéo tất cả lên RAM
  return await repo.getByType(TransactionType.expense);
});

/// Provider lấy tất cả danh sách giao dịch doanh thu (Income Transactions)
final incomeTransactionsProvider = FutureProvider.autoDispose<List<TransactionEntity>>((ref) async {
  final repo = ref.watch(transactionRepositoryProvider);
  return await repo.getByType(TransactionType.income);
});

/// Provider lấy toàn bộ giao dịch (Dành cho Finance Manager)
final allTransactionsProvider = FutureProvider.autoDispose<List<TransactionEntity>>((ref) async {
  final repo = ref.watch(transactionRepositoryProvider);
  return await repo.getAll();
});
