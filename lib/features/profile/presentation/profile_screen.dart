import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/role_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/widgets/scale_on_tap.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            // Green Header (Matching the screenshot style)
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
                      // Floating Avatar (Centered at the bottom of header)
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
                                  child: Icon(
                                    Icons.person_rounded,
                                    size: 55,
                                    color: primaryColor,
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: ScaleOnTap(
                                  onTap: () {},
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: primaryColor,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: cardBgColor, width: 2),
                                    ),
                                    child: const Icon(
                                      Icons.edit,
                                      color: Colors.white,
                                      size: 14,
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
                ),
              ),
            ),

            const SizedBox(height: 55),

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
                  // Permissions Card (Nội dung cũ chuyên nghiệp)
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
                    onTap: () {},
                    isDark: isDark,
                  ),
                  _buildMenuOption(
                    icon: Icons.lock_outline_rounded,
                    iconBgColor: Colors.purple.shade100,
                    iconColor: Colors.purple.shade700,
                    title: 'Bảo mật tài khoản',
                    onTap: () {},
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
