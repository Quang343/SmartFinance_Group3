import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class MoneyFormatter {
  static String format(int amount) {
    final format = NumberFormat.currency(locale: 'vi_VN', symbol: 'VND');
    return format.format(amount);
  }
}

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }

    String rawText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (rawText.isEmpty) {
      return newValue.copyWith(text: '');
    }

    int? value = int.tryParse(rawText);
    if (value == null) {
      return oldValue;
    }

    final formatter = NumberFormat.decimalPattern('vi_VN');
    String newText = formatter.format(value);

    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
