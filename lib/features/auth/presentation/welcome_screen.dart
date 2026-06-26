import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/scale_on_tap.dart';
import '../../../core/widgets/finsmart_logo.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Harmonious Spendly Green palette colors
    final Color primaryColor = theme.colorScheme.primary;
    final Color bgWelcomeColor = isDark
        ? const Color(0xFF06150F)
        : const Color(0xFFF4FBF7);
    final Color textColor = isDark ? Colors.white : const Color(0xFF0A231A);
    final Color buttonRegisterBg = isDark
        ? const Color(0xFF0C251C)
        : const Color(0xFFE2F6EE);

    return Scaffold(
      backgroundColor: bgWelcomeColor,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 450),
            padding: const EdgeInsets.symmetric(
              horizontal: 32.0,
              vertical: 48.0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. App Logo (Custom Painted FinSmart Logo)
                Center(child: FinSmartLogo(size: 130, color: primaryColor)),
                const SizedBox(height: 20),

                // 2. App Name
                Text(
                  'FinSmart',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: primaryColor,
                    fontSize: 40,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // 3. Subtitle / Description in Vietnamese
                Text(
                  'Quản lý tài chính thông minh,\nan tâm tích lũy và phát triển doanh nghiệp.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: isDark ? Colors.white70 : const Color(0xFF4A5D56),
                    height: 1.5,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 60),

                // 4. Log In Button (Log In pill)
                ScaleOnTap(
                  onTap: () {
                    context.go('/login');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'Đăng nhập',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 5. Sign Up Button (Sign Up pill)
                ScaleOnTap(
                  onTap: () {
                    context.go('/register');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      color: buttonRegisterBg,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Center(
                      child: Text(
                        'Đăng ký tài khoản',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 6. Forgot Password text button
                Center(
                  child: TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text(
                            'Tính năng khôi phục mật khẩu đang được phát triển.',
                          ),
                          backgroundColor: primaryColor,
                        ),
                      );
                    },
                    child: Text(
                      'Quên mật khẩu?',
                      style: TextStyle(
                        color: isDark
                            ? const Color.fromARGB(153, 18, 12, 12)
                            : Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
