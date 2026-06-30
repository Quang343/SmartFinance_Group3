import '../../domain/entities/attachment_entity.dart';
import '../local/isar_models/isar_attachment.dart';

class AttachmentMapper {
  static AttachmentEntity toEntity(IsarAttachment model) {
    return AttachmentEntity(
      id: model.uid,
      ownerId: model.ownerId,
      ownerType: model.ownerType,
      filePath: model.filePath,
      fileName: model.fileName,
      mimeType: model.mimeType,
      createdAt: model.createdAt,
    );
  }

  static IsarAttachment toIsarModel(AttachmentEntity entity) {
    return IsarAttachment()
      ..uid = entity.id
      ..ownerId = entity.ownerId
      ..ownerType = entity.ownerType
      ..filePath = entity.filePath
      ..fileName = entity.fileName
      ..mimeType = entity.mimeType
      ..createdAt = entity.createdAt;
  }
}
