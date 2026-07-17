import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:smart_finance/features/reports/utils/report_pdf_generator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('buildReportPdf trả document có nội dung (save được, bytes > 0)', () async {
    final doc = await ReportPdfGenerator.buildReportPdf(
      totalIncome: 1000000,
      totalExpense: 400000,
      netBalance: 600000,
      categories: [MapEntry('Lương', 1000000.0), MapEntry('Mặt bằng', 400000.0)],
      periodLabel: 'Tháng này',
    );
    final bytes = await doc.save();
    expect(bytes.length, greaterThan(0));
  });
}
