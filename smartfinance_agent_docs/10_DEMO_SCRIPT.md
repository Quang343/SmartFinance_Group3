# 10_DEMO_SCRIPT.md
# SmartFinance Demo Script

## 1. Demo Goal
The demo should show SmartFinance as a complete SME cash-flow management app, not just a collection of Flutter screens.

Main message:

```text
SmartFinance helps SME owners track income, expenses, invoices, and cash-flow reports in a simple offline-first app.
```

## 2. Demo Preparation

Before presenting:

- Seed demo income transactions.
- Seed demo expense transactions.
- Seed default categories.
- Prepare one invoice image.
- Make sure dashboard has visible charts.
- Make sure PDF export works.
- Test both mobile and web/desktop layouts.

## 3. Suggested Demo Flow

### Step 1: Introduce the problem

Say:

```text
Many small businesses still track cash flow using Excel, paper notes, or scattered invoices. SmartFinance gives them a simple app to record income/expense, attach receipts, view dashboard reports, and export PDF documents.
```

### Step 2: Open Dashboard

Show:

- Total income
- Total expense
- Net cash flow
- Expense ratio
- Expense pie chart
- Income vs expense chart

Explain:

```text
The dashboard is calculated from confirmed transactions stored locally. It gives managers a quick overview of financial health.
```

### Step 3: Change date filter

Action:

- Switch from This Month to Last Month or All Time.

Explain:

```text
When the filter changes, the dashboard recalculates and charts update automatically through state management.
```

### Step 4: Add transaction

Action:

- Go to Transactions.
- Tap Add.
- Enter amount.
- Select type: Expense.
- Select category: Marketing or Rent.
- Select date.
- Attach receipt image if possible.
- Save.

Explain:

```text
The form validates required fields and stores amount as integer VND to avoid rounding errors.
```

### Step 5: Show transaction list update

Action:

- Show new transaction in list.
- Show dashboard updated.

Explain:

```text
After saving, the transaction list and dashboard are updated from local storage.
```

### Step 6: Delete transaction with swipe

Action:

- Swipe transaction on mobile or click delete on desktop.
- Show confirmation/undo.

Explain:

```text
Deleted transactions are excluded from reports. A soft-delete approach can support undo and future audit logs.
```

### Step 7: Smart Scan invoice

Action:

- Open Invoice Scan.
- Select invoice image.
- Tap Smart Scan.
- Wait for animation.
- Show auto-filled mock data.

Explain:

```text
This version simulates AI OCR. It shows a scanning animation and then fills sample invoice data such as partner tax code, subtotal, VAT, and total amount.
```

### Step 8: Save invoice

Action:

- Review data.
- Save invoice.

Explain:

```text
Before saving, the app recalculates VAT and total amount based on business rules.
```

### Step 9: Export invoice PDF

Action:

- Open invoice preview.
- Export PDF.

Explain:

```text
The app generates a PDF invoice and opens the platform print/share dialog. Vietnamese text is supported through Unicode fonts.
```

### Step 10: Export report PDF

Action:

- Open Reports.
- Select period.
- Export PDF.

Explain:

```text
Managers can export a cash-flow report including total income, total expense, net cash flow, and top expense categories.
```

### Step 11: Show responsive layout

Action:

- Resize browser or switch device.

Explain:

```text
On mobile, SmartFinance uses bottom navigation and card lists. On desktop, it uses sidebar navigation, dashboard grid, and data tables.
```

### Step 12: Explain architecture briefly

Say:

```text
The app separates UI, state management, business logic, repository, and local database. This makes the project easier to maintain, test, and extend later with cloud sync or real OCR.
```

## 4. Demo Key Points to Emphasize

- Offline-first local storage
- Clean architecture
- Riverpod/Bloc/Provider state management
- Responsive UI
- Correct money calculation using int
- Mock AI OCR with animation
- PDF export
- Dashboard charts with filters

## 5. Possible Q&A

### Q: Is this a full accounting system?

Answer:

```text
No. The first version focuses on cash-flow management for SMEs. It does not handle debit/credit accounting, ledger, depreciation, or legal tax filing.
```

### Q: Is the OCR real AI?

Answer:

```text
In this version, OCR is simulated to demonstrate the user flow, animation, and auto-fill behavior. The architecture allows replacing the mock service with a real OCR API later.
```

### Q: Why store money as integer?

Answer:

```text
Money should not be stored as double because floating-point values can cause rounding errors. The app stores VND as integer values.
```

### Q: Can it work offline?

Answer:

```text
Yes. Core data such as transactions, categories, invoices, and settings are stored locally.
```

### Q: Can it support cloud sync later?

Answer:

```text
Yes. Because the app uses repository and local data source layers, a remote data source can be added later without rewriting the UI.
```
