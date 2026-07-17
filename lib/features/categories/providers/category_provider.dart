import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../domain/entities/category_entity.dart';
import '../../../domain/entities/transaction_entity.dart';

final allCategoriesProvider = FutureProvider.autoDispose<List<CategoryEntity>>((ref) async {
  return ref.watch(categoryRepositoryProvider).getAll();
});

final activeCategoriesProvider = FutureProvider.autoDispose<List<CategoryEntity>>((ref) async {
  return ref.watch(categoryRepositoryProvider).getActive();
});

final categoriesByTypeProvider =
    FutureProvider.autoDispose.family<List<CategoryEntity>, TransactionType>((ref, type) async {
  return ref.watch(categoryRepositoryProvider).getByType(type);
});
