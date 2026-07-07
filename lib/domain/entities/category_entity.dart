class CategoryEntity {
  final String id;
  final String name;
  final String type; // 'income' or 'expense'
  final String? iconCode;
  final String? colorHex;
  final bool isDefault;
  final bool isActive;
  final int orderIndex;
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
    required this.createdAt,
    required this.updatedAt,
  });
}
