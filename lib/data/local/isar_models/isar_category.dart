import 'package:isar/isar.dart';

part 'isar_category.g.dart';

@collection
@Name('Category')
class IsarCategory {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String uid;

  late String name;

  @Index()
  late String type; // income | expense

  String? iconCode;
  String? colorHex;

  late bool isDefault;

  @Index()
  late bool isActive;

  int orderIndex = 0;

  late DateTime createdAt;
  late DateTime updatedAt;
}
