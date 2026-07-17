import 'package:flutter_test/flutter_test.dart';
import 'package:smart_finance/domain/entities/transaction_entity.dart';
import 'package:smart_finance/domain/services/report_calculator.dart';

TransactionEntity _tx(int amount, TransactionType type, TransactionStatus status) =>
    TransactionEntity(
      id: 'id',
      amount: amount,
      type: type,
      categoryId: 'c',
      transactionDate: DateTime(2026, 1, 1),
      status: status,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

void main() {
  final start = DateTime(2026, 1, 1);
  final end = DateTime(2026, 12, 31);

  test('tính đúng thu, chi, dòng tiền ròng từ giao dịch confirmed', () {
    final txns = [
      _tx(1000, TransactionType.income, TransactionStatus.confirmed),
      _tx(300, TransactionType.expense, TransactionStatus.confirmed),
      _tx(500, TransactionType.income, TransactionStatus.draft), // bị bỏ qua
      _tx(200, TransactionType.expense, TransactionStatus.deleted), // bị bỏ qua
    ];
    final summary = ReportCalculator.calculateSummary(txns, start, end);
    expect(summary.totalIncome, 1000);
    expect(summary.totalExpense, 300);
    expect(summary.netCashFlow, 700);
    expect(summary.transactionCount, 2); // chỉ confirmed
  });

  test('expenseRatio = 0 khi không có thu', () {
    final txns = [_tx(100, TransactionType.expense, TransactionStatus.confirmed)];
    final summary = ReportCalculator.calculateSummary(txns, start, end);
    expect(summary.expenseRatio, 0.0);
    expect(summary.netCashFlow, -100);
  });
}
