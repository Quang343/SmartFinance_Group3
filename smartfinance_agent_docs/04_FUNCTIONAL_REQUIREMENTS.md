# 04_FUNCTIONAL_REQUIREMENTS.md
# SmartFinance Functional Requirements

## 1. Overview
This document defines the functional requirements of SmartFinance. Each requirement describes what the system must do from the user's perspective.

## 2. Transaction Management

### FR-TRX-01: View transaction list
The system shall display a list of income and expense transactions.

Acceptance criteria:

- Mobile displays transactions as cards.
- Desktop/web displays transactions as a table.
- Empty state appears if there are no transactions.
- Loading and error states are handled.

### FR-TRX-02: Add transaction
The system shall allow users to create a new transaction.

Required input:

- Amount
- Type
- Category
- Transaction date

Optional input:

- Note
- Receipt image

Acceptance criteria:

- Invalid input displays validation errors.
- Valid transaction is saved locally.
- Transaction list updates after saving.
- Dashboard values update after saving.

### FR-TRX-03: Edit transaction
The system shall allow users to edit existing transactions.

Acceptance criteria:

- Existing data is pre-filled.
- Updated data is validated.
- Changes are saved locally.
- Reports use updated values.

### FR-TRX-04: Delete transaction
The system shall allow users to delete or soft-delete transactions.

Acceptance criteria:

- Mobile supports swipe-to-delete using Dismissible.
- Desktop supports delete button per row.
- System shows confirmation or undo snackbar.
- Deleted transactions are not counted in reports.

### FR-TRX-05: Attach receipt image
The system shall allow users to attach an image to a transaction.

Acceptance criteria:

- User can select image from gallery.
- Camera may be supported.
- Image preview is shown.
- File path is stored locally.

### FR-TRX-06: Filter and search transactions
The system shall allow users to filter/search transactions.

Filters:

- Type: all, income, expense
- Category
- Date range
- Keyword search

## 3. Category Management

### FR-CAT-01: View categories
The system shall display income and expense categories.

### FR-CAT-02: Add category
The system shall allow adding a new category.

Required fields:

- Name
- Type

### FR-CAT-03: Edit category
The system shall allow updating category name, icon, color, and active status.

### FR-CAT-04: Delete/deactivate category
The system shall allow category deletion only when safe. If category is used by transactions, deactivate instead of hard-delete.

## 4. Invoice and Smart Scan

### FR-INV-01: Select invoice image
The system shall allow users to select an invoice image from gallery.

### FR-INV-02: Capture invoice image
The system may allow users to capture an invoice using camera.

### FR-INV-03: Smart Scan simulation
The system shall simulate AI OCR scanning.

Acceptance criteria:

- Scan requires selected image.
- Scan animation runs for around 2 seconds.
- System fills mock invoice data after scan.
- OCR state changes correctly.

### FR-INV-04: Edit extracted invoice data
The system shall allow users to edit invoice data after Smart Scan.

### FR-INV-05: Save invoice
The system shall save invoice data locally.

Acceptance criteria:

- VAT and total are recalculated before save.
- Invalid input shows validation errors.
- Invoice list updates after save.

### FR-INV-06: View invoice list
The system shall display saved invoices.

### FR-INV-07: View invoice detail/preview
The system shall show invoice preview with subtotal, VAT, and total amount.

### FR-INV-08: Export invoice PDF
The system shall generate a PDF invoice and open print/share dialog.

## 5. Dashboard and Reports

### FR-DASH-01: View dashboard summary
The system shall display dashboard KPI cards:

- Total income
- Total expense
- Net cash flow
- Expense ratio

### FR-DASH-02: Expense category chart
The system shall display a pie chart for expense distribution by category.

### FR-DASH-03: Income vs expense chart
The system shall display a bar or line chart comparing income and expense by time.

### FR-DASH-04: Time filter
The system shall allow users to filter dashboard data by time.

Supported filters:

- Today
- Last 7 days
- This month
- Last month
- This quarter
- This year
- All time
- Custom range

### FR-DASH-05: Chart tooltip
The system shall show tooltip information when the user taps or hovers chart data.

### FR-REP-01: View cash-flow report
The system shall show a report preview for the selected period.

### FR-REP-02: Export report PDF
The system shall generate a PDF cash-flow report.

## 6. Settings

### FR-SET-01: Theme mode
The system shall allow switching between light mode, dark mode, and system mode.

### FR-SET-02: Demo data reset
The system may provide reset demo data function for presentation/testing.

### FR-SET-03: Save settings locally
The system shall save user settings locally.

## 7. Offline Storage

### FR-OFF-01: Local persistence
The system shall persist transactions, categories, invoices, attachments, and settings locally.

### FR-OFF-02: Offline usability
The system shall allow core functions without network connection.

Core offline functions:

- View/add/edit/delete transactions
- View dashboard from local data
- View/save invoices
- Export PDF
- Change settings

## 8. Non-functional Requirements

### NFR-01: Responsiveness
The app must support mobile and web/desktop layouts.

### NFR-02: Correctness
Money and report calculations must be accurate.

### NFR-03: Performance
Dashboard calculations should not run directly inside widget build methods.

### NFR-04: Maintainability
The project should separate UI, state management, business logic, repository, and database layers.

### NFR-05: User feedback
All long-running or important actions must show feedback:

- Loading
- Success
- Error
- Empty state
