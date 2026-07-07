import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../models/transaction_model.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  TransactionRepositoryImpl(this._firestore, this._auth);

  String get _userId => _auth.currentUser?.uid ?? '';
  CollectionReference get _collection => _firestore.collection('users').doc(_userId).collection('transactions');

  @override
  Future<List<TransactionEntity>> getAll() async {
    if (_userId.isEmpty) return [];
    final snapshot = await _collection.get();
    return snapshot.docs.map((doc) => TransactionModel.fromJson(doc.data() as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<TransactionEntity>> getConfirmed() async {
    if (_userId.isEmpty) return [];
    final snapshot = await _collection.where('status', isEqualTo: TransactionStatus.confirmed.name).get();
    return snapshot.docs.map((doc) => TransactionModel.fromJson(doc.data() as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<TransactionEntity>> getByDateRange(DateTime start, DateTime end) async {
    if (_userId.isEmpty) return [];
    final snapshot = await _collection
        .where('transactionDate', isGreaterThanOrEqualTo: start.toIso8601String())
        .where('transactionDate', isLessThanOrEqualTo: end.toIso8601String())
        .get();
    return snapshot.docs.map((doc) => TransactionModel.fromJson(doc.data() as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<TransactionEntity>> getByType(TransactionType type) async {
    if (_userId.isEmpty) return [];
    final snapshot = await _collection.where('type', isEqualTo: type.name).get();
    return snapshot.docs.map((doc) => TransactionModel.fromJson(doc.data() as Map<String, dynamic>)).toList();
  }

  @override
  Future<TransactionEntity?> getById(String id) async {
    if (_userId.isEmpty) return null;
    final doc = await _collection.doc(id).get();
    if (doc.exists) {
      return TransactionModel.fromJson(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  @override
  Future<void> create(TransactionEntity transaction) async {
    if (_userId.isEmpty) return;
    final model = TransactionModel(
      id: transaction.id,
      amount: transaction.amount,
      type: transaction.type,
      categoryId: transaction.categoryId,
      transactionDate: transaction.transactionDate,
      status: transaction.status,
      note: transaction.note,
      invoiceId: transaction.invoiceId,
      createdAt: transaction.createdAt,
      updatedAt: transaction.updatedAt,
    );
    await _collection.doc(transaction.id).set(model.toJson());
  }

  @override
  Future<void> update(TransactionEntity transaction) async {
    if (_userId.isEmpty) return;
    final model = TransactionModel(
      id: transaction.id,
      amount: transaction.amount,
      type: transaction.type,
      categoryId: transaction.categoryId,
      transactionDate: transaction.transactionDate,
      status: transaction.status,
      note: transaction.note,
      invoiceId: transaction.invoiceId,
      createdAt: transaction.createdAt,
      updatedAt: transaction.updatedAt,
    );
    await _collection.doc(transaction.id).update(model.toJson());
  }

  @override
  Future<void> softDelete(String id) async {
    if (_userId.isEmpty) return;
    await _collection.doc(id).update({
      'status': TransactionStatus.deleted.name,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> hardDelete(String id) async {
    if (_userId.isEmpty) return;
    await _collection.doc(id).delete();
  }

  @override
  Future<void> restore(String id) async {
    if (_userId.isEmpty) return;
    await _collection.doc(id).update({
      'status': TransactionStatus.draft.name,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> cleanupDeletedTransactions() async {
    if (_userId.isEmpty) return;
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30)).toIso8601String();
    
    final snapshot = await _collection
        .where('status', isEqualTo: TransactionStatus.deleted.name)
        .where('updatedAt', isLessThan: thirtyDaysAgo)
        .get();
        
    final batch = _firestore.batch();
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
