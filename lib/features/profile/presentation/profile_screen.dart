import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/providers/role_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/widgets/scale_on_tap.dart';
import '../../../data/repositories/storage_repository.dart';
import '../../../data/repositories/auth_repository.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

// HoangDH
class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickAndUploadAvatar() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 800, imageQuality: 85);
      if (image == null) return;

      setState(() => _isUploading = true);

      final user = ref.read(currentUserProvider);
      if (user == null) throw Exception('Người dùng chưa đăng nhập');

      final storageRepo = ref.read(storageRepositoryProvider);
      
      String? downloadUrl;
      if (kIsWeb) {
        final webFile = await image.readAsBytes();
        downloadUrl = await storageRepo.uploadAvatar(user.id, webFile: webFile, fileName: image.name);
      } else {
        downloadUrl = await storageRepo.uploadAvatar(user.id, file: File(image.path), fileName: image.name);
      }

      if (downloadUrl != null) {
        final updatedUser = user.copyWith(avatarUrl: downloadUrl);
        await ref.read(authRepositoryProvider).updateUserInfo(updatedUser);
        ref.read(currentUserProvider.notifier).state = updatedUser;
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật ảnh đại diện thành công'), backgroundColor: Colors.green));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi tải ảnh: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentRole = ref.watch(roleProvider);
    final user = ref.watch(currentUserProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Define colors matching the modern theme
    final primaryColor = const Color(0xFF00D09E);
    final accentBgColor = isDark ? const Color(0xFF06150F) : const Color(0xFFF4FAF7);
    final cardBgColor = isDark ? const Color(0xFF0D251C) : Colors.white;
    final borderColor = isDark ? const Color(0xFF1E3A2F) : const Color(0xFFE2E8F0);
    final textStyleColor = isDark ? Colors.white : const Color(0xFF1E293B);

    final userName = user?.fullName ?? 'Người dùng';
    final userId = 'ID: ${user?.id ?? '---'}';

    return Scaffold(
      backgroundColor: accentBgColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Green Header
            Container(
              width: double.infinity,
              height: 155,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF0C2C1F), const Color(0xFF06150F)]
                      : [const Color(0xFF00D09E), const Color(0xFF00B388)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Stack(
                    children: [
                      // Header title and navigation actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                            onPressed: () {
                              if (context.canPop()) {
                                context.pop();
                              } else {
                                context.go('/dashboard');
                              }
                            },
                          ),
                          const Text(
                            'Hồ sơ cá nhân',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 24),
                            onPressed: () {
                              context.push('/notifications');
                            },
                          ),
                        ],
                      ),
                      // Floating Avatar
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Transform.translate(
                          offset: const Offset(0, 45),
                          child: Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: cardBgColor, width: 4),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 50,
                                  backgroundColor: primaryColor.withOpacity(0.1),
                                  backgroundImage: user?.avatarUrl != null ? NetworkImage(user!.avatarUrl!) : null,
                                  child: user?.avatarUrl == null 
                                      ? Icon(Icons.person_rounded, size: 55, color: primaryColor)
                                      : null,
                                ),
                              ),
                              if (_isUploading)
                                const Positioned.fill(
                                  child: CircularProgressIndicator(color: Colors.white),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 55),

            Center(
              child: TextButton.icon(
                onPressed: _pickAndUploadAvatar,
                icon: const Icon(Icons.photo_camera, size: 18),
                label: const Text('Đổi ảnh đại diện', style: TextStyle(fontWeight: FontWeight.w600)),
                style: TextButton.styleFrom(
                  foregroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  backgroundColor: primaryColor.withOpacity(0.1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Profile info details
            Text(
              userName,
              style: TextStyle(
                color: textStyleColor,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              userId,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                currentRole.nameVi,
                style: TextStyle(
                  color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF009C77),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),

            // Main options list & permissions card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Permissions Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardBgColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.shield_outlined, color: primaryColor, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Phân quyền tài khoản',
                              style: TextStyle(
                                color: textStyleColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24, thickness: 1),
                        _PermissionRow(
                          label: 'Xem Dashboard & Báo cáo',
                          hasAccess: currentRole.canViewDashboard && currentRole.canViewReports,
                          primaryColor: primaryColor,
                        ),
                        _PermissionRow(
                          label: 'CRUD Giao dịch chi phí',
                          hasAccess: currentRole.canManageExpenses,
                          primaryColor: primaryColor,
                        ),
                        _PermissionRow(
                          label: 'CRUD Giao dịch doanh thu',
                          hasAccess: currentRole.canManageRevenues,
                          primaryColor: primaryColor,
                        ),
                        _PermissionRow(
                          label: 'OCR Quét hóa đơn đầu vào',
                          hasAccess: currentRole.canManageIncomingInvoices,
                          primaryColor: primaryColor,
                        ),
                        _PermissionRow(
                          label: 'Tạo & Xuất hóa đơn đầu ra',
                          hasAccess: currentRole.canManageOutgoingInvoices,
                          primaryColor: primaryColor,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Option Menu Items
                  _buildMenuOption(
                    icon: Icons.person_outline_rounded,
                    iconBgColor: Colors.blue.shade100,
                    iconColor: Colors.blue.shade700,
                    title: 'Chỉnh sửa thông tin',
                    onTap: () {
                      context.push('/profile/edit');
                    },
                    isDark: isDark,
                  ),
                  _buildMenuOption(
                    icon: Icons.lock_outline_rounded,
                    iconBgColor: Colors.purple.shade100,
                    iconColor: Colors.purple.shade700,
                    title: 'Bảo mật tài khoản',
                    onTap: () {
                      context.push('/profile/change-password');
                    },
                    isDark: isDark,
                  ),
                  _buildMenuOption(
                    icon: Icons.settings_outlined,
                    iconBgColor: Colors.orange.shade100,
                    iconColor: Colors.orange.shade700,
                    title: 'Thiết lập ứng dụng',
                    onTap: () {
                      context.push('/settings');
                    },
                    isDark: isDark,
                  ),
                  _buildMenuOption(
                    icon: Icons.help_outline_rounded,
                    iconBgColor: Colors.teal.shade100,
                    iconColor: Colors.teal.shade700,
                    title: 'Hỗ trợ khách hàng',
                    onTap: () {},
                    isDark: isDark,
                  ),

                  const SizedBox(height: 12),

                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuOption({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return ScaleOnTap(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0D251C) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF1E3A2F) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: isDark ? Colors.white38 : Colors.black26,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionRow extends StatelessWidget {
  final String label;
  final bool hasAccess;
  final Color primaryColor;

  const _PermissionRow({
    required this.label,
    required this.hasAccess,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white70 : const Color(0xFF475569),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Icon(
            hasAccess ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: hasAccess ? primaryColor : Colors.redAccent,
            size: 20,
          ),
        ],
      ),
    );
  }
}
