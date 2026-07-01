import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_finance/domain/repositories/transaction_repository.dart';
import 'package:smart_finance/domain/entities/transaction_entity.dart';

class FakeTransactionRepository implements TransactionRepository {
  @override
  Future<void> cleanupDeletedTransactions() async {}

  @override
  Future<void> create(TransactionEntity transaction) async {}

  @override
  Future<List<TransactionEntity>> getAll() async => [];

  @override
  Future<List<TransactionEntity>> getByDateRange(DateTime start, DateTime end) async => [];

  @override
  Future<TransactionEntity?> getById(String id) async => null;

  @override
  Future<List<TransactionEntity>> getByType(TransactionType type) async => [];

  @override
  Future<List<TransactionEntity>> getConfirmed() async => [];

  @override
  Future<void> hardDelete(String id) async {}

  @override
  Future<void> restore(String id) async {}

  @override
  Future<void> softDelete(String id) async {}

  @override
  Future<void> update(TransactionEntity transaction) async {}
}

Widget createTestApp(Widget child, {List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      home: child,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.system,
    ),
  );
}
