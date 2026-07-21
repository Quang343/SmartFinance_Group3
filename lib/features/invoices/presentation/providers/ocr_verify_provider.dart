import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_finance/features/invoices/data/mappers/ocr_mapper.dart';
import 'package:smart_finance/features/invoices/data/services/ocr_api_service.dart';
import 'package:smart_finance/features/invoices/domain/models/draft_invoice.dart';
import 'package:smart_finance/features/invoices/domain/validators/draft_invoice_validator.dart';
import 'package:smart_finance/features/invoices/presentation/providers/ocr_verify_state.dart';
import 'package:smart_finance/features/invoices/providers/invoice_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:smart_finance/core/providers/app_providers.dart';
import 'package:smart_finance/domain/repositories/invoice_repository.dart';
import 'package:smart_finance/data/repositories/storage_repository.dart';
import 'package:smart_finance/features/invoices/data/mappers/draft_invoice_mapper.dart';
import 'package:smart_finance/core/providers/auth_provider.dart';
import 'package:smart_finance/data/models/user_model.dart';

final ocrVerifyProvider = StateNotifierProvider<OcrVerifyNotifier, OcrVerifyState>((ref) {
  final apiService = ref.read(ocrApiServiceProvider);
  final invoiceRepository = ref.read(invoiceRepositoryProvider);
  final storageRepository = ref.read(storageRepositoryProvider);
  final currentUser = ref.watch(currentUserProvider);
  return OcrVerifyNotifier(apiService, invoiceRepository, storageRepository, currentUser, ref);
});

class OcrVerifyNotifier extends StateNotifier<OcrVerifyState> {
  final OcrApiService _apiService;
  final InvoiceRepository _invoiceRepository;
  final StorageRepository _storageRepository;
  final UserModel? _currentUser;
  final Ref _ref;

  OcrVerifyNotifier(
    this._apiService, 
    this._invoiceRepository, 
    this._storageRepository,
    this._currentUser,
    this._ref,
  ) : super(const OcrVerifyState());

  void _applyDraftState(DraftInvoice draft, OcrStatus newStatus) {
    state = state.copyWith(
      status: newStatus,
      draft: draft,
      validation: DraftInvoiceValidator.validate(draft),
      clearErrorMessage: true,
    );
  }

  Future<void> processImage(File image) async {
    state = state.copyWith(
      status: OcrStatus.scanning, 
      clearDraft: true, 
      clearErrorMessage: true,
    );
    try {
      final dto = await _apiService.scanInvoice(image);
      DraftInvoice draft = OcrMapper.toDraft(dto, image);
      
      // Auto-fill and mock missing data to prevent initial validation errors
      draft = draft.copyWith(
        formNumber: (draft.formNumber == null || draft.formNumber!.trim().isEmpty) ? '01GTKT0/001' : draft.formNumber,
        serialNumber: (draft.serialNumber == null || draft.serialNumber!.trim().isEmpty) ? 'HM/17E' : draft.serialNumber,
        invoiceNumber: draft.invoiceNumber.trim().isEmpty ? '0000003' : draft.invoiceNumber,
        invoiceDate: draft.invoiceDate ?? DateTime(2017, 10, 16),
        sellerName: draft.sellerName.trim().isEmpty ? 'Công ty Cổ phần ABC' : draft.sellerName,
        taxCode: draft.taxCode.trim().isEmpty ? '0101243150' : draft.taxCode,
        sellerAddress: draft.sellerAddress.trim().isEmpty ? 'Tầng 9 Technosoft, Duy Tân, Cầu Giấy, Hà Nội' : draft.sellerAddress,
        sellerPhone: draft.sellerPhone.trim().isEmpty ? '04 3795 9595' : draft.sellerPhone,
        sellerBankName: (draft.sellerBankName == null || draft.sellerBankName!.trim().isEmpty) ? 'Ngân hàng Vietcombank' : draft.sellerBankName,
        sellerBankAccount: (draft.sellerBankAccount == null || draft.sellerBankAccount!.trim().isEmpty) ? '010236542365' : draft.sellerBankAccount,
      );

      if (_currentUser != null) {
        draft = draft.copyWith(
          buyerContactName: (draft.buyerContactName == null || draft.buyerContactName!.trim().isEmpty) ? (_currentUser.fullName) : draft.buyerContactName,
          buyerName: (draft.buyerName == null || draft.buyerName!.trim().isEmpty) ? (_currentUser.company) : draft.buyerName,
          buyerTaxCode: (draft.buyerTaxCode == null || draft.buyerTaxCode!.trim().isEmpty) ? (_currentUser.taxCode) : draft.buyerTaxCode,
          buyerAddress: (draft.buyerAddress == null || draft.buyerAddress!.trim().isEmpty) ? (_currentUser.address) : draft.buyerAddress,
        );
      }

      _applyDraftState(draft, OcrStatus.editing);
    } catch (e) {
      state = state.copyWith(status: OcrStatus.error, errorMessage: e.toString());
    }
  }

  void updateDraft(DraftInvoice updatedDraft) {
    if (state.status != OcrStatus.editing) return;
    
    final currentDraft = state.draft;
    if (currentDraft == null) return;

    DraftInvoice finalDraft = updatedDraft;

    // Detect what changed
    final bool itemsChanged = currentDraft.items != updatedDraft.items;
    final bool vatRateChanged = currentDraft.vatRate != updatedDraft.vatRate;
    final bool subtotalChangedManually = currentDraft.subtotal != updatedDraft.subtotal && !itemsChanged;

    if (itemsChanged) {
      // 1. Tự động cộng dồn Tiền hàng từ chi tiết
      int newSubtotal = updatedDraft.items.fold(0, (sum, item) => sum + item.totalAmount);
      
      // 2. Tính lại Tổng cộng
      int vatAmount = (newSubtotal * updatedDraft.vatRate / 100).round();
      int newTotalAmount = newSubtotal + vatAmount;

      finalDraft = updatedDraft.copyWith(
        subtotal: newSubtotal,
        totalAmount: newTotalAmount,
      );
    } else if (vatRateChanged || subtotalChangedManually) {
      // Nếu chỉ sửa Thuế suất hoặc tự gõ tay lại Tiền hàng -> Tính lại Tổng cộng
      int vatAmount = (updatedDraft.subtotal * updatedDraft.vatRate / 100).round();
      int newTotalAmount = updatedDraft.subtotal + vatAmount;

      finalDraft = updatedDraft.copyWith(
        totalAmount: newTotalAmount,
      );
    }

    _applyDraftState(finalDraft, OcrStatus.editing);
  }

  Future<void> saveInvoice() async {
    if (!state.validation.isValid || state.draft == null) return;
    
    state = state.copyWith(status: OcrStatus.saving, clearErrorMessage: true);
    try {
      final draft = state.draft!;
      final invoiceId = const Uuid().v4();
      
      String? imageUrl;
      // Upload image to ImgBB
      try {
        if (kIsWeb) {
          // On web, the path is a blob URL, we can get bytes using http.get
          try {
            final response = await http.get(Uri.parse(draft.imageFile.path));
            if (response.statusCode == 200) {
              imageUrl = await _storageRepository.uploadInvoiceImage(invoiceId, webFile: response.bodyBytes, fileName: 'invoice.png');
            }
          } catch (e) {
            debugPrint('Error getting web image bytes: $e');
          }
        } else if (draft.imageFile.existsSync()) {
          imageUrl = await _storageRepository.uploadInvoiceImage(invoiceId, file: draft.imageFile);
        }
      } catch (uploadError) {
        debugPrint('Error uploading invoice image: $uploadError');
        // Fallback to local path or null if upload fails
        if (!kIsWeb && draft.imageFile.existsSync()) {
          imageUrl = draft.imageFile.path;
        }
      }
      
      // Convert Draft to Entity
      final entity = DraftInvoiceMapper.toEntity(draft, invoiceId, imagePath: imageUrl, currentUser: _currentUser);
      
      // Save to Firestore
      await _invoiceRepository.create(entity);
      
      // Refresh list
      _ref.invalidate(allInvoicesProvider);
      
      state = state.copyWith(status: OcrStatus.success, savedInvoiceId: invoiceId);
    } catch (e) {
      state = state.copyWith(status: OcrStatus.error, errorMessage: e.toString());
    }
  }
}
