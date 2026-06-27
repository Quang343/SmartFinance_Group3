import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/role_provider.dart';
import '../../../app/theme/theme_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentRole = ref.watch(roleProvider);
    final themeMode = ref.watch(themeProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt hệ thống'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Section 1: Role Switcher (convenient for testing/grading)
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.badge, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Phân quyền tài khoản (Demo)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Thay đổi vai trò để kiểm thử phân quyền màn hình và chức năng:',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  Column(
                    children: UserRole.values.map((role) {
                      final isSelected = currentRole == role;
                      IconData roleIcon;
                      String description;
                      Color activeColor;
                      
                      switch (role) {
                        case UserRole.financeManager:
                          roleIcon = Icons.admin_panel_settings_rounded;
                          description = 'Quản lý toàn bộ dòng tiền, xem báo cáo vĩ mô';
                          activeColor = const Color(0xFF00D09E);
                          break;
                        case UserRole.expenseAccountant:
                          roleIcon = Icons.arrow_circle_up_rounded;
                          description = 'Ghi nhận và báo cáo các khoản chi phí';
                          activeColor = const Color(0xFFEF4444);
                          break;
                        case UserRole.revenueAccountant:
                          roleIcon = Icons.arrow_circle_down_rounded;
                          description = 'Ghi nhận và báo cáo các khoản doanh thu';
                          activeColor = const Color(0xFF00D09E);
                          break;
                      }

                      return GestureDetector(
                        onTap: () {
                          ref.read(roleProvider.notifier).state = role;
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? (theme.brightness == Brightness.dark ? const Color(0xFF0D251C) : const Color(0xFFE6F4F0))
                                : (theme.brightness == Brightness.dark ? const Color(0xFF08140F) : const Color(0xFFF8FAFC)),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected 
                                  ? activeColor 
                                  : (theme.brightness == Brightness.dark ? const Color(0xFF152A20) : const Color(0xFFE2E8F0)),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Icon
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isSelected 
                                      ? activeColor.withOpacity(0.12)
                                      : (theme.brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04)),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  roleIcon,
                                  color: isSelected ? activeColor : (theme.brightness == Brightness.dark ? Colors.white60 : Colors.black54),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 14),
                              // Role Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      role.nameVi,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: isSelected 
                                            ? (theme.brightness == Brightness.dark ? Colors.white : const Color(0xFF093021))
                                            : (theme.brightness == Brightness.dark ? Colors.white70 : Colors.black87),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      description,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isSelected 
                                            ? (theme.brightness == Brightness.dark ? Colors.white60 : Colors.black54)
                                            : Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Radio Indicator
                              Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected ? activeColor : Colors.grey.shade400,
                                    width: 1.5,
                                  ),
                                ),
                                child: isSelected
                                    ? Center(
                                        child: Container(
                                          width: 10,
                                          height: 10,
                                          decoration: BoxDecoration(
                                            color: activeColor,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      )
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Section 2: Theme Settings
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.dark_mode, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      const Text(
                        'Giao diện',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text('Chế độ tối'),
                    trailing: Switch(
                      value: themeMode == ThemeMode.dark,
                      activeColor: theme.colorScheme.primary,
                      onChanged: (val) {
                        ref.read(themeProvider.notifier).state = val ? ThemeMode.dark : ThemeMode.light;
                      },
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
