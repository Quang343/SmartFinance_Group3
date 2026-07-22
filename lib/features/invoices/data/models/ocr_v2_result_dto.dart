class OcrV2ResultDto {
  // General & Header
  final String? docTitle;
  final String? invoiceNo;
  final String? invoiceDate;
  final String? formNo;
  final String? symbol;

  // Seller
  final String? sellerName;
  final String? sellerTaxId;
  final String? sellerAddress;
  final String? sellerPhone;
  final String? sellerBankAccount;
  final String? sellerBankName;

  // Buyer
  final String? buyerPerson;
  final String? clientName;
  final String? clientTaxId;
  final String? clientAddress;
  final String? paymentMethod;

  // Line Items
  final List<OcrV2LineItemDto> lineItems;

  // Totals
  final String? totalNetAmount;
  final String? vatRate;
  final String? vatAmount;
  final String? totalAmount;

  // Misc
  final String? signatureName;
  final String? conversionDate;

  const OcrV2ResultDto({
    this.docTitle,
    this.invoiceNo,
    this.invoiceDate,
    this.formNo,
    this.symbol,
    this.sellerName,
    this.sellerTaxId,
    this.sellerAddress,
    this.sellerPhone,
    this.sellerBankAccount,
    this.sellerBankName,
    this.buyerPerson,
    this.clientName,
    this.clientTaxId,
    this.clientAddress,
    this.paymentMethod,
    this.lineItems = const [],
    this.totalNetAmount,
    this.vatRate,
    this.vatAmount,
    this.totalAmount,
    this.signatureName,
    this.conversionDate,
  });

  factory OcrV2ResultDto.fromJson(Map<String, dynamic> json) {
    // API returns data inside 'invoice_data'
    final invoiceData = json['invoice_data'] as Map<String, dynamic>? ?? json;
    final generalInfo = invoiceData['general_info'] as Map<String, dynamic>? ?? invoiceData;
    final itemsList = invoiceData['items'] as List<dynamic>? ?? invoiceData['LINE_ITEMS'] as List<dynamic>?;

    return OcrV2ResultDto(
      docTitle: generalInfo['DOC_TITLE']?.toString(),
      invoiceNo: generalInfo['INVOICE_NO']?.toString(),
      invoiceDate: generalInfo['INVOICE_DATE']?.toString(),
      formNo: generalInfo['FORM_NO']?.toString(),
      symbol: generalInfo['SYMBOL']?.toString(),
      sellerName: generalInfo['SELLER_NAME']?.toString(),
      sellerTaxId: generalInfo['SELLER_TAX_ID']?.toString(),
      sellerAddress: generalInfo['SELLER_ADDRESS']?.toString(),
      sellerPhone: generalInfo['SELLER_PHONE']?.toString(),
      sellerBankAccount: generalInfo['SELLER_BANK_ACCOUNT']?.toString(),
      sellerBankName: generalInfo['SELLER_BANK_NAME']?.toString(),
      buyerPerson: generalInfo['BUYER_PERSON']?.toString(),
      clientName: generalInfo['CLIENT_NAME']?.toString(),
      clientTaxId: generalInfo['CLIENT_TAX_ID']?.toString(),
      clientAddress: generalInfo['CLIENT_ADDRESS']?.toString(),
      paymentMethod: generalInfo['PAYMENT_METHOD']?.toString(),
      lineItems: itemsList?.map((e) => OcrV2LineItemDto.fromJson(e as Map<String, dynamic>)).toList() ?? [],
      totalNetAmount: generalInfo['TOTAL_NET_AMOUNT']?.toString(),
      vatRate: generalInfo['VAT_RATE']?.toString(),
      vatAmount: generalInfo['VAT_AMOUNT']?.toString(),
      totalAmount: generalInfo['TOTAL_AMOUNT']?.toString(),
      signatureName: generalInfo['SIGNATURE_NAME']?.toString(),
      conversionDate: generalInfo['CONVERSION_DATE']?.toString(),
    );
  }
}

class OcrV2LineItemDto {
  final String? itemCode;
  final String? itemDesc;
  final String? itemUnit;
  final String? itemQty;
  final String? itemUnitPrice;
  final String? itemNetAmount;

  const OcrV2LineItemDto({
    this.itemCode,
    this.itemDesc,
    this.itemUnit,
    this.itemQty,
    this.itemUnitPrice,
    this.itemNetAmount,
  });

  factory OcrV2LineItemDto.fromJson(Map<String, dynamic> json) {
    return OcrV2LineItemDto(
      itemCode: json['ITEM_CODE']?.toString(),
      itemDesc: json['ITEM_DESC']?.toString(),
      itemUnit: json['ITEM_UNIT']?.toString(),
      itemQty: json['ITEM_QTY']?.toString(),
      itemUnitPrice: json['ITEM_UNIT_PRICE']?.toString(),
      itemNetAmount: json['ITEM_NET_AMOUNT']?.toString(),
    );
  }
}
