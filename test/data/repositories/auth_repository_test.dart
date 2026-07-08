import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:smart_finance/data/repositories/auth_repository.dart';
import 'package:smart_finance/data/models/user_model.dart';

// --- Mocks ---
class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockGoogleSignIn extends Mock implements GoogleSignIn {}
class MockUserCredential extends Mock implements UserCredential {}
class MockUser extends Mock implements User {}
class MockGoogleSignInAccount extends Mock implements GoogleSignInAccount {}
class MockGoogleSignInAuthentication extends Mock implements GoogleSignInAuthentication {}
class MockCollectionReference extends Mock implements CollectionReference<Map<String, dynamic>> {}
class MockDocumentReference extends Mock implements DocumentReference<Map<String, dynamic>> {}
class MockDocumentSnapshot extends Mock implements DocumentSnapshot<Map<String, dynamic>> {}

// Unit Test by HoangDH
void main() {
  late AuthRepository authRepository;
  late MockFirebaseAuth mockFirebaseAuth;
  late MockFirebaseFirestore mockFirebaseFirestore;
  late MockGoogleSignIn mockGoogleSignIn;

  setUpAll(() {
    // Register fallback values if needed by Mocktail
    registerFallbackValue(
      GoogleAuthProvider.credential(idToken: 'fallback', accessToken: 'fallback'),
    );
  });

  setUp(() {
    mockFirebaseAuth = MockFirebaseAuth();
    mockFirebaseFirestore = MockFirebaseFirestore();
    mockGoogleSignIn = MockGoogleSignIn();

    authRepository = AuthRepository(
      mockFirebaseAuth,
      mockFirebaseFirestore,
      mockGoogleSignIn,
    );
  });

  group('AuthRepository Tests', () {
    final tUid = 'user123';
    final tEmail = 'test@example.com';
    final tPassword = 'password123';
    
    final Map<String, dynamic> tUserData = {
      'id': tUid,
      'email': tEmail,
      'fullName': 'Test User',
      'company': 'Test Corp',
      'taxCode': '123456',
      'role': 'financeManager',
    };

    group('getUserData', () {
      test('returns UserModel when user exists in Firestore', () async {
        // Arrange
        final mockCollection = MockCollectionReference();
        final mockDocRef = MockDocumentReference();
        final mockSnapshot = MockDocumentSnapshot();

        when(() => mockFirebaseFirestore.collection('users')).thenReturn(mockCollection);
        when(() => mockCollection.doc(tUid)).thenReturn(mockDocRef);
        when(() => mockDocRef.get()).thenAnswer((_) async => mockSnapshot);
        when(() => mockSnapshot.exists).thenReturn(true);
        when(() => mockSnapshot.data()).thenReturn(tUserData);
        when(() => mockSnapshot.id).thenReturn(tUid);

        // Act
        final result = await authRepository.getUserData(tUid);

        // Assert
        expect(result, isA<UserModel>());
        expect(result?.email, tEmail);
        verify(() => mockFirebaseFirestore.collection('users').doc(tUid).get()).called(1);
      });

      test('returns null when user does not exist in Firestore', () async {
        // Arrange
        final mockCollection = MockCollectionReference();
        final mockDocRef = MockDocumentReference();
        final mockSnapshot = MockDocumentSnapshot();

        when(() => mockFirebaseFirestore.collection('users')).thenReturn(mockCollection);
        when(() => mockCollection.doc(tUid)).thenReturn(mockDocRef);
        when(() => mockDocRef.get()).thenAnswer((_) async => mockSnapshot);
        when(() => mockSnapshot.exists).thenReturn(false);

        // Act
        final result = await authRepository.getUserData(tUid);

        // Assert
        expect(result, isNull);
      });

      test('returns null when exception occurs', () async {
        // Arrange
        final mockCollection = MockCollectionReference();
        final mockDocRef = MockDocumentReference();

        when(() => mockFirebaseFirestore.collection('users')).thenReturn(mockCollection);
        when(() => mockCollection.doc(tUid)).thenReturn(mockDocRef);
        when(() => mockDocRef.get()).thenThrow(Exception('Firestore error'));

        // Act
        final result = await authRepository.getUserData(tUid);

        // Assert
        expect(result, isNull);
      });
    });

    group('login', () {
      test('returns UserModel on successful login', () async {
        // Arrange
        final mockUserCredential = MockUserCredential();
        final mockUser = MockUser();
        
        final mockCollection = MockCollectionReference();
        final mockDocRef = MockDocumentReference();
        final mockSnapshot = MockDocumentSnapshot();

        when(() => mockFirebaseAuth.signInWithEmailAndPassword(email: tEmail, password: tPassword))
            .thenAnswer((_) async => mockUserCredential);
        when(() => mockUserCredential.user).thenReturn(mockUser);
        when(() => mockUser.uid).thenReturn(tUid);

        // Mock Firestore getUserData internal call
        when(() => mockFirebaseFirestore.collection('users')).thenReturn(mockCollection);
        when(() => mockCollection.doc(tUid)).thenReturn(mockDocRef);
        when(() => mockDocRef.get()).thenAnswer((_) async => mockSnapshot);
        when(() => mockSnapshot.exists).thenReturn(true);
        when(() => mockSnapshot.data()).thenReturn(tUserData);
        when(() => mockSnapshot.id).thenReturn(tUid);

        // Act
        final result = await authRepository.login(tEmail, tPassword);

        // Assert
        expect(result, isNotNull);
        expect(result?.id, tUid);
        verify(() => mockFirebaseAuth.signInWithEmailAndPassword(email: tEmail, password: tPassword)).called(1);
      });

      test('throws Exception on login failure', () async {
        // Arrange
        when(() => mockFirebaseAuth.signInWithEmailAndPassword(email: tEmail, password: tPassword))
            .thenThrow(FirebaseAuthException(code: 'user-not-found'));

        // Act & Assert
        expect(() => authRepository.login(tEmail, tPassword), throwsA(isA<Exception>()));
      });
    });

    group('register', () {
      test('returns UserModel and creates Firestore doc on successful registration', () async {
        // [CASE 1]: Test Đăng ký chuẩn chỉ mọi thông tin hợp lệ
        // Mô phỏng luồng đăng ký hoàn hảo, mọi thông tin đều đúng.
        
        // Arrange (Chuẩn bị dữ liệu và Mock)
        // Cài đặt cho Firebase Auth trả về thành công
        final mockUserCredential = MockUserCredential();
        final mockUser = MockUser();
        
        final mockCollection = MockCollectionReference();
        final mockDocRef = MockDocumentReference();

        when(() => mockFirebaseAuth.createUserWithEmailAndPassword(email: tEmail, password: tPassword))
            .thenAnswer((_) async => mockUserCredential);
        when(() => mockUserCredential.user).thenReturn(mockUser);
        when(() => mockUser.uid).thenReturn(tUid);

        // Cài đặt cho Firestore lưu dữ liệu thành công
        when(() => mockFirebaseFirestore.collection('users')).thenReturn(mockCollection);
        when(() => mockCollection.doc(tUid)).thenReturn(mockDocRef);
        when(() => mockDocRef.set(any())).thenAnswer((_) async => {});

        // Act (Thực thi hành động đăng ký)
        final result = await authRepository.register(tEmail, tPassword, 'Test User', 'Test Corp', '123456');

        // Assert (Kiểm tra kết quả)
        // Đảm bảo trả về UserModel hợp lệ và các hàm create/set đã được gọi đúng 1 lần
        expect(result, isNotNull);
        expect(result?.id, tUid);
        verify(() => mockFirebaseAuth.createUserWithEmailAndPassword(email: tEmail, password: tPassword)).called(1);
        verify(() => mockCollection.doc(tUid).set(any())).called(1);
      });

      test('throws Exception on register failure', () async {
        // [CASE 2]: Test Đăng ký thất bại do Email đã tồn tại
        // Mô phỏng việc Firebase Auth quăng lỗi (VD: email đã được sử dụng)
        
        // Arrange (Cài đặt Mock quăng lỗi FirebaseAuthException)
        when(() => mockFirebaseAuth.createUserWithEmailAndPassword(email: tEmail, password: tPassword))
            .thenThrow(FirebaseAuthException(code: 'email-already-in-use'));

        // Act & Assert (Thực thi và Kiểm tra xem hàm register có quăng ra Exception không)
        expect(() => authRepository.register(tEmail, tPassword, 'Name', 'Corp', 'Tax'), throwsA(isA<Exception>()));
      });

      test('appends @smartfinance.com if email does not contain @', () async {
        // [CASE 3]: Test Đăng ký bị KHUYẾT phần mở rộng email (không có @)
        // Hệ thống phải tự động bổ sung đuôi @smartfinance.com vào phía sau username
        
        // Arrange
        final mockUserCredential = MockUserCredential();
        final mockUser = MockUser();
        final mockCollection = MockCollectionReference();
        final mockDocRef = MockDocumentReference();

        // Kì vọng FirebaseAuth nhận được email đã được format đầy đủ '@smartfinance.com'
        when(() => mockFirebaseAuth.createUserWithEmailAndPassword(email: 'testuser@smartfinance.com', password: tPassword))
            .thenAnswer((_) async => mockUserCredential);
        when(() => mockUserCredential.user).thenReturn(mockUser);
        when(() => mockUser.uid).thenReturn(tUid);

        when(() => mockFirebaseFirestore.collection('users')).thenReturn(mockCollection);
        when(() => mockCollection.doc(tUid)).thenReturn(mockDocRef);
        when(() => mockDocRef.set(any())).thenAnswer((_) async => {});

        // Act (Gửi lên email bị khuyết @)
        final result = await authRepository.register('testuser', tPassword, 'Name', 'Corp', 'Tax');

        // Assert (Kiểm tra lại xem kết quả có đúng chuẩn format email không)
        expect(result, isNotNull);
        expect(result?.email, 'testuser@smartfinance.com');
        verify(() => mockFirebaseAuth.createUserWithEmailAndPassword(email: 'testuser@smartfinance.com', password: tPassword)).called(1);
      });

      test('successfully creates user even if optional string fields are empty (UI handles validation)', () async {
        // [CASE 4]: Test Đăng ký bị KHUYẾT các thông tin phụ rỗng rỗng (fullName, company, taxCode)
        // Do Repository không bắt buộc kiểm tra (Validation đã làm ở UI), nó vẫn phải lưu thành công các chuỗi rỗng
        
        // Arrange
        final mockUserCredential = MockUserCredential();
        final mockUser = MockUser();
        final mockCollection = MockCollectionReference();
        final mockDocRef = MockDocumentReference();

        when(() => mockFirebaseAuth.createUserWithEmailAndPassword(email: tEmail, password: tPassword))
            .thenAnswer((_) async => mockUserCredential);
        when(() => mockUserCredential.user).thenReturn(mockUser);
        when(() => mockUser.uid).thenReturn(tUid);

        when(() => mockFirebaseFirestore.collection('users')).thenReturn(mockCollection);
        when(() => mockCollection.doc(tUid)).thenReturn(mockDocRef);
        when(() => mockDocRef.set(any())).thenAnswer((_) async => {});

        // Act (Truyền toàn bộ các trường phụ là chuỗi rỗng '')
        final result = await authRepository.register(tEmail, tPassword, '', '', '');

        // Assert (Kiểm tra xem object trả về có giữ đúng các chuỗi rỗng không)
        expect(result, isNotNull);
        expect(result?.fullName, '');
        expect(result?.company, '');
        expect(result?.taxCode, '');
      });

      test('assigns custom role when provided', () async {
        // [CASE 5]: Test Đăng ký với chức vụ KHÔNG MẶC ĐỊNH (Custom Role)
        // Hệ thống phải đảm bảo tham số role ghi nhận chính xác theo yêu cầu (VD: Kế toán chi phí)
        
        // Arrange
        final mockUserCredential = MockUserCredential();
        final mockUser = MockUser();
        final mockCollection = MockCollectionReference();
        final mockDocRef = MockDocumentReference();

        when(() => mockFirebaseAuth.createUserWithEmailAndPassword(email: tEmail, password: tPassword))
            .thenAnswer((_) async => mockUserCredential);
        when(() => mockUserCredential.user).thenReturn(mockUser);
        when(() => mockUser.uid).thenReturn(tUid);

        when(() => mockFirebaseFirestore.collection('users')).thenReturn(mockCollection);
        when(() => mockCollection.doc(tUid)).thenReturn(mockDocRef);
        when(() => mockDocRef.set(any())).thenAnswer((_) async => {});

        // Act (Truyền explicit role là 'expenseAccountant')
        final result = await authRepository.register(tEmail, tPassword, 'Name', 'Corp', 'Tax', role: 'expenseAccountant');

        // Assert (Kiểm tra lại xem role có được gán thành công không)
        expect(result?.role, 'expenseAccountant');
      });

      test('throws Exception when password is too short (Firebase weak-password)', () async {
        // [CASE 6]: Test Đăng ký với mật khẩu LỖI/YẾU (Khuyết chuẩn mật khẩu)
        // Khi người dùng chỉ nhập "123", Firebase sẽ chặn lại và bắn ra exception 'weak-password'
        
        // Arrange (Cài mock quăng lỗi weak-password)
        when(() => mockFirebaseAuth.createUserWithEmailAndPassword(email: tEmail, password: '123'))
            .thenThrow(FirebaseAuthException(code: 'weak-password'));

        // Act & Assert
        expect(() => authRepository.register(tEmail, '123', 'Name', 'Corp', 'Tax'), throwsA(isA<Exception>()));
      });
    });

    group('signInWithGoogle', () {
      // Vì `signInWithGoogle` phân nhánh theo kIsWeb (bằng const bool.fromEnvironment('dart.library.js_util')),
      // môi trường Test mặc định (phiên bản VM của test) sẽ rơi vào nhánh else (Android / iOS native).
      
      test('returns UserModel when Google Sign-In is successful (Native path)', () async {
        // Arrange
        final mockGoogleAccount = MockGoogleSignInAccount();
        final mockGoogleAuth = MockGoogleSignInAuthentication();
        final mockUserCredential = MockUserCredential();
        final mockUser = MockUser();
        
        final mockCollection = MockCollectionReference();
        final mockDocRef = MockDocumentReference();
        final mockSnapshot = MockDocumentSnapshot();

        when(() => mockGoogleSignIn.authenticate()).thenAnswer((_) async => mockGoogleAccount);
        when(() => mockGoogleAccount.authentication).thenAnswer((_) => mockGoogleAuth);
        when(() => mockGoogleAuth.idToken).thenReturn('fake_id_token');

        when(() => mockFirebaseAuth.signInWithCredential(any())).thenAnswer((_) async => mockUserCredential);
        when(() => mockUserCredential.user).thenReturn(mockUser);
        when(() => mockUser.uid).thenReturn(tUid);
        when(() => mockUser.email).thenReturn(tEmail);
        when(() => mockUser.displayName).thenReturn('Google User');

        // Mock Firestore for an existing user
        when(() => mockFirebaseFirestore.collection('users')).thenReturn(mockCollection);
        when(() => mockCollection.doc(tUid)).thenReturn(mockDocRef);
        when(() => mockDocRef.get()).thenAnswer((_) async => mockSnapshot);
        when(() => mockSnapshot.exists).thenReturn(true);
        when(() => mockSnapshot.data()).thenReturn(tUserData);
        when(() => mockSnapshot.id).thenReturn(tUid);

        // Act
        final result = await authRepository.signInWithGoogle();

        // Assert
        expect(result, isNotNull);
        expect(result?.id, tUid);
        verify(() => mockGoogleSignIn.authenticate()).called(1);
        verify(() => mockFirebaseAuth.signInWithCredential(any())).called(1);
      });

      test('returns null if user cancels Google Sign-In', () async {
        // Arrange
        when(() => mockGoogleSignIn.authenticate()).thenThrow(Exception('Canceled by user'));

        // Act
        final result = await authRepository.signInWithGoogle();

        // Assert
        expect(result, isNull);
        verify(() => mockGoogleSignIn.authenticate()).called(1);
        verifyNever(() => mockFirebaseAuth.signInWithCredential(any()));
      });


    });

    group('updateUserInfo', () {
      test('cập nhật thành công thông tin user trên Firestore', () async {
        // Arrange
        final mockCollection = MockCollectionReference();
        final mockDocRef = MockDocumentReference();
        final updatedUser = UserModel.fromJson(tUserData, tUid).copyWith(fullName: 'New Name', avatarUrl: 'new_url');

        when(() => mockFirebaseFirestore.collection('users')).thenReturn(mockCollection);
        when(() => mockCollection.doc(tUid)).thenReturn(mockDocRef);
        when(() => mockDocRef.update(updatedUser.toJson())).thenAnswer((_) async => {});

        // Act
        await authRepository.updateUserInfo(updatedUser);

        // Assert
        verify(() => mockFirebaseFirestore.collection('users').doc(tUid).update(updatedUser.toJson())).called(1);
      });

      test('ném ra Exception khi Firestore cập nhật thất bại', () async {
        // Arrange
        final mockCollection = MockCollectionReference();
        final mockDocRef = MockDocumentReference();
        final updatedUser = UserModel.fromJson(tUserData, tUid);

        when(() => mockFirebaseFirestore.collection('users')).thenReturn(mockCollection);
        when(() => mockCollection.doc(tUid)).thenReturn(mockDocRef);
        when(() => mockDocRef.update(any())).thenThrow(Exception('Firestore error'));

        // Act & Assert
        expect(() => authRepository.updateUserInfo(updatedUser), throwsA(isA<Exception>()));
      });
    });

    group('changePassword', () {
      test('ném ra Exception khi người dùng chưa đăng nhập', () async {
        // Arrange
        when(() => mockFirebaseAuth.currentUser).thenReturn(null);

        // Act & Assert
        expect(() => authRepository.changePassword('old', 'new'), throwsA(isA<Exception>()));
      });

      test('đổi mật khẩu thành công khi mật khẩu cũ chính xác', () async {
        // Arrange
        final mockUser = MockUser();
        when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);
        when(() => mockUser.email).thenReturn(tEmail);
        
        // Mock reauthenticateWithCredential success
        when(() => mockUser.reauthenticateWithCredential(any())).thenAnswer((_) async => MockUserCredential());
        // Mock updatePassword success
        when(() => mockUser.updatePassword('newPassword123')).thenAnswer((_) async => {});

        // Act
        await authRepository.changePassword('oldPassword123', 'newPassword123');

        // Assert
        verify(() => mockUser.reauthenticateWithCredential(any())).called(1);
        verify(() => mockUser.updatePassword('newPassword123')).called(1);
      });

      test('ném ra Exception khi mật khẩu cũ sai', () async {
        // Arrange
        final mockUser = MockUser();
        when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);
        when(() => mockUser.email).thenReturn(tEmail);
        
        // Mock reauthenticate throwing wrong-password
        when(() => mockUser.reauthenticateWithCredential(any())).thenThrow(FirebaseAuthException(code: 'wrong-password'));

        // Act & Assert
        expect(() => authRepository.changePassword('wrongOld', 'newPass'), throwsA(isA<Exception>()));
      });

      test('ném ra Exception khi mật khẩu mới quá yếu', () async {
        // Arrange
        final mockUser = MockUser();
        when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);
        when(() => mockUser.email).thenReturn(tEmail);
        
        when(() => mockUser.reauthenticateWithCredential(any())).thenAnswer((_) async => MockUserCredential());
        // Mock updatePassword throwing weak-password
        when(() => mockUser.updatePassword('123')).thenThrow(FirebaseAuthException(code: 'weak-password'));

        // Act & Assert
        expect(() => authRepository.changePassword('oldPass', '123'), throwsA(isA<Exception>()));
      });
    });

    group('logout', () {
      test('calls signOut on both GoogleSignIn and FirebaseAuth', () async {
        // Arrange
        final mockAccount = MockGoogleSignInAccount();
        when(() => mockGoogleSignIn.signOut()).thenAnswer((_) async => mockAccount);
        when(() => mockFirebaseAuth.signOut()).thenAnswer((_) async => {});

        // Act
        await authRepository.logout();

        // Assert
        verify(() => mockGoogleSignIn.signOut()).called(1);
        verify(() => mockFirebaseAuth.signOut()).called(1);
      });
    });
  });
}
