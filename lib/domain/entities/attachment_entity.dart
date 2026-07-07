class AttachmentEntity {
  final String id;
  final String ownerId;
  final String ownerType; // 'transaction' or 'invoice'
  final String filePath;
  final String? fileName;
  final String? mimeType;
  final DateTime createdAt;

  const AttachmentEntity({
    required this.id,
    required this.ownerId,
    required this.ownerType,
    required this.filePath,
    required this.createdAt,
    this.fileName,
    this.mimeType,
  });
}
