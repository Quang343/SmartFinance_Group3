class Validators {
  static String? requiredString(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? positiveAmount(String? value) {
    if (value == null || value.isEmpty) return 'Amount is required';
    final amount = int.tryParse(value);
    if (amount == null) return 'Must be a valid number';
    if (amount <= 0) return 'Amount must be greater than zero';
    return null;
  }
}
