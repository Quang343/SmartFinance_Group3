import '../entities/invoice_entity.dart';

abstract class InvoiceRepository {
  Future<List<InvoiceEntity>> getAll();
  Future<List<InvoiceEntity>> getByOcrStatus(OcrStatus status);
  Future<InvoiceEntity?> getById(String id);
  Future<void> create(InvoiceEntity invoice);
  Future<void> update(InvoiceEntity invoice);
  Future<void> delete(String id);
  Future<void> updateTransactionStatus(String id, InvoiceTransactionStatus status);
  Future<int> getNextSequentialId(InvoiceType type);
  Future<bool> checkInvoiceExists(String sellerTaxCode, String formNumber, String serialNumber, String invoiceNumber);
}
