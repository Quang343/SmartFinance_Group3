import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/route_names.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/transactions/presentation/transaction_list_screen.dart';
import '../features/invoices/presentation/invoice_list_screen.dart';
import '../features/reports/presentation/report_screen.dart';
import '../features/categories/presentation/category_management_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../core/widgets/responsive_layout.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();
final shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/dashboard',
    routes: [
      ShellRoute(
        navigatorKey: shellNavigatorKey,
        builder: (context, state, child) {
          return ResponsiveLayout(child: child);
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            name: RouteNames.dashboard,
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/transactions',
            name: RouteNames.transactions,
            builder: (context, state) => const TransactionListScreen(),
          ),
          GoRoute(
            path: '/invoices',
            name: RouteNames.invoices,
            builder: (context, state) => const InvoiceListScreen(),
          ),
          GoRoute(
            path: '/reports',
            name: RouteNames.reports,
            builder: (context, state) => const ReportScreen(),
          ),
          GoRoute(
            path: '/categories',
            name: RouteNames.categories,
            builder: (context, state) => const CategoryManagementScreen(),
          ),
          GoRoute(
            path: '/settings',
            name: RouteNames.settings,
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
});
