import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'sync_queue_service.dart';
import 'sync_item.dart';
import '../providers/app_providers.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/invoice_model.dart';

final syncWorkerProvider = Provider<SyncWorker>((ref) {
  final queueService = ref.watch(syncQueueServiceProvider);
  return SyncWorker(queueService, ref)..start();
});

class SyncWorker {
  final SyncQueueService _queueService;
  final Ref _ref;
  Timer? _timer;
  bool _isSyncing = false;

  SyncWorker(this._queueService, this._ref);

  void start() {
    _timer?.cancel();
    // Chạy ngầm định kỳ mỗi 10 giây để kiểm tra và sync
    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      _processQueue();
    });
    // Gọi thử luôn lúc khởi tạo
    _processQueue();
  }

  void stop() {
    _timer?.cancel();
  }

  Future<void> _processQueue() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final pendingItems = _queueService.queue.where((e) => e.status == SyncStatus.pending).toList();
      for (final item in pendingItems) {
        if (item.collection == 'transactions') {
          await _syncTransaction(item);
        } else if (item.collection == 'invoices') {
          await _syncInvoice(item);
        }
      }
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _syncInvoice(SyncItem item) async {
    try {
      final repo = _ref.read(invoiceRepositoryProvider);
      if (item.action == SyncAction.delete) {
        await repo.delete(item.entityId);
        await _queueService.removeItem(item.id);
        return;
      }

      final model = InvoiceModel.fromJson(item.payload);

      if (item.action == SyncAction.create) {
        await repo.create(model);
      } else if (item.action == SyncAction.update) {
        await repo.update(model);
      }
      
      // Nếu thành công -> Xóa khỏi hàng đợi
      await _queueService.removeItem(item.id);

    } catch (e) {
      String errorMsg = e.toString().replaceAll('Exception: ', '');
      if (e is FirebaseException && e.code == 'unavailable') {
        // Mất mạng, cứ để pending
        return;
      }
      
      // Lỗi thực sự -> Đánh dấu Error để UI hiện cảnh báo đỏ
      await _queueService.markAsError(item.id, errorMsg);
    }
  }

  Future<void> _syncTransaction(SyncItem item) async {
    try {
      final repo = _ref.read(transactionRepositoryProvider);
      if (item.action == SyncAction.delete) {
        await repo.hardDelete(item.entityId);
        await _queueService.removeItem(item.id);
        return;
      }

      final model = TransactionModel.fromJson(item.payload);
      final entity = TransactionEntity(
        id: model.id,
        amount: model.amount,
        type: model.type,
        categoryId: model.categoryId,
        transactionDate: model.transactionDate,
        title: model.title,
        status: model.status,
        createdAt: model.createdAt,
        updatedAt: model.updatedAt,
        note: model.note,
        invoiceId: model.invoiceId,
        createdByUid: model.createdByUid,
        company: model.company,
        tags: model.tags,
      );

      if (item.action == SyncAction.create) {
        await repo.create(entity);
      } else if (item.action == SyncAction.update) {
        await repo.update(entity);
      }
      
      // Nếu thành công -> Xóa khỏi hàng đợi
      await _queueService.removeItem(item.id);

    } catch (e) {
      // Bị lỗi từ Server (ví dụ: trùng tên, trùng mã)
      String errorMsg = e.toString().replaceAll('Exception: ', '');
      if (e is FirebaseException && e.code == 'unavailable') {
        // Mất mạng, cứ để pending
        return;
      }
      
      // Lỗi thực sự -> Đánh dấu Error để UI hiện cảnh báo đỏ
      await _queueService.markAsError(item.id, errorMsg);
    }
  }
}
