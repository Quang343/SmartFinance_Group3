import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../core/providers/app_providers.dart';
import '../../../domain/entities/invoice_entity.dart';
import '../../../core/widgets/scale_on_tap.dart';

class InvoiceScanScreen extends ConsumerStatefulWidget {
  const InvoiceScanScreen({super.key});

  @override
  ConsumerState<InvoiceScanScreen> createState() => _InvoiceScanScreenState();
}

class _InvoiceScanScreenState extends ConsumerState<InvoiceScanScreen> {
  OcrStatus _status = OcrStatus.notStarted;
  double _progress = 0.0;
  
  // Simulated extracted data
  String _partnerName = '';
  String _partnerTaxCode = '';
  int _subtotal = 0;
  int _vatRate = 10;
  int _totalAmount = 0;

  void _simulateScan() async {
    setState(() {
      _status = OcrStatus.imageSelected;
    });

    await Future.delayed(const Duration(milliseconds: 800));

    setState(() {
      _status = OcrStatus.scanning;
      _progress = 0.0;
    });

    // Animate progress bar
    for (int i = 1; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 200));
      if (mounted) {
        setState(() {
          _progress = i / 10.0;
        });
      }
    }

    if (mounted) {
      setState(() {
        _status = OcrStatus.extracted;
        // Mock extracted data values
        _partnerName = 'Công ty Cổ phần Vận tải biển Việt Nam';
        _partnerTaxCode = '0301427189';
        _subtotal = 1200000;
        _vatRate = 10;
        _totalAmount = 1320000;
      });
    }
  }

  void _saveExtractedInvoice() async {
    final repo = ref.read(invoiceRepositoryProvider);
    final invoice = InvoiceEntity(
      id: const Uuid().v4(),
      invoiceNumber: 'OCR-INV-${DateTime.now().year}-${1000 + DateTime.now().millisecond}',
      partnerName: _partnerName,
      partnerTaxCode: _partnerTaxCode,
      subtotal: _subtotal,
      vatRate: _vatRate,
      vatAmount: (_subtotal * _vatRate / 100).round(),
      totalAmount: _totalAmount,
      ocrStatus: OcrStatus.extracted,
      ocrConfidence: 0.94,
      type: InvoiceType.incoming,
      issuedDate: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      imagePath: 'mock_path_ocr.png',
    );

    await repo.create(invoice);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hóa đơn đã được lưu vào hệ thống thành công!'),
          backgroundColor: Colors.green,
        ),
      );
      context.go('/invoices/incoming');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart OCR Scan'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: _buildMainContent(isDark),
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_status == OcrStatus.notStarted)
              ScaleOnTap(
                onTap: _simulateScan,
                child: ElevatedButton.icon(
                  onPressed: null, // set to null to let ScaleOnTap handle tap and prevent double trigger
                  icon: const Icon(Icons.photo_camera),
                  label: const Text('Chụp / Chọn ảnh hóa đơn', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: theme.colorScheme.primary,
                    disabledForegroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            if (_status == OcrStatus.extracted) ...[
              ScaleOnTap(
                onTap: _saveExtractedInvoice,
                child: ElevatedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Xác nhận & Lưu hóa đơn', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.green,
                    disabledForegroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ScaleOnTap(
                onTap: () => setState(() => _status = OcrStatus.notStarted),
                child: OutlinedButton(
                  onPressed: null,
                  child: const Text('Quét lại', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(bool isDark) {
    final theme = Theme.of(context);
    switch (_status) {
      case OcrStatus.notStarted:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'Chưa chọn hóa đơn',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Tải lên hoặc chụp ảnh hóa đơn đầu vào để trích xuất thông tin tự động.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        );
      case OcrStatus.imageSelected:
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Đang tải ảnh lên...', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        );
      case OcrStatus.scanning:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.document_scanner_outlined, size: 72, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              const Text('Đang quét OCR & Phân tích cấu trúc...', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              LinearProgressIndicator(value: _progress, color: theme.colorScheme.primary),
            ],
          ),
        );
      case OcrStatus.extracted:
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.done_all, color: Colors.green),
                  SizedBox(width: 8),
                  Text(
                    'Đã trích xuất thông tin thành công (Độ tin cậy 94%)',
                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ],
              ),
              const Divider(height: 24),
              _buildExtractedField('Tên đối tác', _partnerName, (val) => _partnerName = val),
              _buildExtractedField('Mã số thuế', _partnerTaxCode, (val) => _partnerTaxCode = val),
              _buildExtractedField('Tiền trước thuế (VND)', _subtotal.toString(), (val) => _subtotal = int.tryParse(val) ?? 0),
              _buildExtractedField('Thuế suất (%)', _vatRate.toString(), (val) => _vatRate = int.tryParse(val) ?? 0),
              _buildExtractedField('Tổng thanh toán (VND)', _totalAmount.toString(), (val) => _totalAmount = int.tryParse(val) ?? 0),
            ],
          ),
        );
      default:
        return Container();
    }
  }

  Widget _buildExtractedField(String label, String value, Function(String) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 4),
          TextFormField(
            initialValue: value,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
