import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../domain/entities/report_summary_entity.dart';
import '../../../domain/entities/transaction_entity.dart';

final dashboardProvider = FutureProvider<ReportSummaryEntity>((ref) async {
  final repo = ref.watch(transactionRepositoryProvider);
  final List<TransactionEntity> transactions = await repo.getConfirmed();
  
  int income = 0;
  int expense = 0;
  for (final t in transactions) {
    if (t.type == TransactionType.income) {
      income += t.amount;
    } else {
      expense += t.amount;
    }
  }
  
  return ReportSummaryEntity(
    totalIncome: income,
    totalExpense: expense,
    netCashFlow: income - expense,
    expenseRatio: income == 0 ? 0.0 : (expense / income) * 100,
    transactionCount: transactions.length,
    periodStart: DateTime.now(),
    periodEnd: DateTime.now(),
  );
});
