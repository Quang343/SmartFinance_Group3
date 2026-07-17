import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_finance/domain/entities/transaction_entity.dart';
import 'package:smart_finance/domain/repositories/transaction_repository.dart';
import 'package:smart_finance/core/providers/app_providers.dart';
import 'package:smart_finance/features/reports/providers/report_provider.dart';

class FakeTransactionRepository extends Mock implements TransactionRepository {}

void main() {
  late FakeTransactionRepository fake;
  late ProviderContainer container;
  final txns = [
    TransactionEntity(id: '1', amount: 1000, type: TransactionType.income, categoryId: 'c', transactionDate: DateTime(2026), status: TransactionStatus.confirmed, createdAt: DateTime(2026), updatedAt: DateTime(2026)),
    TransactionEntity(id: '2', amount: 400, type: TransactionType.expense, categoryId: 'c', transactionDate: DateTime(2026), status: TransactionStatus.confirmed, createdAt: DateTime(2026), updatedAt: DateTime(2026)),
    TransactionEntity(id: '3', amount: 999, type: TransactionType.income, categoryId: 'c', transactionDate: DateTime(2026), status: TransactionStatus.draft, createdAt: DateTime(2026), updatedAt: DateTime(2026)),
  ];

  setUp(() {
    fake = FakeTransactionRepository();
    container = ProviderContainer(overrides: [transactionRepositoryProvider.overrideWithValue(fake)]);
  });
  tearDown(() => container.dispose());

  test('reportSummaryProvider tính từ confirmed qua ReportCalculator', () async {
    when(() => fake.getConfirmed()).thenAnswer((_) async => txns);
    final summary = await container.read(reportSummaryProvider('all').future);
    expect(summary.totalIncome, 1000);
    expect(summary.totalExpense, 400);
    expect(summary.netCashFlow, 600);
    expect(summary.transactionCount, 2);
  });
}
