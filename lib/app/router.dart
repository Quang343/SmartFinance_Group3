import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/route_names.dart';
import '../features/auth/presentation/splash_screen.dart';
import '../features/auth/presentation/onboarding_screen.dart';
import '../features/auth/presentation/welcome_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/auth/presentation/forgot_password_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/transactions/presentation/transaction_list_screen.dart';
import '../features/transactions/presentation/transaction_form_screen.dart';
import 'package:smart_finance/features/invoices/presentation/screens/invoice_capture_screen.dart';
import 'package:smart_finance/features/invoices/presentation/ocr_verify_screen.dart';
import 'dart:io';
import '../features/invoices/presentation/invoice_list_screen.dart';
import '../features/invoices/presentation/invoice_detail_screen.dart';
import '../features/invoices/presentation/invoice_create_screen.dart';
import '../features/invoices/presentation/invoice_preview_screen.dart';
import '../features/reports/presentation/report_screen.dart';
import '../features/reports/presentation/report_detail_screen.dart';
import '../features/categories/presentation/category_management_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/profile/presentation/edit_profile_screen.dart';
import '../features/profile/presentation/change_password_screen.dart';
import '../features/notifications/presentation/notification_screen.dart';
import '../core/widgets/responsive_layout.dart';
import '../domain/entities/invoice_entity.dart';

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
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
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
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/notifications',
        name: RouteNames.notifications,
        builder: (context, state) => const NotificationScreen(),
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
                initialAmount: extra?['initialAmount'] as int?,
                initialNote: extra?['initialNote'] as String?,
                invoiceId: extra?['invoiceId'] as String?,
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
            path: '/invoices/capture',
            name: RouteNames.invoiceCapture,
            builder: (context, state) => const InvoiceCaptureScreen(),
          ),
          GoRoute(
            path: '/invoices/scan',
            name: RouteNames.invoiceScan,
            builder: (context, state) {
              final file = state.extra as File?;
              return OcrVerifyScreen(file: file);
            },
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
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return InvoiceCreateScreen(
                invoiceType: extra?['invoiceType'] as InvoiceType? ?? InvoiceType.outgoing,
                scannedImagePath: extra?['imagePath'] as String?,
                scannedSellerName: extra?['sellerName'] as String?,
                scannedTaxCode: extra?['taxCode'] as String?,
                scannedSubtotal: extra?['subtotal'] as int?,
                scannedVatRate: extra?['vatRate'] as int?,
                scannedTotalAmount: extra?['totalAmount'] as int?,
              );
            },
          ),
          GoRoute(
            path: '/invoices/outgoing/preview/:id',
            name: RouteNames.invoicePreview,
            builder: (context, state) => InvoicePreviewScreen(
              invoiceId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/invoices/outgoing/:id',
            name: 'outgoingInvoiceDetail',
            builder: (context, state) => InvoiceDetailScreen(
              invoiceId: state.pathParameters['id']!,
            ),
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
              final period = state.uri.queryParameters['period'] ?? 'all';
              final startDate = state.uri.queryParameters['startDate'];
              final endDate = state.uri.queryParameters['endDate'];
              return ReportDetailScreen(
                reportType: type,
                period: period,
                startDate: startDate,
                endDate: endDate,
              );
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
          GoRoute(
            path: '/profile/edit',
            builder: (context, state) => const EditProfileScreen(),
          ),
          GoRoute(
            path: '/profile/change-password',
            builder: (context, state) => const ChangePasswordScreen(),
          ),
        ],
      ),
    ],
  );
});
