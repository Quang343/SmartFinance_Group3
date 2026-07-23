import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_finance/features/invoices/data/models/ocr_result_dto.dart';
import 'package:smart_finance/features/invoices/data/models/ocr_v2_result_dto.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
final ocrApiServiceProvider = Provider<OcrApiService>((ref) {
  return OcrApiService();
});

class OcrApiService {
  Future<OcrResultDto> scanInvoice(File image) async {
    // Mock response payload
    final mockJson = {
      "seller_name": { "value": "Công ty Cổ phần ABC", "confidence": 0.98 },
      "tax_code": { "value": "0101243150", "confidence": 0.99 },
      "seller_address": { "value": "Tầng 9 Technosoft, Duy Tân, Cầu Giấy, Hà Nội", "confidence": 0.95 },
      "seller_phone": { "value": "04 3795 9595", "confidence": 0.90 },
      "seller_bank_name": { "value": "Ngân hàng Vietcombank", "confidence": 0.95 },
      "seller_bank_account": { "value": "010236542365", "confidence": 0.98 },
      "subtotal": { "value": 1200000, "confidence": 0.99 },
      "vat_rate": { "value": 10, "confidence": 0.99 },
      "total_amount": { "value": 1320000, "confidence": 0.99 },
      "line_items": [
        {
          "name": "Dịch vụ vận tải tháng 7",
          "quantity": 1,
          "unit_price": 1200000,
          "amount": 1200000
        }
      ]
    };

    return OcrResultDto.fromJson(mockJson);
  }

  Future<OcrV2ResultDto> scanInvoiceV2(File image, {bool isMock = true}) async {
    if (isMock) {
      // Simulate realistic AI scanning delay (1.8s) for smooth visual scan animation
      await Future.delayed(const Duration(milliseconds: 1800));
      
      final mockJsonV2 = {
        "DOC_TITLE": "HÓA ĐƠN GIÁ TRỊ GIA TĂNG",
        "INVOICE_NO": "0000003",
        "INVOICE_DATE": "16/10/2017",
        "FORM_NO": "01GTKT0/001",
        "SYMBOL": "HM/17E",
        "SELLER_NAME": "Công ty cổ phần ABC",
        "SELLER_TAX_ID": "0101243150",
        "SELLER_ADDRESS": "Tầng 9 Technosoft, Duy Tân, Cầu Giấy, Hà Nội",
        "SELLER_PHONE": "04 3795 9595",
        "SELLER_BANK_ACCOUNT": "010236542365",
        "SELLER_BANK_NAME": "Ngân hàng Vietcombank",
        "BUYER_PERSON": "Nguyễn Văn Tiến",
        "CLIENT_NAME": "Công ty TNHH Bảo Ngọc",
        "CLIENT_TAX_ID": "0101243150",
        "CLIENT_ADDRESS": "123 Trần Bình - Mai Dịch - Cầu Giấy - Hà Nội",
        "PAYMENT_METHOD": "TM/CK",
        "LINE_ITEMS": [
          {
            "ITEM_CODE": "TL_HITACHI_110",
            "ITEM_DESC": "Tủ lạnh Hitachi 110 lít",
            "ITEM_UNIT": "Chiếc",
            "ITEM_QTY": "1",
            "ITEM_UNIT_PRICE": "8000000",
            "ITEM_NET_AMOUNT": "8000000"
          }
        ],
        "TOTAL_NET_AMOUNT": "8000000",
        "VAT_RATE": "10",
        "VAT_AMOUNT": "800000",
        "TOTAL_AMOUNT": "8800000",
        "SIGNATURE_NAME": "Lê Thanh Nam",
        "CONVERSION_DATE": "17/10/2017"
      };
      return OcrV2ResultDto.fromJson(mockJsonV2);
    } else {
      // Call actual API
      final uri = Uri.parse('https://escapable-latitude-augmented.ngrok-free.dev/extract_invoice');
      final request = http.MultipartRequest('POST', uri);
      
      // Bỏ qua trang cảnh báo của ngrok
      request.headers['ngrok-skip-browser-warning'] = 'true';
      request.headers['Accept'] = 'application/json';
      if (kIsWeb) {
        // Handle web by fetching bytes from the blob URL
        final fileResponse = await http.get(Uri.parse(image.path));
        request.files.add(http.MultipartFile.fromBytes(
          'file', 
          fileResponse.bodyBytes, 
          filename: 'invoice.png',
        ));
      } else {
        // Handle mobile/desktop with standard path
        request.files.add(await http.MultipartFile.fromPath('file', image.path));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        return OcrV2ResultDto.fromJson(jsonResponse);
      } else {
        throw Exception('Lỗi khi gọi OCR API: ${response.statusCode}');
      }
    }
  }
}
