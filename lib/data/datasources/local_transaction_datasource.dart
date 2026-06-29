import 'package:isar/isar.dart';
import '../local/isar_models/isar_transaction.dart';

class LocalTransactionDataSource {
  final Isar isar;

  LocalTransactionDataSource(this.isar);

  Future<List<IsarTransaction>> getAll() async {
    return await isar.isarTransactions.where().findAll();
  }

  Future<List<IsarTransaction>> getConfirmed() async {
    return await isar.isarTransactions.filter().statusEqualTo('confirmed').findAll();
  }

  Future<List<IsarTransaction>> getByDateRange(DateTime start, DateTime end) async {
    return await isar.isarTransactions.filter()
        .statusEqualTo('confirmed')
        .and()
        .transactionDateBetween(start, end)
        .findAll();
  }

  Future<List<IsarTransaction>> getByType(String type) async {
    return await isar.isarTransactions.filter().typeEqualTo(type).findAll();
  }

  Future<IsarTransaction?> getByUid(String uid) async {
    return await isar.isarTransactions.filter().uidEqualTo(uid).findFirst();
  }

  Future<void> create(IsarTransaction transaction) async {
    await isar.writeTxn(() async {
      await isar.isarTransactions.put(transaction);
    });
  }

  Future<void> update(IsarTransaction transaction) async {
    final existing = await getByUid(transaction.uid);
    if (existing != null) {
      transaction.id = existing.id;
      await isar.writeTxn(() async {
        await isar.isarTransactions.put(transaction);
      });
    }
  }

  Future<void> softDelete(String uid) async {
    final existing = await getByUid(uid);
    if (existing != null) {
      existing.status = 'deleted';
      existing.updatedAt = DateTime.now();
      await isar.writeTxn(() async {
        await isar.isarTransactions.put(existing);
      });
    }
  }

  Future<void> hardDelete(String uid) async {
    final existing = await getByUid(uid);
    if (existing != null) {
      await isar.writeTxn(() async {
        await isar.isarTransactions.delete(existing.id);
      });
    }
  }
}
