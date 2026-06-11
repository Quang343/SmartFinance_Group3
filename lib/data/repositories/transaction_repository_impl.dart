import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../datasources/local_transaction_datasource.dart';
import '../mappers/transaction_mapper.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final LocalTransactionDataSource _dataSource;

  TransactionRepositoryImpl(this._dataSource);

  @override
  Future<List<TransactionEntity>> getAll() async {
    final models = await _dataSource.getAll();
    return models.map(TransactionMapper.toEntity).toList();
  }

  @override
  Future<List<TransactionEntity>> getConfirmed() async {
    final models = await _dataSource.getConfirmed();
    return models.map(TransactionMapper.toEntity).toList();
  }

  @override
  Future<List<TransactionEntity>> getByDateRange(DateTime start, DateTime end) async {
    final models = await _dataSource.getByDateRange(start, end);
    return models.map(TransactionMapper.toEntity).toList();
  }

  @override
  Future<List<TransactionEntity>> getByType(TransactionType type) async {
    final models = await _dataSource.getByType(type.name);
    return models.map(TransactionMapper.toEntity).toList();
  }

  @override
  Future<TransactionEntity?> getById(String id) async {
    final model = await _dataSource.getByUid(id);
    return model != null ? TransactionMapper.toEntity(model) : null;
  }

  @override
  Future<void> create(TransactionEntity transaction) async {
    final model = TransactionMapper.toIsarModel(transaction);
    await _dataSource.create(model);
  }

  @override
  Future<void> update(TransactionEntity transaction) async {
    final model = TransactionMapper.toIsarModel(transaction);
    await _dataSource.update(model);
  }

  @override
  Future<void> softDelete(String id) async {
    await _dataSource.softDelete(id);
  }
}
