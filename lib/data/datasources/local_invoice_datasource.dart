import 'package:isar/isar.dart';
import '../local/isar_models/isar_invoice.dart';

class LocalInvoiceDataSource {
  final Isar isar;

  LocalInvoiceDataSource(this.isar);

  Future<List<IsarInvoice>> getAll() async {
    return await isar.isarInvoices.where().findAll();
  }

  Future<List<IsarInvoice>> getByOcrStatus(String status) async {
    return await isar.isarInvoices.filter().ocrStatusEqualTo(status).findAll();
  }

  Future<IsarInvoice?> getByUid(String uid) async {
    return await isar.isarInvoices.filter().uidEqualTo(uid).findFirst();
  }

  Future<void> create(IsarInvoice invoice) async {
    await isar.writeTxn(() async {
      await isar.isarInvoices.put(invoice);
    });
  }

  Future<void> update(IsarInvoice invoice) async {
    final existing = await getByUid(invoice.uid);
    if (existing != null) {
      invoice.id = existing.id;
      await isar.writeTxn(() async {
        await isar.isarInvoices.put(invoice);
      });
    }
  }

  Future<void> delete(String uid) async {
    final existing = await getByUid(uid);
    if (existing != null) {
      await isar.writeTxn(() async {
        await isar.isarInvoices.delete(existing.id);
      });
    }
  }
}
