import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/role_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/widgets/scale_on_tap.dart';
import '../../../data/repositories/auth_repository.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      try {
        final email = _emailController.text.trim();
        final password = _passwordController.text;

        final user = await ref.read(authRepositoryProvider).login(email, password);

        if (user != null) {
          ref.read(currentUserProvider.notifier).state = user;
          
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đăng nhập thành công!'),
              backgroundColor: Colors.green,
            ),
          );
          context.go('/dashboard');
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Email hoặc mật khẩu không chính xác'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildMockAccountChip(String label, String username, String password, Color primaryColor) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      backgroundColor: primaryColor.withOpacity(0.2),
      side: BorderSide.none,
      onPressed: () {
        _emailController.text = username;
        _passwordController.text = password;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final primaryColor = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    // Design-matched colors
    final Color topBgColor = primaryColor;
    final Color bottomCardColor = isDark
        ? const Color(0xFF0C2C1F)
        : const Color(0xFFF5FAF6);
    final Color inputFillColor = isDark
        ? const Color(0xFF06150F)
        : const Color(0xFFE2F3EB);
    final Color textColorDark = const Color(0xFF0A231A);
    final Color textButtonColor = isDark
        ? Colors.white
        : const Color(0xFF0A231A);
    final Color labelColor = isDark ? Colors.white70 : const Color(0xFF2C5E43);

    return Scaffold(
      backgroundColor: topBgColor,
      body: Row(
        children: [
          // Left side: Illustration (Desktop only)
          if (size.width >= 900)
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF0C2C1F), const Color(0xFF06150F)]
                        : [const Color(0xFFECFDF5), Colors.blue.shade50],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(48.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.analytics_outlined,
                          size: 96,
                          color: primaryColor,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Hệ thống quản lý tài chính doanh nghiệp B2B',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF1A1A2E),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Theo dõi dòng tiền, quét hóa đơn thông minh bằng công nghệ OCR và lập báo cáo tài chính chuyên nghiệp.',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: isDark ? Colors.white60 : Colors.black54,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Main Login UI Frame (Desktop gets standard width, Mobile gets full screen)
          Expanded(
            flex: size.width >= 900 ? 0 : 1,
            child: Container(
              width: size.width >= 900 ? 500 : double.infinity,
              color: topBgColor,
              child: Column(
                children: [
                  // Top Header (Animated Logo and Welcome text)
                  Container(
                    height: size.height * 0.3,
                    width: double.infinity,
                    alignment: Alignment.center,
                    child: SafeArea(
                      bottom: false,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 1000),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return Transform.translate(
                            offset: Offset(0, 40 * (1 - value)),
                            child: Opacity(
                              opacity: value,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Financial Logo
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: textColorDark.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.auto_graph_rounded,
                                      size: 56,
                                      color: textColorDark,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  // App Name
                                  Text(
                                    'FinSmart',
                                    style: theme.textTheme.headlineLarge?.copyWith(
                                      color: textColorDark,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 32,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // Subtitle
                                  Text(
                                    'Đăng nhập để tiếp tục',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      color: textColorDark.withOpacity(0.8),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // Bottom white/cream rounded container
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: bottomCardColor,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(40),
                          topRight: Radius.circular(40),
                        ),
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 36,
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // MOCK TEST ACCOUNTS (TO BE REMOVED)
                              Container(
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(bottom: 24),
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: primaryColor.withOpacity(0.3)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Tài khoản Test (Bấm để điền):',
                                      style: TextStyle(
                                        color: isDark ? Colors.white70 : Colors.black87,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        _buildMockAccountChip('Quản lý', 'manager', '123', primaryColor),
                                        _buildMockAccountChip('KT Chi phí', 'expense', '123', primaryColor),
                                        _buildMockAccountChip('KT Doanh thu', 'revenue', '123', primaryColor),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // 2. Email/Username Label & Textfield
                              Text(
                                'Tên đăng nhập hoặc Email',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: labelColor,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _emailController,
                                decoration: InputDecoration(
                                  hintText: 'example@example.com',
                                  hintStyle: TextStyle(
                                    color: isDark
                                        ? Colors.white30
                                        : Colors.black38,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: inputFillColor,
                                  prefixIcon: Icon(
                                    Icons.email_outlined,
                                    color: labelColor,
                                  ),
                                ),
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Vui lòng nhập tên đăng nhập hoặc email';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),

                              // 3. Password Label & Textfield
                              Text(
                                'Mật khẩu',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: labelColor,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: inputFillColor,
                                  prefixIcon: Icon(
                                    Icons.lock_outlined,
                                    color: labelColor,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: labelColor,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                ),
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Vui lòng nhập mật khẩu';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),

                              // 4. Log In Button (Solid Green Pill)
                              ScaleOnTap(
                                onTap: _handleLogin,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: primaryColor,
                                    borderRadius: BorderRadius.circular(30),
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
                              const SizedBox(height: 12),

                              // 5. Forgot Password Button
                              Center(
                                child: TextButton(
                                  onPressed: () {
                                    context.go('/forgot-password');
                                  },
                                  child: Text(
                                    'Quên mật khẩu?',
                                    style: TextStyle(
                                      color: textButtonColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),

                              // 6. Sign Up Button (Light Green Pill)
                              ScaleOnTap(
                                onTap: () => context.go('/register'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: inputFillColor,
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Đăng ký tài khoản',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // 7. Fingerprint option
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.fingerprint,
                                    color: primaryColor,
                                    size: 28,
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Đang quét vân tay...'),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      'Sử dụng Vân tay để truy cập',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: textButtonColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // 8. Social Login
                              Center(
                                child: Text(
                                  'hoặc đăng ký bằng',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white54
                                        : Colors.grey.shade600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Facebook Icon Button
                                  GestureDetector(
                                    onTap: () {},
                                    child: Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1877F2),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.1,
                                            ),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      alignment: Alignment.bottomCenter,
                                      child: const Text(
                                        'f',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 36,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Arial',
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  // Google Icon Button
                                  GestureDetector(
                                    onTap: () {},
                                    child: Container(
                                      width: 48,
                                      height: 48,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.1,
                                            ),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const CustomPaint(
                                        painter: GoogleLogoPainter(),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GoogleLogoPainter extends CustomPainter {
  const GoogleLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final double scale = size.width / 24.0;
    final paint = Paint()..style = PaintingStyle.fill;

    // Path 1: Red top arc
    paint.color = const Color(0xFFEA4335);
    final path1 = Path()
      ..moveTo(12 * scale, 5.04 * scale)
      ..cubicTo(
        13.94 * scale,
        5.04 * scale,
        15.51 * scale,
        5.76 * scale,
        16.67 * scale,
        6.87 * scale,
      )
      ..lineTo(20.15 * scale, 3.39 * scale)
      ..cubicTo(
        17.97 * scale,
        1.38 * scale,
        15.17 * scale,
        0.5 * scale,
        12 * scale,
        0.5 * scale,
      )
      ..cubicTo(
        7.46 * scale,
        0.5 * scale,
        3.52 * scale,
        3.1 * scale,
        1.54 * scale,
        6.9 * scale,
      )
      ..lineTo(5.63 * scale, 10.08 * scale)
      ..cubicTo(
        6.59 * scale,
        7.37 * scale,
        9.06 * scale,
        5.04 * scale,
        12 * scale,
        5.04 * scale,
      )
      ..close();
    canvas.drawPath(path1, paint);

    // Path 2: Green bottom arc
    paint.color = const Color(0xFF34A853);
    final path2 = Path()
      ..moveTo(12 * scale, 18.96 * scale)
      ..cubicTo(
        9.06 * scale,
        18.96 * scale,
        6.59 * scale,
        16.63 * scale,
        5.63 * scale,
        13.92 * scale,
      )
      ..lineTo(1.54 * scale, 17.1 * scale)
      ..cubicTo(
        3.52 * scale,
        20.9 * scale,
        7.46 * scale,
        23.5 * scale,
        12 * scale,
        23.5 * scale,
      )
      ..cubicTo(
        15.14 * scale,
        23.5 * scale,
        18.02 * scale,
        22.37 * scale,
        20.08 * scale,
        20.39 * scale,
      )
      ..lineTo(16.2 * scale, 17.38 * scale)
      ..cubicTo(
        15.11 * scale,
        18.11 * scale,
        13.67 * scale,
        18.96 * scale,
        12 * scale,
        18.96 * scale,
      )
      ..close();
    canvas.drawPath(path2, paint);

    // Path 3: Yellow left arc
    paint.color = const Color(0xFFFBBC05);
    final path3 = Path()
      ..moveTo(5.63 * scale, 13.92 * scale)
      ..cubicTo(
        5.39 * scale,
        13.19 * scale,
        5.25 * scale,
        12.41 * scale,
        5.25 * scale,
        11.5 * scale,
      )
      ..cubicTo(
        5.25 * scale,
        10.59 * scale,
        5.39 * scale,
        9.81 * scale,
        5.63 * scale,
        9.08 * scale,
      )
      ..lineTo(1.54 * scale, 6.1 * scale)
      ..cubicTo(
        0.56 * scale,
        8.06 * scale,
        0 * scale,
        10.22 * scale,
        0 * scale,
        12.5 * scale,
      )
      ..cubicTo(
        0 * scale,
        14.78 * scale,
        0.56 * scale,
        16.94 * scale,
        1.54 * scale,
        18.9 * scale,
      )
      ..lineTo(5.63 * scale, 13.92 * scale)
      ..close();
    canvas.drawPath(path3, paint);

    // Path 4: Blue right arc and bar
    paint.color = const Color(0xFF4285F4);
    final path4 = Path()
      ..moveTo(23.5 * scale, 12.5 * scale)
      ..cubicTo(
        23.5 * scale,
        11.67 * scale,
        23.43 * scale,
        10.87 * scale,
        23.3 * scale,
        10.1 * scale,
      )
      ..lineTo(12 * scale, 10.1 * scale)
      ..lineTo(12 * scale, 14.7 * scale)
      ..lineTo(18.5 * scale, 14.7 * scale)
      ..cubicTo(
        18.22 * scale,
        16.14 * scale,
        17.4 * scale,
        17.36 * scale,
        16.2 * scale,
        18.17 * scale,
      )
      ..lineTo(20.08 * scale, 21.18 * scale)
      ..cubicTo(
        22.34 * scale,
        19.34 * scale,
        23.5 * scale,
        16.18 * scale,
        23.5 * scale,
        12.5 * scale,
      )
      ..close();
    canvas.drawPath(path4, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
