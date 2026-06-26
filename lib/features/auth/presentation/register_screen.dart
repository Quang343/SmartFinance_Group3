import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/role_provider.dart';
import '../../../core/widgets/scale_on_tap.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _companyController = TextEditingController();
  final _taxCodeController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  UserRole _selectedRole = UserRole.financeManager;
  bool _agreeToTerms = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _companyController.dispose();
    _taxCodeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleRegister() {
    if (_formKey.currentState!.validate()) {
      if (!_agreeToTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng đồng ý với điều khoản sử dụng và chính sách bảo mật'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      
      ref.read(roleProvider.notifier).state = _selectedRole;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đăng ký tài khoản thành công với vai trò: ${_selectedRole.nameVi}'),
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
          // Left side: Illustration (Desktop only, matches login green style)
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
                          Icons.insights_rounded,
                          size: 96,
                          color: accentColor,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Khởi tạo không gian quản trị tài chính số',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                              ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Đăng ký tài khoản doanh nghiệp để đồng bộ hóa quy trình phê duyệt hóa đơn, tự động nhận diện OCR và theo dõi dòng tiền theo thời gian thực.',
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
          
          // Right side: Register Form
          Expanded(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 480),
                padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
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
                          const SizedBox(height: 20),
                        ],
                        Text(
                          'Tạo tài khoản mới',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Bắt đầu chuẩn hóa quy trình kế toán tài chính số ngay hôm nay',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                        ),
                        const SizedBox(height: 28),
                        
                        // Full Name
                        TextFormField(
                          controller: _fullNameController,
                          decoration: InputDecoration(
                            labelText: 'Họ và tên',
                            labelStyle: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                            prefixIcon: Icon(Icons.person_outline, color: isDark ? accentColor.withOpacity(0.7) : Colors.grey),
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
                            if (value == null || value.trim().isEmpty) {
                              return 'Vui lòng nhập họ và tên';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Row of Company Name & Tax Code
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                controller: _companyController,
                                decoration: InputDecoration(
                                  labelText: 'Doanh nghiệp',
                                  labelStyle: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                                  prefixIcon: Icon(Icons.business, color: isDark ? accentColor.withOpacity(0.7) : Colors.grey),
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
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Tên công ty';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _taxCodeController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Mã số thuế',
                                  labelStyle: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                                  prefixIcon: Icon(Icons.pin, color: isDark ? accentColor.withOpacity(0.7) : Colors.grey),
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
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Nhập MST';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Role Selection
                        DropdownButtonFormField<UserRole>(
                          value: _selectedRole,
                          decoration: InputDecoration(
                            labelText: 'Vai trò doanh nghiệp',
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
                            if (role != null) {
                              setState(() {
                                _selectedRole = role;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Email Field
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
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
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                              return 'Định dạng email không hợp lệ';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
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
                            if (value.length < 6) {
                              return 'Mật khẩu phải tối thiểu 6 ký tự';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Confirm Password Field
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Xác nhận mật khẩu',
                            labelStyle: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                            prefixIcon: Icon(Icons.lock_outline_rounded, color: isDark ? accentColor.withOpacity(0.7) : Colors.grey),
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
                              return 'Vui lòng xác nhận mật khẩu';
                            }
                            if (value != _passwordController.text) {
                              return 'Mật khẩu xác nhận không khớp';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Terms & Conditions Checkbox
                        CheckboxListTile(
                          value: _agreeToTerms,
                          activeColor: accentColor,
                          checkColor: isDark ? bgForestColor : Colors.white,
                          onChanged: (val) {
                            setState(() {
                              _agreeToTerms = val ?? false;
                            });
                          },
                          title: const Text(
                            'Tôi đồng ý với Điều khoản dịch vụ và Chính sách bảo mật thông tin',
                            style: TextStyle(fontSize: 12),
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                        ),
                        const SizedBox(height: 20),
                        
                        // Register Button with ScaleOnTap bounce animation
                        ScaleOnTap(
                          onTap: _handleRegister,
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
                                'Đăng ký tài khoản',
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

                        // Go back to login link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Đã có tài khoản?'),
                            TextButton(
                              onPressed: () {
                                context.go('/login');
                              },
                              child: Text(
                                'Đăng nhập ngay',
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
