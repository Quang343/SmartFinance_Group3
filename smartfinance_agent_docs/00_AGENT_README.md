# 00_AGENT_README.md
# SmartFinance Agent Context

## Purpose
This folder contains the business, functional, UI, data, and architecture context for the SmartFinance Flutter project. Any coding/design agent should read these files before generating code, UI, database models, providers, routes, or tests.

## Project Summary
SmartFinance is a Flutter application for SME cash-flow management. It helps small businesses record income/expense transactions, attach receipts, simulate AI OCR invoice scanning, view financial dashboards, and export invoice/report PDFs.

## Product Framing
SmartFinance is **not** a full accounting system. It does not handle debit/credit accounting, general ledger, depreciation, closing entries, or legal tax filing. The product focuses on simple cash-flow tracking and business-friendly reporting.

Correct framing:

```text
SmartFinance = SME cash-flow tracker
             + transaction management
             + receipt/invoice storage
             + mock AI invoice scan
             + dashboard reporting
             + PDF export
             + offline-first local storage
             + responsive Flutter UI
```

## Mandatory Principles for Agents

1. Do not build a full accounting system.
2. Use integer money values for VND. Do not use double for money storage.
3. Keep business logic outside Flutter widgets.
4. Use state management for global/feature state.
5. Design mobile and desktop layouts separately where needed.
6. Support offline-first behavior.
7. Treat OCR as a mock simulation unless explicitly asked otherwise.
8. All dashboard numbers must be calculated from valid transactions only.
9. Deleted transactions must not affect reports.
10. PDF must support Vietnamese text through Unicode fonts.

## Recommended Tech Stack

```text
Flutter
Riverpod
GoRouter
Hive or Isar
fl_chart
image_picker
pdf
printing
intl
uuid
lottie optional
flutter_test
```

Preferred stack for maintainability:

```text
Flutter + Riverpod + GoRouter + Isar + fl_chart + pdf/printing
```

Simpler stack:

```text
Flutter + Riverpod + GoRouter + Hive + fl_chart + pdf/printing
```

## Suggested Reading Order

1. `01_BUSINESS_OVERVIEW.md`
2. `02_BUSINESS_RULES.md`
3. `03_BUSINESS_FLOWS.md`
4. `04_FUNCTIONAL_REQUIREMENTS.md`
5. `05_USE_CASES.md`
6. `06_DATA_MODEL_DATABASE.md`
7. `07_UI_UX_REQUIREMENTS.md`
8. `08_ARCHITECTURE_GUIDE.md`
9. `09_IMPLEMENTATION_CHECKLIST.md`
10. `10_DEMO_SCRIPT.md`

## Delivery Target
The final project should include:

- Business analysis document
- Functional requirements document
- Use-case diagram
- UI design/wireframe
- Database design/ERD
- Flutter implementation
- Demo and presentation
