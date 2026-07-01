import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

import 'package:smart_finance/core/providers/role_provider.dart';
import 'package:smart_finance/core/providers/transaction_providers.dart';
import 'package:smart_finance/core/providers/category_providers.dart';
import 'package:smart_finance/core/providers/app_providers.dart';
import 'package:smart_finance/domain/entities/transaction_entity.dart';
import 'package:smart_finance/domain/entities/category_entity.dart';
import 'package:smart_finance/features/transactions/presentation/transaction_list_screen.dart';

import '../../../helpers/test_utils.dart';

void main() {
  group('TransactionListScreen Widget Tests', () {
    testWidgets('Expense Accountant sees Giao dịch Chi phí title', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(
        const TransactionListScreen(),
        overrides: [
          roleProvider.overrideWithValue(UserRole.expenseAccountant),
          transactionRepositoryProvider.overrideWithValue(FakeTransactionRepository()),
          expenseTransactionsProvider.overrideWith((ref) => Future.value(<TransactionEntity>[])),
          allCategoriesProvider.overrideWith((ref) => Future.value(<CategoryEntity>[])),
        ],
      ));

      await tester.pumpAndSettle();

      expect(find.text('Giao dịch Chi phí'), findsOneWidget);
      expect(find.text('Giao dịch Doanh thu'), findsNothing);
      expect(find.byType(FloatingActionButton), findsOneWidget); // Can add transactions
    });

    testWidgets('Revenue Accountant sees Giao dịch Doanh thu title', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(
        const TransactionListScreen(),
        overrides: [
          roleProvider.overrideWithValue(UserRole.revenueAccountant),
          transactionRepositoryProvider.overrideWithValue(FakeTransactionRepository()),
          incomeTransactionsProvider.overrideWith((ref) => Future.value(<TransactionEntity>[])),
          allCategoriesProvider.overrideWith((ref) => Future.value(<CategoryEntity>[])),
        ],
      ));

      await tester.pumpAndSettle();

      expect(find.text('Giao dịch Doanh thu'), findsOneWidget);
      expect(find.text('Giao dịch Chi phí'), findsNothing);
      expect(find.byType(FloatingActionButton), findsOneWidget); // Can add transactions
    });

    testWidgets('Shows loading indicator when async value is loading', (WidgetTester tester) async {
      final transactionsCompleter = Completer<List<TransactionEntity>>();
      final categoriesCompleter = Completer<List<CategoryEntity>>();

      await tester.pumpWidget(createTestApp(
        const TransactionListScreen(),
        overrides: [
          roleProvider.overrideWithValue(UserRole.expenseAccountant),
          transactionRepositoryProvider.overrideWithValue(FakeTransactionRepository()),
          expenseTransactionsProvider.overrideWith((ref) => transactionsCompleter.future),
          allCategoriesProvider.overrideWith((ref) => categoriesCompleter.future),
        ],
      ));

      await tester.pump(); // Start frame

      expect(find.byType(ClipOval), findsWidgets); 

      transactionsCompleter.complete(<TransactionEntity>[]);
      categoriesCompleter.complete(<CategoryEntity>[]);

      await tester.pumpAndSettle();
    });
  });
}
