import '../entities/transaction_entity.dart';

abstract class TransactionRepository {
  Future<List<TransactionEntity>> getAll();
  Future<List<TransactionEntity>> getConfirmed();
  Future<List<TransactionEntity>> getByDateRange(DateTime start, DateTime end);
  Future<List<TransactionEntity>> getByType(TransactionType type);
  Future<TransactionEntity?> getById(String id);
  Future<void> create(TransactionEntity transaction);
  Future<void> update(TransactionEntity transaction);
  Future<void> softDelete(String id);
  Future<void> hardDelete(String id);
  Future<void> restore(String id);
  Future<void> cleanupDeletedTransactions();
}
