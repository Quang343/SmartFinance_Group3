import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
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

  final ImagePicker _picker = ImagePicker();
  String? _selectedImagePath;

  void _showImageSourcePicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF060E0A) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt_rounded, color: Color(0xFF00D09E)),
                  title: Text('Chụp ảnh (Camera)', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_rounded, color: Color(0xFF00D09E)),
                  title: Text('Chọn từ thư viện (Gallery)', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _selectedImagePath = image.path;
        });
        _simulateScan();
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = 'Lỗi chọn ảnh: $e';
        if (e.toString().contains('cameraDelegate')) {
          errorMsg = 'Tính năng chụp ảnh chưa được hỗ trợ trên thiết bị này (Windows/Desktop). Vui lòng chọn từ Thư viện!';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
        );
      }
    }
  }

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
      paymentStatus: PaymentStatus.unpaid,
      ocrConfidence: 0.94,
      type: InvoiceType.incoming,
      issuedDate: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      imagePath: _selectedImagePath ?? 'mock_path_ocr.png',
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
  Widget _buildScannerTarget(Widget child, bool isDark) {
    final borderColor = const Color(0xFF00D09E);
    return Stack(
      children: [
        Positioned.fill(
          child: Center(child: child),
        ),
        // Top Left
        Positioned(
          top: 0,
          left: 0,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: borderColor, width: 3),
                left: BorderSide(color: borderColor, width: 3),
              ),
            ),
          ),
        ),
        // Top Right
        Positioned(
          top: 0,
          right: 0,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: borderColor, width: 3),
                right: BorderSide(color: borderColor, width: 3),
              ),
            ),
          ),
        ),
        // Bottom Left
        Positioned(
          bottom: 0,
          left: 0,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: borderColor, width: 3),
                left: BorderSide(color: borderColor, width: 3),
              ),
            ),
          ),
        ),
        // Bottom Right
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: borderColor, width: 3),
                right: BorderSide(color: borderColor, width: 3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = const Color(0xFF00D09E);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF060E0A) : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Smart OCR Scan',
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
              context.go('/invoices/incoming');
            }
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F1E15) : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark ? const Color(0xFF1E382B) : Colors.grey.shade200,
                    width: 1.5,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: _buildScannerTarget(
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: _buildMainContent(isDark),
                    ),
                    isDark,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_status == OcrStatus.notStarted)
              ScaleOnTap(
                onTap: _showImageSourcePicker,
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
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.photo_camera_rounded, color: Color(0xFF060E0A)),
                      SizedBox(width: 8),
                      Text(
                        'Chụp / Chọn ảnh hóa đơn',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF060E0A),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (_status == OcrStatus.extracted) ...[
              ScaleOnTap(
                onTap: _saveExtractedInvoice,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline_rounded, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Xác nhận & Lưu hóa đơn',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ScaleOnTap(
                onTap: () => setState(() => _status = OcrStatus.notStarted),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? const Color(0xFF1E382B) : Colors.grey.shade400,
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Quét lại',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
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
    final primaryColor = const Color(0xFF00D09E);
    switch (_status) {
      case OcrStatus.notStarted:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF060E0A) : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? const Color(0xFF1E382B) : Colors.grey.shade100,
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.receipt_long_rounded,
                size: 64,
                color: primaryColor.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Chưa chọn hóa đơn',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Tải lên hoặc chụp ảnh hóa đơn đầu vào để trích xuất thông tin tự động.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? Colors.white60 : Colors.black54,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
          ],
        );
      case OcrStatus.imageSelected:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: primaryColor),
              const SizedBox(height: 20),
              Text(
                'Đang tải ảnh lên...',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        );
      case OcrStatus.scanning:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.document_scanner_rounded, size: 72, color: primaryColor),
              const SizedBox(height: 20),
              Text(
                'Đang quét OCR & Phân tích...',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _progress,
                    color: primaryColor,
                    backgroundColor: isDark ? const Color(0xFF060E0A) : Colors.grey.shade200,
                    minHeight: 6,
                  ),
                ),
              ),
            ],
          ),
        );
      case OcrStatus.extracted:
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0x1500D09E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0x3000D09E)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: Color(0xFF00D09E), size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Đã trích xuất thành công (Độ tin cậy 94%)',
                        style: TextStyle(
                          color: Color(0xFF00D09E),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildExtractedField('Tên đối tác', _partnerName, isDark, (val) => _partnerName = val),
              _buildExtractedField('Mã số thuế', _partnerTaxCode, isDark, (val) => _partnerTaxCode = val),
              _buildExtractedField('Tiền trước thuế (VND)', _subtotal.toString(), isDark, (val) => _subtotal = int.tryParse(val) ?? 0),
              _buildExtractedField('Thuế suất (%)', _vatRate.toString(), isDark, (val) => _vatRate = int.tryParse(val) ?? 0),
              _buildExtractedField('Tổng thanh toán (VND)', _totalAmount.toString(), isDark, (val) => _totalAmount = int.tryParse(val) ?? 0),
            ],
          ),
        );
      default:
        return Container();
    }
  }

  Widget _buildExtractedField(String label, String value, bool isDark, Function(String) onChanged) {
    final primaryColor = const Color(0xFF00D09E);
    final inputFillColor = isDark ? const Color(0xFF060E0A) : Colors.grey.shade50;
    final inputBorderColor = isDark ? const Color(0xFF1E382B) : Colors.grey.shade300;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            initialValue: value,
            style: TextStyle(
              fontSize: 15,
              color: isDark ? Colors.white : Colors.black87,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: inputFillColor,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: inputBorderColor, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: primaryColor, width: 2),
              ),
            ),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
