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
    required super.paymentStatus,
    required super.issuedDate,
    required super.createdAt,
    required super.updatedAt,
    required super.type,
    super.imagePath,
    super.ocrConfidence,
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    return InvoiceModel(
      id: json['id'] as String? ?? '',
      invoiceNumber: json['invoiceNumber'] as String? ?? '',
      partnerName: json['partnerName'] as String? ?? '',
      partnerTaxCode: json['partnerTaxCode'] as String? ?? '',
      subtotal: json['subtotal'] as int? ?? 0,
      vatRate: json['vatRate'] as int? ?? 0,
      vatAmount: json['vatAmount'] as int? ?? 0,
      totalAmount: json['totalAmount'] as int? ?? 0,
      imagePath: json['imagePath'] as String?,
      ocrStatus: OcrStatus.values.firstWhere(
        (e) => e.name == json['ocrStatus'],
        orElse: () => OcrStatus.notStarted,
      ),
      ocrConfidence: (json['ocrConfidence'] as num?)?.toDouble(),
      paymentStatus: PaymentStatus.values.firstWhere(
        (e) => e.name == json['paymentStatus'],
        orElse: () => PaymentStatus.unpaid,
      ),
      issuedDate: json['issuedDate'] != null
          ? DateTime.parse(json['issuedDate'] as String)
          : DateTime.now(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
      type: InvoiceType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => InvoiceType.incoming,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invoiceNumber': invoiceNumber,
      'partnerName': partnerName,
      'partnerTaxCode': partnerTaxCode,
      'subtotal': subtotal,
      'vatRate': vatRate,
      'vatAmount': vatAmount,
      'totalAmount': totalAmount,
      'imagePath': imagePath,
      'ocrStatus': ocrStatus.name,
      'ocrConfidence': ocrConfidence,
      'paymentStatus': paymentStatus.name,
      'issuedDate': issuedDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'type': type.name,
    };
  }
}
