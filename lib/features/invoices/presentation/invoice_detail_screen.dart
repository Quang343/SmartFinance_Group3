import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:smart_finance/core/providers/app_providers.dart';
import 'package:smart_finance/domain/entities/invoice_entity.dart';
import 'package:smart_finance/domain/entities/transaction_entity.dart';
import 'package:smart_finance/core/widgets/scale_on_tap.dart';
import 'package:smart_finance/core/constants/route_names.dart';

class InvoiceDetailScreen extends ConsumerStatefulWidget {
  final String invoiceId;

  const InvoiceDetailScreen({super.key, required this.invoiceId});

  @override
  ConsumerState<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends ConsumerState<InvoiceDetailScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();

  String _getOcrStatusText(OcrStatus status) {
    switch (status) {
      case OcrStatus.notStarted:
        return 'Chưa bắt đầu';
      case OcrStatus.imageSelected:
        return 'Đã chọn ảnh';
      case OcrStatus.scanning:
        return 'Đang quét';
      case OcrStatus.extracted:
        return 'Đã trích xuất';
      case OcrStatus.failed:
        return 'Quét thất bại';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
    final dateFormatter = DateFormat('dd/MM/yyyy HH:mm');
    final invoiceRepository = ref.watch(invoiceRepositoryProvider);
    final transactionRepository = ref.watch(transactionRepositoryProvider);

    return FutureBuilder(
      future: Future.wait([
        invoiceRepository.getById(widget.invoiceId),
        transactionRepository.getAll(),
      ]),
      builder: (context, snapshot) {
        final data = snapshot.data;
        final invoice = data != null ? data[0] as InvoiceEntity? : null;
        final isIncoming = invoice?.type != InvoiceType.outgoing;
        final transactions = data != null ? data[1] as List<TransactionEntity> : <TransactionEntity>[];
        final hasTransaction = transactions.any((tx) => tx.invoiceId == widget.invoiceId);

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF06150F) : const Color(0xFFF4FAF7),
          appBar: AppBar(
            backgroundColor: isDark ? const Color(0xFF06150F) : const Color(0xFFF4FAF7),
            elevation: 0,
            centerTitle: false,
            titleSpacing: 0,
            leading: Center(
              child: ScaleOnTap(
                onTap: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else {
                    context.go(isIncoming ? '/invoices/incoming' : '/invoices/outgoing');
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0D281E) : Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      if (!isDark)
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                    ],
                    border: Border.all(
                      color: isDark ? const Color(0xFF1E3A2F) : const Color(0xFFEDF2F7),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF00D09E),
                    size: 16,
                  ),
                ),
              ),
            ),
            title: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFF00D09E), Color(0xFF34D399)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: const Text(
                'Chi tiết hóa đơn',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  fontSize: 22,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            actions: [
              if (invoice != null && invoice.type == InvoiceType.outgoing)
                Center(
                  child: ScaleOnTap(
                    onTap: () => context.push('/invoices/outgoing/preview/${invoice.id}'),
                    child: Container(
                      margin: const EdgeInsets.only(right: 20),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0D281E) : Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          if (!isDark)
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                        ],
                        border: Border.all(
                          color: isDark ? const Color(0xFF1E3A2F) : const Color(0xFFEDF2F7),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.picture_as_pdf_rounded,
                        color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF00D09E),
                        size: 20,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          body: snapshot.connectionState == ConnectionState.waiting
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF00D09E)))
              : invoice == null
                  ? Center(
                      child: Text(
                        'Không tìm thấy hóa đơn hoặc có lỗi xảy ra.',
                        style: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Screenshot(
                        controller: _screenshotController,
                        child: Container(
                          color: isDark ? const Color(0xFF06150F) : const Color(0xFFF4FAF7),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                          // Header Receipt Card
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0D251C) : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isDark ? const Color(0xFF1E3A2F) : const Color(0xFFE2E8F0),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isDark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.04),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        isIncoming ? 'Hóa đơn đầu vào' : 'Hóa đơn đầu ra',
                                        style: TextStyle(
                                          color: isIncoming ? const Color(0xFFF97316) : const Color(0xFF00D09E),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isDark 
                                            ? (isIncoming ? const Color(0xFF431407) : const Color(0xFF064E3B)) 
                                            : (isIncoming ? const Color(0xFFFFF7ED) : const Color(0xFFECFDF5)),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        _getOcrStatusText(invoice.ocrStatus).toUpperCase(),
                                        style: TextStyle(
                                          color: isIncoming ? const Color(0xFFF97316) : const Color(0xFF00D09E),
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Số: ${invoice.invoiceNumber}',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : const Color(0xFF093021),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  currencyFormatter.format(invoice.totalAmount),
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    color: isIncoming ? const Color(0xFFF97316) : const Color(0xFF00D09E),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Detail Fields Card
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0D251C) : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isDark ? const Color(0xFF1E3A2F) : const Color(0xFFE2E8F0),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isDark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.04),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Thông tin chung',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: isDark ? Colors.white : const Color(0xFF093021),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Divider(color: isDark ? const Color(0xFF1E3A2F) : const Color(0xFFE2E8F0)),
                                const SizedBox(height: 8),
                                _DetailRow(
                                  label: 'Đối tác',
                                  value: invoice.partnerName,
                                ),
                                _DetailRow(
                                  label: 'Mã số thuế đối tác',
                                  value: invoice.partnerTaxCode,
                                ),
                                _DetailRow(
                                  label: 'Ngày phát hành',
                                  value: dateFormatter.format(invoice.issuedDate),
                                ),
                                _DetailRow(
                                  label: 'Tiền trước thuế',
                                  value: currencyFormatter.format(invoice.subtotal),
                                ),
                                _DetailRow(
                                  label: 'Thuế suất VAT',
                                  value: '${invoice.vatRate}%',
                                ),
                                _DetailRow(
                                  label: 'Tiền thuế VAT',
                                  value: currencyFormatter.format(invoice.vatAmount),
                                ),
                                if (invoice.ocrConfidence != null)
                                  _DetailRow(
                                    label: 'Độ tin cậy OCR',
                                    value: '${(invoice.ocrConfidence! * 100).toStringAsFixed(1)}%',
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          if (hasTransaction) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0D251C) : const Color(0xFFF0FDF4),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFF00D09E)),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle_rounded, color: Color(0xFF00D09E)),
                                  SizedBox(width: 8),
                                  Text(
                                    'Đã thanh toán',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF00D09E),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _shareScreenshot(context),
                                    icon: const Icon(Icons.share_rounded, color: Colors.white, size: 20),
                                    label: const Text(
                                      'Chia sẻ',
                                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF00D09E),
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      elevation: 0,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _saveScreenshot(context),
                                    icon: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
                                    label: const Text(
                                      'Chụp',
                                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF10B981),
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      elevation: 0,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                          ],

                          // Image View Section
                          if (invoice.imagePath != null && invoice.imagePath!.isNotEmpty) ...[
                            Text(
                              'Ảnh hóa đơn đính kèm',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isDark ? Colors.white : const Color(0xFF093021),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              constraints: const BoxConstraints(maxHeight: 400),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0D251C) : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isDark ? const Color(0xFF1E3A2F) : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: invoice.imagePath == 'mock_path_ocr.png' || !File(invoice.imagePath!).existsSync()
                                    ? const Padding(
                                        padding: EdgeInsets.all(40.0),
                                        child: Center(
                                          child: Icon(
                                            Icons.image_outlined,
                                            size: 64,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      )
                                    : Image.file(
                                        File(invoice.imagePath!),
                                        fit: BoxFit.contain,
                                      ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
          bottomNavigationBar: invoice != null && !hasTransaction
              ? SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: ScaleOnTap(
                      onTap: () {
                        context.pushNamed(
                          RouteNames.transactionForm,
                          extra: {
                            'initialAmount': invoice.totalAmount,
                            'initialNote': isIncoming
                                ? 'Thanh toán hóa đơn: ${invoice.invoiceNumber}'
                                : 'Doanh thu từ hóa đơn: ${invoice.invoiceNumber}',
                            'invoiceId': invoice.id,
                          },
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00D09E),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00D09E).withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(isIncoming ? Icons.add_card_rounded : Icons.payments_rounded, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              isIncoming ? 'Tạo khoản chi' : 'Tạo khoản thu',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }

  Future<void> _shareScreenshot(BuildContext context) async {
    try {
      final imageBytes = await _screenshotController.capture();
      if (imageBytes != null) {
        final directory = await getTemporaryDirectory();
        final imagePath = await File('${directory.path}/hoadon.png').create();
        await imagePath.writeAsBytes(imageBytes);
        await Share.shareXFiles([XFile(imagePath.path)], text: 'Hóa đơn từ Smart Finance');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi chia sẻ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _saveScreenshot(BuildContext context) async {
    try {
      final imageBytes = await _screenshotController.capture();
      if (imageBytes != null) {
        Directory? directory;
        if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
          directory = await getDownloadsDirectory();
        } else {
          directory = await getApplicationDocumentsDirectory();
        }
        
        if (directory != null) {
          final file = File('${directory.path}/hoadon_${DateTime.now().millisecondsSinceEpoch}.png');
          await file.writeAsBytes(imageBytes);
          
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Đã lưu ảnh tại:\n${file.path}'),
                backgroundColor: const Color(0xFF10B981),
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi lưu ảnh: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: isDark ? Colors.white60 : Colors.black54, 
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: FontWeight.bold, 
                fontSize: 15,
                color: isDark ? Colors.white : const Color(0xFF093021),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
