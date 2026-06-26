import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/role_provider.dart';
import '../../../core/widgets/scale_on_tap.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'manager@smartfinance.com');
  final _passwordController = TextEditingController(text: '******');
  UserRole _selectedRole = UserRole.financeManager;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onRoleChanged(UserRole role) {
    setState(() {
      _selectedRole = role;
      switch (role) {
        case UserRole.financeManager:
          _emailController.text = 'manager@smartfinance.com';
          break;
        case UserRole.expenseAccountant:
          _emailController.text = 'expense@smartfinance.com';
          break;
        case UserRole.revenueAccountant:
          _emailController.text = 'revenue@smartfinance.com';
          break;
      }
    });
  }

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      ref.read(roleProvider.notifier).state = _selectedRole;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đăng nhập thành công với vai trò: ${_selectedRole.nameVi}'),
          backgroundColor: Colors.green,
        ),
      );
      context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final Color accentColor = theme.colorScheme.primary;
    final Color bgForestColor = const Color(0xFF06150F);

    return Scaffold(
      backgroundColor: isDark ? bgForestColor : Colors.grey.shade50,
      body: Row(
        children: [
          // Left side: Illustration (Desktop only, with forest green gradient glow)
          if (MediaQuery.of(context).size.width >= 900)
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF0C2C1F), bgForestColor]
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
                          color: accentColor,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Hệ thống quản lý tài chính doanh nghiệp B2B',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                              ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Theo dõi dòng tiền, quét hóa đơn thông minh bằng công nghệ OCR và lập báo cáo tài chính chuyên nghiệp.',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
          
          // Right side: Login Form
          Expanded(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 450),
                padding: const EdgeInsets.all(32.0),
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (MediaQuery.of(context).size.width < 900) ...[
                          Icon(
                            Icons.analytics_outlined,
                            size: 48,
                            color: accentColor,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'SmartFinance B2B',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: accentColor,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                        ],
                        Text(
                          'Chào mừng trở lại',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Đăng nhập để quản lý tài chính doanh nghiệp của bạn',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                        ),
                        const SizedBox(height: 32),
                        
                        // Role Selection Dropdown
                        Text(
                          'Chọn vai trò truy cập (Demo)',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<UserRole>(
                          value: _selectedRole,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: accentColor, width: 2),
                            ),
                            filled: true,
                            fillColor: isDark ? const Color(0xFF0E1F16) : Colors.grey.shade50,
                            prefixIcon: Icon(Icons.badge_outlined, color: isDark ? accentColor.withOpacity(0.7) : Colors.grey),
                          ),
                          items: UserRole.values.map((role) {
                            return DropdownMenuItem<UserRole>(
                              value: role,
                              child: Text(role.nameVi),
                            );
                          }).toList(),
                          onChanged: (role) {
                            if (role != null) _onRoleChanged(role);
                          },
                        ),
                        const SizedBox(height: 20),
                        
                        // Email Field
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Email công việc',
                            labelStyle: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                            prefixIcon: Icon(Icons.email_outlined, color: isDark ? accentColor.withOpacity(0.7) : Colors.grey),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: accentColor, width: 2),
                            ),
                            filled: true,
                            fillColor: isDark ? const Color(0xFF0E1F16) : Colors.transparent,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Vui lòng nhập email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        
                        // Password Field
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Mật khẩu',
                            labelStyle: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                            prefixIcon: Icon(Icons.lock_outlined, color: isDark ? accentColor.withOpacity(0.7) : Colors.grey),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: accentColor, width: 2),
                            ),
                            filled: true,
                            fillColor: isDark ? const Color(0xFF0E1F16) : Colors.transparent,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Vui lòng nhập mật khẩu';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 32),
                        
                        // Login Button with bouncing ScaleOnTap
                        ScaleOnTap(
                          onTap: _handleLogin,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: accentColor,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: accentColor.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                'Đăng nhập',
                                style: TextStyle(
                                  fontSize: 16, 
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? bgForestColor : Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Chưa có tài khoản?'),
                            TextButton(
                              onPressed: () {
                                context.go('/register');
                              },
                              child: Text(
                                'Đăng ký ngay',
                                style: TextStyle(fontWeight: FontWeight.bold, color: accentColor),
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
          ),
        ],
      ),
    );
  }
}
