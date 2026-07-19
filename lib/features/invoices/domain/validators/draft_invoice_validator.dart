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

    if (draft.sellerName.trim().isEmpty) {
      missingFields.add('Tên người bán');
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
