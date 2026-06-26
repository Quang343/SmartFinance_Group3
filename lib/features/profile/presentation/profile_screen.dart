import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/role_provider.dart';
import '../../../core/widgets/scale_on_tap.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentRole = ref.watch(roleProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ cá nhân'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            // User Avatar
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                    child: Icon(
                      Icons.person,
                      size: 80,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 4,
                    child: ScaleOnTap(
                      onTap: () {
                        // Edit profile picture action
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // User details
            Text(
              currentRole == UserRole.financeManager
                  ? 'Hoàng Nguyễn (FM)'
                  : currentRole == UserRole.expenseAccountant
                      ? 'Minh Trần (EA)'
                      : 'Hương Lê (RA)',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            // Role Badge
            Chip(
              label: Text(
                currentRole.nameVi,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              backgroundColor: theme.colorScheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            ),
            const SizedBox(height: 32),
            
            // Permissions Matrix Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Phân quyền tài khoản',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const Divider(height: 24),
                    _PermissionRow(
                      label: 'Xem Dashboard & Báo cáo',
                      hasAccess: currentRole.canViewDashboard && currentRole.canViewReports,
                    ),
                    _PermissionRow(
                      label: 'CRUD Giao dịch chi phí',
                      hasAccess: currentRole.canManageExpenses,
                    ),
                    _PermissionRow(
                      label: 'CRUD Giao dịch doanh thu',
                      hasAccess: currentRole.canManageRevenues,
                    ),
                    _PermissionRow(
                      label: 'OCR Quét hóa đơn đầu vào',
                      hasAccess: currentRole.canManageIncomingInvoices,
                    ),
                    _PermissionRow(
                      label: 'Tạo & Xuất hóa đơn đầu ra',
                      hasAccess: currentRole.canManageOutgoingInvoices,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Logout Button
            SizedBox(
              width: double.infinity,
              child: ScaleOnTap(
                onTap: () {
                  context.go('/login');
                },
                child: OutlinedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.logout),
                  label: const Text('Đăng xuất'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    disabledForegroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
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

  const _PermissionRow({required this.label, required this.hasAccess});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 15)),
          Icon(
            hasAccess ? Icons.check_circle : Icons.cancel,
            color: hasAccess ? Colors.green : Colors.red,
          ),
        ],
      ),
    );
  }
}
