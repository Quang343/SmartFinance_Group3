import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../data/local/isar_models/isar_category.dart';
import '../data/local/isar_models/isar_transaction.dart';
import '../data/local/isar_models/isar_invoice.dart';

class IsarDatabase {
  static Isar? _instance;

  static Isar get instance {
    if (_instance == null) {
      throw StateError('Isar is not initialized. Call IsarDatabase.open() first.');
    }
    return _instance!;
  }

  static Future<void> open() async {
    if (_instance != null) return;
    
    final dir = await getApplicationDocumentsDirectory();
    _instance = await Isar.open(
      [
        IsarCategorySchema,
        IsarTransactionSchema,
        IsarInvoiceSchema,
      ],
      directory: dir.path,
    );
  }

  static Future<void> close() async {
    if (_instance != null) {
      await _instance!.close();
      _instance = null;
    }
  }
}
