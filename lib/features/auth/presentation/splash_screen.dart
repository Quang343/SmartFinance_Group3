import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/widgets/finsmart_logo.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../data/repositories/auth_repository.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigateToNext();
    });
  }

  Future<void> _navigateToNext() async {
    if (mounted) {
      // Auto-login (Offline persistence support)
      final firebaseUser = ref.read(firebaseAuthProvider).currentUser;
      
      if (firebaseUser != null) {
        try {
          // Fetch from Firestore (will use local cache if offline)
          final userModel = await ref.read(authRepositoryProvider).getUserData(firebaseUser.uid);
          
          if (userModel != null && mounted) {
            // Restore session
            ref.read(currentUserProvider.notifier).state = userModel;
            context.go('/dashboard');
            return;
          }
        } catch (e) {
          print('Lỗi khôi phục phiên đăng nhập: $e');
        }
      }
      
      // If no valid session, go to onboarding/login
      if (mounted) {
        context.go('/onboarding');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Spendly-inspired emerald launch background
    final Color bgLaunchA = isDark ? const Color(0xFF06150F) : theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: bgLaunchA,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // White logo on launch background
            FinSmartLogo(
              size: 130,
              color: Colors.white,
            ),
            const SizedBox(height: 20),
            const Text(
              'FinSmart',
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
