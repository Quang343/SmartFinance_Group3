import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_finance/features/auth/presentation/splash_screen.dart';
import 'package:smart_finance/core/providers/auth_provider.dart';
import 'package:smart_finance/data/repositories/auth_repository.dart';
import 'package:smart_finance/data/models/user_model.dart';
import 'package:go_router/go_router.dart';

// --- Mocks ---
class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockUser extends Mock implements User {}
class MockAuthRepository extends Mock implements AuthRepository {}

// Unit test by HoangDH
void main() {
  late MockFirebaseAuth mockFirebaseAuth;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockFirebaseAuth = MockFirebaseAuth();
    mockAuthRepository = MockAuthRepository();
  });

  Widget createWidgetUnderTest() {
    final router = GoRouter(
      initialLocation: '/splash',
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const Scaffold(body: Text('Dashboard Screen')),
        ),
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const Scaffold(body: Text('Onboarding Screen')),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        firebaseAuthProvider.overrideWithValue(mockFirebaseAuth),
        authRepositoryProvider.overrideWithValue(mockAuthRepository),
      ],
      child: MaterialApp.router(
        routerConfig: router,
      ),
    );
  }

  group('SplashScreen Auto-Login Tests', () {
    testWidgets('Chuyển thẳng sang Dashboard nếu đã đăng nhập (có cache Firebase Auth)', (tester) async {
      // Arrange: Giả lập đã có user lưu trong cache Firebase Auth
      final mockUser = MockUser();
      when(() => mockUser.uid).thenReturn('user123');
      when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);
      
      // Giả lập lấy dữ liệu user từ Firestore thành công
      when(() => mockAuthRepository.getUserData('user123')).thenAnswer(
        (_) async => UserModel(
          id: 'user123',
          email: 'test@example.com',
          fullName: 'Test User',
          role: 'admin',
          company: 'Công ty Test',
          taxCode: '123456',
        ),
      );

      // Act: Mở SplashScreen
      await tester.pumpWidget(createWidgetUnderTest());
      
      // Chờ 2.5 giây cho hiệu ứng splash chạy xong
      await tester.pumpAndSettle(const Duration(milliseconds: 2500));

      // Assert: Phải tìm thấy chữ 'Dashboard Screen' (chứng tỏ đã chuyển trang thành công)
      expect(find.text('Dashboard Screen'), findsOneWidget);
      expect(find.text('Onboarding Screen'), findsNothing);
    });

    testWidgets('Chuyển sang Onboarding nếu CHƯA đăng nhập (FirebaseAuth rỗng)', (tester) async {
      // Arrange: Giả lập chưa đăng nhập
      when(() => mockFirebaseAuth.currentUser).thenReturn(null);

      // Act: Mở SplashScreen
      await tester.pumpWidget(createWidgetUnderTest());
      
      // Chờ 2.5 giây
      await tester.pumpAndSettle(const Duration(milliseconds: 2500));

      // Assert: Phải tìm thấy chữ 'Onboarding Screen'
      expect(find.text('Onboarding Screen'), findsOneWidget);
      expect(find.text('Dashboard Screen'), findsNothing);
    });
  });
}
