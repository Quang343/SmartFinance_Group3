import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_finance/domain/entities/transaction_entity.dart';
import 'package:smart_finance/domain/repositories/transaction_repository.dart';
import 'package:smart_finance/core/providers/app_providers.dart';
import 'package:smart_finance/features/transactions/providers/transaction_provider.dart';

class FakeTransactionRepository extends Mock implements TransactionRepository {}

void main() {
  late FakeTransactionRepository fake;
  late ProviderContainer container;
  final income = TransactionEntity(id: '1', title: 'Test 1', amount: 10, type: TransactionType.income, categoryId: 'c', transactionDate: DateTime(2026), status: TransactionStatus.confirmed, createdAt: DateTime(2026), updatedAt: DateTime(2026));
  final expense = TransactionEntity(id: '2', title: 'Test 2', amount: 20, type: TransactionType.expense, categoryId: 'c', transactionDate: DateTime(2026), status: TransactionStatus.confirmed, createdAt: DateTime(2026), updatedAt: DateTime(2026));

  setUp(() {
    fake = FakeTransactionRepository();
    container = ProviderContainer(overrides: [transactionRepositoryProvider.overrideWithValue(fake)]);
    registerFallbackValue(TransactionType.income);
  });
  tearDown(() => container.dispose());

  test('allTransactionsProvider trả toàn bộ', () async {
    when(() => fake.getAll()).thenAnswer((_) async => [income, expense]);
    final r = await container.read(allTransactionsProvider.future);
    expect(r.length, 2);
  });

  test('incomeTransactionsProvider chỉ trả thu', () async {
    when(() => fake.getByType(TransactionType.income)).thenAnswer((_) async => [income]);
    final r = await container.read(incomeTransactionsProvider.future);
    expect(r.first.type, TransactionType.income);
  });

  test('expenseTransactionsProvider chỉ trả chi', () async {
    when(() => fake.getByType(TransactionType.expense)).thenAnswer((_) async => [expense]);
    final r = await container.read(expenseTransactionsProvider.future);
    expect(r.first.type, TransactionType.expense);
  });

  test('transactionByIdProvider(id) gọi getById', () async {
    when(() => fake.getById('1')).thenAnswer((_) async => income);
    final r = await container.read(transactionByIdProvider('1').future);
    expect(r?.id, '1');
  });
}
