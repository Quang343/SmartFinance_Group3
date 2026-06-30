import 'package:isar/isar.dart';

part 'isar_attachment.g.dart';

@collection
@Name('Attachment')
class IsarAttachment {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String uid;

  @Index()
  late String ownerId;

  @Index()
  late String ownerType; // transaction | invoice

  late String filePath;
  String? fileName;
  String? mimeType;

  late DateTime createdAt;
}
