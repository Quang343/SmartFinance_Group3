import 'package:isar/isar.dart';
import '../local/isar_models/isar_attachment.dart';

class LocalAttachmentDataSource {
  final Isar isar;

  LocalAttachmentDataSource(this.isar);

  Future<List<IsarAttachment>> getByOwnerId(String ownerId) async {
    return await isar.isarAttachments.filter().ownerIdEqualTo(ownerId).findAll();
  }

  Future<IsarAttachment?> getByUid(String uid) async {
    return await isar.isarAttachments.filter().uidEqualTo(uid).findFirst();
  }

  Future<void> create(IsarAttachment attachment) async {
    await isar.writeTxn(() async {
      await isar.isarAttachments.put(attachment);
    });
  }

  Future<void> delete(String uid) async {
    final existing = await getByUid(uid);
    if (existing != null) {
      await isar.writeTxn(() async {
        await isar.isarAttachments.delete(existing.id);
      });
    }
  }
}
