import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';
import 'isar_database.dart';
import '../data/local/isar_models/isar_category.dart';
import '../data/local/isar_models/isar_transaction.dart';
import '../data/local/isar_models/isar_invoice.dart';

class IsarSeedService {
  static Future<void> seedIfNeeded() async {
    final isar = IsarDatabase.instance;
    final categoryCount = await isar.isarCategorys.count();
    
    if (categoryCount == 0) {
      await _seedData(isar);
    }
  }

  static Future<void> _seedData(Isar isar) async {
    final uuid = const Uuid();
    
    // Categories
    final categories = [
      IsarCategory()..uid = uuid.v4()..name = 'Doanh thu bán hàng'..type = 'income'..isDefault = true..isActive = true..createdAt = DateTime.now()..updatedAt = DateTime.now(),
      IsarCategory()..uid = uuid.v4()..name = 'Doanh thu dịch vụ'..type = 'income'..isDefault = true..isActive = true..createdAt = DateTime.now()..updatedAt = DateTime.now(),
      IsarCategory()..uid = uuid.v4()..name = 'Khoản thu khác'..type = 'income'..isDefault = true..isActive = true..createdAt = DateTime.now()..updatedAt = DateTime.now(),
      
      IsarCategory()..uid = uuid.v4()..name = 'Lương'..type = 'expense'..isDefault = true..isActive = true..createdAt = DateTime.now()..updatedAt = DateTime.now(),
      IsarCategory()..uid = uuid.v4()..name = 'Mặt bằng'..type = 'expense'..isDefault = true..isActive = true..createdAt = DateTime.now()..updatedAt = DateTime.now(),
      IsarCategory()..uid = uuid.v4()..name = 'Marketing'..type = 'expense'..isDefault = true..isActive = true..createdAt = DateTime.now()..updatedAt = DateTime.now(),
      IsarCategory()..uid = uuid.v4()..name = 'Mua hàng'..type = 'expense'..isDefault = true..isActive = true..createdAt = DateTime.now()..updatedAt = DateTime.now(),
      IsarCategory()..uid = uuid.v4()..name = 'Vận hành'..type = 'expense'..isDefault = true..isActive = true..createdAt = DateTime.now()..updatedAt = DateTime.now(),
      IsarCategory()..uid = uuid.v4()..name = 'Điện nước'..type = 'expense'..isDefault = true..isActive = true..createdAt = DateTime.now()..updatedAt = DateTime.now(),
      IsarCategory()..uid = uuid.v4()..name = 'Phần mềm'..type = 'expense'..isDefault = true..isActive = true..createdAt = DateTime.now()..updatedAt = DateTime.now(),
      IsarCategory()..uid = uuid.v4()..name = 'Chi phí khác'..type = 'expense'..isDefault = true..isActive = true..createdAt = DateTime.now()..updatedAt = DateTime.now(),
    ];

    final salesCatId = categories[0].uid;
    final rentCatId = categories[4].uid;

    final transactions = [
      IsarTransaction()
        ..uid = uuid.v4()
        ..amount = 5000000
        ..type = 'income'
        ..categoryId = salesCatId
        ..transactionDate = DateTime.now()
        ..note = 'Bán hàng tuần 1'
        ..status = 'confirmed'
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now(),
      IsarTransaction()
        ..uid = uuid.v4()
        ..amount = 2000000
        ..type = 'expense'
        ..categoryId = rentCatId
        ..transactionDate = DateTime.now()
        ..note = 'Tiền thuê văn phòng'
        ..status = 'confirmed'
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now(),
      IsarTransaction()
        ..uid = uuid.v4()
        ..amount = 1000000
        ..type = 'income'
        ..categoryId = salesCatId
        ..transactionDate = DateTime.now()
        ..note = 'Draft transaction'
        ..status = 'draft'
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now(),
      IsarTransaction()
        ..uid = uuid.v4()
        ..amount = 500000
        ..type = 'expense'
        ..categoryId = rentCatId
        ..transactionDate = DateTime.now()
        ..note = 'Deleted transaction'
        ..status = 'deleted'
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now(),
    ];

    final invoices = [
      IsarInvoice()
        ..uid = uuid.v4()
        ..invoiceNumber = 'INV-2026-001'
        ..partnerName = 'Công ty TNHH Minh An'
        ..partnerTaxCode = '0101234567'
        ..subtotal = 2500000
        ..vatRate = 10
        ..vatAmount = 250000
        ..totalAmount = 2750000
        ..ocrStatus = 'extracted'
        ..ocrConfidence = 0.95
        ..type = 'incoming'
        ..issuedDate = DateTime.now()
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now(),
      IsarInvoice()
        ..uid = uuid.v4()
        ..invoiceNumber = 'INV-2026-002'
        ..partnerName = 'Cửa hàng VPP ABC'
        ..partnerTaxCode = '0209876543'
        ..subtotal = 500000
        ..vatRate = 8
        ..vatAmount = 40000
        ..totalAmount = 540000
        ..ocrStatus = 'extracted'
        ..ocrConfidence = 0.88
        ..type = 'outgoing'
        ..issuedDate = DateTime.now()
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now(),
    ];

    await isar.writeTxn(() async {
      await isar.isarCategorys.putAll(categories);
      await isar.isarTransactions.putAll(transactions);
      await isar.isarInvoices.putAll(invoices);
    });
  }
}
