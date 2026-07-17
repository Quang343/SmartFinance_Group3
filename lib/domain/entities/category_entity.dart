class CategoryEntity {
  final String id;
  final String name;
  final String type;
  final String? iconCode;
  final String? colorHex;
  final bool isDefault;
  final bool isActive;
  final int orderIndex;
  final String createdByUid;
  final String company;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CategoryEntity({
    required this.id,
    required this.name,
    required this.type,
    this.iconCode,
    this.colorHex,
    required this.isDefault,
    required this.isActive,
    this.orderIndex = 0,
    this.createdByUid = '',
    this.company = '',
    required this.createdAt,
    required this.updatedAt,
  });
}
