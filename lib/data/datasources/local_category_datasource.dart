import 'package:isar/isar.dart';
import '../local/isar_models/isar_category.dart';

class LocalCategoryDataSource {
  final Isar isar;

  LocalCategoryDataSource(this.isar);

  Future<List<IsarCategory>> getAll() async {
    return await isar.isarCategorys.where().findAll();
  }

  Future<List<IsarCategory>> getActive() async {
    return await isar.isarCategorys.filter().isActiveEqualTo(true).findAll();
  }

  Future<List<IsarCategory>> getByType(String type) async {
    return await isar.isarCategorys.filter().typeEqualTo(type).findAll();
  }

  Future<IsarCategory?> getByUid(String uid) async {
    return await isar.isarCategorys.filter().uidEqualTo(uid).findFirst();
  }

  Future<void> create(IsarCategory category) async {
    await isar.writeTxn(() async {
      await isar.isarCategorys.put(category);
    });
  }

  Future<void> update(IsarCategory category) async {
    final existing = await getByUid(category.uid);
    if (existing != null) {
      category.id = existing.id;
      await isar.writeTxn(() async {
        await isar.isarCategorys.put(category);
      });
    }
  }

  Future<void> deactivate(String uid) async {
    final existing = await getByUid(uid);
    if (existing != null) {
      existing.isActive = false;
      await isar.writeTxn(() async {
        await isar.isarCategorys.put(existing);
      });
    }
  }
}
