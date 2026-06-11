import '../../domain/entities/category_entity.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/category_repository.dart';
import '../datasources/local_category_datasource.dart';
import '../mappers/category_mapper.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final LocalCategoryDataSource _dataSource;

  CategoryRepositoryImpl(this._dataSource);

  @override
  Future<List<CategoryEntity>> getAll() async {
    final models = await _dataSource.getAll();
    return models.map(CategoryMapper.toEntity).toList();
  }

  @override
  Future<List<CategoryEntity>> getActive() async {
    final models = await _dataSource.getActive();
    return models.map(CategoryMapper.toEntity).toList();
  }

  @override
  Future<List<CategoryEntity>> getByType(TransactionType type) async {
    final models = await _dataSource.getByType(type.name);
    return models.map(CategoryMapper.toEntity).toList();
  }

  @override
  Future<CategoryEntity?> getById(String id) async {
    final model = await _dataSource.getByUid(id);
    return model != null ? CategoryMapper.toEntity(model) : null;
  }

  @override
  Future<void> create(CategoryEntity category) async {
    final model = CategoryMapper.toIsarModel(category);
    await _dataSource.create(model);
  }

  @override
  Future<void> update(CategoryEntity category) async {
    final model = CategoryMapper.toIsarModel(category);
    await _dataSource.update(model);
  }

  @override
  Future<void> deactivate(String id) async {
    await _dataSource.deactivate(id);
  }
}
