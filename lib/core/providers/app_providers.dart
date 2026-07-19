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
import '../../data/repositories/partner_repository_impl.dart';
import '../../data/repositories/partner_repository.dart';
import '../../domain/entities/partner_entity.dart';
import 'auth_provider.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final user = ref.watch(currentUserProvider);
  return CategoryRepositoryImpl(FirebaseFirestore.instance, FirebaseAuth.instance, user);
});

final categoryStreamProvider = StreamProvider<List<CategoryEntity>>((ref) {
  final auth = FirebaseAuth.instance;
  final uid = auth.currentUser?.uid ?? '';
  if (uid.isEmpty) return Stream.value([]);
  final user = ref.watch(currentUserProvider);
  final company = user?.company ?? '';
  if (company.isEmpty) return Stream.value([]);
  return FirebaseFirestore.instance.collection('categories').where('company', isEqualTo: company).snapshots().map(
    (snapshot) => snapshot.docs.map((doc) => CategoryModel.fromJson(doc.data())).toList()
  );
});

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final user = ref.watch(currentUserProvider);
  return TransactionRepositoryImpl(FirebaseFirestore.instance, FirebaseAuth.instance, user);
});

final invoiceRepositoryProvider = Provider<InvoiceRepository>((ref) {
  final user = ref.watch(currentUserProvider);
  return InvoiceRepositoryImpl(FirebaseFirestore.instance, FirebaseAuth.instance, user);
});

final attachmentRepositoryProvider = Provider<AttachmentRepository>((ref) {
  final user = ref.watch(currentUserProvider);
  return AttachmentRepositoryImpl(FirebaseFirestore.instance, FirebaseAuth.instance, user);
});

final partnerRepositoryProvider = Provider<PartnerRepository>((ref) {
  return PartnerRepositoryImpl(firestore: FirebaseFirestore.instance);
});

final partnerStreamProvider = StreamProvider<List<PartnerEntity>>((ref) {
  final user = ref.watch(currentUserProvider);
  final company = user?.company ?? '';
  return ref.watch(partnerRepositoryProvider).getPartners(company);
});

final companyBudgetLimitProvider = FutureProvider.autoDispose<int>((ref) async {
  final user = ref.watch(currentUserProvider);
  final company = user?.company;
  if (company == null || company.isEmpty) return 20000000;
  final doc = await FirebaseFirestore.instance.collection('companySettings').doc(company).get();
  if (doc.exists && doc.data() != null) {
    return (doc.data()!['budgetLimit'] as num?)?.toInt() ?? 20000000;
  }
  return 20000000;
});

final companyRevenueKpiProvider = FutureProvider.autoDispose<int>((ref) async {
  final user = ref.watch(currentUserProvider);
  final company = user?.company;
  if (company == null || company.isEmpty) return 500000000;
  final doc = await FirebaseFirestore.instance.collection('companySettings').doc(company).get();
  if (doc.exists && doc.data() != null) {
    return (doc.data()!['revenueKpi'] as num?)?.toInt() ?? 500000000;
  }
  return 500000000;
});
