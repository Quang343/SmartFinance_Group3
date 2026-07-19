import 'dart:io';
import 'package:smart_finance/domain/entities/invoice_item_entity.dart';
import 'package:smart_finance/features/invoices/domain/models/draft_invoice.dart';
import 'package:smart_finance/features/invoices/data/models/ocr_result_dto.dart';

class OcrMapper {
  static const double _confidenceThreshold = 0.7;

  static DraftInvoice toDraft(OcrResultDto dto, File imageFile) {
    bool hasLowConfidence = false;
    
    // Helper to check confidence
    void checkConfidence(OcrFieldDto? field) {
      if (field != null && field.confidence < _confidenceThreshold) {
        hasLowConfidence = true;
      }
    }

    checkConfidence(dto.sellerName);
    checkConfidence(dto.taxCode);
    checkConfidence(dto.sellerAddress);
    checkConfidence(dto.sellerPhone);
    checkConfidence(dto.sellerBankName);
    checkConfidence(dto.sellerBankAccount);
    checkConfidence(dto.subtotal);
    checkConfidence(dto.vatRate);
    checkConfidence(dto.totalAmount);

    final items = dto.lineItems.map((itemDto) {
      return InvoiceItemEntity(
        id: '', // Generated later by Repository/Domain
        itemCode: '',
        itemName: itemDto.name ?? '',
        unit: '', // No arbitrary default
        quantity: (itemDto.quantity ?? 0).toDouble(), // No arbitrary default
        unitPrice: itemDto.unitPrice ?? 0,
        totalAmount: itemDto.amount ?? 0,
      );
    }).toList();

    return DraftInvoice(
      imageFile: imageFile,
      sellerName: dto.sellerName?.value ?? '',
      taxCode: dto.taxCode?.value ?? '',
      sellerAddress: dto.sellerAddress?.value ?? '',
      sellerPhone: dto.sellerPhone?.value ?? '',
      sellerBankName: dto.sellerBankName?.value ?? '',
      sellerBankAccount: dto.sellerBankAccount?.value ?? '',
      subtotal: dto.subtotal?.value ?? 0,
      vatRate: dto.vatRate?.value ?? 0,
      totalAmount: dto.totalAmount?.value ?? 0,
      items: items,
      hasLowConfidence: hasLowConfidence,
    );
  }
}
