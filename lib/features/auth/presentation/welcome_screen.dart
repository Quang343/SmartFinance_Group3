import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/scale_on_tap.dart';
import '../../../core/widgets/finsmart_logo.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color primaryColor = theme.colorScheme.primary;
    final Color buttonRegisterBg = isDark
        ? const Color(0xFF0C251C).withOpacity(0.85)
        : const Color(0xFFE2F6EE).withOpacity(0.95);

    return Scaffold(
      body: Stack(
        children: [
          // Background Image with subtle zoom-out animation
          Positioned.fill(
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 1.1, end: 1.0),
              duration: const Duration(seconds: 4),
              curve: Curves.easeOutCubic,
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: Image.asset(
                    'assets/images/finance_bg.png',
                    fit: BoxFit.cover,
                  ),
                );
              },
            ),
          ),
          
          // Gradient Overlay to ensure text readability
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    (isDark ? Colors.black : Colors.white).withOpacity(0.75),
                    (isDark ? Colors.black : Colors.white).withOpacity(0.95),
                  ],
                ),
              ),
            ),
          ),

          // Main Content
          Center(
            child: SingleChildScrollView(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 450),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32.0,
                  vertical: 48.0,
                ),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 1. App Logo
                        Center(
                          child: Hero(
                            tag: 'finsmart_logo',
                            child: FinSmartLogo(size: 130, color: primaryColor),
                          ),
                        ),
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

                        // 3. Subtitle / Description
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

                        // 4. Log In Button
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
                                  color: primaryColor.withOpacity(0.4),
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
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 5. Sign Up Button
                        ScaleOnTap(
                          onTap: () {
                            context.go('/register');
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            decoration: BoxDecoration(
                              color: buttonRegisterBg,
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: primaryColor.withOpacity(0.2),
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'Đăng ký tài khoản',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : const Color(0xFF0A231A),
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
                              context.go('/forgot-password');
                            },
                            child: Text(
                              'Quên mật khẩu?',
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white54
                                    : Colors.grey.shade700,
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
            ),
          ),
        ],
      ),
    );
  }
}
