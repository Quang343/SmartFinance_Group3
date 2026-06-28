import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:smart_finance/data/local/isar_models/isar_user.dart';
import 'package:smart_finance/data/repositories/auth_repository.dart';

void main() {
  late Isar isar;
  late AuthRepository authRepository;
  late Directory tempDir;

  // Khởi tạo Isar Core cho môi trường Test (chỉ chạy 1 lần)
  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
  });

  // Chạy trước mỗi test case: Tạo DB nháp
  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('isar_test_auth');
    isar = await Isar.open(
      [IsarUserSchema],
      directory: tempDir.path,
    );
    authRepository = AuthRepository(isar);
  });

  // Dọn dẹp sau mỗi test case: Xóa DB nháp
  tearDown(() async {
    await isar.close(deleteFromDisk: true);
  });

  group('Authentication Tests (Login & Register)', () {
    test('1. Đăng ký thành công tài khoản mới', () async {
      final newUser = IsarUser()
        ..email = 'test@example.com'
        ..password = '123456'
        ..fullName = 'Nguyen Van Test'
        ..company = 'Test Co'
        ..taxCode = '123'
        ..role = 'financeManager';

      await authRepository.register(newUser);

      final userInDb = await isar.isarUsers.filter().emailEqualTo('test@example.com').findFirst();
      expect(userInDb, isNotNull);
      expect(userInDb!.fullName, 'Nguyen Van Test');
    });

    test('2. Đăng ký thất bại khi trùng Email', () async {
      final user1 = IsarUser()
        ..email = 'duplicate@example.com'
        ..password = '123'
        ..fullName = 'User 1'
        ..company = 'Co 1'
        ..taxCode = '111'
        ..role = 'expenseAccountant';
      
      final user2 = IsarUser()
        ..email = 'duplicate@example.com'
        ..password = '456'
        ..fullName = 'User 2'
        ..company = 'Co 2'
        ..taxCode = '222'
        ..role = 'revenueAccountant';

      await authRepository.register(user1);

      // Kỳ vọng ném ra Exception khi đăng ký user2
      expect(
        () async => await authRepository.register(user2),
        throwsA(isA<Exception>()),
      );
    });

    test('3. Đăng nhập thành công bằng Full Email', () async {
      // Seed data
      await authRepository.register(IsarUser()
        ..email = 'admin@example.com'
        ..password = 'admin123'
        ..fullName = 'Admin'
        ..company = 'Admin Co'
        ..taxCode = '000'
        ..role = 'financeManager');

      final result = await authRepository.login('admin@example.com', 'admin123');
      
      expect(result, isNotNull);
      expect(result!.email, 'admin@example.com');
    });

    test('4. Đăng nhập thành công bằng Username (chữ trước @)', () async {
      // Seed data
      await authRepository.register(IsarUser()
        ..email = 'manager@smartfinance.com'
        ..password = '123'
        ..fullName = 'Manager'
        ..company = 'Manager Co'
        ..taxCode = '111'
        ..role = 'financeManager');

      // Thử đăng nhập chỉ bằng 'manager' thay vì 'manager@smartfinance.com'
      final result = await authRepository.login('manager', '123');
      
      expect(result, isNotNull);
      expect(result!.email, 'manager@smartfinance.com');
    });

    test('5. Đăng nhập thất bại do sai mật khẩu', () async {
      // Seed data
      await authRepository.register(IsarUser()
        ..email = 'user@example.com'
        ..password = 'correct_password'
        ..fullName = 'User'
        ..company = 'Co'
        ..taxCode = '1'
        ..role = 'financeManager');

      final result = await authRepository.login('user@example.com', 'wrong_password');
      
      expect(result, isNull);
    });

    test('6. Đăng nhập thất bại do tài khoản không tồn tại', () async {
      final result = await authRepository.login('nonexistent@example.com', '123');
      
      expect(result, isNull);
    });
  });
}
