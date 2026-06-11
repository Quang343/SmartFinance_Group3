import '../entities/category_entity.dart';
import '../entities/transaction_entity.dart';

abstract class CategoryRepository {
  Future<List<CategoryEntity>> getAll();
  Future<List<CategoryEntity>> getActive();
  Future<List<CategoryEntity>> getByType(TransactionType type);
  Future<CategoryEntity?> getById(String id);
  Future<void> create(CategoryEntity category);
  Future<void> update(CategoryEntity category);
  Future<void> deactivate(String id);
}
