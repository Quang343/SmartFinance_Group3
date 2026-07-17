import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_finance/features/invoices/data/models/ocr_result_dto.dart';

final ocrApiServiceProvider = Provider<OcrApiService>((ref) {
  return OcrApiService();
});

class OcrApiService {
  Future<OcrResultDto> scanInvoice(File image) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

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
}
