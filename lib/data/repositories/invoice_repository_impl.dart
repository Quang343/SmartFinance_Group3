import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/invoice_entity.dart';
import '../../domain/repositories/invoice_repository.dart';
import '../models/invoice_model.dart';

class InvoiceRepositoryImpl implements InvoiceRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  InvoiceRepositoryImpl(this._firestore, this._auth);

  String get _userId => _auth.currentUser?.uid ?? '';
  CollectionReference get _collection => _firestore.collection('users').doc(_userId).collection('invoices');

  @override
  Future<List<InvoiceEntity>> getAll() async {
    if (_userId.isEmpty) return [];
    final snapshot = await _collection.get();
    return snapshot.docs.map((doc) => InvoiceModel.fromJson(doc.data() as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<InvoiceEntity>> getByOcrStatus(OcrStatus status) async {
    if (_userId.isEmpty) return [];
    final snapshot = await _collection.where('ocrStatus', isEqualTo: status.name).get();
    return snapshot.docs.map((doc) => InvoiceModel.fromJson(doc.data() as Map<String, dynamic>)).toList();
  }

  @override
  Future<InvoiceEntity?> getById(String id) async {
    if (_userId.isEmpty) return null;
    final doc = await _collection.doc(id).get();
    if (doc.exists) {
      return InvoiceModel.fromJson(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  @override
  Future<void> create(InvoiceEntity invoice) async {
    if (_userId.isEmpty) return;
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
      paymentStatus: invoice.paymentStatus,
      issuedDate: invoice.issuedDate,
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
    if (_userId.isEmpty) return;
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
      paymentStatus: invoice.paymentStatus,
      issuedDate: invoice.issuedDate,
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
    if (_userId.isEmpty) return;
    await _collection.doc(id).delete();
  }
}
