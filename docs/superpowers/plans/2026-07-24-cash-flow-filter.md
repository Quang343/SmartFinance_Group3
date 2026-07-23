# Corporate Cash Flow Filter & Count Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Thêm bộ lọc loại giao dịch (Nhận/Mất đi) và hiển thị tổng số lượng giao dịch cạnh tổng số dư trong danh sách Dòng tiền doanh nghiệp.

**Architecture:** Bổ sung state `_selectedType` vào `TransactionListScreen`, áp dụng logic lọc vào danh sách giao dịch trước khi tính toán `totalIncome`, `totalExpense` và hiển thị UI cho bộ lọc này. Cập nhật dòng hiển thị tổng số dư thêm thông tin số lượng giao dịch.

**Tech Stack:** Flutter, Dart (Riverpod)

## Global Constraints

- Ngôn ngữ UI tiếng Việt.
- Tuân thủ thiết kế hiện tại của ứng dụng.

---

### Task 1: Cập nhật state, logic lọc và UI

**Files:**
- Modify: `lib/features/transactions/presentation/transaction_list_screen.dart`

- [ ] **Step 1: Khai báo state mới**
Thêm `String _selectedType = 'all';`

- [ ] **Step 2: Áp dụng bộ lọc type**
Thêm logic lọc theo `_selectedType` ('income', 'expense') trước đoạn lọc theo `_searchQuery`.

- [ ] **Step 3: Cập nhật giao diện đếm tổng số lượng**
Cập nhật Text của "Tổng Số Dư" thành dạng `_getPeriodTitle('Tổng Số Dư') + ' (${list.length})'` hoặc thêm Text widget `(${list.length} GD)` cạnh tổng số dư để người dùng dễ quan sát.

- [ ] **Step 4: Thêm giao diện bộ lọc loại dòng tiền**
Thêm một hàng `Row` chứa các filter chip tương tự như Status/Category nhưng dành cho "Loại dòng tiền: Tất cả | Thu | Chi".