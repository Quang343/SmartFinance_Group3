import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_finance/features/invoices/data/mappers/ocr_mapper.dart';
import 'package:smart_finance/features/invoices/data/services/ocr_api_service.dart';
import 'package:smart_finance/features/invoices/domain/models/draft_invoice.dart';
import 'package:smart_finance/features/invoices/domain/validators/draft_invoice_validator.dart';
import 'package:smart_finance/features/invoices/presentation/providers/ocr_verify_state.dart';
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
  return OcrVerifyNotifier(apiService, invoiceRepository, storageRepository, currentUser);
});

class OcrVerifyNotifier extends StateNotifier<OcrVerifyState> {
  final OcrApiService _apiService;
  final InvoiceRepository _invoiceRepository;
  final StorageRepository _storageRepository;
  final UserModel? _currentUser;

  OcrVerifyNotifier(
    this._apiService, 
    this._invoiceRepository, 
    this._storageRepository,
    this._currentUser,
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
      final draft = OcrMapper.toDraft(dto, image);
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
      if (draft.imageFile.existsSync()) {
        imageUrl = await _storageRepository.uploadInvoiceImage(invoiceId, file: draft.imageFile);
      }
      
      // Convert Draft to Entity
      final entity = DraftInvoiceMapper.toEntity(draft, invoiceId, imagePath: imageUrl, currentUser: _currentUser);
      
      // Save to Firestore
      await _invoiceRepository.create(entity);
      
      state = state.copyWith(status: OcrStatus.success, savedInvoiceId: invoiceId);
    } catch (e) {
      state = state.copyWith(status: OcrStatus.error, errorMessage: e.toString());
    }
  }
}
