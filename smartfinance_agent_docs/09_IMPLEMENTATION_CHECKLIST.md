# 09_IMPLEMENTATION_CHECKLIST.md
# SmartFinance Implementation Checklist

## 1. Foundation

- [ ] Create Flutter project
- [ ] Add required dependencies
- [ ] Setup app theme
- [ ] Setup light/dark theme
- [ ] Setup GoRouter
- [ ] Setup responsive shell
- [ ] Setup local database
- [ ] Seed default categories
- [ ] Add core utility classes

## 2. Domain Layer

- [ ] Create TransactionEntity
- [ ] Create CategoryEntity
- [ ] Create InvoiceEntity
- [ ] Create ReportSummary
- [ ] Create TransactionType enum
- [ ] Create TransactionStatus enum
- [ ] Create OcrStatus enum
- [ ] Create CashFlowCalculator
- [ ] Create VatCalculator
- [ ] Create ReportCalculator
- [ ] Create DateRangeUtils
- [ ] Create Validators

## 3. Repository Layer

- [ ] Create TransactionRepository interface
- [ ] Create CategoryRepository interface
- [ ] Create InvoiceRepository interface
- [ ] Implement local transaction repository
- [ ] Implement local category repository
- [ ] Implement local invoice repository

## 4. Transaction Feature

- [ ] Transaction list screen
- [ ] Mobile transaction card layout
- [ ] Desktop transaction table layout
- [ ] Transaction form screen
- [ ] Amount validation
- [ ] Type selector
- [ ] Category dropdown filtered by type
- [ ] Date picker
- [ ] Receipt image picker
- [ ] Add transaction
- [ ] Edit transaction
- [ ] Delete/soft-delete transaction
- [ ] Dismissible swipe delete on mobile
- [ ] Undo snackbar
- [ ] Transaction filters
- [ ] Empty/loading/error states

## 5. Category Feature

- [ ] Category list screen
- [ ] Income/expense tabs
- [ ] Add category
- [ ] Edit category
- [ ] Deactivate category
- [ ] Prevent hard delete if used

## 6. Invoice Feature

- [ ] Invoice list screen
- [ ] Invoice detail screen
- [ ] Invoice scan screen
- [ ] Image picker
- [ ] Camera optional
- [ ] Image preview
- [ ] Smart Scan button
- [ ] Scan animation
- [ ] Mock OCR service
- [ ] Auto-fill invoice form
- [ ] VAT calculation
- [ ] Save invoice
- [ ] Invoice preview
- [ ] Export invoice PDF
- [ ] Empty/loading/error states

## 7. Dashboard Feature

- [ ] Dashboard screen
- [ ] KPI cards
- [ ] Total income
- [ ] Total expense
- [ ] Net cash flow
- [ ] Expense ratio
- [ ] Date filter
- [ ] Expense pie chart
- [ ] Income vs expense chart
- [ ] Chart tooltip
- [ ] Animated update on filter change
- [ ] Recent transactions
- [ ] Empty/loading/error states

## 8. Report Feature

- [ ] Report screen
- [ ] Report period filter
- [ ] Report summary cards
- [ ] Top expense categories
- [ ] Transaction summary table
- [ ] Report preview
- [ ] Export report PDF

## 9. Settings Feature

- [ ] Theme mode selector
- [ ] Save theme locally
- [ ] Reset demo data
- [ ] App info screen

## 10. PDF

- [ ] Add Unicode font asset
- [ ] Load font for PDF
- [ ] Invoice PDF layout
- [ ] Report PDF layout
- [ ] Printing/share integration
- [ ] Test Vietnamese text display

## 11. Responsive QA

- [ ] Test mobile width < 700px
- [ ] Test tablet width 700px - 1100px
- [ ] Test desktop width > 1100px
- [ ] No overflow in forms
- [ ] Charts readable on mobile
- [ ] Tables usable on desktop

## 12. Unit Tests

- [ ] Test total income
- [ ] Test total expense
- [ ] Test net cash flow
- [ ] Test VAT 8%
- [ ] Test VAT 10%
- [ ] Test expense ratio when income = 0
- [ ] Test this month date range
- [ ] Test last month date range
- [ ] Test category grouping

## 13. Demo Readiness

- [ ] Seed demo transactions
- [ ] Seed demo categories
- [ ] Seed demo invoices
- [ ] Dashboard looks populated
- [ ] Smart Scan mock works smoothly
- [ ] PDF export works
- [ ] Mobile layout ready
- [ ] Web/desktop layout ready
- [ ] Presentation flow rehearsed
