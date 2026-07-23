import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class ReportPdfGenerator {
  static Future<pw.Document> buildReportPdf({
    required int totalIncome,
    required int totalExpense,
    required int netBalance,
    required List<MapEntry<String, double>> incomeCategories,
    required List<MapEntry<String, double>> expenseCategories,
    required int transactionCount,
    required String periodLabel,
  }) async {
    final pdf = pw.Document();

    final fontRegular = pw.Font.ttf(await rootBundle.load('fonts/Roboto-Regular.ttf'));
    final fontBold = pw.Font.ttf(await rootBundle.load('fonts/Roboto-Bold.ttf'));
    final fontItalic = fontRegular; // Fallback since italic is not bundled

    final currency = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        theme: pw.ThemeData.withFont(
          base: fontRegular,
          bold: fontBold,
          italic: fontItalic,
        ),
        header: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'SMARTFINANCE JSC',
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 18,
                          color: PdfColor.fromHex('#00D09E'),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text('Tòa nhà FPT, Khu Công nghệ cao Hòa Lạc', style: pw.TextStyle(font: fontRegular, fontSize: 10)),
                      pw.Text('Mã số thuế: 0102030405', style: pw.TextStyle(font: fontRegular, fontSize: 10)),
                    ]
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('#F4FAF7'),
                      borderRadius: pw.BorderRadius.circular(8),
                      border: pw.Border.all(color: PdfColor.fromHex('#00D09E')),
                    ),
                    child: pw.Text('BÁO CÁO NỘI BỘ', style: pw.TextStyle(font: fontBold, fontSize: 12, color: PdfColor.fromHex('#00D09E'))),
                  ),
                ]
              ),
              pw.SizedBox(height: 24),
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 24),
            ],
          );
        },
        footer: (context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 20),
            child: pw.Text(
              'Trang ${context.pageNumber} / ${context.pagesCount}',
              style: pw.TextStyle(font: fontItalic, fontSize: 10, color: PdfColors.grey),
            ),
          );
        },
        build: (pw.Context context) {
          final profitMargin = totalIncome > 0 ? (netBalance / totalIncome) * 100 : 0.0;
          final expenseRatio = totalIncome > 0 ? (totalExpense / totalIncome) * 100 : 0.0;

          return [
            pw.Center(
              child: pw.Text(
                'BÁO CÁO TÀI CHÍNH DOANH NGHIỆP',
                style: pw.TextStyle(font: fontBold, fontSize: 20),
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Center(
              child: pw.Text(
                'Kỳ báo cáo: $periodLabel',
                style: pw.TextStyle(font: fontItalic, fontSize: 12, color: PdfColors.grey700),
              ),
            ),
            pw.Center(
              child: pw.Text(
                'Ngày lập: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                style: pw.TextStyle(font: fontItalic, fontSize: 10, color: PdfColors.grey700),
              ),
            ),
            pw.SizedBox(height: 30),

            // SUMMARY CARDS
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryCard('TỔNG DOANH THU', currency.format(totalIncome), PdfColor.fromHex('#00D09E'), fontBold, fontRegular),
                _buildSummaryCard('TỔNG CHI PHÍ', currency.format(totalExpense), PdfColor.fromHex('#EF4444'), fontBold, fontRegular),
                _buildSummaryCard('DÒNG TIỀN THUẦN', currency.format(netBalance), netBalance >= 0 ? PdfColor.fromHex('#00D09E') : PdfColor.fromHex('#EF4444'), fontBold, fontRegular),
              ],
            ),
            pw.SizedBox(height: 20),

            // KPI METRICS
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#F8FAFC'),
                borderRadius: pw.BorderRadius.circular(12),
                border: pw.Border.all(color: PdfColors.grey200),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _buildKpiItem('Biên lợi nhuận', '${profitMargin.toStringAsFixed(1)}%', fontBold, fontRegular),
                  _buildKpiItem('Tỷ lệ Chi / Thu', '${expenseRatio.toStringAsFixed(1)}%', fontBold, fontRegular),
                  _buildKpiItem('Số giao dịch', '$transactionCount', fontBold, fontRegular),
                  _buildKpiItem('TB / Giao dịch', currency.format(transactionCount > 0 ? (totalIncome + totalExpense)/transactionCount : 0), fontBold, fontRegular),
                ],
              ),
            ),
            pw.SizedBox(height: 30),

            // CHART SECTION
            if (totalIncome > 0 || totalExpense > 0) ...[
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      children: [
                        pw.Text('TỔNG QUAN THU / CHI', style: pw.TextStyle(font: fontBold, fontSize: 10)),
                        pw.SizedBox(height: 8),
                        pw.Container(
                          height: 120,
                          child: pw.Chart(
                            grid: pw.PieGrid(),
                            datasets: [
                              if (totalIncome > 0)
                                pw.PieDataSet(value: totalIncome.toDouble(), color: PdfColor.fromHex('#00D09E')),
                              if (totalExpense > 0)
                                pw.PieDataSet(value: totalExpense.toDouble(), color: PdfColor.fromHex('#EF4444')),
                            ],
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.center,
                          children: [
                            if (totalIncome > 0) _buildCustomLegendItem('Doanh thu', PdfColor.fromHex('#00D09E')),
                            pw.SizedBox(width: 12),
                            if (totalExpense > 0) _buildCustomLegendItem('Chi phí', PdfColor.fromHex('#EF4444')),
                          ]
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 20),
                  if (expenseCategories.isNotEmpty)
                    pw.Expanded(
                      child: pw.Column(
                        children: [
                          pw.Text('TOP CHI PHÍ', style: pw.TextStyle(font: fontBold, fontSize: 10)),
                          pw.SizedBox(height: 8),
                          pw.Container(
                            height: 120,
                            child: pw.Chart(
                              grid: pw.PieGrid(),
                              datasets: expenseCategories.take(4).toList().asMap().entries.map((e) {
                                final colors = [PdfColor.fromHex('#EF4444'), PdfColor.fromHex('#F97316'), PdfColor.fromHex('#F59E0B'), PdfColor.fromHex('#EC4899')];
                                return pw.PieDataSet(value: e.value.value, color: colors[e.key % colors.length]);
                              }).toList(),
                            ),
                          ),
                          pw.SizedBox(height: 8),
                          pw.Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            alignment: pw.WrapAlignment.center,
                            children: expenseCategories.take(4).toList().asMap().entries.map((e) {
                                final colors = [PdfColor.fromHex('#EF4444'), PdfColor.fromHex('#F97316'), PdfColor.fromHex('#F59E0B'), PdfColor.fromHex('#EC4899')];
                                return _buildCustomLegendItem(e.value.key, colors[e.key % colors.length]);
                            }).toList(),
                          )
                        ],
                      ),
                    )
                  else if (incomeCategories.isNotEmpty)
                    pw.Expanded(
                      child: pw.Column(
                        children: [
                          pw.Text('TOP DOANH THU', style: pw.TextStyle(font: fontBold, fontSize: 10)),
                          pw.SizedBox(height: 8),
                          pw.Container(
                            height: 120,
                            child: pw.Chart(
                              grid: pw.PieGrid(),
                              datasets: incomeCategories.take(4).toList().asMap().entries.map((e) {
                                final colors = [PdfColor.fromHex('#00D09E'), PdfColor.fromHex('#3B82F6'), PdfColor.fromHex('#06B6D4'), PdfColor.fromHex('#8B5CF6')];
                                return pw.PieDataSet(value: e.value.value, color: colors[e.key % colors.length]);
                              }).toList(),
                            ),
                          ),
                          pw.SizedBox(height: 8),
                          pw.Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            alignment: pw.WrapAlignment.center,
                            children: incomeCategories.take(4).toList().asMap().entries.map((e) {
                                final colors = [PdfColor.fromHex('#00D09E'), PdfColor.fromHex('#3B82F6'), PdfColor.fromHex('#06B6D4'), PdfColor.fromHex('#8B5CF6')];
                                return _buildCustomLegendItem(e.value.key, colors[e.key % colors.length]);
                            }).toList(),
                          )
                        ],
                      ),
                    ),
                ],
              ),
              pw.SizedBox(height: 30),
            ],

            // INCOME CATEGORIES
            if (incomeCategories.isNotEmpty) ...[
              pw.Text('1. Chi tiết Cơ cấu Nguồn thu', style: pw.TextStyle(font: fontBold, fontSize: 14)),
              pw.SizedBox(height: 12),
              _buildCategoryTable(incomeCategories, totalIncome, currency, fontBold, fontRegular),
              pw.SizedBox(height: 24),
            ],

            // EXPENSE CATEGORIES
            if (expenseCategories.isNotEmpty) ...[
              pw.Text('2. Chi tiết Cơ cấu Khoản chi', style: pw.TextStyle(font: fontBold, fontSize: 14)),
              pw.SizedBox(height: 12),
              _buildCategoryTable(expenseCategories, totalExpense, currency, fontBold, fontRegular),
              pw.SizedBox(height: 30),
            ],

            // SIGNATURES
            pw.SizedBox(height: 40),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                pw.Column(
                  children: [
                    pw.Text('Người lập biểu', style: pw.TextStyle(font: fontBold, fontSize: 12)),
                    pw.SizedBox(height: 4),
                    pw.Text('(Ký, ghi rõ họ tên)', style: pw.TextStyle(font: fontItalic, fontSize: 10)),
                    pw.SizedBox(height: 60),
                  ],
                ),
                pw.Column(
                  children: [
                    pw.Text('Giám đốc tài chính', style: pw.TextStyle(font: fontBold, fontSize: 12)),
                    pw.SizedBox(height: 4),
                    pw.Text('(Ký, đóng dấu)', style: pw.TextStyle(font: fontItalic, fontSize: 10)),
                    pw.SizedBox(height: 60),
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );
    return pdf;
  }

  static pw.Widget _buildSummaryCard(String title, String value, PdfColor valueColor, pw.Font fontBold, pw.Font fontRegular) {
    return pw.Container(
      width: 150,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: pw.TextStyle(font: fontRegular, fontSize: 10, color: PdfColors.grey700)),
          pw.SizedBox(height: 8),
          pw.Text(value, style: pw.TextStyle(font: fontBold, fontSize: 14, color: valueColor)),
        ],
      ),
    );
  }

  static pw.Widget _buildKpiItem(String label, String value, pw.Font fontBold, pw.Font fontRegular) {
    return pw.Column(
      children: [
        pw.Text(label, style: pw.TextStyle(font: fontRegular, fontSize: 10, color: PdfColors.grey600)),
        pw.SizedBox(height: 4),
        pw.Text(value, style: pw.TextStyle(font: fontBold, fontSize: 14)),
      ],
    );
  }

  static pw.Widget _buildCustomLegendItem(String label, PdfColor color) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Container(width: 8, height: 8, decoration: pw.BoxDecoration(color: color, shape: pw.BoxShape.circle)),
        pw.SizedBox(width: 4),
        pw.Text(label, style: const pw.TextStyle(fontSize: 8)),
      ],
    );
  }

  static pw.Widget _buildCategoryTable(List<MapEntry<String, double>> categories, int total, NumberFormat currency, pw.Font fontBold, pw.Font fontRegular) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(1),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(1.5),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF1F5F9)),
          children: [
            pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('STT', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: fontBold, fontSize: 10))),
            pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Tên danh mục', style: pw.TextStyle(font: fontBold, fontSize: 10))),
            pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Số tiền', textAlign: pw.TextAlign.right, style: pw.TextStyle(font: fontBold, fontSize: 10))),
            pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Tỷ trọng', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: fontBold, fontSize: 10))),
          ],
        ),
        ...categories.asMap().entries.map((entry) {
          final index = entry.key + 1;
          final cat = entry.value;
          final pct = total > 0 ? (cat.value / total) * 100 : 0.0;
          return pw.TableRow(
            children: [
              pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('$index', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: fontRegular, fontSize: 10))),
              pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(cat.key, style: pw.TextStyle(font: fontRegular, fontSize: 10))),
              pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(currency.format(cat.value), textAlign: pw.TextAlign.right, style: pw.TextStyle(font: fontRegular, fontSize: 10))),
              pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('${pct.toStringAsFixed(1)}%', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: fontRegular, fontSize: 10))),
            ],
          );
        }),
      ],
    );
  }
}
