import '../../domain/entities/category_entity.dart';
import '../local/isar_models/isar_category.dart';

class CategoryMapper {
  static CategoryEntity toEntity(IsarCategory model) {
    return CategoryEntity(
      id: model.uid,
      name: model.name,
      type: model.type,
      iconCode: model.iconCode,
      colorHex: model.colorHex,
      isDefault: model.isDefault,
      isActive: model.isActive,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
    );
  }

  static IsarCategory toIsarModel(CategoryEntity entity) {
    return IsarCategory()
      ..uid = entity.id
      ..name = entity.name
      ..type = entity.type
      ..iconCode = entity.iconCode
      ..colorHex = entity.colorHex
      ..isDefault = entity.isDefault
      ..isActive = entity.isActive
      ..createdAt = entity.createdAt
      ..updatedAt = entity.updatedAt;
  }
}
