import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../../storage/isar_database.dart';
import '../../data/datasources/local_category_datasource.dart';
import '../../data/datasources/local_transaction_datasource.dart';
import '../../data/datasources/local_invoice_datasource.dart';
import '../../data/datasources/local_attachment_datasource.dart';
import '../../data/repositories/category_repository_impl.dart';
import '../../data/repositories/transaction_repository_impl.dart';
import '../../data/repositories/invoice_repository_impl.dart';
import '../../data/repositories/attachment_repository_impl.dart';
import '../../domain/repositories/category_repository.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../domain/repositories/invoice_repository.dart';
import '../../domain/repositories/attachment_repository.dart';

final isarProvider = Provider<Isar>((ref) {
  return IsarDatabase.instance;
});

// Data Sources
final categoryLocalDataSourceProvider = Provider<LocalCategoryDataSource>((ref) {
  return LocalCategoryDataSource(ref.watch(isarProvider));
});

final transactionLocalDataSourceProvider = Provider<LocalTransactionDataSource>((ref) {
  return LocalTransactionDataSource(ref.watch(isarProvider));
});

final invoiceLocalDataSourceProvider = Provider<LocalInvoiceDataSource>((ref) {
  return LocalInvoiceDataSource(ref.watch(isarProvider));
});

final attachmentLocalDataSourceProvider = Provider<LocalAttachmentDataSource>((ref) {
  return LocalAttachmentDataSource(ref.watch(isarProvider));
});

// Repositories
final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepositoryImpl(ref.watch(categoryLocalDataSourceProvider));
});

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepositoryImpl(ref.watch(transactionLocalDataSourceProvider));
});

final invoiceRepositoryProvider = Provider<InvoiceRepository>((ref) {
  return InvoiceRepositoryImpl(ref.watch(invoiceLocalDataSourceProvider));
});

final attachmentRepositoryProvider = Provider<AttachmentRepository>((ref) {
  return AttachmentRepositoryImpl(ref.watch(attachmentLocalDataSourceProvider));
});
