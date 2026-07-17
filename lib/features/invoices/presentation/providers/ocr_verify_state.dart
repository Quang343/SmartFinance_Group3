import 'package:smart_finance/features/invoices/domain/models/draft_invoice.dart';
import 'package:smart_finance/features/invoices/domain/validators/draft_invoice_validator.dart';

enum OcrStatus { initial, scanning, editing, saving, success, error }

class OcrVerifyState {
  final OcrStatus status;
  final DraftInvoice? draft;
  final String? errorMessage;
  final String? savedInvoiceId;
  final DraftInvoiceValidationResult validation;

  const OcrVerifyState({
    this.status = OcrStatus.initial,
    this.draft,
    this.errorMessage,
    this.savedInvoiceId,
    this.validation = const DraftInvoiceValidationResult(isValid: true),
  });

  OcrVerifyState copyWith({
    OcrStatus? status,
    DraftInvoice? draft,
    bool clearDraft = false,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? savedInvoiceId,
    DraftInvoiceValidationResult? validation,
  }) {
    return OcrVerifyState(
      status: status ?? this.status,
      draft: clearDraft ? null : (draft ?? this.draft),
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      savedInvoiceId: savedInvoiceId ?? this.savedInvoiceId,
      validation: validation ?? this.validation,
    );
  }
}
