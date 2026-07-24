import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/invoice_entity.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../models/transaction_model.dart';
import '../models/user_model.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final UserModel? _currentUser;

  TransactionRepositoryImpl(this._firestore, this._auth, this._currentUser);

  String get _uid => _currentUser?.id ?? _auth.currentUser?.uid ?? '';
  String get _company => _currentUser?.company ?? '';
  String get _role => _currentUser?.role ?? '';
  CollectionReference get _collection => _firestore.collection('transactions');

  Future<QuerySnapshot> _getWithCacheFallback(Query query) async {
    try {
      return await query.get().timeout(
        const Duration(seconds: 3),
        onTimeout: () => query.get(const GetOptions(source: Source.cache)),
      );
    } catch (e) {
      return await query.get(const GetOptions(source: Source.cache));
    }
  }

  @override
  Future<List<TransactionEntity>> getAll() async {
    if (_uid.isEmpty) return [];
    Query query = _collection.where('company', isEqualTo: _company);
    final snapshot = await _getWithCacheFallback(query);
    return snapshot.docs.map((doc) => TransactionModel.fromJson(doc.data() as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<TransactionEntity>> getConfirmed() async {
    if (_uid.isEmpty) return [];
    Query query = _collection
        .where('company', isEqualTo: _company)
        .where('status', isEqualTo: TransactionStatus.confirmed.name);
    final snapshot = await _getWithCacheFallback(query);
    return snapshot.docs.map((doc) => TransactionModel.fromJson(doc.data() as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<TransactionEntity>> getByDateRange(DateTime start, DateTime end) async {
    if (_uid.isEmpty) return [];
    Query query = _collection
        .where('company', isEqualTo: _company)
        .where('transactionDate', isGreaterThanOrEqualTo: start.toIso8601String())
        .where('transactionDate', isLessThanOrEqualTo: end.toIso8601String());
    final snapshot = await _getWithCacheFallback(query);
    return snapshot.docs.map((doc) => TransactionModel.fromJson(doc.data() as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<TransactionEntity>> getByType(TransactionType type) async {
    if (_uid.isEmpty) return [];
    Query query = _collection
        .where('company', isEqualTo: _company)
        .where('type', isEqualTo: type.name);
    final snapshot = await _getWithCacheFallback(query);
    return snapshot.docs.map((doc) => TransactionModel.fromJson(doc.data() as Map<String, dynamic>)).toList();
  }

  @override
  Future<TransactionEntity?> getById(String id) async {
    if (_uid.isEmpty) return null;
    try {
      final doc = await _collection.doc(id).get().timeout(
        const Duration(seconds: 3),
        onTimeout: () => _collection.doc(id).get(const GetOptions(source: Source.cache)),
      );
      if (doc.exists) {
        return TransactionModel.fromJson(doc.data() as Map<String, dynamic>);
      }
    } catch (e) {
      try {
        final doc = await _collection.doc(id).get(const GetOptions(source: Source.cache));
        if (doc.exists) {
          return TransactionModel.fromJson(doc.data() as Map<String, dynamic>);
        }
      } catch (_) {}
    }
    return null;
  }

  void _validateTransactionPayload(TransactionEntity tx) {
    if (tx.amount <= 0) {
      throw Exception("Số tiền giao dịch phải lớn hơn 0.");
    }
    if (_role == 'expenseAccountant' && tx.type == TransactionType.income) {
      throw Exception("Kế toán chi phí không được tạo giao dịch Doanh thu.");
    }
    if (_role == 'revenueAccountant' && tx.type == TransactionType.expense) {
      throw Exception("Kế toán doanh thu không được tạo giao dịch Chi phí.");
    }
  }

  Future<void> _checkImmutableStatus(String id) async {
    final oldDoc = await _collection.doc(id).get();
    if (oldDoc.exists) {
      final oldStatus = (oldDoc.data() as Map<String, dynamic>)['status'] as String?;
      if (oldStatus == TransactionStatus.deleted.name) {
        throw Exception("Giao dịch đã bị xóa. Vui lòng khôi phục trước khi thao tác!");
      }
      if (oldStatus == TransactionStatus.confirmed.name && _role != 'financeManager') {
        throw Exception("Giao dịch đã xác nhận. Chỉ Quản lý mới có quyền thao tác!");
      }
    } else {
      throw Exception("Không tìm thấy giao dịch.");
    }
  }
  Future<void> _checkTitleUniqueness(String title, String transactionId, TransactionStatus status) async {
    if (status != TransactionStatus.confirmed) return;
    
    final query = await _collection
        .where('company', isEqualTo: _company)
        .where('title', isEqualTo: title)
        .where('status', isEqualTo: TransactionStatus.confirmed.name)
        .get();
        
    for (var doc in query.docs) {
      if (doc.id != transactionId) {
        throw Exception("Tiêu đề '$title' đã tồn tại ở một giao dịch đã xác nhận khác. Vui lòng chọn tên khác!");
      }
    }
  }

  Future<void> _checkInvoiceConfirmedUniqueness(String? invoiceId, String transactionId, TransactionStatus status) async {
    if (invoiceId == null || invoiceId.isEmpty) return;
    if (status != TransactionStatus.confirmed) return;

    final query = await _collection
        .where('invoiceId', isEqualTo: invoiceId)
        .where('status', isEqualTo: TransactionStatus.confirmed.name)
        .get();

    for (var doc in query.docs) {
      if (doc.id != transactionId) {
        final existingTitle = (doc.data() as Map<String, dynamic>)['title'] as String? ?? '';
        throw Exception("Hóa đơn này đã được xác nhận bởi giao dịch '$existingTitle'. Mỗi hóa đơn chỉ được phép có 1 giao dịch đã xác nhận!");
      }
    }
  }

  @override
  Future<void> create(TransactionEntity transaction) async {
    if (_uid.isEmpty) return;
    _validateTransactionPayload(transaction);
    await _checkTitleUniqueness(transaction.title, transaction.id, transaction.status);
    await _checkInvoiceConfirmedUniqueness(transaction.invoiceId, transaction.id, transaction.status);
    final model = TransactionModel(
      id: transaction.id,
      amount: transaction.amount,
      type: transaction.type,
      categoryId: transaction.categoryId,
      transactionDate: transaction.transactionDate,
      status: transaction.status,
      title: transaction.title,
      note: transaction.note,
      invoiceId: transaction.invoiceId,
      createdByUid: _uid,
      company: _company,
      createdAt: transaction.createdAt,
      updatedAt: transaction.updatedAt,
      tags: transaction.tags,
    );
    await _collection.doc(transaction.id).set(model.toJson());
    await _updateInvoiceTransactionStatus(transaction.invoiceId);
  }

  @override
  Future<void> update(TransactionEntity transaction) async {
    if (_uid.isEmpty) return;
    _validateTransactionPayload(transaction);
    await _checkImmutableStatus(transaction.id);
    await _checkTitleUniqueness(transaction.title, transaction.id, transaction.status);
    await _checkInvoiceConfirmedUniqueness(transaction.invoiceId, transaction.id, transaction.status);
    final model = TransactionModel(
      id: transaction.id,
      amount: transaction.amount,
      type: transaction.type,
      categoryId: transaction.categoryId,
      transactionDate: transaction.transactionDate,
      status: transaction.status,
      title: transaction.title,
      note: transaction.note,
      invoiceId: transaction.invoiceId,
      createdByUid: transaction.createdByUid.isNotEmpty ? transaction.createdByUid : _uid,
      company: transaction.company.isNotEmpty ? transaction.company : _company,
      createdAt: transaction.createdAt,
      updatedAt: transaction.updatedAt,
    );
    await _collection.doc(transaction.id).update(model.toJson());
    await _updateInvoiceTransactionStatus(transaction.invoiceId);
  }

  @override
  Future<void> softDelete(String id) async {
    if (_uid.isEmpty) return;
    await _checkImmutableStatus(id);
    final doc = await _collection.doc(id).get();
    String? invoiceIdToUpdate;
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>?;
      invoiceIdToUpdate = data?['invoiceId'] as String?;
    }
    await _collection.doc(id).update({
      'status': TransactionStatus.deleted.name,
      'updatedAt': DateTime.now().toIso8601String(),
    });
    await _updateInvoiceTransactionStatus(invoiceIdToUpdate);
  }

  @override
  Future<void> hardDelete(String id) async {
    if (_uid.isEmpty) return;
    final doc = await _collection.doc(id).get();
    String? invoiceIdToUpdate;
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>?;
      invoiceIdToUpdate = data?['invoiceId'] as String?;
    }
    await _collection.doc(id).delete();
    await _updateInvoiceTransactionStatus(invoiceIdToUpdate);
  }

  @override
  Future<void> restore(String id) async {
    if (_uid.isEmpty) return;
    final oldDoc = await _collection.doc(id).get();
    String? invoiceIdToUpdate;
    if (oldDoc.exists) {
      final data = oldDoc.data() as Map<String, dynamic>?;
      final oldStatus = data?['status'] as String?;
      if (oldStatus == TransactionStatus.confirmed.name && _role != 'financeManager') {
        throw Exception("Giao dịch đã xác nhận. Chỉ Quản lý mới có quyền thao tác!");
      }
      invoiceIdToUpdate = data?['invoiceId'] as String?;
    }
    
    await _collection.doc(id).update({
      'status': TransactionStatus.draft.name,
      'updatedAt': DateTime.now().toIso8601String(),
    });
    await _updateInvoiceTransactionStatus(invoiceIdToUpdate);
  }

  @override
  Future<void> cleanupDeletedTransactions() async {
    if (_uid.isEmpty) return;
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30)).toIso8601String();
    
    Query query = _collection
        .where('status', isEqualTo: TransactionStatus.deleted.name)
        .where('updatedAt', isLessThan: thirtyDaysAgo);
    if (_role == 'financeManager') {
      query = query.where('company', isEqualTo: _company);
    } else {
      query = query.where('createdByUid', isEqualTo: _uid);
    }
    final snapshot = await query.get();
        
    final batch = _firestore.batch();
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Future<void> _updateInvoiceTransactionStatus(String? invoiceId) async {
    if (invoiceId == null || invoiceId.isEmpty) return;
    
    QuerySnapshot txsQuery;
    try {
      txsQuery = await _collection.where('invoiceId', isEqualTo: invoiceId).get().timeout(const Duration(seconds: 1));
    } catch (_) {
      txsQuery = await _collection.where('invoiceId', isEqualTo: invoiceId).get(const GetOptions(source: Source.cache));
    }
    
    final activeTxs = txsQuery.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .where((tx) => tx['status'] != TransactionStatus.deleted.name)
        .toList();
    
    InvoiceTransactionStatus newStatus = InvoiceTransactionStatus.notCreated;
    if (activeTxs.any((tx) => tx['status'] == TransactionStatus.confirmed.name)) {
      newStatus = InvoiceTransactionStatus.confirmedCreated;
    } else if (activeTxs.isNotEmpty) {
      newStatus = InvoiceTransactionStatus.draftCreated;
    }
    
    await _firestore.collection('invoices').doc(invoiceId).update({
      'transactionStatus': newStatus.name,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }
}
