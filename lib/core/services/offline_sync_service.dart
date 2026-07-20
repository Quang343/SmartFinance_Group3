import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_finance/core/providers/app_providers.dart';
import 'package:smart_finance/domain/entities/invoice_entity.dart';
import 'package:smart_finance/data/repositories/storage_repository.dart';

class OfflineSyncService {
  final FirebaseFirestore _firestore;
  final StorageRepository _storageRepo;

  OfflineSyncService({
    required FirebaseFirestore firestore,
    required StorageRepository storageRepo,
  })  : _firestore = firestore,
        _storageRepo = storageRepo;

  /// Quét qua toàn bộ Hóa đơn (Invoices) để tìm những hóa đơn có chứa 
  /// đường dẫn ảnh nội bộ (chưa tải lên Firebase Storage do mất mạng)
  /// và tiến hành tải lên tự động.
  Future<void> syncOfflineImages(String company) async {
    try {
      debugPrint('OfflineSyncService: Bắt đầu đồng bộ ảnh hóa đơn ngoại tuyến...');
      
      // Lấy danh sách hóa đơn đầu vào (Incoming) của công ty
      final snapshot = await _firestore
          .collection('invoices')
          .where('company', isEqualTo: company)
          .where('type', isEqualTo: InvoiceType.incoming.name)
          .get(const GetOptions(source: Source.serverAndCache));

      int syncedCount = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final imageUrl = data['imageUrl'] as String?;

        // Nếu có đường dẫn ảnh mà không phải HTTP -> Đây là đường dẫn local (Draft)
        if (imageUrl != null && imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
          final file = File(imageUrl);
          
          if (await file.exists()) {
            debugPrint('OfflineSyncService: Đang tải lên ảnh bị kẹt của hóa đơn ${doc.id}');
            final uploadedUrl = await _storageRepo.uploadInvoiceImage(doc.id, file: file);
            
            if (uploadedUrl != null) {
              await doc.reference.update({
                'imageUrl': uploadedUrl,
                'updatedAt': FieldValue.serverTimestamp(),
              });
              syncedCount++;
              debugPrint('OfflineSyncService: Tải ảnh thành công cho hóa đơn ${doc.id}');
            }
          } else {
             debugPrint('OfflineSyncService: Không tìm thấy file local tại $imageUrl cho hóa đơn ${doc.id}');
          }
        }
      }

      debugPrint('OfflineSyncService: Đã đồng bộ xong $syncedCount ảnh bị kẹt.');
    } catch (e) {
      debugPrint('OfflineSyncService Lỗi: $e');
    }
  }
}

// Provider để inject service này dễ dàng
final offlineSyncServiceProvider = Provider<OfflineSyncService>((ref) {
  return OfflineSyncService(
    firestore: FirebaseFirestore.instance,
    storageRepo: ref.watch(storageRepositoryProvider),
  );
});
