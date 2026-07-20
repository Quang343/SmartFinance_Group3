import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:smart_finance/domain/entities/invoice_item_entity.dart';

class DraftInvoice extends Equatable {
  final File imageFile;
  final String invoiceNumber;
  final String? serialNumber;
  final String? formNumber;
  final DateTime? invoiceDate;
  
  final String sellerName;
  final String taxCode;
  final String sellerAddress;
  final String sellerPhone;
  final String? sellerBankName;
  final String? sellerBankAccount;
  
  final String? buyerContactName;
  final String? buyerName;
  final String? buyerTaxCode;
  final String? buyerAddress;
  
  final int subtotal;
  final int vatRate;
  final int totalAmount;
  final List<InvoiceItemEntity> items;
  final bool hasLowConfidence;

  const DraftInvoice({
    required this.imageFile,
    this.invoiceNumber = '',
    this.serialNumber,
    this.formNumber,
    this.invoiceDate,
    this.sellerName = '',
    this.taxCode = '',
    this.sellerAddress = '',
    this.sellerPhone = '',
    this.sellerBankName,
    this.sellerBankAccount,
    this.buyerContactName,
    this.buyerName,
    this.buyerTaxCode,
    this.buyerAddress,
    this.subtotal = 0,
    this.vatRate = 0,
    this.totalAmount = 0,
    this.items = const [],
    this.hasLowConfidence = false,
  });

  @override
  List<Object?> get props => [
        imageFile.path, // Compare path for File
        invoiceNumber,
        serialNumber,
        formNumber,
        invoiceDate,
        sellerName,
        taxCode,
        sellerAddress,
        sellerPhone,
        sellerBankName,
        sellerBankAccount,
        buyerContactName,
        buyerName,
        buyerTaxCode,
        buyerAddress,
        subtotal,
        vatRate,
        totalAmount,
        items,
        hasLowConfidence,
      ];

  DraftInvoice copyWith({
    File? imageFile,
    String? invoiceNumber,
    String? serialNumber,
    String? formNumber,
    DateTime? invoiceDate,
    String? sellerName,
    String? taxCode,
    String? sellerAddress,
    String? sellerPhone,
    String? sellerBankName,
    String? sellerBankAccount,
    String? buyerContactName,
    String? buyerName,
    String? buyerTaxCode,
    String? buyerAddress,
    int? subtotal,
    int? vatRate,
    int? totalAmount,
    List<InvoiceItemEntity>? items,
    bool? hasLowConfidence,
  }) {
    return DraftInvoice(
      imageFile: imageFile ?? this.imageFile,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      serialNumber: serialNumber ?? this.serialNumber,
      formNumber: formNumber ?? this.formNumber,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      sellerName: sellerName ?? this.sellerName,
      taxCode: taxCode ?? this.taxCode,
      sellerAddress: sellerAddress ?? this.sellerAddress,
      sellerPhone: sellerPhone ?? this.sellerPhone,
      sellerBankName: sellerBankName ?? this.sellerBankName,
      sellerBankAccount: sellerBankAccount ?? this.sellerBankAccount,
      buyerContactName: buyerContactName ?? this.buyerContactName,
      buyerName: buyerName ?? this.buyerName,
      buyerTaxCode: buyerTaxCode ?? this.buyerTaxCode,
      buyerAddress: buyerAddress ?? this.buyerAddress,
      subtotal: subtotal ?? this.subtotal,
      vatRate: vatRate ?? this.vatRate,
      totalAmount: totalAmount ?? this.totalAmount,
      items: items ?? this.items,
      hasLowConfidence: hasLowConfidence ?? this.hasLowConfidence,
    );
  }
}
