# 01_BUSINESS_OVERVIEW.md
# SmartFinance Business Overview

## 1. Project Name
SmartFinance – SME Cash Flow Management Application

## 2. Business Context
Small and medium-sized enterprises often manage income, expenses, invoices, and receipts using spreadsheets, paper notes, chat messages, or disconnected tools. This causes common business problems:

- Income and expense data is scattered.
- Receipts and invoices are difficult to search later.
- Owners cannot quickly understand cash-flow status.
- Manual calculation creates errors.
- There is no visual dashboard for management decisions.
- Reports are difficult to export or share.

SmartFinance solves this by providing a simple, visual, offline-first application for recording cash movement and generating basic financial reports.

## 3. Business Goal
The main goal is to help SME managers answer these questions quickly:

- How much money came in during this period?
- How much money went out during this period?
- Is net cash flow positive or negative?
- Which expense category consumes the most money?
- How does this period compare with previous periods?
- Are invoices and receipts stored with the transactions?
- Can the manager export a PDF invoice or cash-flow report?

## 4. Scope

### In Scope

- Income transaction management
- Expense transaction management
- Category management
- Receipt/image attachment
- Invoice management
- Mock AI OCR invoice scan
- Auto-filled mock invoice data
- Dashboard KPI cards
- Pie chart for expense category distribution
- Bar/line chart for income vs expense over time
- Time filters
- Invoice PDF export
- Cash-flow report PDF export
- Offline local storage
- Responsive mobile and web/desktop UI

### Out of Scope

- Real accounting debit/credit entries
- General ledger
- Depreciation
- Closing entries
- Official tax filing
- Legal e-invoice integration
- Complex payroll
- Bank synchronization
- Multi-level approval workflow in the first version
- Real AI OCR in the first version
- Multi-company SaaS in the first version

## 5. Main User Groups

### Business Owner / Manager
Needs a quick overview of business financial health.

Main needs:

- View dashboard
- View income, expense, net cash flow
- Filter report by time
- View charts
- Export PDF reports

### Data Entry Staff
Records daily income and expense transactions.

Main needs:

- Add income
- Add expense
- Attach receipt image
- Edit or delete transactions
- Search/filter transaction history

### Invoice Staff
Handles invoice images and invoice data.

Main needs:

- Select or capture invoice image
- Run Smart Scan mock OCR
- Verify extracted data
- Save invoice
- Export invoice PDF

### System Admin / App Configurator
Manages base settings and categories.

Main needs:

- Manage income/expense categories
- Toggle theme
- Reset demo data
- Configure default filters

## 6. Product Positioning
SmartFinance should feel like a lightweight SaaS dashboard for SME cash-flow management. It should be simpler than professional accounting software but more structured than a spreadsheet.

## 7. Success Criteria
The project is successful when:

- Users can create and view income/expense transactions.
- Dashboard values are correct.
- Charts update when filters change.
- Invoice Smart Scan mock flow feels smooth.
- PDF invoice/report export works.
- App works offline.
- UI is responsive on mobile and web/desktop.
- Code follows a clean architecture and state management approach.
