import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/invoice_entity.dart';
import '../../domain/repositories/invoice_repository.dart';
import '../models/invoice_model.dart';
import '../models/user_model.dart';

class InvoiceRepositoryImpl implements InvoiceRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final UserModel? _currentUser;

  InvoiceRepositoryImpl(this._firestore, this._auth, this._currentUser);

  String get _uid => _currentUser?.id ?? _auth.currentUser?.uid ?? '';
  String get _company => _currentUser?.company ?? '';
  CollectionReference get _collection => _firestore.collection('invoices');

  @override
  Future<List<InvoiceEntity>> getAll() async {
    if (_uid.isEmpty) return [];
    Query query = _collection.where('company', isEqualTo: _company);
    final snapshot = await query.get();
    return snapshot.docs.map((doc) => InvoiceModel.fromJson(doc.data() as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<InvoiceEntity>> getByOcrStatus(OcrStatus status) async {
    if (_uid.isEmpty) return [];
    Query query = _collection
        .where('company', isEqualTo: _company)
        .where('ocrStatus', isEqualTo: status.name);
    final snapshot = await query.get();
    return snapshot.docs.map((doc) => InvoiceModel.fromJson(doc.data() as Map<String, dynamic>)).toList();
  }

  @override
  Future<InvoiceEntity?> getById(String id) async {
    if (_uid.isEmpty) return null;
    final doc = await _collection.doc(id).get();
    if (doc.exists) {
      return InvoiceModel.fromJson(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  @override
  Future<void> create(InvoiceEntity invoice) async {
    if (_uid.isEmpty) return;
    final model = InvoiceModel(
      id: invoice.id,
      invoiceNumber: invoice.invoiceNumber,
      sellerName: invoice.sellerName,
      sellerTaxCode: invoice.sellerTaxCode,
      sellerAddress: invoice.sellerAddress,
      sellerPhone: invoice.sellerPhone,
      sellerBankName: invoice.sellerBankName,
      sellerBankAccount: invoice.sellerBankAccount,
      buyerContactName: invoice.buyerContactName,
      buyerName: invoice.buyerName,
      buyerTaxCode: invoice.buyerTaxCode,
      buyerAddress: invoice.buyerAddress,
      buyerBankName: invoice.buyerBankName,
      buyerBankAccount: invoice.buyerBankAccount,
      paymentMethod: invoice.paymentMethod,
      items: invoice.items,
      subtotal: invoice.subtotal,
      vatRate: invoice.vatRate,
      vatAmount: invoice.vatAmount,
      totalAmount: invoice.totalAmount,
      ocrStatus: invoice.ocrStatus,
      transactionStatus: invoice.transactionStatus,
      issuedDate: invoice.issuedDate,
      createdByUid: _uid,
      company: _company,
      createdAt: invoice.createdAt,
      updatedAt: invoice.updatedAt,
      type: invoice.type,
      imagePath: invoice.imagePath,
      ocrConfidence: invoice.ocrConfidence,
    );
    await _collection.doc(invoice.id).set(model.toJson());
  }

  @override
  Future<void> update(InvoiceEntity invoice) async {
    if (_uid.isEmpty) return;
    final model = InvoiceModel(
      id: invoice.id,
      invoiceNumber: invoice.invoiceNumber,
      sellerName: invoice.sellerName,
      sellerTaxCode: invoice.sellerTaxCode,
      sellerAddress: invoice.sellerAddress,
      sellerPhone: invoice.sellerPhone,
      sellerBankName: invoice.sellerBankName,
      sellerBankAccount: invoice.sellerBankAccount,
      buyerContactName: invoice.buyerContactName,
      buyerName: invoice.buyerName,
      buyerTaxCode: invoice.buyerTaxCode,
      buyerAddress: invoice.buyerAddress,
      buyerBankName: invoice.buyerBankName,
      buyerBankAccount: invoice.buyerBankAccount,
      paymentMethod: invoice.paymentMethod,
      items: invoice.items,
      subtotal: invoice.subtotal,
      vatRate: invoice.vatRate,
      vatAmount: invoice.vatAmount,
      totalAmount: invoice.totalAmount,
      ocrStatus: invoice.ocrStatus,
      transactionStatus: invoice.transactionStatus,
      issuedDate: invoice.issuedDate,
      createdByUid: invoice.createdByUid.isNotEmpty ? invoice.createdByUid : _uid,
      company: invoice.company.isNotEmpty ? invoice.company : _company,
      createdAt: invoice.createdAt,
      updatedAt: invoice.updatedAt,
      type: invoice.type,
      imagePath: invoice.imagePath,
      ocrConfidence: invoice.ocrConfidence,
    );
    await _collection.doc(invoice.id).update(model.toJson());
  }

  @override
  Future<void> delete(String id) async {
    if (_uid.isEmpty) return;
    await _collection.doc(id).delete();
  }

  @override
  Future<void> updateTransactionStatus(String id, InvoiceTransactionStatus status) async {
    if (_uid.isEmpty) return;
    await _collection.doc(id).update({
      'transactionStatus': status.name,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }
}
