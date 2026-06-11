import '../entities/transaction_entity.dart';

class CashFlowCalculator {
  static int calculateTotalIncome(List<TransactionEntity> transactions) {
    return transactions
        .where((t) => t.type == TransactionType.income && t.status == TransactionStatus.confirmed)
        .fold(0, (sum, t) => sum + t.amount);
  }

  static int calculateTotalExpense(List<TransactionEntity> transactions) {
    return transactions
        .where((t) => t.type == TransactionType.expense && t.status == TransactionStatus.confirmed)
        .fold(0, (sum, t) => sum + t.amount);
  }

  static int calculateNetCashFlow(int totalIncome, int totalExpense) {
    return totalIncome - totalExpense;
  }

  static double calculateExpenseRatio(int totalIncome, int totalExpense) {
    if (totalIncome == 0) return 0.0;
    return (totalExpense / totalIncome) * 100;
  }
}
