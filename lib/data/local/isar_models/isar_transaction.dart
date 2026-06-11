import 'package:isar/isar.dart';

part 'isar_transaction.g.dart';

@collection
@Name('Transaction')
class IsarTransaction {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String uid;

  late int amount;

  @Index()
  late String type; // income | expense

  @Index()
  late String categoryId;

  @Index()
  late DateTime transactionDate;

  String? note;

  @Index()
  late String status; // draft | confirmed | deleted

  String? invoiceId;

  late DateTime createdAt;
  late DateTime updatedAt;
}
