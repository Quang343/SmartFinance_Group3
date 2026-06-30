import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:smart_finance/core/providers/app_providers.dart';
import 'package:smart_finance/domain/entities/invoice_entity.dart';
import 'package:smart_finance/core/widgets/scale_on_tap.dart';

class InvoiceCreateScreen extends ConsumerStatefulWidget {
  const InvoiceCreateScreen({super.key});

  @override
  ConsumerState<InvoiceCreateScreen> createState() => _InvoiceCreateScreenState();
}

class _InvoiceCreateScreenState extends ConsumerState<InvoiceCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _partnerNameController = TextEditingController();
  final _partnerTaxCodeController = TextEditingController();
  final _subtotalController = TextEditingController();
  final _vatRateController = TextEditingController(text: '10');

  int get _subtotal => int.tryParse(_subtotalController.text) ?? 0;
  int get _vatRate => int.tryParse(_vatRateController.text) ?? 0;
  int get _vatAmount => (_subtotal * _vatRate / 100).round();
  int get _totalAmount => _subtotal + _vatAmount;

  @override
  void dispose() {
    _partnerNameController.dispose();
    _partnerTaxCodeController.dispose();
    _subtotalController.dispose();
    _vatRateController.dispose();
    super.dispose();
  }

  void _saveInvoice() async {
    if (_formKey.currentState!.validate()) {
      final repo = ref.read(invoiceRepositoryProvider);
      final newInvoice = InvoiceEntity(
        id: const Uuid().v4(),
        invoiceNumber: 'INV-${DateTime.now().year}-${1000 + DateTime.now().millisecond}',
        partnerName: _partnerNameController.text,
        partnerTaxCode: _partnerTaxCodeController.text,
        subtotal: _subtotal,
        vatRate: _vatRate,
        vatAmount: _vatAmount,
        totalAmount: _totalAmount,
        ocrStatus: OcrStatus.extracted,
        paymentStatus: PaymentStatus.unpaid,
        ocrConfidence: 1.0,
        type: InvoiceType.outgoing,
        issuedDate: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repo.create(newInvoice);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hóa đơn đầu ra đã được tạo thành công!'),
          backgroundColor: Colors.green,
        ),
      );
      context.go('/invoices/outgoing');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF00D09E);
    final inputFillColor = isDark ? const Color(0xFF0F1E15) : Colors.grey.shade50;
    final inputBorderColor = isDark ? const Color(0xFF1E382B) : Colors.grey.shade300;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF060E0A) : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Tạo hóa đơn bán ra',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white70 : Colors.black87, size: 20),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/invoices/outgoing');
            }
          },
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          children: [
            TextFormField(
              controller: _partnerNameController,
              style: TextStyle(fontSize: 15, color: isDark ? Colors.white : Colors.black87),
              decoration: InputDecoration(
                labelText: 'Tên Khách hàng / Đối tác',
                labelStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 14),
                prefixIcon: const Icon(Icons.business_outlined, color: Color(0xFF00D09E)),
                filled: true,
                fillColor: inputFillColor,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: inputBorderColor, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: primaryColor, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
                ),
              ),
              validator: (value) => value == null || value.isEmpty ? 'Nhập tên đối tác' : null,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _partnerTaxCodeController,
              style: TextStyle(fontSize: 15, color: isDark ? Colors.white : Colors.black87),
              decoration: InputDecoration(
                labelText: 'Mã số thuế',
                labelStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 14),
                prefixIcon: const Icon(Icons.credit_card_outlined, color: Color(0xFF00D09E)),
                filled: true,
                fillColor: inputFillColor,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: inputBorderColor, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: primaryColor, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
                ),
              ),
              validator: (value) => value == null || value.isEmpty ? 'Nhập mã số thuế' : null,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _subtotalController,
              keyboardType: TextInputType.number,
              style: TextStyle(fontSize: 15, color: isDark ? Colors.white : Colors.black87),
              decoration: InputDecoration(
                labelText: 'Tiền trước thuế (Subtotal) VND',
                labelStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 14),
                prefixIcon: const Icon(Icons.attach_money_outlined, color: Color(0xFF00D09E)),
                filled: true,
                fillColor: inputFillColor,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: inputBorderColor, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: primaryColor, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
                ),
              ),
              validator: (value) => value == null || int.tryParse(value) == null ? 'Nhập số tiền hợp lệ' : null,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _vatRateController,
              keyboardType: TextInputType.number,
              style: TextStyle(fontSize: 15, color: isDark ? Colors.white : Colors.black87),
              decoration: InputDecoration(
                labelText: 'Thuế suất VAT (%)',
                labelStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 14),
                prefixIcon: const Icon(Icons.percent_outlined, color: Color(0xFF00D09E)),
                filled: true,
                fillColor: inputFillColor,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: inputBorderColor, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: primaryColor, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
                ),
              ),
              validator: (value) => value == null || int.tryParse(value) == null ? 'Nhập phần trăm thuế' : null,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 28),
            
            // Calc summary card
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F1E15) : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark ? const Color(0xFF1E382B) : Colors.grey.shade200,
                  width: 1.5,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Thuế VAT:',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        Text(
                          '${_vatAmount.toString()} VND',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Tổng tiền thanh toán:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        Text(
                          '${_totalAmount.toString()} VND',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Color(0xFF00D09E),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            ScaleOnTap(
              onTap: _saveInvoice,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'Lưu & Phát hành',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF060E0A),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
