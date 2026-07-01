import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/invoice_entity.dart';

class InvoicePdfGenerator {
  static Future<void> generateAndPrintInvoice(InvoiceEntity invoice) async {
    final pdf = pw.Document();

    final fontRegular = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();
    final fontItalic = await PdfGoogleFonts.robotoItalic();

    final currencyFormatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );
    final dateFormatter = DateFormat('dd/MM/yyyy');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'SMARTFINANCE JSC',
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 20,
                          color: PdfColor.fromHex('#00D09E'),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Tòa nhà FPT, Khu Công nghệ cao Hòa Lạc',
                        style: pw.TextStyle(font: fontRegular, fontSize: 12),
                      ),
                      pw.Text(
                        'MST: 0102030405',
                        style: pw.TextStyle(font: fontRegular, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 30),

              // Title
              pw.Center(
                child: pw.Text(
                  'HÓA ĐƠN GIÁ TRỊ GIA TĂNG',
                  style: pw.TextStyle(font: fontBold, fontSize: 24),
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text(
                  'Số hóa đơn: ${invoice.invoiceNumber}',
                  style: pw.TextStyle(font: fontItalic, fontSize: 14),
                ),
              ),
              pw.SizedBox(height: 30),

              // Customer Info
              pw.Text(
                'Đơn vị mua hàng: ${invoice.partnerName}',
                style: pw.TextStyle(font: fontBold, fontSize: 14),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Mã số thuế: ${invoice.partnerTaxCode}',
                style: pw.TextStyle(font: fontRegular, fontSize: 12),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Ngày phát hành: ${dateFormatter.format(invoice.issuedDate)}',
                style: pw.TextStyle(font: fontRegular, fontSize: 12),
              ),
              pw.SizedBox(height: 20),

              // Table
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
                children: [
                  // Table Header
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('STT', style: pw.TextStyle(font: fontBold, fontSize: 12), textAlign: pw.TextAlign.center),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Tên sản phẩm / Dịch vụ', style: pw.TextStyle(font: fontBold, fontSize: 12)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('SL', style: pw.TextStyle(font: fontBold, fontSize: 12), textAlign: pw.TextAlign.center),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Thành tiền', style: pw.TextStyle(font: fontBold, fontSize: 12), textAlign: pw.TextAlign.right),
                      ),
                    ],
                  ),
                  // Single Item Row
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('1', style: pw.TextStyle(font: fontRegular, fontSize: 12), textAlign: pw.TextAlign.center),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Dịch vụ phần mềm SmartFinance SaaS', style: pw.TextStyle(font: fontRegular, fontSize: 12)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('1', style: pw.TextStyle(font: fontRegular, fontSize: 12), textAlign: pw.TextAlign.center),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(currencyFormatter.format(invoice.subtotal), style: pw.TextStyle(font: fontRegular, fontSize: 12), textAlign: pw.TextAlign.right),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // Summary
              pw.Container(
                alignment: pw.Alignment.centerRight,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.end,
                      children: [
                        pw.Text('Cộng tiền hàng:', style: pw.TextStyle(font: fontRegular, fontSize: 12)),
                        pw.SizedBox(width: 40),
                        pw.Text(currencyFormatter.format(invoice.subtotal), style: pw.TextStyle(font: fontBold, fontSize: 12)),
                      ],
                    ),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.end,
                      children: [
                        pw.Text('Thuế GTGT (${invoice.vatRate}%):', style: pw.TextStyle(font: fontRegular, fontSize: 12)),
                        pw.SizedBox(width: 40),
                        pw.Text(currencyFormatter.format(invoice.vatAmount), style: pw.TextStyle(font: fontBold, fontSize: 12)),
                      ],
                    ),
                    pw.SizedBox(height: 12),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.end,
                      children: [
                        pw.Text('Tổng cộng tiền thanh toán:', style: pw.TextStyle(font: fontBold, fontSize: 14)),
                        pw.SizedBox(width: 40),
                        pw.Text(currencyFormatter.format(invoice.totalAmount), style: pw.TextStyle(font: fontBold, fontSize: 14, color: PdfColor.fromHex('#00D09E'))),
                      ],
                    ),
                  ],
                ),
              ),

              pw.Spacer(),

              // Signatures
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    children: [
                      pw.Text('Người mua hàng', style: pw.TextStyle(font: fontBold, fontSize: 12)),
                      pw.Text('(Ký, ghi rõ họ tên)', style: pw.TextStyle(font: fontItalic, fontSize: 10)),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Text('Người bán hàng', style: pw.TextStyle(font: fontBold, fontSize: 12)),
                      pw.Text('(Ký, ghi rõ họ tên)', style: pw.TextStyle(font: fontItalic, fontSize: 10)),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'HoaDon_${invoice.invoiceNumber}.pdf',
    );
  }
}
