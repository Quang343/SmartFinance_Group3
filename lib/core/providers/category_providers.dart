import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/category_entity.dart';
import 'app_providers.dart';

/// Provider lấy tất cả danh sách danh mục
final allCategoriesProvider = FutureProvider.autoDispose<List<CategoryEntity>>((ref) async {
  final repo = ref.watch(categoryRepositoryProvider);
  return await repo.getAll();
});
