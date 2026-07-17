# Hoàn thiện chức năng trang Quản lý tài chính (Finance Manager)

Date: 2026-07-17

## Mục tiêu

Hoàn thiện các chức năng của vai trò **Quản lý tài chính (financeManager)** theo đúng
cấu trúc API của dự án SmartFinance, giữ đơn giản (không refactor code đang chạy tốt).

Trang của Quản lý tài chính về bản chất là **tổng hợp view từ Kế toán doanh thu
(revenueAccountant) + Kế toán chi phí (expenseAccountant)** — hiển thị đồng thời cả
thu và chi (toàn bộ dòng tiền), khác với 2 kế toán chỉ xem 1 bên.

## Phạm vi (đã thống nhất với user)

Làm 2 việc thực tế:
1. Implement 4 feature provider còn là stub (`// To be implemented`).
2. Nối nút "Xuất báo cáo PDF" ở màn Báo cáo thành sinh file PDF thật.

**Loại trừ (user bỏ):** Role switcher ở Cài đặt giữ nguyên (không sửa).

## Hiện trạng đã xác nhận

- Tầng Repository gọi Firestore đã hoạt động (transaction/invoice/category/attachment/auth).
- Dashboard, Báo cáo, Chi tiết báo cáo, Giao dịch, Hóa đơn FM đã hiện dữ liệu thật.
- `InvoicePdfGenerator` (`features/invoices/utils/invoice_pdf_generator.dart`) đã sinh PDF
  hóa đơn thật dùng package `pdf` + `printing` → tái dùng pattern.
- `ReportCalculator` (`domain/services/report_calculator.dart`) tồn tại nhưng CHƯA ai dùng
  và hiện trả về hardcode 0 (cần implement đúng).
- `UserModel` có `role` + `copyWith`; `authRepository.updateUserInfo` có sẵn.
- Logic tổng hợp thu+chi của FM đã đúng (xem Phần 4) → không sửa.

## Phần 1 — Hoàn thiện 4 Feature Provider

Vị trí: implement vào đúng 4 file stub hiện tại
`features/<x>/providers/<x>_provider.dart` (giữ cấu trúc thư mục project;
`category_provider` đã được Dashboard import `allCategoriesProvider`).

Quy tắc chung (theo pattern `core/providers/transaction_providers.dart`):
- Dùng `FutureProvider` / `FutureProvider.autoDispose` bọc repo từ `core/providers/app_providers.dart`.
- Cần tham số → dùng `.family`.
- Repo lấy qua `ref.watch(<repo>Provider)`.

Nội dung:

| File | Provider bổ sung | Logic |
|------|------------------|-------|
| `transactions/providers/transaction_provider.dart` | `allTransactionsProvider`, `expenseTransactionsProvider`, `incomeTransactionsProvider`, `transactionByIdProvider(id)` (family) | bọc `transactionRepository.getAll / getByType / getById` |
| `categories/providers/category_provider.dart` | `allCategoriesProvider` (đã dùng), `activeCategoriesProvider`, `categoriesByTypeProvider(type)` (family) | bọc `categoryRepository.getAll / getActive / getByType` |
| `invoices/providers/invoice_provider.dart` | `allInvoicesProvider`, `invoicesByOcrStatusProvider(status)` (family), `invoiceByIdProvider(id)` (family) | bọc `invoiceRepository.getAll / getByOcrStatus / getById` |
| `reports/providers/report_provider.dart` | `reportSummaryProvider(period)` (family) | gọi `transactionRepository.getConfirmed()` rồi dùng `ReportCalculator` tính tổng thu/chi/dòng tiền ròng |

Lưu ý: UI hiện phần lớn gọi trực tiếp repo hoặc dùng provider ở `core/`. Phần này chủ
yếu lấp stub để cấu trúc hoàn chỉnh; chỉ nối UI vào provider mới nếu hợp lý
(vd: report dùng `reportSummaryProvider`).

### Sửa ReportCalculator (phụ thuộc Phần 1)

`ReportCalculator.calculateSummary` hiện hardcode 0 → implement thật:
```dart
static ReportSummaryEntity calculateSummary(
  List<TransactionEntity> transactions, DateTime start, DateTime end) {
  final confirmed = transactions.where((t) => t.status == TransactionStatus.confirmed);
  final income = confirmed.where((t) => t.type == TransactionType.income)
      .fold(0, (s, t) => s + t.amount);
  final expense = confirmed.where((t) => t.type == TransactionType.expense)
      .fold(0, (s, t) => s + t.amount);
  return ReportSummaryEntity(
    totalIncome: income,
    totalExpense: expense,
    netCashFlow: income - expense,
    expenseRatio: income == 0 ? 0.0 : (expense / income) * 100,
    transactionCount: confirmed.length,
    periodStart: start,
    periodEnd: end,
  );
}
```
(Sử dụng `CashFlowCalculator` đã có nếu muốn tránh lặp logic tính toán.)

## Phần 2 — Nối nút "Xuất báo cáo PDF" thành thật

Hiện trạng: `report_screen.dart:598` chỉ show SnackBar. Infrastructure PDF có sẵn.

Cách làm:
1. Tạo `features/reports/utils/report_pdf_generator.dart` — class `ReportPdfGenerator`:
   - `static pw.Document buildReportPdf({ required int totalIncome, required int totalExpense, required int netBalance, required List<MapEntry<String,double>> categories, required String periodLabel })`
   - Vẽ: tiêu đề "Báo cáo Tài chính", kỳ báo cáo, tổng thu/tổng chi/dòng tiền ròng,
     danh sách đóng góp theo danh mục. Style theo `InvoicePdfGenerator` (header, bảng,
     font tiếng Việt). Dùng `pw.Document()` từ `pdf/widgets.dart` (có sẵn pubspec).
2. Sửa nút ở `report_screen.dart`: thay SnackBar bằng
   `await Printing.sharePdf(pdf: (await ReportPdfGenerator.buildReportPdf(...)).save())`
   truyền data đã tính sẵn trong màn (`totalIncome`, `totalExpense`, `netBalance`,
   `displayCategories`, `_selectedPeriod`).
3. Truyền thẳng `displayCategories` (List<MapEntry<String,double>>) vào generator —
   không thêm entity phụ để giữ đơn giản.

Kết quả: bấm nút → hộp in/chia sẻ PDF báo cáo tổng hợp thật, đúng dữ liệu đang hiển thị.

## Phần 4 — Xác nhận tổng hợp thu+chi FM (chỉ verify, không sửa)

- `dashboard_screen.dart`: FM dùng `allTransactionsProvider` (thu+chi), header
  "DÒNG TIỀN THUẦN", hiển thị Tổng thu + Tổng chi → đúng.
- `report_screen.dart`: `showIncome = (FM || revenue)`, `showExpense = (FM || expense)`
  → FM thấy cả 2 card + card dòng tiền thuần → đúng.
- `report_detail_screen.dart`: nhận `reportType` từ route → FM vào được cả 2 chi tiết → đúng.

Logic đã đúng, không sửa code. Sau implement sẽ chạy `flutter analyze` + `flutter build`
để đảm bảo không break.

## Rủi ro / Lưu ý

- Package `pdf` + `printing` đã có sẵn (`pubspec.yaml`) → không thêm dependency.
- Không đụng vào Repository/Firestore (đã chạy tốt).
- Giữ nguyên Role switcher (user bỏ Phần 3).
- Format tiền: VND nguyên (`int`), `NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0)`.

## Tiêu chí hoàn thành

- 4 feature provider được implement, không còn `// To be implemented`.
- `ReportCalculator` trả về giá trị thật.
- Nút Xuất PDF ở Báo cáo sinh được file PDF thật.
- `flutter analyze` sạch, build thành công.
