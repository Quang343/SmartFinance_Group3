# BỘ NHÃN (LABEL SCHEMA) CHÍNH THỨC CHO MOBILE APP
*Phiên bản: 2.0 (Dành cho bản Release AI V3 Đa Ngôn Ngữ)*

## 🌐 THÔNG TIN KẾT NỐI API
- **Endpoint URL:** `https://escapable-latitude-augmented.ngrok-free.dev/extract_invoice`
- **Method:** `POST`
- **Body Format:** `multipart/form-data` (Chứa 1 file ảnh với key là `file`)

Tài liệu này định nghĩa cấu trúc JSON (Key-Value) mà Hệ thống AI (LayoutLMv3) sẽ trả về cho Mobile App.
**LƯU Ý QUAN TRỌNG CHO TEAM MOBILE:** App chỉ thiết kế giao diện (UI) và xử lý logic cho đúng **28 trường dữ liệu (Labels)** được liệt kê dưới đây. AI sẽ KHÔNG bao giờ trả về các trường ngoài danh sách này.

---

## 1. Thông tin Chung & Tiêu đề (General & Header)
| JSON Key (Nhãn AI) | Ý nghĩa | Ví dụ thực tế AI trả về |
| :--- | :--- | :--- |
| `DOC_TITLE` | Tiêu đề tài liệu | "HÓA ĐƠN GIÁ TRỊ GIA TĂNG", "INVOICE" |
| `INVOICE_NO` | Số hóa đơn | "0000003", "40378170" |
| `INVOICE_DATE` | Ngày lập hóa đơn | "16/10/2017", "10/15/2012" |
| `FORM_NO` | Mẫu số hóa đơn | "01GTKT0/001" |
| `SYMBOL` | Ký hiệu hóa đơn | "HM/17E" |

## 2. Thông tin Bên Bán (Seller / Issuer Information)
| JSON Key (Nhãn AI) | Ý nghĩa | Ví dụ thực tế AI trả về |
| :--- | :--- | :--- |
| `SELLER_NAME` | Tên công ty/đơn vị bán hàng | "Công ty cổ phần ABC", "Patel, Thompson" |
| `SELLER_TAX_ID` | Mã số thuế bên bán | "0101243150", "958-74-3511" |
| `SELLER_ADDRESS` | Địa chỉ bên bán | "Tầng 9 Technosoft, Duy Tân...", "356 Kyle Vista" |
| `SELLER_PHONE` | Số điện thoại bên bán | "04 3795 9595" |
| `SELLER_BANK_ACCOUNT` | Số tài khoản ngân hàng bên bán | "010236542365" |
| `SELLER_BANK_NAME` | Tên ngân hàng/chi nhánh bên bán | "Vietcombank - CN Hoàn Kiếm" |

## 3. Thông tin Bên Mua (Client / Buyer Information)
| JSON Key (Nhãn AI) | Ý nghĩa | Ví dụ thực tế AI trả về |
| :--- | :--- | :--- |
| `BUYER_PERSON` | Họ tên cá nhân người mua hàng | "Nguyễn Văn Tiến" |
| `CLIENT_NAME` | Tên đơn vị/công ty mua hàng | "Công ty TNHH Bảo Ngọc" |
| `CLIENT_TAX_ID` | Mã số thuế bên mua | "0101243150" |
| `CLIENT_ADDRESS` | Địa chỉ bên mua | "123 Trần Bình, Cầu Giấy..." |
| `PAYMENT_METHOD` | Hình thức thanh toán | "TM/CK", "Credit Card" |

## 4. Chi tiết Hàng hóa & Dịch vụ (Line Items)
*Lưu ý: App Mobile cần thiết kế một danh sách (List/RecyclerView) để hứng các item này, vì 1 hóa đơn có thể có nhiều mặt hàng.*

| JSON Key (Nhãn AI) | Ý nghĩa | Ví dụ thực tế AI trả về |
| :--- | :--- | :--- |
| `ITEM_CODE` | Mã hàng hóa | "TL_HITACHI_110" |
| `ITEM_DESC` | Tên/diễn giải hàng hóa, dịch vụ | "Tủ lạnh Hitachi 110 lít", "Corkscrew Opener" |
| `ITEM_UNIT` | Đơn vị tính | "Chiếc", "Cái", "Kg", "each" |
| `ITEM_QTY` | Số lượng | "1", "10", "50.5" |
| `ITEM_UNIT_PRICE` | Đơn giá | "8.000.000", "7.50" |
| `ITEM_NET_AMOUNT` | Thành tiền (chưa thuế) của mặt hàng | "8.000.000", "7.50" |

## 5. Tổng tiền & Thuế (Summary & Totals)
| JSON Key (Nhãn AI) | Ý nghĩa | Ví dụ thực tế AI trả về |
| :--- | :--- | :--- |
| `TOTAL_NET_AMOUNT` | Cộng tiền hàng (Tổng chưa thuế) | "8.000.000", "7.50" |
| `VAT_RATE` | Thuế suất GTGT | "8%", "10%", "KCT" |
| `VAT_AMOUNT` | Tiền thuế GTGT | "800.000", "0.75" |
| `TOTAL_AMOUNT` | Tổng tiền thanh toán toàn hóa đơn | "8.800.000", "8.25" |

## 6. Chữ ký & Thông tin Khác (Signatures & Misc)
| JSON Key (Nhãn AI) | Ý nghĩa | Ví dụ thực tế AI trả về |
| :--- | :--- | :--- |
| `SIGNATURE_NAME` | Tên người ký | "Lê Thanh Nam" |
| `CONVERSION_DATE` | Ngày chuyển đổi hóa đơn ra giấy | "17/10/2017" |
| `OTHER` | *(Bỏ qua - App Mobile không cần quan tâm)* | Các từ khóa in sẵn ("Số lượng", "Đơn giá", "Total"...) |

---

### Giao thức xử lý lỗi (Dành cho Mobile App)
1. **Lỗi khuyết số lượng (QTY):** 
   Nếu AI trả về `ITEM_UNIT_PRICE` và `ITEM_NET_AMOUNT` nhưng thiếu `ITEM_QTY`, App Mobile tự động điền: `ITEM_QTY = ITEM_NET_AMOUNT / ITEM_UNIT_PRICE`.
2. **Lỗi tiền tệ (Currency):** 
   AI xuất thuần túy dạng Số (String). App Mobile tự động format phân cách hàng nghìn (VD: `8000000` -> `8,000,000 đ`). Dấu thập phân của tiếng Anh (VD: `7.50`) cần được giữ nguyên.
