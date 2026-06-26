import 'package:isar/isar.dart';

part 'isar_invoice.g.dart';

@collection
@Name('Invoice')
class IsarInvoice {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String uid;

  @Index(unique: true)
  late String invoiceNumber;

  late String partnerName;

  @Index()
  late String partnerTaxCode;

  late int subtotal;
  late int vatRate;
  late int vatAmount;
  late int totalAmount;

  String? imagePath;

  @Index()
  late String ocrStatus;

  double? ocrConfidence;

  @Index()
  late String type;

  @Index()
  late DateTime issuedDate;

  late DateTime createdAt;
  late DateTime updatedAt;
}
