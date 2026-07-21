import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    FirebaseAuth.instance,
    FirebaseFirestore.instance,
    GoogleSignIn.instance,
  );
});
// HoangDH
class AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  AuthRepository(this._firebaseAuth, this._firestore, this._googleSignIn);

  // Lấy UserModel từ Firestore dựa vào uid
  Future<UserModel?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromJson(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // Đăng nhập bằng Email & Password
  Future<UserModel?> login(String email, String password) async {
    try {
      if (!email.contains('@')) {
        email = '$email@smartfinance.com';
      }
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (userCredential.user != null) {
        return await getUserData(userCredential.user!.uid);
      }
    } on FirebaseAuthException catch (e) {
      print('Login error (FirebaseAuth): ${e.code}');
      if (e.code == 'invalid-credential' || e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-email') {
        throw Exception('Tài khoản hoặc mật khẩu không đúng, vui lòng kiểm tra lại.');
      } else if (e.code == 'user-disabled') {
        throw Exception('Tài khoản này đã bị khóa.');
      }
      throw Exception('Đăng nhập thất bại. Vui lòng thử lại.');
    } catch (e) {
      print('Login error: $e');
      throw Exception('Đăng nhập thất bại. Vui lòng thử lại sau.');
    }
    return null;
  }

  // Đăng ký bằng Email & Password
  Future<UserModel?> register(String email, String password, String fullName, String company, String taxCode, {String role = 'financeManager'}) async {
    try {
      if (!email.contains('@')) {
        email = '$email@smartfinance.com';
      }
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (userCredential.user != null) {
        final newUser = UserModel(
          id: userCredential.user!.uid,
          email: email,
          fullName: fullName,
          company: company,
          taxCode: taxCode,
          phone: '0909123456',
          address: 'Tầng 3, Tòa nhà FPT, Khu Công nghệ cao Hòa Lạc',
          bankName: 'Vietcombank',
          bankAccount: '1010101010',
          role: role, // Role được truyền vào
        );
        
        await _firestore.collection('users').doc(newUser.id).set(newUser.toJson());
        return newUser;
      }
    } catch (e) {
      print('Register error: $e');
      throw Exception('Đăng ký thất bại: $e');
    }
    return null;
  }

  // Đăng nhập bằng Google
  Future<UserModel?> signInWithGoogle() async {
    try {
      UserCredential userCredential;

      // Sử dụng kIsWeb (cần import 'package:flutter/foundation.dart') để kiểm tra Web
      if (const bool.fromEnvironment('dart.library.js_util')) {
        // Trên nền Web, gọi thẳng Firebase Auth signInWithPopup bằng GoogleAuthProvider
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        
        userCredential = await _firebaseAuth.signInWithPopup(googleProvider);
      } else {
        // Trên nền Android / iOS, dùng google_sign_in native
        GoogleSignInAccount account;
        try {
          account = await _googleSignIn.authenticate();
        } on Exception catch (e) {
          // Bị hủy bởi người dùng hoặc lỗi khác
          print('Google Sign-In canceled or failed: $e');
          return null;
        }

        final GoogleSignInAuthentication googleAuth = account.authentication;
        final OAuthCredential credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
        );

        userCredential = await _firebaseAuth.signInWithCredential(credential);
      }
      
      final User? firebaseUser = userCredential.user;

      if (firebaseUser != null) {
        // Kiểm tra xem user đã có trong Firestore chưa
        UserModel? userModel = await getUserData(firebaseUser.uid);
        
        if (userModel == null) {
          // Lấy tiền tố trước @ của email để làm username mặc định
          String defaultName = firebaseUser.displayName ?? 'Google User';
          if (firebaseUser.email != null && firebaseUser.email!.contains('@')) {
            defaultName = firebaseUser.email!.split('@')[0];
          }

          // Lần đầu đăng nhập, tạo profile mặc định
          userModel = UserModel(
            id: firebaseUser.uid,
            email: firebaseUser.email ?? '',
            fullName: defaultName,
            company: 'N/A', // Mặc định
            taxCode: 'N/A', // Mặc định
            phone: '0909123456',
            address: 'Tầng 3, Tòa nhà FPT, Khu Công nghệ cao Hòa Lạc',
            bankName: 'Vietcombank',
            bankAccount: '1010101010',
            role: 'financeManager', // Theo yêu cầu hardcode thành Quản lý cho tiện demo
          );
          await _firestore.collection('users').doc(userModel.id).set(userModel.toJson());
        }
        return userModel;
      }
    } catch (e) {
      print('Google Sign-In error: $e');
      throw Exception('Đăng nhập Google thất bại: $e');
    }
    return null;
  }
  
  // Cập nhật thông tin User
  Future<void> updateUserInfo(UserModel updatedUser) async {
    try {
      await _firestore.collection('users').doc(updatedUser.id).update(updatedUser.toJson());
    } catch (e) {
      print('Update user info error: $e');
      throw Exception('Cập nhật thông tin thất bại: $e');
    }
  }

  // Đổi mật khẩu
  Future<void> changePassword(String oldPassword, String newPassword) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null || user.email == null) {
        throw Exception('Người dùng chưa đăng nhập');
      }

      // 1. Xác thực lại bằng mật khẩu cũ (bắt buộc trước khi đổi MK)
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: oldPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // 2. Cập nhật mật khẩu mới
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        throw Exception('Mật khẩu hiện tại không đúng');
      } else if (e.code == 'weak-password') {
        throw Exception('Mật khẩu mới quá yếu');
      }
      throw Exception('Lỗi đổi mật khẩu: ${e.message}');
    } catch (e) {
      print('Change password error: $e');
      throw Exception('Đổi mật khẩu thất bại: $e');
    }
  }
  
  // Đăng xuất
  Future<void> logout() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _firebaseAuth.signOut();
  }
}
