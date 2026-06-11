import '../entities/transaction_entity.dart';
import '../entities/report_summary_entity.dart';

class ReportCalculator {
  static ReportSummaryEntity calculateSummary(
    List<TransactionEntity> transactions,
    DateTime start,
    DateTime end,
  ) {
    return ReportSummaryEntity(
      totalIncome: 0,
      totalExpense: 0,
      netCashFlow: 0,
      expenseRatio: 0.0,
      transactionCount: transactions.length,
      periodStart: start,
      periodEnd: end,
    );
  }
}
