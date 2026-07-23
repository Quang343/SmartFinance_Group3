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

final isRealApiProvider = StateProvider<bool>((ref) => false);

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
      final isRealApi = _ref.read(isRealApiProvider);
      DraftInvoice draft;
      if (isRealApi) {
        // Gọi API thật sử dụng schema V2
        final dtoV2 = await _apiService.scanInvoiceV2(image, isMock: false);
        draft = OcrMapper.toDraftV2(dtoV2, image);
      } else {
        // Dùng OCR Mock V2 (đầy đủ các trường)
        final dtoV2 = await _apiService.scanInvoiceV2(image, isMock: true);
        draft = OcrMapper.toDraftV2(dtoV2, image);
      }
      
      // Call scanInvoiceV2 (isMock: true for Mock mode with 1.8s delay and exact Hitachi sample JSON)
      final dtoV2 = await _apiService.scanInvoiceV2(image, isMock: !isRealApi);
      draft = OcrMapper.toDraftV2(dtoV2, image);

      // Fill Buyer / Client information with current accountant & company data
      final String buyerPerson = (_currentUser?.fullName.isNotEmpty == true)
          ? _currentUser!.fullName
          : (draft.buyerContactName ?? '');
      
      final String clientName = (_currentUser?.company.isNotEmpty == true)
          ? _currentUser!.company
          : (draft.buyerName ?? '');
          
      final String clientTaxId = (_currentUser?.taxCode.isNotEmpty == true)
          ? _currentUser!.taxCode
          : (draft.buyerTaxCode ?? '');
          
      final String clientAddress = (_currentUser?.address.isNotEmpty == true)
          ? _currentUser!.address
          : (draft.buyerAddress ?? '');

      draft = draft.copyWith(
        buyerContactName: buyerPerson,
        buyerName: clientName,
        buyerTaxCode: clientTaxId,
        buyerAddress: clientAddress,
      );

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
    if (state.draft == null) return;
    
    if (!state.validation.isValid) {
      final missingText = state.validation.missingFields.join(', ');
      state = state.copyWith(
        status: OcrStatus.error,
        errorMessage: 'Vui lòng điền đầy đủ các thông tin bắt buộc: $missingText',
      );
      return;
    }
    
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
