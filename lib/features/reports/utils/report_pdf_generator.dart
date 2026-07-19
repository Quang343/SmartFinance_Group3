import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

class ReportPdfGenerator {
  static Future<pw.Document> buildReportPdf({
    required int totalIncome,
    required int totalExpense,
    required int netBalance,
    required List<MapEntry<String, double>> categories,
    required String periodLabel,
  }) async {
    final pdf = pw.Document();
    final fontRegular = pw.Font.ttf(await rootBundle.load('fonts/Roboto-Regular.ttf'));
    final fontBold = pw.Font.ttf(await rootBundle.load('fonts/Roboto-Bold.ttf'));
    final currency = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Text('BÁO CÁO TÀI CHÍNH',
                  style: pw.TextStyle(font: fontBold, fontSize: 22, color: PdfColor.fromHex('#00D09E'))),
              pw.SizedBox(height: 4),
              pw.Text('Kỳ báo cáo: $periodLabel', style: pw.TextStyle(font: fontRegular, fontSize: 12)),
              pw.SizedBox(height: 16),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Tổng thu', style: pw.TextStyle(font: fontRegular, fontSize: 14)),
                  pw.Text(currency.format(totalIncome), style: pw.TextStyle(font: fontBold, fontSize: 14)),
                ],
              ),
              pw.SizedBox(height: 6),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Tổng chi', style: pw.TextStyle(font: fontRegular, fontSize: 14)),
                  pw.Text(currency.format(totalExpense), style: pw.TextStyle(font: fontBold, fontSize: 14)),
                ],
              ),
              pw.SizedBox(height: 6),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Dòng tiền thuần', style: pw.TextStyle(font: fontBold, fontSize: 14)),
                  pw.Text(currency.format(netBalance), style: pw.TextStyle(font: fontBold, fontSize: 14)),
                ],
              ),
              pw.Divider(height: 24),
              pw.Text('Cơ cấu theo danh mục',
                  style: pw.TextStyle(font: fontBold, fontSize: 16)),
              pw.SizedBox(height: 8),
              ...categories.map((e) => pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 4),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(e.key, style: pw.TextStyle(font: fontRegular, fontSize: 12)),
                        pw.Text(currency.format(e.value.round()),
                            style: pw.TextStyle(font: fontRegular, fontSize: 12)),
                      ],
                    ),
                  )),
            ],
          );
        },
      ),
    );
    return pdf;
  }
}
