import 'dart:io';
import 'package:smart_finance/domain/entities/invoice_item_entity.dart';
import 'package:smart_finance/features/invoices/domain/models/draft_invoice.dart';
import 'package:smart_finance/features/invoices/data/models/ocr_result_dto.dart';
import 'package:smart_finance/features/invoices/data/models/ocr_v2_result_dto.dart';
import 'package:intl/intl.dart';

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

  static int _parseInt(String? val) {
    if (val == null || val.isEmpty) return 0;
    // Remove non-digit characters except dot and comma
    String cleaned = val.replaceAll(RegExp(r'[^0-9\.,]'), '');
    if (cleaned.isEmpty) return 0;
    // Check if it has decimal point (e.g. 7.50). If so, we might want to round or handle it.
    // For simplicity, remove all commas and dots if it's typical VND, or parse as double and round.
    // Assuming VND which is large integer, usually comma or dot is thousand separator.
    cleaned = cleaned.replaceAll(RegExp(r'[.,]'), '');
    return int.tryParse(cleaned) ?? 0;
  }

  static double _parseDouble(String? val) {
    if (val == null || val.isEmpty) return 0.0;
    String cleaned = val.replaceAll(RegExp(r'[^0-9\.,]'), '');
    if (cleaned.isEmpty) return 0.0;
    // For decimals like 7.50 vs thousand separator 7,500
    // If it has both, comma is probably thousand, dot is decimal or vice-versa
    if (cleaned.contains(',') && cleaned.contains('.')) {
      cleaned = cleaned.replaceAll(',', '');
    } else if (cleaned.contains(',')) {
      // Could be 7,50 -> 7.50
      cleaned = cleaned.replaceAll(',', '.');
    }
    return double.tryParse(cleaned) ?? 0.0;
  }

  static DateTime? _parseDate(String? val) {
    if (val == null || val.isEmpty) return null;
    try {
      return DateFormat('dd/MM/yyyy').parse(val);
    } catch (_) {
      try {
        return DateFormat('MM/dd/yyyy').parse(val); // Fallback
      } catch (_) {
        return null;
      }
    }
  }

  static DraftInvoice toDraftV2(OcrV2ResultDto dto, File imageFile) {
    final items = dto.lineItems.map((itemDto) {
      double qty = _parseDouble(itemDto.itemQty);
      int netAmount = _parseInt(itemDto.itemNetAmount);
      int unitPrice = _parseInt(itemDto.itemUnitPrice);

      // Handle missing quantity as requested: QTY = NET_AMOUNT / UNIT_PRICE
      if (qty == 0 && netAmount > 0 && unitPrice > 0) {
        qty = netAmount / unitPrice;
      }

      return InvoiceItemEntity(
        id: '', 
        itemCode: itemDto.itemCode ?? '',
        itemName: itemDto.itemDesc ?? '',
        unit: itemDto.itemUnit ?? '',
        quantity: qty,
        unitPrice: unitPrice,
        totalAmount: netAmount,
      );
    }).toList();

    return DraftInvoice(
      imageFile: imageFile,
      invoiceNumber: dto.invoiceNo ?? '',
      serialNumber: dto.symbol ?? '',
      formNumber: dto.formNo ?? '',
      invoiceDate: _parseDate(dto.invoiceDate),
      sellerName: dto.sellerName ?? '',
      taxCode: dto.sellerTaxId ?? '',
      sellerAddress: dto.sellerAddress ?? '',
      sellerPhone: dto.sellerPhone ?? '',
      sellerBankName: dto.sellerBankName ?? '',
      sellerBankAccount: dto.sellerBankAccount ?? '',
      buyerContactName: dto.buyerPerson ?? '',
      buyerName: dto.clientName ?? '',
      buyerTaxCode: dto.clientTaxId ?? '',
      buyerAddress: dto.clientAddress ?? '',
      subtotal: _parseInt(dto.totalNetAmount),
      vatRate: _parseInt(dto.vatRate), // E.g., '10%' -> 10
      totalAmount: _parseInt(dto.totalAmount),
      items: items,
      hasLowConfidence: false, // New schema does not provide confidence scores yet
    );
  }
}
