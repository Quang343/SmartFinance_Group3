import '../entities/attachment_entity.dart';

abstract class AttachmentRepository {
  Future<List<AttachmentEntity>> getByOwnerId(String ownerId);
  Future<AttachmentEntity?> getById(String id);
  Future<void> create(AttachmentEntity attachment);
  Future<void> delete(String id);
}
