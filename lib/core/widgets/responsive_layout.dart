import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/role_provider.dart';
import '../providers/auth_provider.dart';
import 'scale_on_tap.dart';

class NavigationItem {
  final String path;
  final String label;
  final IconData icon;

  const NavigationItem({
    required this.path,
    required this.label,
    required this.icon,
  });
}

class ResponsiveLayout extends ConsumerWidget {
  final Widget child;

  const ResponsiveLayout({super.key, required this.child});

  List<NavigationItem> _getNavigationItems(UserRole role) {
    switch (role) {
      case UserRole.financeManager:
        return const [
          NavigationItem(path: '/dashboard', label: 'Tổng quan', icon: Icons.dashboard),
          NavigationItem(path: '/transactions', label: 'Dòng tiền', icon: Icons.compare_arrows),
          NavigationItem(path: '/invoices/incoming', label: 'HD đầu vào', icon: Icons.receipt),
          NavigationItem(path: '/invoices/outgoing', label: 'HD đầu ra', icon: Icons.receipt_long),
          NavigationItem(path: '/reports', label: 'Báo cáo', icon: Icons.bar_chart),
          NavigationItem(path: '/settings', label: 'Cài đặt', icon: Icons.settings),
          NavigationItem(path: '/profile', label: 'Cá nhân', icon: Icons.person),
        ];
      case UserRole.expenseAccountant:
        return const [
          NavigationItem(path: '/dashboard', label: 'Tổng quan', icon: Icons.dashboard),
          NavigationItem(path: '/transactions', label: 'Chi phí', icon: Icons.trending_down),
          NavigationItem(path: '/categories', label: 'Danh mục chi', icon: Icons.category),
          NavigationItem(path: '/invoices/incoming', label: 'HD đầu vào', icon: Icons.receipt),
          NavigationItem(path: '/invoices/scan', label: 'Quét hóa đơn', icon: Icons.qr_code_scanner),
          NavigationItem(path: '/reports', label: 'Báo cáo', icon: Icons.bar_chart),
          NavigationItem(path: '/settings', label: 'Cài đặt', icon: Icons.settings),
          NavigationItem(path: '/profile', label: 'Cá nhân', icon: Icons.person),
        ];
      case UserRole.revenueAccountant:
        return const [
          NavigationItem(path: '/dashboard', label: 'Tổng quan', icon: Icons.dashboard),
          NavigationItem(path: '/transactions', label: 'Doanh thu', icon: Icons.trending_up),
          NavigationItem(path: '/categories', label: 'Danh mục thu', icon: Icons.category),
          NavigationItem(path: '/invoices/outgoing', label: 'HD đầu ra', icon: Icons.receipt_long),
          NavigationItem(path: '/invoices/outgoing/new', label: 'Tạo HD', icon: Icons.add_box),
          NavigationItem(path: '/reports', label: 'Báo cáo', icon: Icons.bar_chart),
          NavigationItem(path: '/settings', label: 'Cài đặt', icon: Icons.settings),
          NavigationItem(path: '/profile', label: 'Cá nhân', icon: Icons.person),
        ];
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentRole = ref.watch(roleProvider);
    final navItems = _getNavigationItems(currentRole);

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 800) {
          return _MobileScaffold(child: child, items: navItems);
        } else {
          return _DesktopScaffold(child: child, items: navItems);
        }
      },
    );
  }
}

class _MobileScaffold extends ConsumerWidget {
  final Widget child;
  final List<NavigationItem> items;

  const _MobileScaffold({required this.child, required this.items});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scaffoldKey = GlobalKey<ScaffoldState>();
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final user = ref.watch(currentUserProvider);
    final currentRole = ref.watch(roleProvider);
    final userName = user?.fullName ?? 'Người dùng';
    final roleName = currentRole.nameVi;
    
    // Bottom bar items: show at most 4 primary items, and 1 'More' item
    final primaryItems = items.length > 5 ? items.sublist(0, 4) : items;
    final hasDrawer = items.length > 5;
    final drawerItems = hasDrawer ? items.sublist(4) : <NavigationItem>[];

    final location = GoRouterState.of(context).uri.path;
    int selectedIndex = primaryItems.indexWhere((item) => location.startsWith(item.path));
    if (selectedIndex == -1 && hasDrawer) {
      // If active route is in drawer, set index to 'More' tab (index 4)
      selectedIndex = 4;
    } else if (selectedIndex == -1) {
      selectedIndex = 0;
    }

    return Scaffold(
      body: child,
      drawer: hasDrawer
          ? Drawer(
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    // Custom Gradient Header with User Info
                    InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        context.go('/profile');
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                        margin: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDark
                                ? [const Color(0xFF0C2C1F), const Color(0xFF06150F)]
                                : [const Color(0xFF00D09E), const Color(0xFF008B6B)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.person_rounded,
                                size: 28,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    userName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    roleName,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: Colors.white70,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'TIỆN ÍCH & CÀI ĐẶT',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                    // Navigation list items with modern rounded container
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        children: drawerItems.map((item) {
                          final isSelected = location.startsWith(item.path);
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: InkWell(
                              onTap: () {
                                Navigator.pop(context); // close drawer
                                context.go(item.path);
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? primaryColor.withOpacity(0.12)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  border: isSelected
                                      ? Border.all(color: primaryColor.withOpacity(0.2), width: 1)
                                      : null,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      item.icon,
                                      color: isSelected ? primaryColor : Colors.grey.shade600,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Text(
                                        item.label,
                                        style: TextStyle(
                                          color: isSelected
                                              ? primaryColor
                                              : null,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    if (isSelected)
                                      Icon(
                                        Icons.chevron_right,
                                        color: primaryColor,
                                        size: 16,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const Divider(height: 1, color: Colors.black12),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: InkWell(
                        onTap: () {
                          ref.read(currentUserProvider.notifier).state = null;
                          Navigator.pop(context); // close drawer
                          context.go('/welcome');
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.logout_rounded, color: Colors.red, size: 20),
                              SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  'Đăng xuất',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Drawer Footer
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        'SmartFinance v1.1.0',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 11,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
      bottomNavigationBar: Builder(
        builder: (context) {
          return BottomNavigationBar(
            currentIndex: selectedIndex,
            onTap: (index) {
              if (hasDrawer && index == 4) {
                Scaffold.of(context).openDrawer();
              } else {
                context.go(primaryItems[index].path);
              }
            },
            type: BottomNavigationBarType.fixed,
            selectedItemColor: primaryColor,
            unselectedItemColor: Colors.grey,
            showUnselectedLabels: false,
            selectedLabelStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.2,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 10,
            ),
            items: [
              ...primaryItems.map((item) => BottomNavigationBarItem(
                    icon: Icon(item.icon),
                    label: item.label,
                  )),
              if (hasDrawer)
                const BottomNavigationBarItem(
                  icon: Icon(Icons.more_horiz),
                  label: 'Thêm',
                ),
            ],
          );
        },
      ),
    );
  }
}

class _DesktopScaffold extends StatelessWidget {
  final Widget child;
  final List<NavigationItem> items;

  const _DesktopScaffold({required this.child, required this.items});

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final index = items.indexWhere((item) => location.startsWith(item.path));
    return index == -1 ? 0 : index;
  }

  void _onItemTapped(int index, BuildContext context) {
    context.go(items[index].path);
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _calculateSelectedIndex(context),
            onDestinationSelected: (index) => _onItemTapped(index, context),
            labelType: NavigationRailLabelType.all,
            selectedIconTheme: IconThemeData(color: primaryColor),
            selectedLabelTextStyle: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
            destinations: items
                .map((item) => NavigationRailDestination(
                      icon: Icon(item.icon),
                      label: Text(item.label),
                    ))
                .toList(),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}
