import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:smart_finance/domain/entities/invoice_item_entity.dart';

class DraftInvoice extends Equatable {
  final File imageFile;
  final String sellerName;
  final String taxCode;
  final String sellerAddress;
  final String sellerPhone;
  final String sellerBankName;
  final String sellerBankAccount;
  final int subtotal;
  final int vatRate;
  final int totalAmount;
  final List<InvoiceItemEntity> items;
  final bool hasLowConfidence;

  const DraftInvoice({
    required this.imageFile,
    this.sellerName = '',
    this.taxCode = '',
    this.sellerAddress = '',
    this.sellerPhone = '',
    this.sellerBankName = '',
    this.sellerBankAccount = '',
    this.subtotal = 0,
    this.vatRate = 0,
    this.totalAmount = 0,
    List<InvoiceItemEntity> items = const [],
    this.hasLowConfidence = false,
  }) : items = items; // Let's keep it simple, we already enforce immutability generally. But wait, `List.unmodifiable` is safer. Let's use it but Equatable checks equality by reference if not careful. Actually, Equatable deep checks lists!

  @override
  List<Object?> get props => [
        imageFile.path, // Compare path for File
        sellerName,
        taxCode,
        sellerAddress,
        sellerPhone,
        sellerBankName,
        sellerBankAccount,
        subtotal,
        vatRate,
        totalAmount,
        items,
        hasLowConfidence,
      ];

  DraftInvoice copyWith({
    File? imageFile,
    String? sellerName,
    String? taxCode,
    String? sellerAddress,
    String? sellerPhone,
    String? sellerBankName,
    String? sellerBankAccount,
    int? subtotal,
    int? vatRate,
    int? totalAmount,
    List<InvoiceItemEntity>? items,
    bool? hasLowConfidence,
  }) {
    return DraftInvoice(
      imageFile: imageFile ?? this.imageFile,
      sellerName: sellerName ?? this.sellerName,
      taxCode: taxCode ?? this.taxCode,
      sellerAddress: sellerAddress ?? this.sellerAddress,
      sellerPhone: sellerPhone ?? this.sellerPhone,
      sellerBankName: sellerBankName ?? this.sellerBankName,
      sellerBankAccount: sellerBankAccount ?? this.sellerBankAccount,
      subtotal: subtotal ?? this.subtotal,
      vatRate: vatRate ?? this.vatRate,
      totalAmount: totalAmount ?? this.totalAmount,
      items: items ?? this.items,
      hasLowConfidence: hasLowConfidence ?? this.hasLowConfidence,
    );
  }
}
