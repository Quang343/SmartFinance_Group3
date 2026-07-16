import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/category_repository_impl.dart';
import '../../data/repositories/transaction_repository_impl.dart';
import '../../data/repositories/invoice_repository_impl.dart';
import '../../data/repositories/attachment_repository_impl.dart';
import '../../data/models/category_model.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/repositories/category_repository.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../domain/repositories/invoice_repository.dart';
import '../../domain/repositories/attachment_repository.dart';

// Repositories
final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepositoryImpl(FirebaseFirestore.instance, FirebaseAuth.instance);
});

final categoryStreamProvider = StreamProvider<List<CategoryEntity>>((ref) {
  final auth = FirebaseAuth.instance;
  final userId = auth.currentUser?.uid ?? '';
  if (userId.isEmpty) return Stream.value([]);
  return FirebaseFirestore.instance.collection('users').doc(userId).collection('categories').snapshots().map(
    (snapshot) => snapshot.docs.map((doc) => CategoryModel.fromJson(doc.data())).toList()
  );
});

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepositoryImpl(FirebaseFirestore.instance, FirebaseAuth.instance);
});

final invoiceRepositoryProvider = Provider<InvoiceRepository>((ref) {
  return InvoiceRepositoryImpl(FirebaseFirestore.instance, FirebaseAuth.instance);
});

final attachmentRepositoryProvider = Provider<AttachmentRepository>((ref) {
  return AttachmentRepositoryImpl(FirebaseFirestore.instance, FirebaseAuth.instance);
});

