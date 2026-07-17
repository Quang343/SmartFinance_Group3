import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/ocr_verify_provider.dart';
import 'ocr_verify_constants.dart';

class HeaderSection extends ConsumerStatefulWidget {
  const HeaderSection({super.key});

  @override
  ConsumerState<HeaderSection> createState() => _HeaderSectionState();
}

class _HeaderSectionState extends ConsumerState<HeaderSection> {
  late final TextEditingController _sellerController;
  late final TextEditingController _taxCodeController;
  late final TextEditingController _sellerAddressController;
  late final TextEditingController _sellerPhoneController;
  late final TextEditingController _sellerBankNameController;
  late final TextEditingController _sellerBankAccountController;

  late final FocusNode _sellerFocus;
  late final FocusNode _taxCodeFocus;
  late final FocusNode _sellerAddressFocus;
  late final FocusNode _sellerPhoneFocus;
  late final FocusNode _sellerBankNameFocus;
  late final FocusNode _sellerBankAccountFocus;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(ocrVerifyProvider).draft;
    _sellerController = TextEditingController(text: draft?.sellerName);
    _taxCodeController = TextEditingController(text: draft?.taxCode);
    _sellerAddressController = TextEditingController(text: draft?.sellerAddress);
    _sellerPhoneController = TextEditingController(text: draft?.sellerPhone);
    _sellerBankNameController = TextEditingController(text: draft?.sellerBankName);
    _sellerBankAccountController = TextEditingController(text: draft?.sellerBankAccount);

    _sellerFocus = FocusNode()..addListener(_onFocusChange);
    _taxCodeFocus = FocusNode()..addListener(_onFocusChange);
    _sellerAddressFocus = FocusNode()..addListener(_onFocusChange);
    _sellerPhoneFocus = FocusNode()..addListener(_onFocusChange);
    _sellerBankNameFocus = FocusNode()..addListener(_onFocusChange);
    _sellerBankAccountFocus = FocusNode()..addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (!_sellerFocus.hasFocus &&
        !_taxCodeFocus.hasFocus &&
        !_sellerAddressFocus.hasFocus &&
        !_sellerPhoneFocus.hasFocus &&
        !_sellerBankNameFocus.hasFocus &&
        !_sellerBankAccountFocus.hasFocus) {
      _dispatchChange();
    }
  }

  void _dispatchChange() {
    final currentDraft = ref.read(ocrVerifyProvider).draft;
    if (currentDraft == null) return;
    
    final updated = currentDraft.copyWith(
      sellerName: _sellerController.text.trim().isNotEmpty ? _sellerController.text.trim() : null,
      taxCode: _taxCodeController.text.trim().isNotEmpty ? _taxCodeController.text.trim() : null,
      sellerAddress: _sellerAddressController.text.trim().isNotEmpty ? _sellerAddressController.text.trim() : null,
      sellerPhone: _sellerPhoneController.text.trim().isNotEmpty ? _sellerPhoneController.text.trim() : null,
      sellerBankName: _sellerBankNameController.text.trim().isNotEmpty ? _sellerBankNameController.text.trim() : null,
      sellerBankAccount: _sellerBankAccountController.text.trim().isNotEmpty ? _sellerBankAccountController.text.trim() : null,
    );
    
    if (updated != currentDraft) {
      ref.read(ocrVerifyProvider.notifier).updateDraft(updated);
    }
  }

  @override
  void dispose() {
    _sellerFocus.removeListener(_onFocusChange);
    _taxCodeFocus.removeListener(_onFocusChange);
    _sellerAddressFocus.removeListener(_onFocusChange);
    _sellerPhoneFocus.removeListener(_onFocusChange);
    _sellerBankNameFocus.removeListener(_onFocusChange);
    _sellerBankAccountFocus.removeListener(_onFocusChange);
    
    _sellerFocus.dispose();
    _taxCodeFocus.dispose();
    _sellerAddressFocus.dispose();
    _sellerPhoneFocus.dispose();
    _sellerBankNameFocus.dispose();
    _sellerBankAccountFocus.dispose();

    _sellerController.dispose();
    _taxCodeController.dispose();
    _sellerAddressController.dispose();
    _sellerPhoneController.dispose();
    _sellerBankNameController.dispose();
    _sellerBankAccountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(ocrVerifyProvider.select((s) => s.draft?.sellerName), (_, next) {
      if (!_sellerFocus.hasFocus && _sellerController.text != next) {
        _sellerController.text = next ?? '';
      }
    });
    ref.listen(ocrVerifyProvider.select((s) => s.draft?.taxCode), (_, next) {
      if (!_taxCodeFocus.hasFocus && _taxCodeController.text != next) {
        _taxCodeController.text = next ?? '';
      }
    });
    ref.listen(ocrVerifyProvider.select((s) => s.draft?.sellerAddress), (_, next) {
      if (!_sellerAddressFocus.hasFocus && _sellerAddressController.text != next) {
        _sellerAddressController.text = next ?? '';
      }
    });
    ref.listen(ocrVerifyProvider.select((s) => s.draft?.sellerPhone), (_, next) {
      if (!_sellerPhoneFocus.hasFocus && _sellerPhoneController.text != next) {
        _sellerPhoneController.text = next ?? '';
      }
    });
    ref.listen(ocrVerifyProvider.select((s) => s.draft?.sellerBankName), (_, next) {
      if (!_sellerBankNameFocus.hasFocus && _sellerBankNameController.text != next) {
        _sellerBankNameController.text = next ?? '';
      }
    });
    ref.listen(ocrVerifyProvider.select((s) => s.draft?.sellerBankAccount), (_, next) {
      if (!_sellerBankAccountFocus.hasFocus && _sellerBankAccountController.text != next) {
        _sellerBankAccountController.text = next ?? '';
      }
    });

    final sellerError = null;
    final taxCodeError = null;

    return Semantics(
      container: true,
      label: 'Thông tin chung',
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(OcrVerifyDimens.cardRadius),
        ),
        child: Padding(
          padding: const EdgeInsets.all(OcrVerifyDimens.spacingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Thông tin chung',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: OcrVerifyDimens.spacingMedium),
              TextFormField(
                controller: _sellerController,
                focusNode: _sellerFocus,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Tên người bán',
                  errorText: sellerError,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.store),
                ),
              ),
              const SizedBox(height: OcrVerifyDimens.spacingMedium),
              TextFormField(
                controller: _taxCodeController,
                focusNode: _taxCodeFocus,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Mã số thuế',
                  errorText: taxCodeError,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.credit_card),
                ),
              ),
              const SizedBox(height: OcrVerifyDimens.spacingMedium),
              TextFormField(
                controller: _sellerAddressController,
                focusNode: _sellerAddressFocus,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Địa chỉ',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
              const SizedBox(height: OcrVerifyDimens.spacingMedium),
              TextFormField(
                controller: _sellerPhoneController,
                focusNode: _sellerPhoneFocus,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Số điện thoại',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
              const SizedBox(height: OcrVerifyDimens.spacingMedium),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _sellerBankNameController,
                      focusNode: _sellerBankNameFocus,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Ngân hàng',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.account_balance),
                      ),
                    ),
                  ),
                  const SizedBox(width: OcrVerifyDimens.spacingMedium),
                  Expanded(
                    child: TextFormField(
                      controller: _sellerBankAccountController,
                      focusNode: _sellerBankAccountFocus,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        labelText: 'Số tài khoản',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.numbers),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
