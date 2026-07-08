import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/role_provider.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repository.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

// HoangDH
class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _fullNameController;
  late TextEditingController _companyController;
  late TextEditingController _taxCodeController;
  late TextEditingController _emailController;
  late TextEditingController _roleController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    final role = ref.read(roleProvider);
    
    _fullNameController = TextEditingController(text: user?.fullName ?? '');
    _companyController = TextEditingController(text: user?.company ?? '');
    _taxCodeController = TextEditingController(text: user?.taxCode ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _roleController = TextEditingController(text: role.nameVi);
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _companyController.dispose();
    _taxCodeController.dispose();
    _emailController.dispose();
    _roleController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    try {
      final user = ref.read(currentUserProvider);
      if (user == null) throw Exception('Không tìm thấy thông tin người dùng');

      final authRepo = ref.read(authRepositoryProvider);
      
      final updatedUser = user.copyWith(
        fullName: _fullNameController.text.trim(),
        company: _companyController.text.trim(),
        taxCode: _taxCodeController.text.trim(),
      );

      await authRepo.updateUserInfo(updatedUser);
      
      // Update local state
      ref.read(currentUserProvider.notifier).state = updatedUser;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật thông tin thành công'), backgroundColor: Colors.green),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉnh sửa thông tin'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Thông tin không thể thay đổi', Icons.lock_outline),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _emailController,
                label: 'Email',
                icon: Icons.email_outlined,
                enabled: false,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _roleController,
                label: 'Chức vụ',
                icon: Icons.badge_outlined,
                enabled: false,
              ),
              
              const SizedBox(height: 32),
              _buildSectionTitle('Thông tin có thể thay đổi', Icons.edit_outlined),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _fullNameController,
                label: 'Họ và tên',
                icon: Icons.person_outline,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Vui lòng nhập họ tên';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _companyController,
                label: 'Tên Doanh nghiệp',
                icon: Icons.business_outlined,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Vui lòng nhập tên doanh nghiệp';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _taxCodeController,
                label: 'Mã số thuế',
                icon: Icons.receipt_long_outlined,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Vui lòng nhập mã số thuế';
                  return null;
                },
              ),
              
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Lưu thay đổi',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      validator: validator,
      style: TextStyle(
        color: enabled ? null : Colors.grey.shade600,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: enabled ? null : Colors.grey.shade400),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        filled: !enabled,
        fillColor: enabled ? Colors.transparent : Colors.grey.shade100,
      ),
    );
  }
}
