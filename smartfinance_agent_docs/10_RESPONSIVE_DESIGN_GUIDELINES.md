# SmartFinance Unified Responsive & Adaptive Design Guidelines
**Roles:** Senior Product Designer & Senior Flutter Engineer & UX Architect  
**Version:** 1.0.0  
**Target Scope:** Global Architecture & All Screen Modules (Transactions, Invoices, Analytics, Settings)

---

## Executive Summary
Ứng dụng **SmartFinance** hướng tới trải nghiệm ERP đa nền tảng (Windows Desktop, Web, Android, iOS). Để giải quyết triệt để vấn đề bóp méo giao diện khi resize cửa sổ Desktop hoặc khi chạy trên các thiết bị Mobile/Tablet màn hình nhỏ, tài liệu này thiết lập **Chiến lược Responsive & Adaptive chuẩn hóa** bất biến cho toàn hệ thống.

---

## Phase 1 — Window Constraints (Ràng Buộc Kích Thước Cửa Sổ Desktop)

### 1.1 Nguyên Tắc
Nền tảng Desktop (Windows / macOS / Linux) được thiết kế cho thao tác đa nhiệm với bàn phím và chuột. **Tuyệt đối không cho phép người dùng co kéo cửa sổ Desktop nhỏ hơn kích thước usable tối thiểu (Minimum Usable Boundary)**.

### 1.2 Cấu Hình Kích Thước Tối Thiểu (Win32 Native API & Desktop Runner)
- **Minimum Width:** `960px` (Đảm bảo đủ không gian hiển thị Navigation Rail + Content 2 cột/Grid).
- **Minimum Height:** `650px` (Đảm bảo không bị tràn chiều dọc với thanh AppBar & Bottom Bar).
- **Default Launch Size:** `1280px x 720px` (HD Standard 16:9).

```cpp
// Win32 Native Constraint (windows/runner/win32_window.cpp)
case WM_GETMINMAXINFO: {
  MINMAXINFO* info = reinterpret_cast<MINMAXINFO*>(lparam);
  info->ptMinTrackSize.x = 960;  // Chống co kéo nhỏ hơn 960px
  info->ptMinTrackSize.y = 650;  // Chống co kéo nhỏ hơn 650px
  return 0;
}
```

---

## Phase 2 — Responsive Breakpoints Strategy (Điểm Ngắt Kích Thước)

Thay vì dùng 1 layout gượng ép cho mọi kích thước, hệ thống định nghĩa 4 Breakpoint chuẩn hóa:

| Breakpoint Name | Width Range ($W$) | Target Device / Use Case | Layout Structure | Navigation Paradigm |
| :--- | :--- | :--- | :--- | :--- |
| **Phone / Compact** | $W < 600\text{px}$ | Smartphones (iOS / Android) | 1-Column Vertical Stack | Bottom Navigation Bar |
| **Tablet / Medium** | $600\text{px} \le W < 1000\text{px}$ | Foldables, Tablets, Small Window | Single/Split Hybrid | Collapsible Drawer / Mini Rail |
| **Desktop / Expanded** | $1000\text{px} \le W < 1400\text{px}$ | Laptops, Standard Desktop | 2-Column Split-View | Permanent Navigation Rail (Expanded) |
| **Desktop XL / Ultra-Wide** | $W \ge 1400\text{px}$ | Ultra-Wide Monitors, Workstations | 3-Column / Grid Dashboard | Permanent Full Sidebar Navigation |

---

## Phase 3 — Transaction List UX & Filter Strategy (Chiến Lược Bộ Lọc)

### 3.1 Đánh Giá UX 3 Phương Án Cho Filter

| Phương Án | Mô Tả | Ưu Điểm | Nhược Điểm | Đánh Giá UX |
| :--- | :--- | :--- | :--- | :--- |
| **Option A (Wrap)** | Xuống dòng tự động tất cả các Chip | Thấy hết các Filter trên màn hình rộng | Chiếm quá nhiều chiều cao màn hình nhỏ, làm tụt danh sách dữ liệu | 🟡 Trung bình (Chỉ tốt trên Desktop lớn) |
| **Option B (Modal / BottomSheet)** | Ẩn toàn bộ Chips, mở bằng nút `[ 🔍 Bộ lọc (3) ]` | Giao diện gọn gàng 100%, tiết kiệm diện tích tối đa | Mất thêm 1-2 lần click để đổi filter | 🟢 Rất tốt trên Mobile / Màn hình hẹp |
| **Option C (Adaptive Dropdowns)** | Đổi Chips dài thành Dropdown Select `[ Trạng thái ▼ ]` `[ Danh mục ▼ ]` | Nhỏ gọn, thao tác chọn nhanh trong 1 dòng | Vẫn tốn diện tích ngang nếu có 4-5 bộ lọc cùng lúc | 🟢 Rất tốt trên Tablet / Medium Desktop |

### 3.2 Đề Xuất Chiến Lược Hybrid (Adaptive Filter Matrix) — LỰA CHỌN TỐI ƯU NHẤT
Áp dụng cơ chế **Adaptive theo Width**:
1. **Desktop XL ($W \ge 1400\text{px}$):** Hiển thị **Full Choice Chips** (Ngang).
2. **Desktop ($1000\text{px} \le W < 1400\text{px}$):** Hiển thị **Dropdown Filter Bar** trên 1 hàng duy nhất (`Status Dropdown` + `Category Dropdown` + `Date Picker`).
3. **Mobile & Tablet ($W < 1000\text{px}$):** Hiển thị **Filter Pill Component**:
   - `Search Bar` ở trên.
   - 1 Hàng Filter Quick Access gồm: Nút **`[ 🎛️ Bộ lọc (2) ]`** (hiển thị Badge số lượng lọc đang bật) + Chips trạng thái rút gọn.
   - Bấm vào **`[ 🎛️ Bộ lọc ]`** sẽ mở **Adaptive Filter Modal Sheet** chứa đầy đủ: *Loại giao dịch, Trạng thái, Danh mục, Khoảng thời gian, Khoảng tiền (Range slider)*.

---

## Phase 4 — Adaptive Layout & Spacing System (Hệ Thống Khoảng Cách)

Hệ thống Spacing tỉ lệ thuận với kích thước màn hình nhằm đảm bảo mật độ thông tin (Information Density) hợp lý:

```dart
class AppSpacing {
  static double pagePadding(double width) {
    if (width >= 1000) return 32.0; // Desktop
    if (width >= 600) return 20.0;  // Tablet
    return 14.0;                     // Mobile
  }

  static double cardGap(double width) {
    if (width >= 1000) return 16.0;
    if (width >= 600) return 12.0;
    return 10.0;
  }

  static double cardBorderRadius(double width) {
    if (width >= 1000) return 16.0;
    return 14.0;
  }
}
```

---

## Phase 5 — Typography System & Ellipsis/Flexible Text (An Toàn Văn Bản)

### 5.1 Quy Tắc An Toàn Tránh Tràn Text (Text Protection Rules)
1. **Không Bao Giờ Để Text Tràn Dọc (Prevent Vertical Character Splitting):**
   - Mọi Widget chứa Tiêu đề/Tên giao dịch/Mã hóa đơn BẮT BỘC gói trong `Expanded` hoặc `Flexible`.
   - Bắt buộc khai báo `maxLines: 1` hoặc `maxLines: 2` kết hợp `overflow: TextOverflow.ellipsis`.
2. **Hiển Thị Mã Số & Tiền Tệ (Codes & Amounts):**
   - Mã hóa đơn (OCR-INV-...): Sử dụng `TextOverflow.ellipsis` với `maxLines: 1`.
   - Số tiền (VND): Khai báo `FittedBox(fit: BoxFit.scaleDown)` cho các thẻ Summary Card để số tiền không bao giờ bị cắt rập hoặc nhảy dòng gãy vỡ.

---

## Phase 6 — Floating Action Button (FAB) Strategy

### 6.1 Vấn Đề
FAB đặt cố định ở góc dưới bên phải (`bottomRight`) thường che mất thông tin thẻ giao dịch cuối cùng hoặc che số tiền ở góc phải card.

### 6.2 Giải Pháp Cải Tiến
1. **Trên Mobile ($W < 600\text{px}$):**
   - **Tích hợp FAB vào Bottom Navigation Bar** (Center Docked FAB): Đặt nút `+` vào giữa thanh điều hướng đáy, vừa tiện tay bấm ngón cái, vừa loại bỏ hoàn toàn việc che nội dung danh sách!
   - Hoặc tự động ẩn FAB khi cuộn xuống (`Auto-hide on Scroll Down`).
2. **Trên Desktop / Tablet ($W \ge 600\text{px}$):**
   - **Chuyển FAB thành Header Action Button**: Đặt nút **`[ + Tạo Giao Dịch ]`** (Gradient Button) trực tiếp trên Top Header / AppBar. 
   - Loại bỏ hoàn toàn FAB nổi ở góc màn hình Desktop.

---

## Summary Matrix of Component Behavior

| Component | Mobile ($W < 600$) | Tablet ($600 \le W < 1000$) | Desktop ($W \ge 1000$) |
| :--- | :--- | :--- | :--- |
| **Window Min Size** | N/A (Native App) | N/A (Native App) | Fixed $960 \times 650\text{px}$ |
| **Navigation** | Bottom Navigation Bar | Mini Navigation Rail | Full Expanded Sidebar |
| **Filter Bar** | Search + Filter Sheet Button | Dropdown Selects (1 Row) | Horizontal Chips / Filter Bar |
| **FAB / Add Action** | Center Docked Bottom FAB | Top Header Action Button | Top Header Action Button |
| **Card Spacing** | $14\text{px}$ padding / $10\text{px}$ gap | $20\text{px}$ padding / $12\text{px}$ gap | $32\text{px}$ padding / $16\text{px}$ gap |
| **Amount Protection** | `FittedBox` scaleDown | `FittedBox` scaleDown | Direct bold text |

---

## Execution Plan & Next Steps
1. **Review & Approval:** User duyệt và thống nhất toàn bộ Guideline này.
2. **Implementation Order:**
   - **Step 1:** Cấu hình Minimum Window Size trong `windows/runner/win32_window.cpp`.
   - **Step 2:** Xây dựng `AdaptiveLayoutHelper` & `AppBreakpoints` trong `lib/core/responsive/`.
   - **Step 3:** Refactor `TransactionListScreen` áp dụng Adaptive Filters & Header Add Button.
   - **Step 4:** Chuẩn hóa Typography & Spacing cho toàn bộ các màn hình còn lại.
