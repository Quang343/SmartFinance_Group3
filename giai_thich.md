# Giải thích Cấu trúc Dự án SmartFinance

Dựa vào cách tổ chức các thư mục và file trong mã nguồn (đặc biệt là thư mục `lib`), project này đang được xây dựng theo mô hình **Clean Architecture (Kiến trúc Sạch)** kết hợp với **Feature-Driven (Hướng Tính Năng)** ở tầng giao diện (Presentation). 

Đây **KHÔNG PHẢI** là mô hình MVC (Model-View-Controller) truyền thống. 

Dưới đây là giải thích chi tiết về cấu trúc và lý do dự án áp dụng mô hình này:

## 1. Cấu trúc cụ thể của dự án

Nếu nhìn vào thư mục `lib`, ta sẽ thấy sự phân chia rõ ràng các tầng (layers):

- **`domain/` (Tầng nghiệp vụ cốt lõi)**
  - Chứa `entities/` (các đối tượng nghiệp vụ thuần túy như `UserEntity`, `InvoiceEntity`...).
  - Chứa `repositories/` (các interface/hợp đồng định nghĩa các thao tác dữ liệu, nhưng không chứa code thực hiện).
  - Tầng này độc lập hoàn toàn, không phụ thuộc vào bất kỳ thư viện bên ngoài nào (kể cả Firebase hay Flutter UI).

- **`data/` (Tầng dữ liệu)**
  - Chứa `models/` (kế thừa hoặc map từ entities, thêm các logic chuyển đổi dữ liệu như `fromJson`, `toJson` để làm việc với Firebase).
  - Chứa `repositories/` (chứa các class *implement* các interface từ tầng `domain`, trực tiếp gọi Firebase, API, hay Local Storage).

- **`features/` (Tầng giao diện - Presentation Layer)**
  - Chứa giao diện người dùng và logic điều khiển màn hình, được chia theo từng tính năng cụ thể thay vì chia theo loại file. Ví dụ: `auth/`, `categories/`, `invoices/`, `dashboard/`... 
  - Trong mỗi thư mục tính năng này sẽ chứa các màn hình (screens), widgets nhỏ, và State Management (Bloc, Provider hoặc Riverpod...).

- **`core/`**
  - Chứa các thành phần dùng chung cho toàn bộ ứng dụng như: màu sắc (theme), utils, helpers, định nghĩa lỗi (errors/exceptions).

- **`app/`**
  - Thường chứa các cài đặt tổng thể của ứng dụng, cấu hình Route (điều hướng), Dependency Injection (cấp phát phụ thuộc).

---

## 2. Vì sao dự án lại chọn cấu trúc này (Clean Architecture + Feature-Driven)?

### A. Tách biệt mối quan tâm (Separation of Concerns)
Trong MVC, đôi khi Controller bị "phình to" vì chứa cả logic giao diện, logic nghiệp vụ lẫn logic gọi database. 
Với Clean Architecture, mọi thứ được tách bạch:
- Màn hình (UI) chỉ làm nhiệm vụ hiển thị.
- Logic lấy dữ liệu, giao tiếp Firebase nằm riêng ở tầng `data`.
- UI không bao giờ gọi trực tiếp Firebase, mà gọi thông qua tầng `domain`.

### B. Tính linh hoạt và Dễ dàng thay đổi (Flexibility)
Vì dự án dùng Firebase, một ngày nào đó nếu công ty quyết định đổi sang dùng một server riêng (REST API bằng Node.js/Java), lập trình viên **chỉ cần viết lại tầng `data`**. Các màn hình UI (trong `features/`) và logic nghiệp vụ cốt lõi (trong `domain/`) sẽ không cần phải sửa đổi bất kỳ dòng code nào.

### C. Khả năng mở rộng (Scalability) với Feature-Driven
Khi dự án lớn lên (rất nhiều màn hình), việc gom nhóm theo tính năng (`features/invoices`, `features/transactions`...) giúp lập trình viên mới dễ dàng tìm code. Nếu cần sửa lỗi phần "Hóa đơn", họ chỉ cần vào thư mục `invoices` là có đủ từ UI đến State Management của hóa đơn, thay vì phải nhảy qua lại giữa thư mục `views` và `controllers` to đùng như MVC.

### D. Dễ dàng viết Unit Test
Vì các tầng không bị dính chặt vào nhau, chúng ta có thể dễ dàng test riêng lẻ từng phần. Ví dụ: Có thể tạo ra dữ liệu giả (Mock) cho tầng `repositories` để test giao diện UI mà không cần phải gọi thật lên mạng (Firebase).

## Tóm lại
Dự án được cấu trúc cực kỳ chuyên nghiệp và chuẩn mực theo xu hướng hiện đại của lập trình Mobile (Flutter/Android/iOS). Nó giải quyết được bài toán phình to của ứng dụng (scale-up), giúp team làm việc chung ít bị conflict (đụng code) và dễ dàng bảo trì trong tương lai.
