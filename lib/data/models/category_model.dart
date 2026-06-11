import '../../domain/entities/category_entity.dart';

class CategoryModel extends CategoryEntity {
  const CategoryModel({
    required super.id,
    required super.name,
    required super.type,
    super.iconCode,
    super.colorHex,
    required super.isDefault,
    required super.isActive,
    required super.createdAt,
    required super.updatedAt,
  });
}
