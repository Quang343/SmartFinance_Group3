import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_finance/core/providers/app_providers.dart';
import 'package:smart_finance/domain/entities/invoice_entity.dart';
import 'package:smart_finance/core/widgets/scale_on_tap.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class InvoicePreviewScreen extends ConsumerWidget {
  final String invoiceId;

  const InvoicePreviewScreen({super.key, required this.invoiceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final invoiceRepo = ref.watch(invoiceRepositoryProvider);
    final currencyFormatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );
    final dateFormatter = DateFormat('dd/MM/yyyy');

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF06150F)
          : const Color(0xFFF4FAF7),
      appBar: AppBar(
        backgroundColor: isDark
            ? const Color(0xFF06150F)
            : const Color(0xFFF4FAF7),
        elevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        leading: Center(
          child: ScaleOnTap(
            onTap: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                context.go('/invoices/outgoing');
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
                  color: isDark
                      ? const Color(0xFF1E3A2F)
                      : const Color(0xFFEDF2F7),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: isDark
                    ? const Color(0xFF86EFAC)
                    : const Color(0xFF00D09E),
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
            'Xem trước Hóa đơn',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: Colors.white,
              fontSize: 22,
              letterSpacing: -0.5,
            ),
          ),
        ),
      ),
      body: FutureBuilder<InvoiceEntity?>(
        future: invoiceRepo.getById(invoiceId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF00D09E)),
            );
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Text(
                'Không tìm thấy hóa đơn để xem trước.',
                style: TextStyle(
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
            );
          }

          final invoice = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Simulated PDF view
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: DefaultTextStyle(
                      style: const TextStyle(
                        color: Color(0xFF1E293B),
                        fontFamily: 'Courier',
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'SMARTFINANCE JSC',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Color(0xFF00D09E),
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Tòa nhà FPT, Khu Công nghệ cao Hòa Lạc',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'MST: 0102030405',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Icon(
                                Icons.account_balance_wallet_rounded,
                                size: 40,
                                color: const Color(0xFF00D09E).withOpacity(0.8),
                              ),
                            ],
                          ),
                          const Divider(height: 24, color: Colors.black12),
                          const Center(
                            child: Text(
                              'HÓA ĐƠN GIÁ TRỊ GIA TĂNG',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Center(
                            child: Text(
                              'Số hóa đơn: ${invoice.invoiceNumber}',
                              style: const TextStyle(
                                fontStyle: FontStyle.italic,
                                fontSize: 13,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Customer info
                          Text(
                            'Đơn vị mua hàng: ${invoice.partnerName}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Mã số thuế khách hàng: ${invoice.partnerTaxCode}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Ngày phát hành: ${dateFormatter.format(invoice.issuedDate)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black87,
                            ),
                          ),
                          const Divider(height: 24, color: Colors.black12),

                          // Items table header
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  'Tên sản phẩm / Dịch vụ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'SL',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Thành tiền',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 12, color: Colors.black12),

                          // Single Item Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  'Cung cấp Sản phẩm/Dịch vụ cho ${invoice.partnerName}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                              const Expanded(
                                child: Text(
                                  '1',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  currencyFormatter.format(invoice.subtotal),
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24, color: Colors.black12),

                          // Summary block with Expanded labels to prevent overlaps
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Cộng tiền hàng (Subtotal):',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                              Text(
                                currencyFormatter.format(invoice.subtotal),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Thuế suất GTGT (VAT): ${invoice.vatRate}%',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                              Text(
                                currencyFormatter.format(invoice.vatAmount),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 16, color: Colors.black12),
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Tổng cộng tiền thanh toán:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              Text(
                                currencyFormatter.format(invoice.totalAmount),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Color(0xFF00D09E),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _shareInvoice(context, invoice),
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
                        onPressed: () => _saveInvoice(context, invoice),
                        icon: const Icon(Icons.download_rounded, color: Colors.white, size: 20),
                        label: const Text(
                          'Lưu PDF',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981), // slightly different green or use a secondary color
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _printInvoice(context, invoice),
                    icon: const Icon(Icons.print_rounded, color: Colors.white, size: 20),
                    label: const Text(
                      'In Hóa Đơn',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6), // Blue to distinguish
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<pw.Document> _generatePdfDocument(InvoiceEntity invoice) async {
    final pdf = pw.Document();
    final ttf = await PdfGoogleFonts.robotoRegular();
    final ttfBold = await PdfGoogleFonts.robotoBold();
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('HÓA ĐƠN BÁN RA', style: pw.TextStyle(font: ttfBold, fontSize: 24, color: PdfColors.green800)),
              pw.SizedBox(height: 20),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Đơn vị bán: SmartFinance', style: pw.TextStyle(font: ttfBold, fontSize: 14)),
                      pw.Text('Ngày lập: ${DateFormat('dd/MM/yyyy HH:mm').format(invoice.issuedDate)}', style: pw.TextStyle(font: ttf, fontSize: 12)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Mã HĐ: ${invoice.invoiceNumber}', style: pw.TextStyle(font: ttfBold, fontSize: 12)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 30),
              pw.Text('Thông tin khách hàng:', style: pw.TextStyle(font: ttfBold, fontSize: 14)),
              pw.Text('Tên: ${invoice.partnerName}', style: pw.TextStyle(font: ttf, fontSize: 12)),
              if (invoice.partnerTaxCode != null && invoice.partnerTaxCode!.isNotEmpty)
                pw.Text('MST: ${invoice.partnerTaxCode}', style: pw.TextStyle(font: ttf, fontSize: 12)),
              pw.SizedBox(height: 30),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Sản phẩm / Dịch vụ', style: pw.TextStyle(font: ttfBold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('SL', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: ttfBold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Thành tiền', textAlign: pw.TextAlign.right, style: pw.TextStyle(font: ttfBold))),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Cung cấp cho ${invoice.partnerName}', style: pw.TextStyle(font: ttf))),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('1', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: ttf))),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(currencyFormatter.format(invoice.subtotal), textAlign: pw.TextAlign.right, style: pw.TextStyle(font: ttf))),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Tổng tiền chưa thuế (Subtotal)', style: pw.TextStyle(font: ttf))),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('')),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(currencyFormatter.format(invoice.subtotal), textAlign: pw.TextAlign.right, style: pw.TextStyle(font: ttf))),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Thuế VAT (${invoice.vatRate}%)', style: pw.TextStyle(font: ttf))),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('')),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(currencyFormatter.format(invoice.vatAmount), textAlign: pw.TextAlign.right, style: pw.TextStyle(font: ttf))),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Tổng cộng', style: pw.TextStyle(font: ttfBold, color: PdfColors.green800))),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('')),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(currencyFormatter.format(invoice.totalAmount), textAlign: pw.TextAlign.right, style: pw.TextStyle(font: ttfBold, color: PdfColors.green800))),
                    ],
                  ),
                ],
              ),
              pw.Spacer(),
              pw.Center(
                child: pw.Text('Cảm ơn quý khách!', style: pw.TextStyle(font: ttf, fontSize: 12, fontStyle: pw.FontStyle.italic)),
              ),
            ],
          );
        },
      ),
    );
    return pdf;
  }

  Future<void> _shareInvoice(BuildContext context, InvoiceEntity invoice) async {
    try {
      final pdf = await _generatePdfDocument(invoice);
      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'HoaDon_${invoice.invoiceNumber}.pdf',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi chia sẻ PDF: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _saveInvoice(BuildContext context, InvoiceEntity invoice) async {
    try {
      final pdf = await _generatePdfDocument(invoice);
      final bytes = await pdf.save();
      
      Directory? directory;
      if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        directory = await getDownloadsDirectory();
      } else {
        directory = await getApplicationDocumentsDirectory();
      }
      
      if (directory != null) {
        final file = File('${directory.path}/HoaDon_${invoice.invoiceNumber}.pdf');
        await file.writeAsBytes(bytes);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã lưu PDF tại:\n${file.path}'),
              backgroundColor: const Color(0xFF10B981),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi lưu PDF: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _printInvoice(BuildContext context, InvoiceEntity invoice) async {
    try {
      final pdf = await _generatePdfDocument(invoice);
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'HoaDon_${invoice.invoiceNumber}.pdf',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi in hóa đơn: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
