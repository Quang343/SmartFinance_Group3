class ReportSummaryEntity {
  final int totalIncome;
  final int totalExpense;
  final int netCashFlow;
  final double expenseRatio;
  final int transactionCount;
  final String? topExpenseCategoryName;
  final DateTime periodStart;
  final DateTime periodEnd;

  const ReportSummaryEntity({
    required this.totalIncome,
    required this.totalExpense,
    required this.netCashFlow,
    required this.expenseRatio,
    required this.transactionCount,
    this.topExpenseCategoryName,
    required this.periodStart,
    required this.periodEnd,
  });
}
