# Finance Manager Pages Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Hoàn thiện các chức năng trang Quản lý tài chính: implement 4 feature provider còn stub và nối nút "Xuất báo cáo PDF" thành sinh file PDF thật, theo đúng cấu trúc API của dự án SmartFinance.

**Architecture:** Feature provider là lớp mỏng bọc Repository (đã có sẵn) qua Riverpod `FutureProvider`/`.family` theo pattern `core/providers/transaction_providers.dart`. Tính toán báo cáo dùng `ReportCalculator` (sửa để trả giá trị thật). Xuất PDF tái dùng package `pdf`+`printing` (đã có) qua một generator mới `report_pdf_generator.dart`, nút ở `report_screen.dart` gọi `Printing.sharePdf`.

**Tech Stack:** Flutter/Dart, Riverpod, Firebase Firestore (chỉ read qua repo, không sửa), `pdf` + `printing` (đã trong pubspec), `mocktail` (test), `intl` (format VND).

## Global Constraints

- Không thêm dependency mới (`pdf`, `printing`, `mocktail`, `intl` đã có sẵn trong `pubspec.yaml`).
- Không sửa tầng Repository Firestore (đã chạy tốt).
- Giữ nguyên Role switcher ở Cài đặt (không sửa — user bỏ phần này).
- Format tiền: VND nguyên (`int`), `NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0)`.
- UI tiếng Việt.
- Provider repo lấy từ `core/providers/app_providers.dart` (`transactionRepositoryProvider`, `categoryRepositoryProvider`, `invoiceRepositoryProvider`).
- Enum `TransactionType` (income/expense) và `TransactionStatus` (draft/confirmed/deleted) dùng `.name` khi serialize; so sánh bằng `==`.

---

## File Structure

**Implement (sửa stub / tạo mới):**
- `lib/domain/services/report_calculator.dart` — sửa `calculateSummary` trả giá trị thật.
- `lib/features/transactions/providers/transaction_provider.dart` — implement provider.
- `lib/features/categories/providers/category_provider.dart` — implement provider (giữ `allCategoriesProvider` đã dùng bởi Dashboard).
- `lib/features/invoices/providers/invoice_provider.dart` — implement provider.
- `lib/features/reports/providers/report_provider.dart` — implement `reportSummaryProvider` family.
- `lib/features/reports/utils/report_pdf_generator.dart` — tạo mới, sinh `pw.Document` báo cáo.
- `lib/features/reports/presentation/report_screen.dart` — nối nút Xuất PDF (thay SnackBar).

**Test (mới):**
- `test/domain/services/report_calculator_test.dart`
- `test/features/transactions/providers/transaction_provider_test.dart`
- `test/features/categories/providers/category_provider_test.dart`
- `test/features/invoices/providers/invoice_provider_test.dart`
- `test/features/reports/providers/report_provider_test.dart`
- `test/features/reports/utils/report_pdf_generator_test.dart`

**Không đổi:** Repository impl, router, responsive_layout, dashboard_screen, report_detail_screen.

---

### Task 1: Implement ReportCalculator trả giá trị thật

**Files:**
- Modify: `lib/domain/services/report_calculator.dart`
- Test: `test/domain/services/report_calculator_test.dart`

**Interfaces:**
- Consumes: `TransactionEntity` (`amount: int`, `type: TransactionType`, `status: TransactionStatus`), `ReportSummaryEntity(...)` constructor (xem `lib/domain/entities/report_summary_entity.dart`: `totalIncome`, `totalExpense`, `netCashFlow`, `expenseRatio`, `transactionCount`, `periodStart`, `periodEnd` — các field khác optional).
- Produces: `ReportCalculator.calculateSummary(List<TransactionEntity>, DateTime, DateTime) → ReportSummaryEntity` (dùng ở Task 3).

- [ ] **Step 1: Write the failing test**

```dart
// test/domain/services/report_calculator_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_finance/domain/entities/transaction_entity.dart';
import 'package:smart_finance/domain/services/report_calculator.dart';

TransactionEntity _tx(int amount, TransactionType type, TransactionStatus status) =>
    TransactionEntity(
      id: 'id',
      amount: amount,
      type: type,
      categoryId: 'c',
      transactionDate: DateTime(2026, 1, 1),
      status: status,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

void main() {
  final start = DateTime(2026, 1, 1);
  final end = DateTime(2026, 12, 31);

  test('tính đúng thu, chi, dòng tiền ròng từ giao dịch confirmed', () {
    final txns = [
      _tx(1000, TransactionType.income, TransactionStatus.confirmed),
      _tx(300, TransactionType.expense, TransactionStatus.confirmed),
      _tx(500, TransactionType.income, TransactionStatus.draft),   // bị bỏ qua
      _tx(200, TransactionType.expense, TransactionStatus.deleted), // bị bỏ qua
    ];
    final summary = ReportCalculator.calculateSummary(txns, start, end);
    expect(summary.totalIncome, 1000);
    expect(summary.totalExpense, 300);
    expect(summary.netCashFlow, 700);
    expect(summary.transactionCount, 2); // chỉ confirmed
  });

  test('expenseRatio = 0 khi không có thu', () {
    final txns = [_tx(100, TransactionType.expense, TransactionStatus.confirmed)];
    final summary = ReportCalculator.calculateSummary(txns, start, end);
    expect(summary.expenseRatio, 0.0);
    expect(summary.netCashFlow, -100);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/domain/services/report_calculator_test.dart`
Expected: FAIL (assertion `totalIncome` = 0 thay vì 1000, vì code cũ hardcode 0).

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/domain/services/report_calculator.dart
import '../entities/transaction_entity.dart';
import '../entities/report_summary_entity.dart';

class ReportCalculator {
  static ReportSummaryEntity calculateSummary(
    List<TransactionEntity> transactions,
    DateTime start,
    DateTime end,
  ) {
    final confirmed = transactions.where((t) => t.status == TransactionStatus.confirmed);

    final totalIncome = confirmed
        .where((t) => t.type == TransactionType.income)
        .fold(0, (sum, t) => sum + t.amount);

    final totalExpense = confirmed
        .where((t) => t.type == TransactionType.expense)
        .fold(0, (sum, t) => sum + t.amount);

    final netCashFlow = totalIncome - totalExpense;
    final expenseRatio = totalIncome == 0 ? 0.0 : (totalExpense / totalIncome) * 100;

    return ReportSummaryEntity(
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      netCashFlow: netCashFlow,
      expenseRatio: expenseRatio,
      transactionCount: confirmed.length,
      periodStart: start,
      periodEnd: end,
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/domain/services/report_calculator_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/domain/services/report_calculator.dart test/domain/services/report_calculator_test.dart
git commit -m "feat: implement ReportCalculator.calculateSummary with real totals"
```

---

### Task 2: Implement transaction / category / invoice feature providers

**Files:**
- Modify: `lib/features/transactions/providers/transaction_provider.dart`
- Modify: `lib/features/categories/providers/category_provider.dart`
- Modify: `lib/features/invoices/providers/invoice_provider.dart`
- Test: `test/features/transactions/providers/transaction_provider_test.dart`
- Test: `test/features/categories/providers/category_provider_test.dart`
- Test: `test/features/invoices/providers/invoice_provider_test.dart`

**Interfaces:**
- Consumes: `transactionRepositoryProvider`, `categoryRepositoryProvider`, `invoiceRepositoryProvider` (từ `core/providers/app_providers.dart`); `TransactionType`, `OcrStatus` enum; repo methods: `transactionRepository.{getAll():Future<List<TransactionEntity>>, getByType(TransactionType):Future<List<TransactionEntity>>, getById(String):Future<TransactionEntity?>}`, `categoryRepository.{getAll(), getActive(), getByType(TransactionType)}`, `invoiceRepository.{getAll(), getByOcrStatus(OcrStatus), getById(String)}`.
- Produces: các provider tên dưới đây (tiêu thụ bởi UI/provider khác nếu cần).

- [ ] **Step 1: Write the failing tests**

```dart
// test/features/transactions/providers/transaction_provider_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_finance/domain/entities/transaction_entity.dart';
import 'package:smart_finance/domain/repositories/transaction_repository.dart';
import 'package:smart_finance/features/transactions/providers/transaction_provider.dart';

class FakeTransactionRepository extends Mock implements TransactionRepository {}

void main() {
  late FakeTransactionRepository fake;
  late ProviderContainer container;
  final income = TransactionEntity(id: '1', amount: 10, type: TransactionType.income, categoryId: 'c', transactionDate: DateTime(2026), status: TransactionStatus.confirmed, createdAt: DateTime(2026), updatedAt: DateTime(2026));
  final expense = TransactionEntity(id: '2', amount: 20, type: TransactionType.expense, categoryId: 'c', transactionDate: DateTime(2026), status: TransactionStatus.confirmed, createdAt: DateTime(2026), updatedAt: DateTime(2026));

  setUp(() {
    fake = FakeTransactionRepository();
    container = ProviderContainer(overrides: [transactionRepositoryProvider.overrideWithValue(fake)]);
    registerFallbackValue(TransactionType.income);
  });
  tearDown(() => container.dispose());

  test('allTransactionsProvider trả toàn bộ', () async {
    when(() => fake.getAll()).thenAnswer((_) async => [income, expense]);
    final r = await container.read(allTransactionsProvider.future);
    expect(r.length, 2);
  });

  test('incomeTransactionsProvider chỉ trả thu', () async {
    when(() => fake.getByType(TransactionType.income)).thenAnswer((_) async => [income]);
    final r = await container.read(incomeTransactionsProvider.future);
    expect(r.first.type, TransactionType.income);
  });

  test('transactionByIdProvider(id) gọi getById', () async {
    when(() => fake.getById('1')).thenAnswer((_) async => income);
    final r = await container.read(transactionByIdProvider('1').future);
    expect(r?.id, '1');
  });
}
```

Tương tự cho category (`FakeCategoryRepository` implements `CategoryRepository`, override `categoryRepositoryProvider`, assert `allCategoriesProvider`/`activeCategoriesProvider`/`categoriesByTypeProvider(TransactionType.expense)`) và invoice (`FakeInvoiceRepository` implements `InvoiceRepository`, override `invoiceRepositoryProvider`, assert `allInvoicesProvider`/`invoiceByIdProvider('x')`/`invoicesByOcrStatusProvider(OcrStatus.pending)`). Dùng `registerFallbackValue(TransactionType.expense)` / `registerFallbackValue(OcrStatus.pending)` tương ứng.

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/features/transactions/providers/transaction_provider_test.dart test/features/categories/providers/category_provider_test.dart test/features/invoices/providers/invoice_provider_test.dart`
Expected: FAIL (provider chưa định nghĩa / trả `null`).

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/features/transactions/providers/transaction_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../domain/entities/transaction_entity.dart';

final allTransactionsProvider = FutureProvider.autoDispose<List<TransactionEntity>>((ref) async {
  return ref.watch(transactionRepositoryProvider).getAll();
});

final expenseTransactionsProvider = FutureProvider.autoDispose<List<TransactionEntity>>((ref) async {
  return ref.watch(transactionRepositoryProvider).getByType(TransactionType.expense);
});

final incomeTransactionsProvider = FutureProvider.autoDispose<List<TransactionEntity>>((ref) async {
  return ref.watch(transactionRepositoryProvider).getByType(TransactionType.income);
});

final transactionByIdProvider = FutureProvider.autoDispose.family<TransactionEntity?, String>((ref, id) async {
  return ref.watch(transactionRepositoryProvider).getById(id);
});
```

```dart
// lib/features/categories/providers/category_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../domain/entities/category_entity.dart';
import '../../../domain/entities/transaction_entity.dart';

final allCategoriesProvider = FutureProvider.autoDispose<List<CategoryEntity>>((ref) async {
  return ref.watch(categoryRepositoryProvider).getAll();
});

final activeCategoriesProvider = FutureProvider.autoDispose<List<CategoryEntity>>((ref) async {
  return ref.watch(categoryRepositoryProvider).getActive();
});

final categoriesByTypeProvider =
    FutureProvider.autoDispose.family<List<CategoryEntity>, TransactionType>((ref, type) async {
  return ref.watch(categoryRepositoryProvider).getByType(type);
});
```

```dart
// lib/features/invoices/providers/invoice_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../domain/entities/invoice_entity.dart';
import '../../../domain/entities/transaction_entity.dart';

final allInvoicesProvider = FutureProvider.autoDispose<List<InvoiceEntity>>((ref) async {
  return ref.watch(invoiceRepositoryProvider).getAll();
});

final invoiceByIdProvider =
    FutureProvider.autoDispose.family<InvoiceEntity?, String>((ref, id) async {
  return ref.watch(invoiceRepositoryProvider).getById(id);
});

final invoicesByOcrStatusProvider =
    FutureProvider.autoDispose.family<List<InvoiceEntity>, OcrStatus>((ref, status) async {
  return ref.watch(invoiceRepositoryProvider).getByOcrStatus(status);
});
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/features/transactions/providers/transaction_provider_test.dart test/features/categories/providers/category_provider_test.dart test/features/invoices/providers/invoice_provider_test.dart`
Expected: PASS (tất cả tests).

- [ ] **Step 5: Commit**

```bash
git add lib/features/transactions/providers/transaction_provider.dart lib/features/categories/providers/category_provider.dart lib/features/invoices/providers/invoice_provider.dart test/features/transactions/providers/transaction_provider_test.dart test/features/categories/providers/category_provider_test.dart test/features/invoices/providers/invoice_provider_test.dart
git commit -m "feat: implement transaction, category, invoice feature providers"
```

---

### Task 3: Implement report provider (dùng ReportCalculator)

**Files:**
- Modify: `lib/features/reports/providers/report_provider.dart`
- Test: `test/features/reports/providers/report_provider_test.dart`

**Interfaces:**
- Consumes: `transactionRepositoryProvider.getAll()` / `.getConfirmed()`; `ReportCalculator.calculateSummary` (Task 1).
- Produces: `reportSummaryProvider(period: String) → FutureProvider.family<ReportSummaryEntity, String>`.

- [ ] **Step 1: Write the failing test**

```dart
// test/features/reports/providers/report_provider_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_finance/domain/entities/transaction_entity.dart';
import 'package:smart_finance/domain/repositories/transaction_repository.dart';
import 'package:smart_finance/features/reports/providers/report_provider.dart';

class FakeTransactionRepository extends Mock implements TransactionRepository {}

void main() {
  late FakeTransactionRepository fake;
  late ProviderContainer container;
  final txns = [
    TransactionEntity(id: '1', amount: 1000, type: TransactionType.income, categoryId: 'c', transactionDate: DateTime(2026), status: TransactionStatus.confirmed, createdAt: DateTime(2026), updatedAt: DateTime(2026)),
    TransactionEntity(id: '2', amount: 400, type: TransactionType.expense, categoryId: 'c', transactionDate: DateTime(2026), status: TransactionStatus.confirmed, createdAt: DateTime(2026), updatedAt: DateTime(2026)),
    TransactionEntity(id: '3', amount: 999, type: TransactionType.income, categoryId: 'c', transactionDate: DateTime(2026), status: TransactionStatus.draft, createdAt: DateTime(2026), updatedAt: DateTime(2026)),
  ];

  setUp(() {
    fake = FakeTransactionRepository();
    container = ProviderContainer(overrides: [transactionRepositoryProvider.overrideWithValue(fake)]);
  });
  tearDown(() => container.dispose());

  test('reportSummaryProvider tính từ confirmed qua ReportCalculator', () async {
    when(() => fake.getConfirmed()).thenAnswer((_) async => txns);
    final summary = await container.read(reportSummaryProvider('all').future);
    expect(summary.totalIncome, 1000);
    expect(summary.totalExpense, 400);
    expect(summary.netCashFlow, 600);
    expect(summary.transactionCount, 2);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/reports/providers/report_provider_test.dart`
Expected: FAIL (`reportSummaryProvider` chưa định nghĩa).

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/features/reports/providers/report_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../domain/entities/transaction_entity.dart';
import '../../../domain/services/report_calculator.dart';

final reportSummaryProvider =
    FutureProvider.autoDispose.family<ReportSummaryEntity, String>((ref, period) async {
  final transactions = await ref.watch(transactionRepositoryProvider).getConfirmed();
  final now = DateTime.now();
  return ReportCalculator.calculateSummary(transactions, now, now);
});
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/reports/providers/report_provider_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/reports/providers/report_provider.dart test/features/reports/providers/report_provider_test.dart
git commit -m "feat: implement reportSummaryProvider using ReportCalculator"
```

---

### Task 4: Create report_pdf_generator

**Files:**
- Create: `lib/features/reports/utils/report_pdf_generator.dart`
- Test: `test/features/reports/utils/report_pdf_generator_test.dart`

**Interfaces:**
- Consumes: `package:pdf/widgets.dart` (`pw.Document`, `pw.Page`, ...), `package:printing/printing.dart`, `NumberFormat` (`intl`), `PdfGoogleFonts` (từ `pdf/widgets.dart`).
- Produces: `ReportPdfGenerator.buildReportPdf({required int totalIncome, required int totalExpense, required int netBalance, required List<MapEntry<String,double>> categories, required String periodLabel}) → pw.Document`.

- [ ] **Step 1: Write the failing test**

```dart
// test/features/reports/utils/report_pdf_generator_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:smart_finance/features/reports/utils/report_pdf_generator.dart';

void main() {
  test('buildReportPdf trả document có nội dung (save được, bytes > 0)', () async {
    final doc = ReportPdfGenerator.buildReportPdf(
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/reports/utils/report_pdf_generator_test.dart`
Expected: FAIL (class chưa tồn tại).

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/features/reports/utils/report_pdf_generator.dart
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

class ReportPdfGenerator {
  static pw.Document buildReportPdf({
    required int totalIncome,
    required int totalExpense,
    required int netBalance,
    required List<MapEntry<String, double>> categories,
    required String periodLabel,
  }) {
    final pdf = pw.Document();
    final fontRegular = pw.Font.helvetica();
    final fontBold = pw.Font.helveticaBold();
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
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/reports/utils/report_pdf_generator_test.dart`
Expected: PASS (bytes > 0).

- [ ] **Step 5: Commit**

```bash
git add lib/features/reports/utils/report_pdf_generator.dart test/features/reports/utils/report_pdf_generator_test.dart
git commit -m "feat: add ReportPdfGenerator for cash flow report"
```

---

### Task 5: Wire Xuất PDF button in Report screen

**Files:**
- Modify: `lib/features/reports/presentation/report_screen.dart` (imports + hàm onTap của nút "Xuất báo cáo PDF", khoảng dòng 596-628).

**Interfaces:**
- Consumes: `ReportPdfGenerator.buildReportPdf(...)` (Task 4); `package:printing/printing.dart` hàm `Printing.sharePdf({required Uint8List bytes, String? filename})`; dữ liệu đã có trong `build`: `totalIncome`, `totalExpense`, `netBalance`, `displayCategories` (`List<MapEntry<String,double>>`), `_selectedPeriod` (String: 'all'/'today'/'month'/'year'/'custom').

- [ ] **Step 1: Add imports**

Thêm vào đầu file (sau các import hiện có):
```dart
import 'dart:async';
import 'dart:typed_data';
import 'package:printing/printing.dart';
import 'features/reports/utils/report_pdf_generator.dart';
```
(Lưu ý: import path tương đối từ `lib/features/reports/presentation/` là `'../utils/report_pdf_generator.dart'`.)

- [ ] **Step 2: Replace the SnackBar handler with real PDF export**

Tìm widget `ScaleOnTap` chứa `ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đang tạo báo cáo PDF tổng hợp...'), backgroundColor: Color(0xFF00D09E)));` (bên trong card "Dòng tiền thuần doanh nghiệp", chỉ hiển thị cho `financeManager`). Thay toàn bộ `onTap` của `ScaleOnTap` đó bằng:

```dart
onTap: () async {
  try {
    final doc = ReportPdfGenerator.buildReportPdf(
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      netBalance: netBalance,
      categories: displayCategories,
      periodLabel: _periodLabel(),
    );
    final bytes = await doc.save();
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'BaoCaoTaiChinh_${_selectedPeriod}.pdf',
    );
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Xuất PDF thất bại: $e'), backgroundColor: Colors.red),
      );
    }
  }
},
```

Thêm helper `_periodLabel()` vào class `_ReportScreenState` (trả nhãn tiếng Việt tương ứng `_selectedPeriod`):
```dart
String _periodLabel() {
  switch (_selectedPeriod) {
    case 'today': return 'Hôm nay';
    case 'month': return 'Tháng này';
    case 'year': return 'Năm nay';
    case 'custom': return 'Tùy chỉnh';
    case 'all':
    default: return 'Tất cả';
  }
}
```

- [ ] **Step 3: Verify analyze**

Run: `flutter analyze lib/features/reports/presentation/report_screen.dart`
Expected: không lỗi (đặc biệt: `displayCategories` đã là `List<MapEntry<String,double>>`, `dart:async` đã import để dùng `async`/`await`).

- [ ] **Step 4: Commit**

```bash
git add lib/features/reports/presentation/report_screen.dart
git commit -m "feat: wire real PDF export on Finance Manager report screen"
```

---

### Task 6: Final verification

**Files:** không đổi code.

- [ ] **Step 1: Run full analyze**

Run: `flutter analyze`
Expected: no issues (exit 0).

- [ ] **Step 2: Run all tests**

Run: `flutter test`
Expected: tất cả tests PASS (Tasks 1-4).

- [ ] **Step 3: Build check (không chạy app)**

Run: `flutter build apk --debug` (hoặc `flutter build web`)
Expected: build thành công, không lỗi compile.

- [ ] **Step 4: Commit (nếu có sửa nhỏ từ verify)**

Nếu analyze/test/build bắt lỗi và bạn sửa: commit riêng. Ví dụ:
```bash
git add -A
git commit -m "fix: resolve analyze/test issues from FM pages completion"
```
Nếu không có sửa → bỏ qua bước này.

---

## Self-Review Notes (đã chạy)

- **Spec coverage:** Phần 1 (4 provider) → Tasks 2,3; Phần 2 (Xuất PDF) → Tasks 4,5; Phần 4 (verify FM thu+chi) → không sửa code, xác nhận qua Task 6 + hiện trạng đã đọc. Role switcher bị loại trừ → không có task. ✔
- **Placeholder scan:** mọi step đều có code/command cụ thể, không có "TBD/implement later". ✔
- **Type consistency:** `displayCategories` là `List<MapEntry<String,double>>` khớp tham số `categories` của `buildReportPdf`. `reportSummaryProvider(period: String)` family khớp test. Repo method signatures lấy từ impl thực tế. `Printing.sharePdf(bytes:)` khớp `invoice_preview_screen.dart`. ✔
