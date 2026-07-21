import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_finance/core/widgets/responsive_layout.dart';
import 'package:smart_finance/core/providers/auth_provider.dart';
import 'package:smart_finance/core/providers/role_provider.dart';
import 'package:smart_finance/data/repositories/auth_repository.dart';
import 'package:smart_finance/data/models/user_model.dart';
import 'package:smart_finance/app/router.dart';

class MockAuthRepository extends Mock implements AuthRepository {}
class MockGoRouter extends Mock implements GoRouter {}

void main() {
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    when(() => mockAuthRepository.logout()).thenAnswer((_) async {});
  });

  testWidgets('Logout button on Desktop navigates to /welcome and clears state', (tester) async {
    final user = UserModel(
      id: '1',
      email: 'test@test.com',
      fullName: 'Test',
      role: 'financeManager',
      company: 'test_company',
      taxCode: '',
      phone: '',
      address: '',
      bankName: '',
      bankAccount: '',
    );

    final router = GoRouter(
      initialLocation: '/dashboard',
      routes: [
        GoRoute(
          path: '/welcome',
          builder: (context, state) => const Text('Welcome Screen'),
        ),
        ShellRoute(
          builder: (context, state, child) => ResponsiveLayout(child: child),
          routes: [
            GoRoute(
              path: '/dashboard',
              builder: (context, state) => const Text('Dashboard Content'),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepository),
          currentUserProvider.overrideWith((ref) => user),
        ],
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify we are on desktop layout (it renders NavigationRail on large screens)
    // We need to set surface size to simulate desktop
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    
    await tester.pumpAndSettle();

    final logoutIcon = find.byIcon(Icons.logout_rounded);
    expect(logoutIcon, findsOneWidget);

    // Tap logout
    await tester.tap(logoutIcon);
    await tester.pump(); // Start async gap
    await tester.pump(const Duration(milliseconds: 150)); // Advance delayed future
    await tester.pumpAndSettle(); // Settle navigation

    expect(find.text('Welcome Screen'), findsOneWidget);
    verify(() => mockAuthRepository.logout()).called(1);
    
    // Reset view
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
