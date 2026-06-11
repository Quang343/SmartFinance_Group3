# 08_ARCHITECTURE_GUIDE.md
# SmartFinance Flutter Architecture Guide

## 1. Architecture Goal
The project should use a maintainable architecture that separates UI, state management, business logic, repositories, and local database.

Do not place business rules directly inside Flutter widgets.

Recommended architecture:

```text
UI Layer
→ Controller / Notifier Layer
→ Domain Service / Use Case Layer
→ Repository Layer
→ Local Data Source
→ Local Database
```

## 2. Recommended Packages

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.5.1
  go_router: ^14.2.0
  intl: ^0.19.0
  uuid: ^4.4.0
  fl_chart: ^0.68.0
  image_picker: ^1.1.2
  pdf: ^3.11.0
  printing: ^5.13.0
  lottie: ^3.1.2
```

Choose one local DB option:

```yaml
# Option A
hive: ^2.2.3
hive_flutter: ^1.1.0

# Option B
isar: latest compatible version
isar_flutter_libs: latest compatible version
```

## 3. Folder Structure

```text
lib/
├── main.dart
├── app/
│   ├── app.dart
│   ├── router.dart
│   ├── theme.dart
│   └── app_startup.dart
│
├── core/
│   ├── constants/
│   ├── errors/
│   ├── utils/
│   │   ├── money_utils.dart
│   │   ├── date_range_utils.dart
│   │   ├── validators.dart
│   │   └── pdf_font_loader.dart
│   └── widgets/
│       ├── responsive_shell.dart
│       ├── adaptive_scaffold.dart
│       ├── app_card.dart
│       ├── empty_state.dart
│       └── error_view.dart
│
├── data/
│   ├── local/
│   │   ├── app_database.dart
│   │   ├── transaction_local_source.dart
│   │   ├── invoice_local_source.dart
│   │   └── category_local_source.dart
│   └── mappers/
│       ├── transaction_mapper.dart
│       └── invoice_mapper.dart
│
├── domain/
│   ├── entities/
│   │   ├── transaction_entity.dart
│   │   ├── invoice_entity.dart
│   │   ├── category_entity.dart
│   │   └── report_summary.dart
│   ├── repositories/
│   │   ├── transaction_repository.dart
│   │   ├── invoice_repository.dart
│   │   └── category_repository.dart
│   └── services/
│       ├── cash_flow_calculator.dart
│       ├── vat_calculator.dart
│       ├── report_calculator.dart
│       └── mock_ocr_service.dart
│
├── features/
│   ├── dashboard/
│   ├── transactions/
│   ├── invoices/
│   ├── reports/
│   ├── categories/
│   └── settings/
└── storage/
```

## 4. Routing
Use `go_router`.

Suggested routes:

```text
/dashboard
/transactions
/transactions/new
/transactions/:id/edit
/invoices
/invoices/scan
/invoices/:id
/reports
/categories
/settings
```

## 5. State Management
Use Riverpod or Bloc. Riverpod is recommended for this project because it is faster to implement and still maintainable.

Suggested providers/controllers:

```text
transactionRepositoryProvider
transactionListProvider
transactionFormControllerProvider
invoiceRepositoryProvider
invoiceScanControllerProvider
invoiceListProvider
dashboardProvider
reportProvider
dateRangeFilterProvider
themeModeProvider
categoryProvider
```

## 6. State Patterns
Each feature should represent loading, success, empty, and error states.

Example:

```dart
sealed class DashboardState {}
class DashboardLoading extends DashboardState {}
class DashboardSuccess extends DashboardState {
  final ReportSummary summary;
  DashboardSuccess(this.summary);
}
class DashboardEmpty extends DashboardState {}
class DashboardError extends DashboardState {
  final String message;
  DashboardError(this.message);
}
```

Using Riverpod `AsyncValue` is also acceptable.

## 7. Business Logic Placement

Correct:

```text
cash_flow_calculator.dart calculates totals
vat_calculator.dart calculates VAT
report_calculator.dart aggregates dashboard data
mock_ocr_service.dart returns mock invoice data
```

Incorrect:

```text
Dashboard widget loops through transactions and calculates totals in build()
Invoice form widget calculates VAT in UI code only
Transaction form directly writes to database
```

## 8. Data Flow Examples

### Add Transaction

```text
TransactionFormScreen
→ TransactionFormController
→ Validator
→ TransactionRepository
→ LocalDataSource
→ LocalDatabase
→ Providers refresh
→ UI updates
```

### Dashboard

```text
DashboardScreen
→ DateRangeFilterProvider
→ DashboardProvider
→ TransactionRepository
→ ReportCalculator
→ DashboardState
→ Chart widgets
```

### Smart Scan

```text
InvoiceScanScreen
→ ImagePicker
→ InvoiceScanController
→ MockOcrService
→ InvoiceFormState
→ InvoiceRepository
→ LocalDatabase
```

## 9. Testing Strategy

Minimum unit tests:

- Total income calculation
- Total expense calculation
- Net cash flow calculation
- VAT 8% calculation
- VAT 10% calculation
- Expense ratio divide-by-zero handling
- Date filter this month
- Date filter last month

Test files:

```text
test/domain/services/cash_flow_calculator_test.dart
test/domain/services/vat_calculator_test.dart
test/domain/services/date_range_utils_test.dart
```

## 10. Architecture Risks

| Risk | Prevention |
|---|---|
| Business logic inside UI | Keep calculators/services in domain layer |
| Wrong money calculations | Use int for money |
| Hard-to-test code | Keep repositories and services injectable |
| UI rebuild too much | Use Riverpod selectors or scoped providers |
| PDF Vietnamese font issue | Load Unicode font explicitly |
| Database schema too weak | Use Category, Transaction, Invoice at minimum |
