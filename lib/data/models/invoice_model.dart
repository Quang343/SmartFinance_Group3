import '../../domain/entities/invoice_entity.dart';

class InvoiceModel extends InvoiceEntity {
  const InvoiceModel({
    required super.id,
    required super.invoiceNumber,
    required super.partnerName,
    required super.partnerTaxCode,
    required super.subtotal,
    required super.vatRate,
    required super.vatAmount,
    required super.totalAmount,
    required super.ocrStatus,
    required super.issuedDate,
    required super.createdAt,
    required super.updatedAt,
    super.imagePath,
    super.ocrConfidence,
  });
}
