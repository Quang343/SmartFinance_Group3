import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/scale_on_tap.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleResetPassword() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Yêu cầu khôi phục mật khẩu đã được gửi đến: ${_emailController.text}'),
          backgroundColor: Colors.green,
        ),
      );
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final primaryColor = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    // Design-matched colors
    final Color topBgColor = primaryColor;
    final Color bottomCardColor = isDark ? const Color(0xFF0C2C1F) : const Color(0xFFF5FAF6);
    final Color inputFillColor = isDark ? const Color(0xFF06150F) : const Color(0xFFE2F3EB);
    final Color textColorDark = const Color(0xFF0A231A);
    final Color textButtonColor = isDark ? Colors.white : const Color(0xFF0A231A);
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
                          Icons.lock_reset,
                          size: 96,
                          color: primaryColor,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Khôi phục tài khoản của bạn',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nhập email đã đăng ký của bạn để bắt đầu quá trình khôi phục mật khẩu nhanh chóng và an toàn.',
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

          // Main Forgot Password UI Frame
          Expanded(
            flex: size.width >= 900 ? 0 : 1,
            child: Container(
              width: size.width >= 900 ? 500 : double.infinity,
              color: topBgColor,
              child: Column(
                children: [
                  // Top Header ("Quên mật khẩu" text)
                  Container(
                    height: size.height * 0.25,
                    width: double.infinity,
                    alignment: Alignment.center,
                    child: SafeArea(
                      bottom: false,
                      child: Text(
                        'Quên mật khẩu',
                        style: theme.textTheme.headlineLarge?.copyWith(
                          color: textColorDark,
                          fontWeight: FontWeight.w800,
                          fontSize: 32,
                        ),
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
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Subtitle & Instruction text
                              Text(
                                'Đặt lại mật khẩu?',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : textColorDark,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Vui lòng nhập địa chỉ email đã đăng ký của bạn. Chúng tôi sẽ gửi hướng dẫn khôi phục mật khẩu qua email.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark ? Colors.white60 : Colors.black54,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 36),

                              // Email Input field
                              Text(
                                'Nhập địa chỉ Email',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: labelColor,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  hintText: 'example@example.com',
                                  hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.black38),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: inputFillColor,
                                  prefixIcon: Icon(Icons.email_outlined, color: labelColor),
                                ),
                                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Vui lòng nhập địa chỉ email';
                                  }
                                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                    return 'Định dạng email không hợp lệ';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),

                              // Next Step Button
                              ScaleOnTap(
                                onTap: _handleResetPassword,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  decoration: BoxDecoration(
                                    color: primaryColor,
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'Tiếp theo',
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

                              // Sign Up Button
                              ScaleOnTap(
                                onTap: () => context.go('/register'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
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
                                        color: isDark ? Colors.white : Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Social options
                              Center(
                                child: Text(
                                  'hoặc đăng ký bằng',
                                  style: TextStyle(
                                    color: isDark ? Colors.white54 : Colors.grey.shade600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
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
                                            color: Colors.black.withOpacity(0.1),
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
                                            color: Colors.black.withOpacity(0.1),
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
                              const SizedBox(height: 24),

                              // Link to back to login
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Quay lại ',
                                    style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      context.go('/login');
                                    },
                                    child: Text(
                                      'Đăng nhập ngay',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: textButtonColor,
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
      ..cubicTo(13.94 * scale, 5.04 * scale, 15.51 * scale, 5.76 * scale, 16.67 * scale, 6.87 * scale)
      ..lineTo(20.15 * scale, 3.39 * scale)
      ..cubicTo(17.97 * scale, 1.38 * scale, 15.17 * scale, 0.5 * scale, 12 * scale, 0.5 * scale)
      ..cubicTo(7.46 * scale, 0.5 * scale, 3.52 * scale, 3.1 * scale, 1.54 * scale, 6.9 * scale)
      ..lineTo(5.63 * scale, 10.08 * scale)
      ..cubicTo(6.59 * scale, 7.37 * scale, 9.06 * scale, 5.04 * scale, 12 * scale, 5.04 * scale)
      ..close();
    canvas.drawPath(path1, paint);

    // Path 2: Green bottom arc
    paint.color = const Color(0xFF34A853);
    final path2 = Path()
      ..moveTo(12 * scale, 18.96 * scale)
      ..cubicTo(9.06 * scale, 18.96 * scale, 6.59 * scale, 16.63 * scale, 5.63 * scale, 13.92 * scale)
      ..lineTo(1.54 * scale, 17.1 * scale)
      ..cubicTo(3.52 * scale, 20.9 * scale, 7.46 * scale, 23.5 * scale, 12 * scale, 23.5 * scale)
      ..cubicTo(15.14 * scale, 23.5 * scale, 18.02 * scale, 22.37 * scale, 20.08 * scale, 20.39 * scale)
      ..lineTo(16.2 * scale, 17.38 * scale)
      ..cubicTo(15.11 * scale, 18.11 * scale, 13.67 * scale, 18.96 * scale, 12 * scale, 18.96 * scale)
      ..close();
    canvas.drawPath(path2, paint);

    // Path 3: Yellow left arc
    paint.color = const Color(0xFFFBBC05);
    final path3 = Path()
      ..moveTo(5.63 * scale, 13.92 * scale)
      ..cubicTo(5.39 * scale, 13.19 * scale, 5.25 * scale, 12.41 * scale, 5.25 * scale, 11.5 * scale)
      ..cubicTo(5.25 * scale, 10.59 * scale, 5.39 * scale, 9.81 * scale, 5.63 * scale, 9.08 * scale)
      ..lineTo(1.54 * scale, 6.1 * scale)
      ..cubicTo(0.56 * scale, 8.06 * scale, 0 * scale, 10.22 * scale, 0 * scale, 12.5 * scale)
      ..cubicTo(0 * scale, 14.78 * scale, 0.56 * scale, 16.94 * scale, 1.54 * scale, 18.9 * scale)
      ..lineTo(5.63 * scale, 13.92 * scale)
      ..close();
    canvas.drawPath(path3, paint);

    // Path 4: Blue right arc and bar
    paint.color = const Color(0xFF4285F4);
    final path4 = Path()
      ..moveTo(23.5 * scale, 12.5 * scale)
      ..cubicTo(23.5 * scale, 11.67 * scale, 23.43 * scale, 10.87 * scale, 23.3 * scale, 10.1 * scale)
      ..lineTo(12 * scale, 10.1 * scale)
      ..lineTo(12 * scale, 14.7 * scale)
      ..lineTo(18.5 * scale, 14.7 * scale)
      ..cubicTo(18.22 * scale, 16.14 * scale, 17.4 * scale, 17.36 * scale, 16.2 * scale, 18.17 * scale)
      ..lineTo(20.08 * scale, 21.18 * scale)
      ..cubicTo(22.34 * scale, 19.34 * scale, 23.5 * scale, 16.18 * scale, 23.5 * scale, 12.5 * scale)
      ..close();
    canvas.drawPath(path4, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
