import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../data/models/user_model.dart';
import '../data/models/transaction_model.dart';
import '../domain/entities/transaction_entity.dart';

class FirebaseSeedService {
  static Future<void> seedDefaultUsers() async {
    final auth = FirebaseAuth.instance;
    final firestore = FirebaseFirestore.instance;

    await _migrateOldData(firestore);
    await _cleanupAdminSeedData(firestore);

    final defaultUsers = [
      {
        'email': 'admin@smartfinance.com',
        'password': '123456',
        'fullName': 'Quản lý Tài chính',
        'company': 'CÔNG TY CỔ PHẦN SMART FINANCE',
        'taxCode': '0312345678',
        'phone': '0909123456',
        'address': 'Tầng 3, Tòa nhà FPT, Khu Công nghệ cao Hòa Lạc',
        'bankName': 'Vietcombank',
        'bankAccount': '1010101010',
        'role': 'financeManager',
      },
      {
        'email': 'expense@smartfinance.com',
        'password': '123456',
        'fullName': 'Kế toán Chi phí',
        'company': 'CÔNG TY CỔ PHẦN SMART FINANCE',
        'taxCode': '0312345678',
        'phone': '0909123456',
        'address': 'Tầng 3, Tòa nhà FPT, Khu Công nghệ cao Hòa Lạc',
        'bankName': 'Vietcombank',
        'bankAccount': '1010101010',
        'role': 'expenseAccountant',
      },
      {
        'email': 'revenue@smartfinance.com',
        'password': '123456',
        'fullName': 'Kế toán Doanh thu',
        'company': 'CÔNG TY CỔ PHẦN SMART FINANCE',
        'taxCode': '0312345678',
        'address': 'Tầng 3, Tòa nhà FPT, Khu Công nghệ cao Hòa Lạc',
        'bankName': 'Vietcombank',
        'bankAccount': '1010101010',
        'role': 'revenueAccountant',
      },
    ];

    for (final userData in defaultUsers) {
      try {
        final userCredential = await auth.createUserWithEmailAndPassword(
          email: userData['email']!,
          password: userData['password']!,
        );
        
        if (userCredential.user != null) {
          final newUser = UserModel(
            id: userCredential.user!.uid,
            email: userData['email']!,
            fullName: userData['fullName']!,
            company: userData['company']!,
            taxCode: userData['taxCode']!,
            phone: userData['phone']!,
            address: userData['address']!,
            bankName: userData['bankName']!,
            bankAccount: userData['bankAccount']!,
            role: userData['role']!,
          );
          
          await firestore.collection('users').doc(newUser.id).set(newUser.toJson());
          print('✅ Đã tạo tài khoản test: ${userData['email']}');
          await _seedForUser(firestore, userCredential.user!.uid, userData['role']!, userData['company']!);
        }
      } catch (e) {
        if (e is FirebaseAuthException && e.code == 'email-already-in-use') {
          print('ℹ️ Tài khoản test đã tồn tại: ${userData['email']}');
          final existingUser = auth.currentUser;
          if (existingUser != null) {
            final doc = await firestore.collection('users').doc(existingUser.uid).get();
            if (doc.exists) {
              final user = UserModel.fromJson(doc.data()!, existingUser.uid);
              await _seedForUser(firestore, existingUser.uid, user.role, user.company);
            }
          }
        } else {
          print('Lỗi khi seed user ${userData['email']}: $e');
        }
      }
    }
  }

  static Future<void> _migrateOldData(FirebaseFirestore firestore) async {
    final migrationDoneKey = '_migration_done_20260717';
    final migrationDoc = await firestore.collection('_meta').doc(migrationDoneKey).get();
    if (migrationDoc.exists) return;

    final usersSnapshot = await firestore.collection('users').get();
    int migratedCount = 0;

    for (final userDoc in usersSnapshot.docs) {
      final uid = userDoc.id;
      final company = (userDoc.data()['company'] as String?) ?? '';
      if (company.isEmpty) continue;

      final oldTxs = await firestore.collection('users').doc(uid).collection('transactions').get();
      for (final txDoc in oldTxs.docs) {
        final data = Map<String, dynamic>.from(txDoc.data());
        data['createdByUid'] = uid;
        data['company'] = company;
        await firestore.collection('transactions').doc(txDoc.id).set(data, SetOptions(merge: true));
        migratedCount++;
      }

      final oldInvs = await firestore.collection('users').doc(uid).collection('invoices').get();
      for (final invDoc in oldInvs.docs) {
        final data = Map<String, dynamic>.from(invDoc.data());
        data['createdByUid'] = uid;
        data['company'] = company;
        await firestore.collection('invoices').doc(invDoc.id).set(data, SetOptions(merge: true));
        migratedCount++;
      }

      final oldCats = await firestore.collection('users').doc(uid).collection('categories').get();
      for (final catDoc in oldCats.docs) {
        final data = Map<String, dynamic>.from(catDoc.data());
        data['createdByUid'] = uid;
        data['company'] = company;
        await firestore.collection('categories').doc(catDoc.id).set(data, SetOptions(merge: true));
        migratedCount++;
      }

      final oldAtts = await firestore.collection('users').doc(uid).collection('attachments').get();
      for (final attDoc in oldAtts.docs) {
        final data = Map<String, dynamic>.from(attDoc.data());
        data['createdByUid'] = uid;
        data['company'] = company;
        await firestore.collection('attachments').doc(attDoc.id).set(data, SetOptions(merge: true));
        migratedCount++;
      }
    }

    await firestore.collection('_meta').doc(migrationDoneKey).set({'done': true, 'migratedCount': migratedCount, 'migratedAt': DateTime.now().toIso8601String()});
    print('✅ Migration hoàn tất: $migratedCount documents');
  }

  static Future<void> _cleanupAdminSeedData(FirebaseFirestore firestore) async {
    final cleanupKey = '_cleanup_admin_tx_20260717';
    final cleanupDoc = await firestore.collection('_meta').doc(cleanupKey).get();
    if (cleanupDoc.exists) return;

    final adminSnapshot = await firestore.collection('users').where('role', isEqualTo: 'financeManager').get();
    for (final userDoc in adminSnapshot.docs) {
      final adminUid = userDoc.id;
      final oldTxs = await firestore.collection('transactions').where('createdByUid', isEqualTo: adminUid).get();
      final batch = firestore.batch();
      for (final txDoc in oldTxs.docs) {
        batch.delete(txDoc.reference);
      }
      await batch.commit();
      if (oldTxs.docs.isNotEmpty) {
        print('✅ Đã xóa ${oldTxs.docs.length} transaction cũ của admin');
      }
    }
    await firestore.collection('_meta').doc(cleanupKey).set({'done': true, 'cleanedAt': DateTime.now().toIso8601String()});
  }

  static Future<void> _seedForUser(FirebaseFirestore firestore, String uid, String role, String company) async {
    final existing = await firestore.collection('transactions').where('createdByUid', isEqualTo: uid).limit(1).get();
    if (existing.docs.isNotEmpty) return;

    final now = DateTime.now();
    final sampleTransactions = <TransactionModel>[];

    if (role == 'expenseAccountant') {
      sampleTransactions.addAll([
        TransactionModel(
          id: const Uuid().v4(), amount: 3000000, type: TransactionType.expense,
          categoryId: 'cat_office', transactionDate: now.subtract(const Duration(days: 1)),
          status: TransactionStatus.confirmed, createdByUid: uid, company: company,
          note: 'Mua văn phòng phẩm', createdAt: now, updatedAt: now,
        ),
        TransactionModel(
          id: const Uuid().v4(), amount: 15000000, type: TransactionType.expense,
          categoryId: 'cat_salary', transactionDate: now.subtract(const Duration(days: 2)),
          status: TransactionStatus.confirmed, createdByUid: uid, company: company,
          note: 'Lương nhân viên tháng 6', createdAt: now, updatedAt: now,
        ),
        TransactionModel(
          id: const Uuid().v4(), amount: 2000000, type: TransactionType.expense,
          categoryId: 'cat_utility', transactionDate: now.subtract(const Duration(days: 4)),
          status: TransactionStatus.confirmed, createdByUid: uid, company: company,
          note: 'Tiền internet tháng 6', createdAt: now, updatedAt: now,
        ),
      ]);
    } else if (role == 'revenueAccountant') {
      sampleTransactions.addAll([
        TransactionModel(
          id: const Uuid().v4(), amount: 35000000, type: TransactionType.income,
          categoryId: 'cat_revenue', transactionDate: now.subtract(const Duration(days: 1)),
          status: TransactionStatus.confirmed, createdByUid: uid, company: company,
          note: 'Doanh thu từ khách hàng A', createdAt: now, updatedAt: now,
        ),
        TransactionModel(
          id: const Uuid().v4(), amount: 18000000, type: TransactionType.income,
          categoryId: 'cat_service', transactionDate: now.subtract(const Duration(days: 3)),
          status: TransactionStatus.confirmed, createdByUid: uid, company: company,
          note: 'Phí dịch vụ tháng 6', createdAt: now, updatedAt: now,
        ),
      ]);
    }

    for (final tx in sampleTransactions) {
      await firestore.collection('transactions').doc(tx.id).set(tx.toJson());
    }
    if (sampleTransactions.isNotEmpty) {
      print('✅ Đã seed ${sampleTransactions.length} giao dịch cho $role');
    }
  }
}
