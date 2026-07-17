class AttachmentEntity {
  final String id;
  final String ownerId;
  final String ownerType;
  final String filePath;
  final String? fileName;
  final String? mimeType;
  final String createdByUid;
  final String company;
  final DateTime createdAt;

  const AttachmentEntity({
    required this.id,
    required this.ownerId,
    required this.ownerType,
    required this.filePath,
    required this.createdAt,
    this.fileName,
    this.mimeType,
    this.createdByUid = '',
    this.company = '',
  });
}
