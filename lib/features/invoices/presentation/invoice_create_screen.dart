import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:smart_finance/core/providers/app_providers.dart';
import 'package:smart_finance/domain/entities/invoice_entity.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo hóa đơn bán ra'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            TextFormField(
              controller: _partnerNameController,
              decoration: InputDecoration(
                labelText: 'Tên Khách hàng / Đối tác',
                prefixIcon: const Icon(Icons.business_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (value) => value == null || value.isEmpty ? 'Nhập tên đối tác' : null,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _partnerTaxCodeController,
              decoration: InputDecoration(
                labelText: 'Mã số thuế',
                prefixIcon: const Icon(Icons.credit_card_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (value) => value == null || value.isEmpty ? 'Nhập mã số thuế' : null,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _subtotalController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Tiền trước thuế (Subtotal) VND',
                prefixIcon: const Icon(Icons.attach_money_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (value) => value == null || int.tryParse(value) == null ? 'Nhập số tiền hợp lệ' : null,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _vatRateController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Thuế suất VAT (%)',
                prefixIcon: const Icon(Icons.percent_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (value) => value == null || int.tryParse(value) == null ? 'Nhập phần trăm thuế' : null,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 32),
            
            // Calc summary card
            Card(
              color: Colors.blueAccent.withOpacity(0.05),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.blueAccent.withOpacity(0.2)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Thuế VAT:'),
                        Text(
                          '${_vatAmount.toString()} VND',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Tổng tiền thanh toán:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          '${_totalAmount.toString()} VND',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.blueAccent,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saveInvoice,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Lưu & Phát hành', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
