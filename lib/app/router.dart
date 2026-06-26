import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/route_names.dart';
import '../features/auth/presentation/splash_screen.dart';
import '../features/auth/presentation/welcome_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/transactions/presentation/transaction_list_screen.dart';
import '../features/transactions/presentation/transaction_form_screen.dart';
import '../features/invoices/presentation/invoice_list_screen.dart';
import '../features/invoices/presentation/invoice_scan_screen.dart';
import '../features/invoices/presentation/invoice_detail_screen.dart';
import '../features/invoices/presentation/invoice_create_screen.dart';
import '../features/invoices/presentation/invoice_preview_screen.dart';
import '../features/reports/presentation/report_screen.dart';
import '../features/reports/presentation/report_detail_screen.dart';
import '../features/categories/presentation/category_management_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../core/widgets/responsive_layout.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();
final shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/',
        redirect: (context, state) => '/splash',
      ),
      GoRoute(
        path: '/splash',
        name: RouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/login',
        name: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: RouteNames.register,
        builder: (context, state) => const RegisterScreen(),
      ),
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
            path: '/transactions/form',
            name: RouteNames.transactionForm,
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return TransactionFormScreen(
                transactionId: extra?['transactionId'] as String?,
              );
            },
          ),
          GoRoute(
            path: '/categories',
            name: RouteNames.categories,
            builder: (context, state) => const CategoryManagementScreen(),
          ),
          GoRoute(
            path: '/invoices/incoming',
            name: RouteNames.incomingInvoices,
            builder: (context, state) => const InvoiceListScreen(type: 'incoming'),
          ),
          GoRoute(
            path: '/invoices/scan',
            name: RouteNames.invoiceScan,
            builder: (context, state) => const InvoiceScanScreen(),
          ),
          GoRoute(
            path: '/invoices/incoming/:id',
            name: RouteNames.invoiceDetail,
            builder: (context, state) => InvoiceDetailScreen(
              invoiceId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/invoices/outgoing',
            name: RouteNames.outgoingInvoices,
            builder: (context, state) => const InvoiceListScreen(type: 'outgoing'),
          ),
          GoRoute(
            path: '/invoices/outgoing/new',
            name: RouteNames.invoiceCreate,
            builder: (context, state) => const InvoiceCreateScreen(),
          ),
          GoRoute(
            path: '/invoices/outgoing/preview',
            name: RouteNames.invoicePreview,
            builder: (context, state) => const InvoicePreviewScreen(),
          ),
          GoRoute(
            path: '/reports',
            name: RouteNames.reports,
            builder: (context, state) => const ReportScreen(),
          ),
          GoRoute(
            path: '/reports/detail',
            name: RouteNames.reportDetail,
            builder: (context, state) {
              final type = state.uri.queryParameters['type'] ?? 'expense';
              return ReportDetailScreen(reportType: type);
            },
          ),
          GoRoute(
            path: '/settings',
            name: RouteNames.settings,
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/profile',
            name: RouteNames.profile,
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
    ],
  );
});
