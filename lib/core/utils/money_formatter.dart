import 'package:intl/intl.dart';

class MoneyFormatter {
  static String format(int amount) {
    final format = NumberFormat.currency(locale: 'vi_VN', symbol: 'VND');
    return format.format(amount);
  }
}
