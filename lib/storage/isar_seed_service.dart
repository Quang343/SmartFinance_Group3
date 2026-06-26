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

    // Dynamic seeding for additional invoices if the database contains only the original 2 (or fewer)
    final invoiceCount = await isar.isarInvoices.count();
    if (invoiceCount <= 2) {
      await _seedAdditionalInvoices(isar);
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

  static Future<void> _seedAdditionalInvoices(Isar isar) async {
    final uuid = const Uuid();

    // Check existing invoice numbers to avoid duplicates
    final existingInvoices = await isar.isarInvoices.where().findAll();
    final existingNumbers = existingInvoices.map((inv) => inv.invoiceNumber).toSet();

    final newInvoices = <IsarInvoice>[];

    void addInvoiceIfNeeded(IsarInvoice invoice) {
      if (!existingNumbers.contains(invoice.invoiceNumber)) {
        newInvoices.add(invoice);
      }
    }

    // Add high quality outgoing mock invoices
    addInvoiceIfNeeded(
      IsarInvoice()
        ..uid = uuid.v4()
        ..invoiceNumber = 'HD-OUT-001'
        ..partnerName = 'Tập đoàn Công nghệ G-Tech'
        ..partnerTaxCode = '0312456789'
        ..subtotal = 12000000
        ..vatRate = 10
        ..vatAmount = 1200000
        ..totalAmount = 13200000
        ..ocrStatus = 'extracted'
        ..ocrConfidence = 0.98
        ..type = 'outgoing'
        ..issuedDate = DateTime.now().subtract(const Duration(days: 2))
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now(),
    );

    addInvoiceIfNeeded(
      IsarInvoice()
        ..uid = uuid.v4()
        ..invoiceNumber = 'HD-OUT-002'
        ..partnerName = 'Công ty Cổ phần Sao Mai'
        ..partnerTaxCode = '0415678901'
        ..subtotal = 8500000
        ..vatRate = 8
        ..vatAmount = 680000
        ..totalAmount = 9180000
        ..ocrStatus = 'extracted'
        ..ocrConfidence = 0.94
        ..type = 'outgoing'
        ..issuedDate = DateTime.now().subtract(const Duration(days: 1))
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now(),
    );

    addInvoiceIfNeeded(
      IsarInvoice()
        ..uid = uuid.v4()
        ..invoiceNumber = 'HD-OUT-003'
        ..partnerName = 'Đại lý Phân phối Hoàng Gia'
        ..partnerTaxCode = '0517891234'
        ..subtotal = 4000000
        ..vatRate = 0
        ..vatAmount = 0
        ..totalAmount = 4000000
        ..ocrStatus = 'extracted'
        ..ocrConfidence = 0.92
        ..type = 'outgoing'
        ..issuedDate = DateTime.now()
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now(),
    );

    addInvoiceIfNeeded(
      IsarInvoice()
        ..uid = uuid.v4()
        ..invoiceNumber = 'HD-INC-002'
        ..partnerName = 'Tổng kho Thiết bị Vinamart'
        ..partnerTaxCode = '0812398471'
        ..subtotal = 7500000
        ..vatRate = 10
        ..vatAmount = 750000
        ..totalAmount = 8250000
        ..ocrStatus = 'extracted'
        ..ocrConfidence = 0.96
        ..type = 'incoming'
        ..issuedDate = DateTime.now().subtract(const Duration(days: 3))
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now(),
    );

    if (newInvoices.isNotEmpty) {
      await isar.writeTxn(() async {
        await isar.isarInvoices.putAll(newInvoices);
      });
    }
  }
}
