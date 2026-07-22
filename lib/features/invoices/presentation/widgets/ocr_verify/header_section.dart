import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../core/providers/auth_provider.dart';
import '../../providers/ocr_verify_provider.dart';

class HeaderSection extends ConsumerStatefulWidget {
  const HeaderSection({super.key});

  @override
  ConsumerState<HeaderSection> createState() => _HeaderSectionState();
}

class _HeaderSectionState extends ConsumerState<HeaderSection> {
  // Invoice Info
  late final TextEditingController _formNumberController;
  late final TextEditingController _serialNumberController;
  late final TextEditingController _invoiceNumberController;
  DateTime? _invoiceDate;

  // Seller
  late final TextEditingController _sellerController;
  late final TextEditingController _taxCodeController;
  late final TextEditingController _sellerAddressController;
  late final TextEditingController _sellerPhoneController;
  late final TextEditingController _sellerBankNameController;
  late final TextEditingController _sellerBankAccountController;

  // Buyer
  late final TextEditingController _buyerContactNameController;
  late final TextEditingController _buyerNameController;
  late final TextEditingController _buyerTaxCodeController;
  late final TextEditingController _buyerAddressController;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(ocrVerifyProvider).draft;
    
    _formNumberController = TextEditingController(text: draft?.formNumber ?? '');
    _serialNumberController = TextEditingController(text: draft?.serialNumber ?? '');
    _invoiceNumberController = TextEditingController(text: draft?.invoiceNumber ?? '');
    _invoiceDate = draft?.invoiceDate;

    _sellerController = TextEditingController(text: draft?.sellerName ?? '');
    _taxCodeController = TextEditingController(text: draft?.taxCode ?? '');
    _sellerAddressController = TextEditingController(text: draft?.sellerAddress ?? '');
    _sellerPhoneController = TextEditingController(text: draft?.sellerPhone ?? '');
    _sellerBankNameController = TextEditingController(text: draft?.sellerBankName ?? '');
    _sellerBankAccountController = TextEditingController(text: draft?.sellerBankAccount ?? '');

    _buyerContactNameController = TextEditingController(text: draft?.buyerContactName ?? '');
    _buyerNameController = TextEditingController(text: draft?.buyerName ?? '');
    _buyerTaxCodeController = TextEditingController(text: draft?.buyerTaxCode ?? '');
    _buyerAddressController = TextEditingController(text: draft?.buyerAddress ?? '');

    final controllers = [
      _formNumberController, _serialNumberController, _invoiceNumberController,
      _sellerController, _taxCodeController, _sellerAddressController, _sellerPhoneController, _sellerBankNameController, _sellerBankAccountController,
      _buyerContactNameController, _buyerNameController, _buyerTaxCodeController, _buyerAddressController
    ];
    for (var c in controllers) {
      c.addListener(_dispatchChange);
    }
  }

  void _dispatchChange() {
    final currentDraft = ref.read(ocrVerifyProvider).draft;
    if (currentDraft == null) return;
    
    final updated = currentDraft.copyWith(
      formNumber: _formNumberController.text.trim().isNotEmpty ? _formNumberController.text.trim() : null,
      serialNumber: _serialNumberController.text.trim().isNotEmpty ? _serialNumberController.text.trim() : null,
      invoiceNumber: _invoiceNumberController.text.trim().isNotEmpty ? _invoiceNumberController.text.trim() : null,
      invoiceDate: _invoiceDate,
      sellerName: _sellerController.text.trim().isNotEmpty ? _sellerController.text.trim() : null,
      taxCode: _taxCodeController.text.trim().isNotEmpty ? _taxCodeController.text.trim() : null,
      sellerAddress: _sellerAddressController.text.trim().isNotEmpty ? _sellerAddressController.text.trim() : null,
      sellerPhone: _sellerPhoneController.text.trim().isNotEmpty ? _sellerPhoneController.text.trim() : null,
      sellerBankName: _sellerBankNameController.text.trim().isNotEmpty ? _sellerBankNameController.text.trim() : null,
      sellerBankAccount: _sellerBankAccountController.text.trim().isNotEmpty ? _sellerBankAccountController.text.trim() : null,
      buyerContactName: _buyerContactNameController.text.trim().isNotEmpty ? _buyerContactNameController.text.trim() : null,
      buyerName: _buyerNameController.text.trim().isNotEmpty ? _buyerNameController.text.trim() : null,
      buyerTaxCode: _buyerTaxCodeController.text.trim().isNotEmpty ? _buyerTaxCodeController.text.trim() : null,
      buyerAddress: _buyerAddressController.text.trim().isNotEmpty ? _buyerAddressController.text.trim() : null,
    );
    
    if (updated != currentDraft) {
      // Delay update to avoid build cycle issues
      Future.microtask(() {
         ref.read(ocrVerifyProvider.notifier).updateDraft(updated);
      });
    }
  }

  @override
  void dispose() {
    _formNumberController.dispose();
    _serialNumberController.dispose();
    _invoiceNumberController.dispose();
    _sellerController.dispose();
    _taxCodeController.dispose();
    _sellerAddressController.dispose();
    _sellerPhoneController.dispose();
    _sellerBankNameController.dispose();
    _sellerBankAccountController.dispose();
    _buyerContactNameController.dispose();
    _buyerNameController.dispose();
    _buyerTaxCodeController.dispose();
    _buyerAddressController.dispose();
    super.dispose();
  }
  
  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _invoiceDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF00D09E),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _invoiceDate = picked;
      });
      _dispatchChange();
    }
  }

  InputDecoration _buildInputDeco(String label, IconData? icon, bool isDark, Color primaryColor, Color inputFillColor, Color inputBorderColor) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 13),
      prefixIcon: icon != null ? Icon(icon, color: primaryColor, size: 18) : null,
      filled: true,
      fillColor: inputFillColor,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: inputBorderColor, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(ocrVerifyProvider.select((s) => s.draft), (_, next) {
      if (next == null) return;
      if (_formNumberController.text != (next.formNumber ?? '')) _formNumberController.text = next.formNumber ?? '';
      if (_serialNumberController.text != (next.serialNumber ?? '')) _serialNumberController.text = next.serialNumber ?? '';
      if (_invoiceNumberController.text != next.invoiceNumber) _invoiceNumberController.text = next.invoiceNumber;
      if (_sellerController.text != next.sellerName) _sellerController.text = next.sellerName;
      if (_taxCodeController.text != next.taxCode) _taxCodeController.text = next.taxCode;
      if (_sellerAddressController.text != next.sellerAddress) _sellerAddressController.text = next.sellerAddress;
      if (_sellerPhoneController.text != next.sellerPhone) _sellerPhoneController.text = next.sellerPhone;
      if (_sellerBankNameController.text != (next.sellerBankName ?? '')) _sellerBankNameController.text = next.sellerBankName ?? '';
      if (_sellerBankAccountController.text != (next.sellerBankAccount ?? '')) _sellerBankAccountController.text = next.sellerBankAccount ?? '';
      if (_buyerContactNameController.text != (next.buyerContactName ?? '')) _buyerContactNameController.text = next.buyerContactName ?? '';
      if (_buyerNameController.text != (next.buyerName ?? '')) _buyerNameController.text = next.buyerName ?? '';
      if (_buyerTaxCodeController.text != (next.buyerTaxCode ?? '')) _buyerTaxCodeController.text = next.buyerTaxCode ?? '';
      if (_buyerAddressController.text != next.buyerAddress) _buyerAddressController.text = next.buyerAddress ?? '';
      if (_invoiceDate != next.invoiceDate) {
        setState(() {
          _invoiceDate = next.invoiceDate;
        });
      }
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF00D09E);
    final inputFillColor = isDark ? const Color(0xFF0F1E15) : Colors.grey.shade50;
    final inputBorderColor = isDark ? const Color(0xFF1E382B) : Colors.grey.shade300;
    
    final missingFields = ref.watch(ocrVerifyProvider.select((s) => s.validation.missingFields));
    String? getError(String fieldName) => missingFields.contains(fieldName) ? 'Bắt buộc' : null;

    final textStyle = TextStyle(fontSize: 14, color: isDark ? Colors.white : Colors.black87);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('THÔNG TIN HÓA ĐƠN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: TextFormField(
                controller: _formNumberController,
                style: textStyle,
                decoration: _buildInputDeco('Mẫu số', null, isDark, primaryColor, inputFillColor, inputBorderColor),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: TextFormField(
                controller: _serialNumberController,
                style: textStyle,
                decoration: _buildInputDeco('Ký hiệu', null, isDark, primaryColor, inputFillColor, inputBorderColor),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 4,
              child: TextFormField(
                controller: _invoiceNumberController,
                style: textStyle,
                decoration: _buildInputDeco('Số hóa đơn', null, isDark, primaryColor, inputFillColor, inputBorderColor).copyWith(
                  errorText: getError('Số hóa đơn'),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: _selectDate,
          borderRadius: BorderRadius.circular(12),
          child: IgnorePointer(
            child: TextFormField(
              controller: TextEditingController(text: _invoiceDate != null ? DateFormat('dd/MM/yyyy').format(_invoiceDate!) : ''),
              style: textStyle,
              decoration: _buildInputDeco('Ngày lập hóa đơn', Icons.calendar_today_outlined, isDark, primaryColor, inputFillColor, inputBorderColor).copyWith(
                errorText: getError('Ngày lập hóa đơn'),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        const Text('THÔNG TIN ĐƠN VỊ BÁN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 12),
        TextFormField(
          controller: _sellerController,
          style: textStyle,
          decoration: _buildInputDeco('Tên người bán', Icons.storefront_outlined, isDark, primaryColor, inputFillColor, inputBorderColor).copyWith(
            errorText: getError('Tên người bán'),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: TextFormField(
                controller: _taxCodeController,
                style: textStyle,
                decoration: _buildInputDeco('Mã số thuế', Icons.credit_card_outlined, isDark, primaryColor, inputFillColor, inputBorderColor),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 5,
              child: TextFormField(
                controller: _sellerPhoneController,
                style: textStyle,
                decoration: _buildInputDeco('Số điện thoại', Icons.phone_outlined, isDark, primaryColor, inputFillColor, inputBorderColor),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _sellerAddressController,
          style: textStyle,
          decoration: _buildInputDeco('Địa chỉ', Icons.location_on_outlined, isDark, primaryColor, inputFillColor, inputBorderColor),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: _sellerBankNameController,
                style: textStyle,
                decoration: _buildInputDeco('Ngân hàng', Icons.account_balance_outlined, isDark, primaryColor, inputFillColor, inputBorderColor),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: _sellerBankAccountController,
                style: textStyle,
                decoration: _buildInputDeco('Số tài khoản', Icons.numbers_outlined, isDark, primaryColor, inputFillColor, inputBorderColor),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        const Text('THÔNG TIN NGƯỜI MUA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 12),
        TextFormField(
          controller: _buyerContactNameController,
          style: textStyle,
          decoration: _buildInputDeco('Họ tên người mua hàng', Icons.person_outline, isDark, primaryColor, inputFillColor, inputBorderColor),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _buyerNameController,
          style: textStyle,
          decoration: _buildInputDeco('Tên đơn vị', Icons.business_outlined, isDark, primaryColor, inputFillColor, inputBorderColor).copyWith(
            errorText: getError('Tên người mua'),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _buyerTaxCodeController,
          style: textStyle,
          decoration: _buildInputDeco('Mã số thuế', Icons.credit_card_outlined, isDark, primaryColor, inputFillColor, inputBorderColor).copyWith(
            errorText: getError('MST người mua'),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _buyerAddressController,
          style: textStyle,
          decoration: _buildInputDeco('Địa chỉ', Icons.location_on_outlined, isDark, primaryColor, inputFillColor, inputBorderColor),
        ),
      ],
    );
  }
}
