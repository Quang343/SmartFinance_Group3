import '../../domain/entities/invoice_entity.dart';
import 'invoice_item_model.dart';

class InvoiceModel extends InvoiceEntity {
  const InvoiceModel({
    required super.id,
    required super.invoiceNumber,
    required super.sellerName,
    required super.sellerTaxCode,
    super.sellerAddress,
    super.sellerPhone,
    super.sellerBankName,
    super.sellerBankAccount,
    super.buyerContactName,
    required super.buyerName,
    required super.buyerTaxCode,
    super.buyerAddress,
    super.buyerBankName,
    super.buyerBankAccount,
    super.paymentMethod,
    super.items = const [],
    required super.subtotal,
    required super.vatRate,
    required super.vatAmount,
    required super.totalAmount,
    required super.ocrStatus,
    required super.paymentStatus,
    required super.issuedDate,
    super.createdByUid,
    super.company,
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
      sellerName: json['sellerName'] as String? ?? '',
      sellerTaxCode: json['sellerTaxCode'] as String? ?? '',
      sellerAddress: json['sellerAddress'] as String?,
      sellerPhone: json['sellerPhone'] as String?,
      sellerBankName: json['sellerBankName'] as String?,
      sellerBankAccount: json['sellerBankAccount'] as String?,
      buyerContactName: json['buyerContactName'] as String?,
      buyerName: json['buyerName'] as String? ?? '',
      buyerTaxCode: json['buyerTaxCode'] as String? ?? '',
      buyerAddress: json['buyerAddress'] as String?,
      buyerBankName: json['buyerBankName'] as String?,
      buyerBankAccount: json['buyerBankAccount'] as String?,
      paymentMethod: json['paymentMethod'] as String?,
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => InvoiceItemModel.fromJson(item as Map<String, dynamic>))
              .toList() ??
          const [],
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
      createdByUid: json['createdByUid'] as String? ?? '',
      company: json['company'] as String? ?? '',
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
      'sellerName': sellerName,
      'sellerTaxCode': sellerTaxCode,
      'sellerAddress': sellerAddress,
      'sellerPhone': sellerPhone,
      'sellerBankName': sellerBankName,
      'sellerBankAccount': sellerBankAccount,
      'buyerContactName': buyerContactName,
      'buyerName': buyerName,
      'buyerTaxCode': buyerTaxCode,
      'buyerAddress': buyerAddress,
      'buyerBankName': buyerBankName,
      'buyerBankAccount': buyerBankAccount,
      'paymentMethod': paymentMethod,
      'items': items.map((item) => InvoiceItemModel.fromEntity(item).toJson()).toList(),
      'subtotal': subtotal,
      'vatRate': vatRate,
      'vatAmount': vatAmount,
      'totalAmount': totalAmount,
      'imagePath': imagePath,
      'ocrStatus': ocrStatus.name,
      'ocrConfidence': ocrConfidence,
      'paymentStatus': paymentStatus.name,
      'issuedDate': issuedDate.toIso8601String(),
      'createdByUid': createdByUid,
      'company': company,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'type': type.name,
    };
  }
}
