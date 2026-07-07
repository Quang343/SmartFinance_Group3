import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/user_model.dart';

class FirebaseSeedService {
  static Future<void> seedDefaultUsers() async {
    final auth = FirebaseAuth.instance;
    final firestore = FirebaseFirestore.instance;

    final defaultUsers = [
      {
        'email': 'admin@smartfinance.com',
        'password': '123456', // Firebase BẮT BUỘC mật khẩu tối thiểu 6 ký tự
        'fullName': 'Quản lý Tài chính',
        'company': 'Smart Finance Corp',
        'taxCode': '000000',
        'role': 'financeManager',
      },
      {
        'email': 'expense@smartfinance.com',
        'password': '123456',
        'fullName': 'Kế toán Chi phí',
        'company': 'Smart Finance Corp',
        'taxCode': '111111',
        'role': 'expenseAccountant',
      },
      {
        'email': 'revenue@smartfinance.com',
        'password': '123456',
        'fullName': 'Kế toán Doanh thu',
        'company': 'Smart Finance Corp',
        'taxCode': '222222',
        'role': 'revenueAccountant',
      },
    ];

    for (final userData in defaultUsers) {
      try {
        // Cố gắng tạo tài khoản mới, nếu trùng email sẽ ném lỗi email-already-in-use
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
            role: userData['role']!,
          );
          
          await firestore.collection('users').doc(newUser.id).set(newUser.toJson());
          print('✅ Đã tạo tài khoản test: ${userData['email']}');
        }
      } catch (e) {
        if (e is FirebaseAuthException && e.code == 'email-already-in-use') {
          print('ℹ️ Tài khoản test đã tồn tại: ${userData['email']}');
        } else {
          print('Lỗi khi seed user ${userData['email']}: $e');
        }
      }
    }
  }
}
