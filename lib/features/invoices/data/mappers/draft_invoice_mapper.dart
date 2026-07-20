
import 'package:smart_finance/domain/entities/invoice_entity.dart';
import 'package:smart_finance/features/invoices/domain/models/draft_invoice.dart';

import 'dart:math';

import 'package:smart_finance/data/models/user_model.dart';

class DraftInvoiceMapper {
  static InvoiceEntity toEntity(DraftInvoice draft, String id, {String? imagePath, UserModel? currentUser}) {
    // We assume incoming invoices for expenses
    final invoiceType = InvoiceType.incoming;
    final now = DateTime.now();
    
    // Calculate vatAmount from subtotal and vatRate
    final int vatAmount = (draft.subtotal * draft.vatRate / 100).round();
    
    final String generatedInvoiceNumber = 'OCR-INV-${now.year}-${Random().nextInt(9000) + 1000}';

    return InvoiceEntity(
      id: id,
      invoiceNumber: generatedInvoiceNumber, // Generated as fallback
      sellerName: draft.sellerName,
      sellerTaxCode: draft.taxCode,
      sellerAddress: draft.sellerAddress.isNotEmpty ? draft.sellerAddress : null,
      sellerPhone: draft.sellerPhone.isNotEmpty ? draft.sellerPhone : null,
      sellerBankName: draft.sellerBankName?.isNotEmpty == true ? draft.sellerBankName : null,
      sellerBankAccount: draft.sellerBankAccount?.isNotEmpty == true ? draft.sellerBankAccount : null,
      buyerName: draft.buyerName?.isNotEmpty == true ? draft.buyerName! : (currentUser?.company ?? ''),
      buyerTaxCode: draft.buyerTaxCode?.isNotEmpty == true ? draft.buyerTaxCode! : (currentUser?.taxCode ?? ''),
      buyerAddress: draft.buyerAddress?.isNotEmpty == true ? draft.buyerAddress : (currentUser?.address ?? ''),
      buyerContactName: draft.buyerContactName?.isNotEmpty == true ? draft.buyerContactName : (currentUser?.fullName ?? ''),
      items: draft.items, // ID for items will be preserved from Draft
      subtotal: draft.subtotal,
      vatRate: draft.vatRate,
      vatAmount: vatAmount,
      totalAmount: draft.totalAmount,
      ocrStatus: OcrStatus.extracted,
      paymentStatus: PaymentStatus.unpaid,
      issuedDate: now,
      createdAt: now,
      updatedAt: now,
      type: invoiceType,
      imagePath: imagePath,
      ocrConfidence: null, // Could add if needed
    );
  }
}
