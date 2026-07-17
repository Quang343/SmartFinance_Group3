class OcrFieldDto<T> {
  final T? value;
  final double confidence;

  const OcrFieldDto({
    this.value,
    this.confidence = 1.0,
  });

  factory OcrFieldDto.fromJson(Map<String, dynamic>? json) {
    if (json == null) return OcrFieldDto<T>();
    return OcrFieldDto<T>(
      value: json['value'] as T?,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
    );
  }
}

class OcrLineItemDto {
  final String? name;
  final int? quantity;
  final int? unitPrice;
  final int? amount;

  const OcrLineItemDto({
    this.name,
    this.quantity,
    this.unitPrice,
    this.amount,
  });

  factory OcrLineItemDto.fromJson(Map<String, dynamic> json) {
    return OcrLineItemDto(
      name: json['name'] as String?,
      quantity: json['quantity'] as int?,
      unitPrice: json['unit_price'] as int?,
      amount: json['amount'] as int?,
    );
  }
}

class OcrResultDto {
  final OcrFieldDto<String>? sellerName;
  final OcrFieldDto<String>? taxCode;
  final OcrFieldDto<String>? sellerAddress;
  final OcrFieldDto<String>? sellerPhone;
  final OcrFieldDto<String>? sellerBankName;
  final OcrFieldDto<String>? sellerBankAccount;
  final OcrFieldDto<int>? subtotal;
  final OcrFieldDto<int>? vatRate;
  final OcrFieldDto<int>? totalAmount;
  final List<OcrLineItemDto> lineItems;

  const OcrResultDto({
    this.sellerName,
    this.taxCode,
    this.sellerAddress,
    this.sellerPhone,
    this.sellerBankName,
    this.sellerBankAccount,
    this.subtotal,
    this.vatRate,
    this.totalAmount,
    this.lineItems = const [],
  });

  factory OcrResultDto.fromJson(Map<String, dynamic> json) {
    return OcrResultDto(
      sellerName: OcrFieldDto<String>.fromJson(json['seller_name']),
      taxCode: OcrFieldDto<String>.fromJson(json['tax_code']),
      sellerAddress: OcrFieldDto<String>.fromJson(json['seller_address']),
      sellerPhone: OcrFieldDto<String>.fromJson(json['seller_phone']),
      sellerBankName: OcrFieldDto<String>.fromJson(json['seller_bank_name']),
      sellerBankAccount: OcrFieldDto<String>.fromJson(json['seller_bank_account']),
      subtotal: OcrFieldDto<int>.fromJson(json['subtotal']),
      vatRate: OcrFieldDto<int>.fromJson(json['vat_rate']),
      totalAmount: OcrFieldDto<int>.fromJson(json['total_amount']),
      lineItems: (json['line_items'] as List<dynamic>?)
              ?.map((e) => OcrLineItemDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
