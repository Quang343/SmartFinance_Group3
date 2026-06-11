# 03_BUSINESS_FLOWS.md
# SmartFinance Business Flows

## 1. Flow: Add Income/Expense Transaction

### Goal
User records a new income or expense transaction.

### Actor
Data Entry Staff

### Main Flow

```text
Open Transactions screen
→ Tap Add Transaction
→ Enter amount
→ Select transaction type: Income or Expense
→ Select category
→ Select transaction date
→ Add note if needed
→ Attach receipt image if needed
→ Tap Save
→ System validates input
→ System saves transaction locally
→ Transaction list updates
→ Dashboard recalculates
```

### Validation

- Amount must not be empty.
- Amount must be numeric.
- Amount must be greater than 0.
- Type is required.
- Category is required.
- Date is required.

### Success Result
A confirmed transaction is stored and included in dashboard/report calculations.

### Failure Cases

- Invalid amount → show field error.
- Missing category → show field error.
- Local database write failed → show error message.

---

## 2. Flow: Edit Transaction

### Goal
User updates an existing transaction.

### Actor
Data Entry Staff

### Main Flow

```text
Open Transactions screen
→ Select transaction
→ Open edit form
→ System pre-fills current data
→ User changes data
→ Tap Save
→ System validates input
→ System updates local database
→ List and dashboard update
```

### Success Result
Transaction is updated and reports use the latest values.

### Failure Cases

- Transaction not found → show error.
- Invalid input → show field error.
- Update failed → show error message.

---

## 3. Flow: Delete Transaction

### Goal
User removes an invalid or unwanted transaction.

### Actor
Data Entry Staff

### Main Flow

```text
Open Transactions screen
→ Swipe transaction or tap delete
→ System shows confirmation
→ User confirms
→ System marks transaction as deleted
→ Transaction disappears from normal list
→ Dashboard recalculates
```

### Alternative Flow: Undo

```text
After deletion
→ System shows snackbar with Undo
→ User taps Undo
→ System restores transaction status to confirmed
→ List and dashboard update again
```

### Success Result
Deleted transaction is not included in reports.

---

## 4. Flow: Attach Receipt Image to Transaction

### Goal
User attaches evidence to a transaction.

### Actor
Data Entry Staff

### Main Flow

```text
Open Transaction Form
→ Tap Attach Receipt
→ Choose Camera or Gallery
→ Select/Capture image
→ System stores local file path
→ Preview image in form
→ Save transaction
```

### Success Result
Transaction stores a reference to the receipt image.

### Failure Cases

- User denies permission → show permission message.
- User cancels picker → return to form.
- File not found later → show missing file placeholder.

---

## 5. Flow: Smart Scan Invoice

### Goal
User simulates AI OCR invoice extraction.

### Actor
Invoice Staff

### Main Flow

```text
Open Invoice Scan screen
→ Select or capture invoice image
→ Preview image
→ Tap Smart Scan
→ System enters scanning state
→ Show scan animation for around 2 seconds
→ Mock OCR service returns fake extracted data
→ System fills invoice form
→ User reviews data
→ User saves invoice
```

### OCR States

```text
idle
imageSelected
scanning
extracted
failed
```

### Mock Data Example

```text
Partner Name: Công ty TNHH Minh An
Partner Tax Code: 0101234567
Subtotal: 2,500,000 VND
VAT Rate: 10%
VAT Amount: 250,000 VND
Total Amount: 2,750,000 VND
OCR Confidence: 92%
```

### Failure Cases

- No image selected → show warning.
- Scan simulation failed → show failed state and retry button.

---

## 6. Flow: Save Invoice

### Goal
User saves verified invoice data.

### Actor
Invoice Staff

### Main Flow

```text
Invoice data is filled
→ User reviews/edit data
→ Tap Save Invoice
→ System validates invoice
→ System recalculates VAT and total amount
→ System saves invoice locally
→ Invoice list updates
```

### Success Result
Invoice is stored and can be viewed/exported later.

### Validation

- Partner name required.
- Tax code required.
- Subtotal must be greater than 0.
- VAT rate must be 8 or 10.
- Issued date required.

---

## 7. Flow: Export Invoice PDF

### Goal
User exports a saved invoice as PDF.

### Actor
Invoice Staff or Manager

### Main Flow

```text
Open Invoice Preview
→ Review invoice layout
→ Tap Export PDF
→ System generates PDF using Unicode font
→ System opens print/share dialog
→ User saves, prints, or shares PDF
```

### Success Result
PDF invoice is generated and shareable.

### Failure Cases

- PDF generation failed → show error.
- Missing font → Vietnamese text may break. Must prevent by loading Unicode font.

---

## 8. Flow: View Dashboard

### Goal
Manager views financial overview.

### Actor
Manager

### Main Flow

```text
Open Dashboard
→ System loads confirmed transactions
→ Apply default date filter
→ Calculate total income
→ Calculate total expense
→ Calculate net cash flow
→ Calculate expense ratio
→ Group expense by category
→ Group income/expense by time
→ Render KPI cards and charts
```

### Dashboard Outputs

- Total income
- Total expense
- Net cash flow
- Expense ratio
- Expense category pie chart
- Income vs expense chart
- Recent transactions

### Empty State
If no transaction exists, show:

```text
No financial data yet. Add your first transaction to see dashboard insights.
```

---

## 9. Flow: Change Dashboard Date Filter

### Goal
Manager changes the report period.

### Actor
Manager

### Main Flow

```text
Open Dashboard
→ Select date filter
→ System calculates startDate and endDate
→ System filters confirmed transactions
→ System recalculates KPI and chart data
→ UI updates with animation
```

### Supported Filters

- Today
- Last 7 days
- This month
- Last month
- This quarter
- This year
- All time
- Custom range

---

## 10. Flow: Export Cash Flow Report PDF

### Goal
Manager exports a summary financial report.

### Actor
Manager

### Main Flow

```text
Open Reports screen
→ Select report period
→ System calculates summary
→ Show report preview
→ Tap Export PDF
→ Generate PDF report
→ Open print/share dialog
```

### PDF Content

- Report title
- Period
- Total income
- Total expense
- Net cash flow
- Expense ratio
- Top expense categories
- Transaction summary table

---

## 11. Flow: Manage Categories

### Goal
Admin manages income and expense categories.

### Actor
Admin

### Main Flow: Add Category

```text
Open Category Management
→ Tap Add Category
→ Enter category name
→ Select type: income or expense
→ Choose icon/color if needed
→ Save
→ Category appears in category list and transaction form
```

### Main Flow: Deactivate Category

```text
Open Category Management
→ Select category
→ Tap Delete/Deactivate
→ If category is used by transactions, mark as inactive
→ If not used, allow deletion
```

### Rule
Do not hard-delete categories used by existing transactions.
