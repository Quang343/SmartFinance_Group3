import 'package:smart_finance/features/invoices/domain/models/draft_invoice.dart';

class DraftInvoiceValidationResult {
  final bool isValid;
  final String? mathWarning;
  final List<String> missingFields;

  const DraftInvoiceValidationResult({
    required this.isValid,
    this.mathWarning,
    this.missingFields = const [],
  });
}

class DraftInvoiceValidator {
  static DraftInvoiceValidationResult empty() {
    return const DraftInvoiceValidationResult(isValid: true);
  }

  static DraftInvoiceValidationResult validate(DraftInvoice draft) {
    final missingFields = <String>[];
    String? mathWarning;

    if (draft.invoiceNumber.trim().isEmpty) {
      missingFields.add('Số hóa đơn');
    }
    if (draft.invoiceDate == null) {
      missingFields.add('Ngày lập hóa đơn');
    }
    if (draft.sellerName.trim().isEmpty) {
      missingFields.add('Tên người bán');
    }
    if (draft.taxCode.trim().isEmpty) {
      missingFields.add('MST người bán');
    }
    if (draft.buyerName?.trim().isEmpty ?? true) {
      missingFields.add('Tên người mua');
    }
    if (draft.buyerTaxCode?.trim().isEmpty ?? true) {
      missingFields.add('MST người mua');
    }
    
    // Validating basic math Subtotal + VAT = Total
    final expectedVatAmount = (draft.subtotal * draft.vatRate / 100).round();
    final expectedTotal = draft.subtotal + expectedVatAmount;
    
    if (draft.totalAmount != expectedTotal) {
      final diff = (draft.totalAmount - expectedTotal).abs();
      // Allow minor rounding difference of 10 VND or less, else warn
      if (diff > 10) {
         mathWarning = 'Cảnh báo: Tổng thanh toán lệch $diff so với phép tính (Trước thuế + VAT).';
      }
    }

    final isValid = missingFields.isEmpty;

    return DraftInvoiceValidationResult(
      isValid: isValid,
      mathWarning: mathWarning,
      missingFields: missingFields,
    );
  }
}
