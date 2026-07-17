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
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

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
                            'Đơn vị mua hàng: ${invoice.buyerName}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Mã số thuế khách hàng: ${invoice.buyerTaxCode}',
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
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  child: Text(
                                    'Cung cấp Sản phẩm/Dịch vụ cho ${invoice.buyerName}',
                                    style: TextStyle(
                                      color: const Color(0xFF00D09E),
                                    ),
                                  ),
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
    final ttfItalic = await PdfGoogleFonts.robotoItalic();

    String formatQuantity(double q) {
      return q == q.toInt() ? q.toInt().toString() : q.toString().replaceAll('.', ',');
    }
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: '');
    
    // Convert int to words (simple)
    String numberToWords(int number) {
      if (number == 0) return "Không đồng";
      final units = ["", "nghìn", "triệu", "tỷ", "nghìn tỷ", "triệu tỷ"];
      final words = ["không", "một", "hai", "ba", "bốn", "năm", "sáu", "bảy", "tám", "chín"];

      String readGroup(int n, bool fullString) {
        String res = "";
        int hundred = n ~/ 100;
        int ten = (n % 100) ~/ 10;
        int unit = n % 10;

        if (fullString || hundred > 0) {
          res += "${words[hundred]} trăm ";
        }
        if (ten == 0 && unit > 0 && (fullString || hundred > 0)) {
          res += "lẻ ";
        } else if (ten == 1) {
          res += "mười ";
        } else if (ten > 1) {
          res += "${words[ten]} mươi ";
        }
        if (unit == 1 && ten > 1) {
          res += "mốt ";
        } else if (unit == 5 && ten > 0) {
          res += "lăm ";
        } else if (unit > 0) {
          res += "${words[unit]} ";
        }
        return res.trim();
      }

      String result = "";
      int group = 0;
      int temp = number;
      while (temp > 0) {
        int n = temp % 1000;
        if (n > 0) {
          String groupWords = readGroup(n, temp ~/ 1000 > 0);
          result = "$groupWords ${units[group]} $result".trim();
        }
        group++;
        temp ~/= 1000;
      }
      
      result = result.trim() + " đồng chẵn.";
      return result[0].toUpperCase() + result.substring(1);
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text('HÓA ĐƠN GIÁ TRỊ GIA TĂNG', style: pw.TextStyle(font: ttfBold, fontSize: 20)),
                        pw.Text('(Bản thể hiện của hóa đơn điện tử)', style: pw.TextStyle(font: ttfItalic, fontSize: 12)),
                        pw.SizedBox(height: 4),
                        pw.Text('Ngày ${invoice.issuedDate.day} tháng ${invoice.issuedDate.month} năm ${invoice.issuedDate.year}', style: pw.TextStyle(font: ttfItalic, fontSize: 12)),
                      ],
                    ),
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Mẫu số: 01GTKT0/001', style: pw.TextStyle(font: ttf, fontSize: 10)),
                      pw.Text('Ký hiệu: HM/26E', style: pw.TextStyle(font: ttf, fontSize: 10)),
                      pw.Text('Số: ${invoice.invoiceNumber.replaceAll(RegExp(r'[^0-9]'), '').padLeft(7, '0')}', style: pw.TextStyle(font: ttfBold, fontSize: 10)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              
              // Seller Info
              pw.Text('Đơn vị bán hàng: ${invoice.sellerName}', style: pw.TextStyle(font: ttfBold, fontSize: 11)),
              pw.Text('Mã số thuế: ${invoice.sellerTaxCode}', style: pw.TextStyle(font: ttfBold, fontSize: 11)),
              pw.Text('Địa chỉ: ${invoice.sellerAddress ?? "Không có"}', style: pw.TextStyle(font: ttf, fontSize: 11)),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Điện thoại: ${invoice.sellerPhone ?? ""}', style: pw.TextStyle(font: ttf, fontSize: 11)),
                  pw.Text('Số tài khoản: ${invoice.sellerBankAccount ?? ""}${invoice.sellerBankName != null ? " tại ${invoice.sellerBankName}" : ""}', style: pw.TextStyle(font: ttf, fontSize: 11)),
                ]
              ),
              pw.SizedBox(height: 10),
              pw.Divider(thickness: 1, color: PdfColors.black),
              pw.SizedBox(height: 10),

              // Buyer Info
              if (invoice.buyerContactName != null && invoice.buyerContactName!.isNotEmpty)
                pw.Text('Họ tên người mua hàng: ${invoice.buyerContactName}', style: pw.TextStyle(font: ttf, fontSize: 11))
              else
                pw.Text('Họ tên người mua hàng: ', style: pw.TextStyle(font: ttf, fontSize: 11)),
              pw.Text('Tên đơn vị: ${invoice.buyerName}', style: pw.TextStyle(font: ttfBold, fontSize: 11)),
              pw.Text('Mã số thuế: ${invoice.buyerTaxCode}', style: pw.TextStyle(font: ttfBold, fontSize: 11)),
              pw.Text('Địa chỉ: ${invoice.buyerAddress ?? "Không có"}', style: pw.TextStyle(font: ttf, fontSize: 11)),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Hình thức thanh toán: ${invoice.paymentMethod ?? "TM/CK"}', style: pw.TextStyle(font: ttf, fontSize: 11)),
                  pw.Text('', style: pw.TextStyle(font: ttf, fontSize: 11)),
                ]
              ),
              pw.SizedBox(height: 15),

              // Items Table
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
                columnWidths: {
                  0: const pw.FixedColumnWidth(30),
                  1: const pw.FixedColumnWidth(80),
                  2: const pw.FlexColumnWidth(),
                  3: const pw.FixedColumnWidth(60),
                  4: const pw.FixedColumnWidth(50),
                  5: const pw.FixedColumnWidth(80),
                  6: const pw.FixedColumnWidth(90),
                },
                children: [
                  // Table Header
                  pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('STT', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: ttfBold, fontSize: 10))),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Mã hàng', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: ttfBold, fontSize: 10))),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Tên hàng hóa, dịch vụ', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: ttfBold, fontSize: 10))),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Đơn vị tính', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: ttfBold, fontSize: 10))),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Số lượng', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: ttfBold, fontSize: 10))),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Đơn giá', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: ttfBold, fontSize: 10))),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Thành tiền', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: ttfBold, fontSize: 10))),
                    ],
                  ),
                  // Table sub-header mapping
                  pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(2), child: pw.Text('A', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: ttf, fontSize: 9))),
                      pw.Padding(padding: const pw.EdgeInsets.all(2), child: pw.Text('B', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: ttf, fontSize: 9))),
                      pw.Padding(padding: const pw.EdgeInsets.all(2), child: pw.Text('C', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: ttf, fontSize: 9))),
                      pw.Padding(padding: const pw.EdgeInsets.all(2), child: pw.Text('D', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: ttf, fontSize: 9))),
                      pw.Padding(padding: const pw.EdgeInsets.all(2), child: pw.Text('1', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: ttf, fontSize: 9))),
                      pw.Padding(padding: const pw.EdgeInsets.all(2), child: pw.Text('2', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: ttf, fontSize: 9))),
                      pw.Padding(padding: const pw.EdgeInsets.all(2), child: pw.Text('3 = 1 x 2', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: ttf, fontSize: 9))),
                    ],
                  ),
                  // Items
                  ...invoice.items.asMap().entries.map((entry) {
                    int index = entry.key;
                    var item = entry.value;
                    return pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('${index + 1}', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: ttf, fontSize: 10))),
                        pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(item.itemCode, textAlign: pw.TextAlign.center, style: pw.TextStyle(font: ttf, fontSize: 10))),
                        pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(item.itemName, style: pw.TextStyle(font: ttf, fontSize: 10))),
                        pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(item.unit, textAlign: pw.TextAlign.center, style: pw.TextStyle(font: ttf, fontSize: 10))),
                        pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(formatQuantity(item.quantity), textAlign: pw.TextAlign.center, style: pw.TextStyle(font: ttf, fontSize: 10))),
                        pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(currencyFormatter.format(item.unitPrice).trim(), textAlign: pw.TextAlign.right, style: pw.TextStyle(font: ttf, fontSize: 10))),
                        pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(currencyFormatter.format(item.totalAmount).trim(), textAlign: pw.TextAlign.right, style: pw.TextStyle(font: ttf, fontSize: 10))),
                      ],
                    );
                  }),
                ],
              ),
              
              // Footer Rows (Subtotal, VAT, Total, In Words)
              pw.Container(
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    left: pw.BorderSide(width: 0.5),
                    right: pw.BorderSide(width: 0.5),
                    bottom: pw.BorderSide(width: 0.5),
                  )
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Row 1: Subtotal
                    pw.Row(
                      children: [
                        pw.Expanded(child: pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Cộng tiền hàng:', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: ttfBold, fontSize: 10)))),
                        pw.Container(
                          width: 90,
                          decoration: const pw.BoxDecoration(border: pw.Border(left: pw.BorderSide(width: 0.5))),
                          padding: const pw.EdgeInsets.all(4),
                          alignment: pw.Alignment.centerRight,
                          child: pw.Text(currencyFormatter.format(invoice.subtotal).trim(), style: pw.TextStyle(font: ttfBold, fontSize: 10)),
                        ),
                      ]
                    ),
                    pw.Divider(thickness: 0.5, color: PdfColors.black, height: 0),
                    // Row 2: VAT
                    pw.Row(
                      children: [
                        pw.Expanded(
                          flex: 1, 
                          child: pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Thuế suất GTGT: ${invoice.vatRate}%', style: pw.TextStyle(font: ttf, fontSize: 10))),
                        ),
                        pw.Container(width: 0.5, height: 20, color: PdfColors.black), // vertical line
                        pw.Expanded(
                          flex: 2,
                          child: pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Tiền thuế GTGT:', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: ttfBold, fontSize: 10))),
                        ),
                        pw.Container(
                          width: 90,
                          decoration: const pw.BoxDecoration(border: pw.Border(left: pw.BorderSide(width: 0.5))),
                          padding: const pw.EdgeInsets.all(4),
                          alignment: pw.Alignment.centerRight,
                          child: pw.Text(currencyFormatter.format(invoice.vatAmount).trim(), style: pw.TextStyle(font: ttfBold, fontSize: 10)),
                        ),
                      ]
                    ),
                    pw.Divider(thickness: 0.5, color: PdfColors.black, height: 0),
                    // Row 3: Total
                    pw.Row(
                      children: [
                        pw.Expanded(child: pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Tổng tiền thanh toán:', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: ttfBold, fontSize: 10)))),
                        pw.Container(
                          width: 90,
                          decoration: const pw.BoxDecoration(border: pw.Border(left: pw.BorderSide(width: 0.5))),
                          padding: const pw.EdgeInsets.all(4),
                          alignment: pw.Alignment.centerRight,
                          child: pw.Text(currencyFormatter.format(invoice.totalAmount).trim(), style: pw.TextStyle(font: ttfBold, fontSize: 10)),
                        ),
                      ]
                    ),
                    pw.Divider(thickness: 0.5, color: PdfColors.black, height: 0),
                    // Row 4: In Words
                    pw.Container(
                      width: double.infinity,
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('Số tiền viết bằng chữ: ${numberToWords(invoice.totalAmount)}', style: pw.TextStyle(font: ttfBold, fontStyle: pw.FontStyle.italic, fontSize: 10)),
                    ),
                  ]
                )
              ),
              
              pw.SizedBox(height: 20),

              // Signatures
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text('Người chuyển đổi', style: pw.TextStyle(font: ttfBold, fontSize: 10)),
                      pw.Text('(Ký, ghi rõ họ, tên)', style: pw.TextStyle(font: ttfItalic, fontSize: 10)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text('Người mua hàng', style: pw.TextStyle(font: ttfBold, fontSize: 10)),
                      pw.Text('(Ký, ghi rõ họ, tên)', style: pw.TextStyle(font: ttfItalic, fontSize: 10)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text('Người bán hàng', style: pw.TextStyle(font: ttfBold, fontSize: 10)),
                      pw.Text('(Ký, ghi rõ họ, tên)', style: pw.TextStyle(font: ttfItalic, fontSize: 10)),
                    ],
                  ),
                ],
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
      final bytes = await pdf.save();
      
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/HoaDon_${invoice.invoiceNumber}.pdf');
      await file.writeAsBytes(bytes);
      
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Hóa đơn ${invoice.invoiceNumber} từ Smart Finance',
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
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Mở ngay',
                textColor: Colors.white,
                onPressed: () {
                  OpenFilex.open(file.path);
                },
              ),
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
