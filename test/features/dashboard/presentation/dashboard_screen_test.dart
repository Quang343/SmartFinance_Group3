import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:smart_finance/core/providers/role_provider.dart';
import 'package:smart_finance/core/providers/transaction_providers.dart';
import 'package:smart_finance/core/providers/category_providers.dart';
import 'package:smart_finance/core/providers/app_providers.dart';
import 'package:smart_finance/domain/entities/transaction_entity.dart';
import 'package:smart_finance/domain/entities/category_entity.dart';
import 'package:smart_finance/features/dashboard/presentation/dashboard_screen.dart';

import '../../../helpers/test_utils.dart';

void main() {
  group('DashboardScreen Widget Tests', () {
    testWidgets('Expense Accountant sees Expense logic (Ngân sách còn lại)', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(
        const DashboardScreen(),
        overrides: [
          roleProvider.overrideWithValue(UserRole.expenseAccountant),
          transactionRepositoryProvider.overrideWithValue(FakeTransactionRepository()),
          expenseTransactionsProvider.overrideWith((ref) => Future.value(<TransactionEntity>[])),
          allCategoriesProvider.overrideWith((ref) => Future.value(<CategoryEntity>[])),
        ],
      ));

      await tester.pumpAndSettle();

      expect(find.text('Phân tích Ngân sách'), findsOneWidget);
      expect(find.text('Ngân sách còn lại'), findsOneWidget);
      expect(find.text('Hạn mức chi tiêu'), findsNothing);
    });

    testWidgets('Revenue Accountant sees Revenue logic (Hạn mức chi tiêu)', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(
        const DashboardScreen(),
        overrides: [
          roleProvider.overrideWithValue(UserRole.revenueAccountant),
          transactionRepositoryProvider.overrideWithValue(FakeTransactionRepository()),
          incomeTransactionsProvider.overrideWith((ref) => Future.value(<TransactionEntity>[])),
          allCategoriesProvider.overrideWith((ref) => Future.value(<CategoryEntity>[])),
        ],
      ));

      await tester.pumpAndSettle();

      expect(find.text('Hạn mức chi tiêu'), findsOneWidget);
      expect(find.textContaining('Doanh thu'), findsOneWidget);
      expect(find.text('Phân tích Ngân sách'), findsNothing);
    });

    testWidgets('Shows loading indicator when async value is loading', (WidgetTester tester) async {
      final transactionsCompleter = Completer<List<TransactionEntity>>();
      final categoriesCompleter = Completer<List<CategoryEntity>>();

      await tester.pumpWidget(createTestApp(
        const DashboardScreen(),
        overrides: [
          roleProvider.overrideWithValue(UserRole.expenseAccountant),
          transactionRepositoryProvider.overrideWithValue(FakeTransactionRepository()),
          expenseTransactionsProvider.overrideWith((ref) => transactionsCompleter.future),
          allCategoriesProvider.overrideWith((ref) => categoriesCompleter.future),
        ],
      ));

      await tester.pump();
      
      expect(find.byType(ClipOval), findsWidgets);

      transactionsCompleter.complete(<TransactionEntity>[]);
      categoriesCompleter.complete(<CategoryEntity>[]);

      await tester.pumpAndSettle();
    });
  });
}
