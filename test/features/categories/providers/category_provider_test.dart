import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_finance/domain/entities/category_entity.dart';
import 'package:smart_finance/domain/entities/transaction_entity.dart';
import 'package:smart_finance/domain/repositories/category_repository.dart';
import 'package:smart_finance/core/providers/app_providers.dart';
import 'package:smart_finance/features/categories/providers/category_provider.dart';

class FakeCategoryRepository extends Mock implements CategoryRepository {}

CategoryEntity _cat(String id, String name, bool active) => CategoryEntity(
      id: id,
      name: name,
      type: 'expense',
      isDefault: false,
      isActive: active,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

void main() {
  late FakeCategoryRepository fake;
  late ProviderContainer container;
  final active = _cat('1', 'Lương', true);
  final inactive = _cat('2', 'Ẩn', false);

  setUp(() {
    fake = FakeCategoryRepository();
    container = ProviderContainer(overrides: [categoryRepositoryProvider.overrideWithValue(fake)]);
    registerFallbackValue(TransactionType.expense);
  });
  tearDown(() => container.dispose());

  test('allCategoriesProvider trả toàn bộ', () async {
    when(() => fake.getAll()).thenAnswer((_) async => [active, inactive]);
    final r = await container.read(allCategoriesProvider.future);
    expect(r.length, 2);
  });

  test('activeCategoriesProvider chỉ trả active', () async {
    when(() => fake.getActive()).thenAnswer((_) async => [active]);
    final r = await container.read(activeCategoriesProvider.future);
    expect(r.every((c) => c.isActive), isTrue);
  });

  test('categoriesByTypeProvider(type) gọi getByType', () async {
    when(() => fake.getByType(TransactionType.expense)).thenAnswer((_) async => [active]);
    final r = await container.read(categoriesByTypeProvider(TransactionType.expense).future);
    expect(r.first.type, 'expense');
  });
}
