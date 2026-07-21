class CurrencyCalculator {
  /// Tính Tổng Thu (Total Income)
  static double calculateTotalIncome(List<double>? incomes) {
    if (incomes == null) throw ArgumentError('Dữ liệu đầu vào không hợp lệ.');
    if (incomes.isEmpty) return 0.0;
    return incomes.reduce((a, b) => a + b);
  }

  /// Tính Tổng Chi (Total Expense)
  static double calculateTotalExpense(List<double>? expenses) {
    if (expenses == null) throw ArgumentError('Dữ liệu đầu vào không hợp lệ.');
    if (expenses.isEmpty) return 0.0;
    return expenses.reduce((a, b) => a + b);
  }

  /// Tính Thuế VAT (Dựa trên Thành Tiền và % Thuế)
  static double calculateVatAmount(double? subtotal, double? vatPercentage) {
    if (subtotal == null || vatPercentage == null) {
      throw ArgumentError('Dữ liệu đầu vào không hợp lệ.');
    }
    if (subtotal < 0 || vatPercentage < 0) {
      throw ArgumentError('Số tiền và phần trăm thuế không được là số âm.');
    }
    return subtotal * (vatPercentage / 100);
  }

  /// Tính Tổng Tiền Sau Thuế (Thành tiền + Thuế VAT)
  static double calculateTotalWithVat(double? subtotal, double? vatPercentage) {
    if (subtotal == null || vatPercentage == null) {
      throw ArgumentError('Dữ liệu đầu vào không hợp lệ.');
    }
    return subtotal + calculateVatAmount(subtotal, vatPercentage);
  }
}
