import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/finsmart_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    // Wait for splash timeout
    await Future.delayed(const Duration(milliseconds: 2200));
    if (mounted) {
      context.go('/welcome');
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
