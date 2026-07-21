import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

final storageRepositoryProvider = Provider<StorageRepository>((ref) {
  return StorageRepository();
});

// HoangDH
class StorageRepository {
  // Lấy API Key từ file .env
  String get _imgbbApiKey => dotenv.env['IMGBB_API_KEY'] ?? '';
  static const String _uploadUrl = 'https://api.imgbb.com/1/upload';

  /// Uploads an avatar image to ImgBB and returns the direct image URL
  Future<String?> uploadAvatar(String uid, {File? file, Uint8List? webFile, String? fileName}) async {
    return _uploadToImgBB(file: file, webFile: webFile, fileName: fileName, name: 'avatar_$uid');
  }

  /// Uploads an invoice image to ImgBB and returns the direct image URL
  Future<String?> uploadInvoiceImage(String invoiceId, {File? file, Uint8List? webFile, String? fileName}) async {
    return _uploadToImgBB(file: file, webFile: webFile, fileName: fileName, name: 'invoice_$invoiceId');
  }

  /// Uploads a transaction image to ImgBB and returns the direct image URL
  Future<String?> uploadTransactionImage(String transactionId, {File? file, Uint8List? webFile, String? fileName}) async {
    return _uploadToImgBB(file: file, webFile: webFile, fileName: fileName, name: 'transaction_$transactionId');
  }

  Future<String?> _uploadToImgBB({File? file, Uint8List? webFile, String? fileName, String? name}) async {
    try {
      if (_imgbbApiKey.isEmpty || _imgbbApiKey.contains('YOUR_IMGBB_API_KEY')) {
        throw Exception('Vui lòng thay thế API key của bạn trong file .env');
      }

      var request = http.MultipartRequest('POST', Uri.parse('$_uploadUrl?key=$_imgbbApiKey'));

      // Thêm tên file để phân biệt Avatar và Invoice trên ImgBB
      if (name != null) {
        request.fields['name'] = name;
      }

      if (kIsWeb && webFile != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'image',
          webFile,
          filename: fileName ?? 'upload.jpg',
        ));
      } else if (file != null) {
        final safeFileName = fileName ?? (name != null ? '$name.jpg' : 'upload.jpg');
        request.files.add(await http.MultipartFile.fromPath(
          'image',
          file.path,
          filename: safeFileName,
        ));
      } else {
        return null;
      }

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      
      if (response.statusCode == 200) {
        final jsonResult = json.decode(responseData);
        return jsonResult['data']['url'];
      } else {
        debugPrint('Upload error (ImgBB HTTP ${response.statusCode}): $responseData');
        return null;
      }
    } catch (e) {
      debugPrint('Upload error (ImgBB Exception): $e');
      return null;
    }
  }
}

