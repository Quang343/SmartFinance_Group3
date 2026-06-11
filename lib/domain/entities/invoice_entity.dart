enum OcrStatus { notStarted, imageSelected, scanning, extracted, failed }

class InvoiceEntity {
  final String id;
  final String invoiceNumber;
  final String partnerName;
  final String partnerTaxCode;
  final int subtotal;
  final int vatRate;
  final int vatAmount;
  final int totalAmount;
  final String? imagePath;
  final OcrStatus ocrStatus;
  final double? ocrConfidence;
  final DateTime issuedDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const InvoiceEntity({
    required this.id,
    required this.invoiceNumber,
    required this.partnerName,
    required this.partnerTaxCode,
    required this.subtotal,
    required this.vatRate,
    required this.vatAmount,
    required this.totalAmount,
    required this.ocrStatus,
    required this.issuedDate,
    required this.createdAt,
    required this.updatedAt,
    this.imagePath,
    this.ocrConfidence,
  });
}
