import '../entities/transaction_entity.dart';
import '../entities/report_summary_entity.dart';

class ReportCalculator {
  static ReportSummaryEntity calculateSummary(
    List<TransactionEntity> transactions,
    DateTime start,
    DateTime end,
  ) {
    final confirmed = transactions.where((t) => t.status == TransactionStatus.confirmed);

    final totalIncome = confirmed
        .where((t) => t.type == TransactionType.income)
        .fold(0, (sum, t) => sum + t.amount);

    final totalExpense = confirmed
        .where((t) => t.type == TransactionType.expense)
        .fold(0, (sum, t) => sum + t.amount);

    final netCashFlow = totalIncome - totalExpense;
    final expenseRatio = totalIncome == 0 ? 0.0 : (totalExpense / totalIncome) * 100;

    return ReportSummaryEntity(
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      netCashFlow: netCashFlow,
      expenseRatio: expenseRatio,
      transactionCount: confirmed.length,
      periodStart: start,
      periodEnd: end,
    );
  }
}
