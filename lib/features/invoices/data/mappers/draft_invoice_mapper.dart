import 'package:uuid/uuid.dart';
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
      sellerBankName: draft.sellerBankName.isNotEmpty ? draft.sellerBankName : null,
      sellerBankAccount: draft.sellerBankAccount.isNotEmpty ? draft.sellerBankAccount : null,
      buyerName: currentUser?.company.isNotEmpty == true ? currentUser!.company : 'Công ty TNHH SmartFinance',
      buyerTaxCode: currentUser?.taxCode.isNotEmpty == true ? currentUser!.taxCode : '0101243150',
      buyerAddress: '123 Đường Sáng Tạo, Cầu Giấy, Hà Nội', // UserModel currently doesn't have address
      buyerContactName: 'Nguyễn Văn Tiến', // Mocked, as this would ideally come from OCR
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
