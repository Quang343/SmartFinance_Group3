import 'invoice_item_entity.dart';

enum OcrStatus { notStarted, imageSelected, scanning, extracted, failed }

enum InvoiceType { incoming, outgoing }

enum PaymentStatus { unpaid, partiallyPaid, paid }

class InvoiceEntity {
  final String id;
  final String invoiceNumber;
  
  // Seller (Đơn vị bán hàng)
  final String sellerName;
  final String sellerTaxCode;
  final String? sellerAddress;
  final String? sellerPhone;
  final String? sellerBankName;
  final String? sellerBankAccount;

  // Buyer (Người mua hàng)
  final String? buyerContactName;
  final String buyerName;
  final String buyerTaxCode;
  final String? buyerAddress;
  final String? buyerBankName;
  final String? buyerBankAccount;

  final String? paymentMethod; // Hình thức thanh toán

  final List<InvoiceItemEntity> items; // Danh sách hàng hóa, dịch vụ

  final int subtotal;
  final int vatRate;
  final int vatAmount;
  final int totalAmount;
  final String? imagePath;
  final OcrStatus ocrStatus;
  final double? ocrConfidence;
  final PaymentStatus paymentStatus;
  final DateTime issuedDate;
  final String createdByUid;
  final String company;
  final DateTime createdAt;
  final DateTime updatedAt;
  final InvoiceType type;

  const InvoiceEntity({
    required this.id,
    required this.invoiceNumber,
    required this.sellerName,
    required this.sellerTaxCode,
    this.sellerAddress,
    this.sellerPhone,
    this.sellerBankName,
    this.sellerBankAccount,
    this.buyerContactName,
    required this.buyerName,
    required this.buyerTaxCode,
    this.buyerAddress,
    this.buyerBankName,
    this.buyerBankAccount,
    this.paymentMethod,
    this.items = const [],
    required this.subtotal,
    required this.vatRate,
    required this.vatAmount,
    required this.totalAmount,
    required this.ocrStatus,
    required this.paymentStatus,
    required this.issuedDate,
    this.createdByUid = '',
    this.company = '',
    required this.createdAt,
    required this.updatedAt,
    required this.type,
    this.imagePath,
    this.ocrConfidence,
  });
}

