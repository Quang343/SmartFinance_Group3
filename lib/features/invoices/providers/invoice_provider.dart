import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../domain/entities/invoice_entity.dart';
import '../../../domain/entities/transaction_entity.dart';

final allInvoicesProvider = StreamProvider.autoDispose<List<InvoiceEntity>>((ref) {
  return ref.watch(invoiceRepositoryProvider).watchAll();
});

final invoiceByIdProvider =
    FutureProvider.autoDispose.family<InvoiceEntity?, String>((ref, id) async {
  return ref.watch(invoiceRepositoryProvider).getById(id);
});

final invoicesByOcrStatusProvider =
    FutureProvider.autoDispose.family<List<InvoiceEntity>, OcrStatus>((ref, status) async {
  return ref.watch(invoiceRepositoryProvider).getByOcrStatus(status);
});
