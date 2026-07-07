import '../../domain/entities/attachment_entity.dart';

class AttachmentModel extends AttachmentEntity {
  const AttachmentModel({
    required super.id,
    required super.ownerId,
    required super.ownerType,
    required super.filePath,
    required super.createdAt,
    super.fileName,
    super.mimeType,
  });

  factory AttachmentModel.fromJson(Map<String, dynamic> json) {
    return AttachmentModel(
      id: json['id'] as String? ?? '',
      ownerId: json['ownerId'] as String? ?? '',
      ownerType: json['ownerType'] as String? ?? '',
      filePath: json['filePath'] as String? ?? '',
      fileName: json['fileName'] as String?,
      mimeType: json['mimeType'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ownerId': ownerId,
      'ownerType': ownerType,
      'filePath': filePath,
      'fileName': fileName,
      'mimeType': mimeType,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
