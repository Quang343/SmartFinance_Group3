import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  @override
  Future<List<TransactionEntity>> getAll() async {
    if (_uid.isEmpty) return [];
    Query query = _collection;
    if (_role == 'financeManager') {
      query = query.where('company', isEqualTo: _company);
    } else {
      query = query.where('createdByUid', isEqualTo: _uid);
    }
    final snapshot = await query.get();
    return snapshot.docs.map((doc) => TransactionModel.fromJson(doc.data() as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<TransactionEntity>> getConfirmed() async {
    if (_uid.isEmpty) return [];
    Query query = _collection.where('status', isEqualTo: TransactionStatus.confirmed.name);
    if (_role == 'financeManager') {
      query = query.where('company', isEqualTo: _company);
    } else {
      query = query.where('createdByUid', isEqualTo: _uid);
    }
    final snapshot = await query.get();
    return snapshot.docs.map((doc) => TransactionModel.fromJson(doc.data() as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<TransactionEntity>> getByDateRange(DateTime start, DateTime end) async {
    if (_uid.isEmpty) return [];
    Query query = _collection
        .where('transactionDate', isGreaterThanOrEqualTo: start.toIso8601String())
        .where('transactionDate', isLessThanOrEqualTo: end.toIso8601String());
    if (_role == 'financeManager') {
      query = query.where('company', isEqualTo: _company);
    } else {
      query = query.where('createdByUid', isEqualTo: _uid);
    }
    final snapshot = await query.get();
    return snapshot.docs.map((doc) => TransactionModel.fromJson(doc.data() as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<TransactionEntity>> getByType(TransactionType type) async {
    if (_uid.isEmpty) return [];
    Query query = _collection.where('type', isEqualTo: type.name);
    if (_role == 'financeManager') {
      query = query.where('company', isEqualTo: _company);
    } else {
      query = query.where('createdByUid', isEqualTo: _uid);
    }
    final snapshot = await query.get();
    return snapshot.docs.map((doc) => TransactionModel.fromJson(doc.data() as Map<String, dynamic>)).toList();
  }

  @override
  Future<TransactionEntity?> getById(String id) async {
    if (_uid.isEmpty) return null;
    final doc = await _collection.doc(id).get();
    if (doc.exists) {
      return TransactionModel.fromJson(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  @override
  Future<void> create(TransactionEntity transaction) async {
    if (_uid.isEmpty) return;
    final model = TransactionModel(
      id: transaction.id,
      amount: transaction.amount,
      type: transaction.type,
      categoryId: transaction.categoryId,
      transactionDate: transaction.transactionDate,
      status: transaction.status,
      note: transaction.note,
      invoiceId: transaction.invoiceId,
      createdByUid: _uid,
      company: _company,
      createdAt: transaction.createdAt,
      updatedAt: transaction.updatedAt,
    );
    await _collection.doc(transaction.id).set(model.toJson());
  }

  @override
  Future<void> update(TransactionEntity transaction) async {
    if (_uid.isEmpty) return;
    final model = TransactionModel(
      id: transaction.id,
      amount: transaction.amount,
      type: transaction.type,
      categoryId: transaction.categoryId,
      transactionDate: transaction.transactionDate,
      status: transaction.status,
      note: transaction.note,
      invoiceId: transaction.invoiceId,
      createdByUid: transaction.createdByUid.isNotEmpty ? transaction.createdByUid : _uid,
      company: transaction.company.isNotEmpty ? transaction.company : _company,
      createdAt: transaction.createdAt,
      updatedAt: transaction.updatedAt,
    );
    await _collection.doc(transaction.id).update(model.toJson());
  }

  @override
  Future<void> softDelete(String id) async {
    if (_uid.isEmpty) return;
    await _collection.doc(id).update({
      'status': TransactionStatus.deleted.name,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> hardDelete(String id) async {
    if (_uid.isEmpty) return;
    await _collection.doc(id).delete();
  }

  @override
  Future<void> restore(String id) async {
    if (_uid.isEmpty) return;
    await _collection.doc(id).update({
      'status': TransactionStatus.draft.name,
      'updatedAt': DateTime.now().toIso8601String(),
    });
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
}
