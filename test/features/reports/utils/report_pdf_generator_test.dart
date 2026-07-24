import 'package:flutter_test/flutter_test.dart';
import 'package:smart_finance/features/reports/utils/report_pdf_generator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('buildReportPdf tra ve document co noi dung', () async {
    final doc = await ReportPdfGenerator.buildReportPdf(
      totalIncome: 1000000,
      totalExpense: 400000,
      netBalance: 600000,
      incomeCategories: const [MapEntry('Luong', 1000000.0)],
      expenseCategories: const [MapEntry('Mat bang', 400000.0)],
      transactionCount: 2,
      periodLabel: 'Thang nay',
    );
    final bytes = await doc.save();
    expect(bytes.length, greaterThan(0));
  });
}
