# 02_BUSINESS_RULES.md
# SmartFinance Business Rules

## 1. Money Rules

### BR-MONEY-01: Store money as integer
All VND money values must be stored as integer values.

Correct:

```dart
final amount = 1500000; // 1,500,000 VND
```

Incorrect:

```dart
final amount = 1500000.0;
```

Reason: Double values can create rounding errors and are not suitable for money storage.

### BR-MONEY-02: Amount must be positive
Transaction amount, invoice subtotal, VAT amount, and total amount must be greater than or equal to zero depending on context.

For user input:

```text
transaction.amount > 0
invoice.subtotal > 0
```

### BR-MONEY-03: Display money using VND format
Money should be displayed using Vietnamese currency formatting.

Example:

```text
1.500.000 VND
```

## 2. Transaction Rules

### BR-TRX-01: Transaction type
A transaction can only be one of:

```text
income
expense
```

### BR-TRX-02: Required transaction fields
A valid transaction must have:

- id
- amount
- type
- categoryId
- transactionDate
- status
- createdAt
- updatedAt

Optional fields:

- note
- invoiceId
- attachment

### BR-TRX-03: Transaction status
A transaction can have one of these statuses:

```text
draft
confirmed
deleted
```

### BR-TRX-04: Report calculation status
Only `confirmed` transactions are included in dashboard and report calculations.

Excluded from reports:

```text
draft
deleted
```

### BR-TRX-05: Deleted transactions
Deleted transactions should preferably be soft-deleted by changing status to `deleted` instead of physical deletion.

Reason:

- Supports undo
- Prevents accidental data loss
- Allows future audit log support

## 3. Category Rules

### BR-CAT-01: Category type
A category must belong to one of:

```text
income
expense
```

### BR-CAT-02: Category name required
A category must have a non-empty name.

### BR-CAT-03: Category used by transaction
If a category is already used by existing transactions, it should not be hard-deleted. It should be marked as inactive.

### BR-CAT-04: Default categories
The system should provide default categories.

Income examples:

- Doanh thu bán hàng
- Doanh thu dịch vụ
- Khoản thu khác

Expense examples:

- Lương
- Mặt bằng
- Marketing
- Mua hàng
- Vận hành
- Điện nước
- Phần mềm
- Chi phí khác

## 4. Invoice Rules

### BR-INV-01: Required invoice fields
A valid invoice must have:

- id
- invoiceNumber
- partnerName
- partnerTaxCode
- subtotal
- vatRate
- vatAmount
- totalAmount
- ocrStatus
- issuedDate
- createdAt
- updatedAt

### BR-INV-02: VAT rate
VAT rate can only be:

```text
8
10
```

### BR-INV-03: VAT calculation
VAT amount is calculated as:

```text
vatAmount = subtotal * vatRate / 100
```

In code, use integer-safe calculation:

```dart
final vatAmount = subtotal * vatRate ~/ 100;
```

### BR-INV-04: Total payment
Total payment is calculated as:

```text
totalAmount = subtotal + vatAmount
```

### BR-INV-05: Recalculate before save
Before saving an invoice, the system should recalculate `vatAmount` and `totalAmount` based on `subtotal` and `vatRate`.

## 5. OCR / Smart Scan Rules

### BR-OCR-01: OCR is mock in version 1
Smart Scan does not call a real AI OCR service in the initial version. It simulates scanning with animation and mock data.

### BR-OCR-02: OCR states
OCR status can be:

```text
notStarted
imageSelected
scanning
extracted
failed
```

### BR-OCR-03: Scan duration
When user taps Smart Scan, the app should show scanning animation for about 2 seconds before filling mock data.

### BR-OCR-04: Scan requires image
Smart Scan cannot start if no invoice image has been selected.

## 6. Dashboard Rules

### BR-DASH-01: Total income
```text
totalIncome = sum(amount) where transaction.type = income and status = confirmed and date within selected range
```

### BR-DASH-02: Total expense
```text
totalExpense = sum(amount) where transaction.type = expense and status = confirmed and date within selected range
```

### BR-DASH-03: Net cash flow
```text
netCashFlow = totalIncome - totalExpense
```

### BR-DASH-04: Expense ratio
```text
expenseRatio = totalExpense / totalIncome * 100
```

If totalIncome is 0, return 0 or null and display “Không có dữ liệu”. Never divide by zero.

### BR-DASH-05: Expense category chart
Pie chart only includes expense transactions with status `confirmed` within the selected date range.

### BR-DASH-06: Income vs expense chart
Bar/line chart should aggregate income and expense by time bucket:

- Daily for short periods
- Monthly for yearly view
- Custom bucket if required

## 7. Date Filter Rules

Supported filters:

- Today
- Last 7 days
- This month
- Last month
- This quarter
- This year
- All time
- Custom range

For custom range:

```text
startDate <= endDate
```

## 8. PDF Rules

### BR-PDF-01: Unicode font
PDF generation must use a Unicode font that supports Vietnamese text.

### BR-PDF-02: Invoice PDF contents
Invoice PDF must include:

- Invoice title
- Seller information
- Partner information
- Invoice number
- Issued date
- Subtotal
- VAT rate
- VAT amount
- Total amount

### BR-PDF-03: Report PDF contents
Report PDF should include:

- Report period
- Total income
- Total expense
- Net cash flow
- Expense ratio
- Top expense categories
- Main transaction table

## 9. Offline Rules

### BR-OFFLINE-01: Local-first
Core data must be stored locally so the user can use the app without internet.

### BR-OFFLINE-02: Offline available functions
Without internet, user should still be able to:

- View transactions
- Add/edit/delete transactions
- View dashboard from local data
- View invoices
- Export PDF
- Change settings

## 10. Validation Rules

Transaction form:

- Amount is required
- Amount must be numeric
- Amount must be greater than 0
- Type is required
- Category is required
- Date is required and valid

Invoice form:

- Partner name is required
- Partner tax code is required
- Subtotal is required and positive
- VAT rate must be 8 or 10
- Issued date is required
