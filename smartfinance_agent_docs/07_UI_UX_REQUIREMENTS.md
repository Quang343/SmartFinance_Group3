# 07_UI_UX_REQUIREMENTS.md
# SmartFinance UI/UX Requirements

## 1. Design Goal
SmartFinance should look like a modern SME financial dashboard. The UI must be clean, professional, responsive, and easy for non-accountants to use.

Design direction:

```text
Simple + business-friendly + dashboard-oriented + mobile/web responsive
```

Avoid:

- Overly complex accounting UI
- Too many technical financial terms
- Dense screens without spacing
- UI that only works on mobile
- UI that only works on desktop

## 2. Responsive Layout Strategy

### Breakpoints

| Width | Layout |
|---|---|
| < 700px | Mobile |
| 700px - 1100px | Tablet |
| > 1100px | Desktop/Web |

### Mobile UX

- Bottom navigation
- Card list
- Vertical forms
- Floating Action Button for adding transaction
- Charts stacked vertically
- Simple filters

### Desktop/Web UX

- Sidebar navigation
- Top bar with page title and filters
- Grid dashboard
- DataTable for transactions/invoices
- Form panel or modal
- Wider charts

## 3. Navigation

### Mobile Tabs

1. Dashboard
2. Transactions
3. Invoices
4. Reports
5. Settings

### Desktop Sidebar

1. Dashboard
2. Transactions
3. Invoices
4. Reports
5. Categories
6. Settings

## 4. Screen List

| ID | Screen | Purpose |
|---|---|---|
| UI01 | Dashboard | Financial overview |
| UI02 | Transaction List | View transaction history |
| UI03 | Transaction Form | Add/edit income or expense |
| UI04 | Invoice List | View saved invoices |
| UI05 | Invoice Scan | Select image and Smart Scan |
| UI06 | Invoice Preview | Preview and export PDF invoice |
| UI07 | Report Screen | View and export cash-flow report |
| UI08 | Category Management | Manage income/expense categories |
| UI09 | Settings | Theme and app settings |

## 5. UI01 Dashboard

### Components

- Page title
- Date filter
- KPI card: Total income
- KPI card: Total expense
- KPI card: Net cash flow
- KPI card: Expense ratio
- Pie chart: Expense by category
- Bar/line chart: Income vs expense over time
- Recent transactions

### Mobile Layout

```text
[Dashboard Header]
[Date Filter]

[Total Income Card]
[Total Expense Card]
[Net Cash Flow Card]
[Expense Ratio Card]

[Expense Pie Chart]
[Income vs Expense Chart]
[Recent Transactions]
```

### Desktop Layout

```text
[Sidebar] [Top Bar: Dashboard + Date Filter]

          [Income] [Expense] [Net Cash Flow] [Expense Ratio]

          [Expense Pie Chart]      [Income vs Expense Chart]

          [Recent Transaction Table]
```

### Interaction

- Changing filter updates all KPI cards and charts.
- Chart touch/hover shows tooltip.
- Negative net cash flow should be visually warned.
- Empty dashboard shows guidance to add transaction.

## 6. UI02 Transaction List

### Components

- Title
- Add button
- Search
- Filter by type
- Filter by category
- Filter by date range
- Transaction list/table

### Mobile Card Content

- Category icon
- Category name
- Transaction note
- Date
- Amount
- Income/expense badge
- Receipt indicator

### Desktop Table Columns

```text
Date | Type | Category | Note | Amount | Receipt | Actions
```

### Interaction

- Swipe to delete on mobile.
- Edit/delete action buttons on desktop.
- Undo snackbar after delete if possible.
- Tap transaction to edit or view detail.

## 7. UI03 Transaction Form

### Fields

- Amount
- Transaction type: Income/Expense
- Category
- Transaction date
- Note
- Receipt image

### Validation

- Amount required
- Amount numeric
- Amount > 0
- Type required
- Category required
- Date required

### Mobile Layout

```text
[Header]
[Amount]
[Type segmented control]
[Category dropdown]
[Date picker]
[Note]
[Receipt picker]
[Save button]
```

### Desktop Layout

```text
[Form Panel]
Left: Amount, Type, Category
Right: Date, Note, Receipt
Bottom: Cancel, Save
```

## 8. UI04 Invoice List

### Components

- Title
- Smart Scan button
- OCR status filter
- Invoice list/table

### Desktop Table Columns

```text
Invoice No | Partner | Tax Code | Date | Total | OCR Status | Actions
```

## 9. UI05 Invoice Scan

### Components

- Image picker area
- Image preview
- Smart Scan button
- Scan animation
- Extracted data form
- Save Invoice button
- Export PDF button

### States

```text
idle
imageSelected
scanning
extracted
failed
```

### Flow UI

```text
Select Image
→ Preview Image
→ Tap Smart Scan
→ Show scanning animation for 2s
→ Auto-fill invoice data
→ User reviews and saves
```

### Interaction Rules

- Disable Smart Scan during scanning.
- Require image before scan.
- Allow user to edit extracted data.
- Show retry option if failed.

## 10. UI06 Invoice Preview

### Content

```text
HÓA ĐƠN BÁN HÀNG

Seller: SmartFinance Demo Company
Tax Code: 0100000000

Partner: Công ty TNHH Minh An
Partner Tax Code: 0101234567
Date: 10/06/2026

Subtotal: 2,500,000 VND
VAT 10%: 250,000 VND
Total: 2,750,000 VND

[Export PDF]
```

## 11. UI07 Report Screen

### Components

- Report period filter
- Total income
- Total expense
- Net cash flow
- Expense ratio
- Top expense categories
- Transaction summary table
- Export PDF button

## 12. UI08 Category Management

### Components

- Income/Expense tabs
- Category list
- Add category button
- Edit category modal/form
- Deactivate/delete action

### Rules

- Category name required.
- Category type required.
- Used category should be deactivated, not hard-deleted.

## 13. UI09 Settings

### Components

- Theme mode: light/dark/system
- Reset demo data
- App version
- Team information

## 14. UI States

Every data-heavy screen should support:

```text
initial
loading
success
empty
error
```

Examples:

Dashboard:

```text
DashboardLoading
DashboardSuccess
DashboardEmpty
DashboardError
```

Smart Scan:

```text
ScanInitial
ScanImageSelected
ScanInProgress
ScanExtracted
ScanFailed
```

## 15. Design Quality Checklist

- No layout overflow on mobile.
- Desktop uses table/grid, not oversized mobile cards.
- Buttons have clear labels.
- Forms show helpful validation messages.
- Important actions show feedback.
- Charts have tooltip.
- Empty states explain next action.
- PDF preview looks similar to exported PDF.
