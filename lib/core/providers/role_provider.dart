import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';

enum UserRole {
  financeManager,
  expenseAccountant,
  revenueAccountant,
}

extension UserRoleExtension on UserRole {
  String get nameVi {
    switch (this) {
      case UserRole.financeManager:
        return 'Quản lý tài chính';
      case UserRole.expenseAccountant:
        return 'Kế toán chi phí';
      case UserRole.revenueAccountant:
        return 'Kế toán doanh thu';
    }
  }

  // Navigation tabs/options config
  bool get canViewDashboard => true;
  bool get canViewReports => true;
  bool get canViewTransactions => true;

  bool get canEditTransactions {
    return this == UserRole.expenseAccountant || this == UserRole.revenueAccountant;
  }

  bool get canManageExpenses {
    return this == UserRole.expenseAccountant;
  }

  bool get canManageRevenues {
    return this == UserRole.revenueAccountant;
  }

  bool get canViewIncomingInvoices {
    return this == UserRole.financeManager || this == UserRole.expenseAccountant;
  }

  bool get canViewOutgoingInvoices {
    return this == UserRole.financeManager || this == UserRole.revenueAccountant;
  }

  bool get canManageIncomingInvoices {
    return this == UserRole.expenseAccountant;
  }

  bool get canManageOutgoingInvoices {
    return this == UserRole.revenueAccountant;
  }
}

// Current active role provider
final roleProvider = Provider<UserRole>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) {
    return UserRole.financeManager;
  }
  
  switch (currentUser.role) {
    case 'financeManager':
      return UserRole.financeManager;
    case 'expenseAccountant':
      return UserRole.expenseAccountant;
    case 'revenueAccountant':
      return UserRole.revenueAccountant;
    default:
      return UserRole.financeManager;
  }
});
