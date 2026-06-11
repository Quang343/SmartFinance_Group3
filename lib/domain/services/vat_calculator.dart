class VatCalculator {
  static int calculateVatAmount(int subtotal, int vatRate) {
    if (vatRate != 8 && vatRate != 10) {
      throw ArgumentError('VAT rate must be 8 or 10');
    }
    return (subtotal * vatRate) ~/ 100;
  }

  static int calculateTotalAmount(int subtotal, int vatAmount) {
    return subtotal + vatAmount;
  }
}
