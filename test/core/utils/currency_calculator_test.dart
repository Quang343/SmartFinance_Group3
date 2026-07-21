import 'package:flutter_test/flutter_test.dart';
import 'package:smart_finance/core/utils/currency_calculator.dart';

void main() {
  group('CurrencyCalculator - Tầng Logic Xử Lý Tiền Tệ (Điểm Cộng)', () {
    
    // TC_CUR_01
    test('Nên tính chính xác Tổng Thu (Total Income) từ danh sách các khoản thu', () {
      final incomes = [1500000.0, 500000.0, 2000000.0];
      final totalIncome = CurrencyCalculator.calculateTotalIncome(incomes);
      expect(totalIncome, 4000000.0);
    });

    // TC_CUR_02
    test('Nên tính chính xác Tổng Chi (Total Expense) từ danh sách các khoản chi', () {
      final expenses = [100000.0, 250000.0, 50000.0];
      final totalExpense = CurrencyCalculator.calculateTotalExpense(expenses);
      expect(totalExpense, 400000.0);
    });

    // TC_CUR_03
    test('Nên tính chính xác Thuế VAT và Tổng Tiền Sau Thuế', () {
      final subtotal = 1000000.0;
      final vatPercentage = 10.0;
      final vatAmount = CurrencyCalculator.calculateVatAmount(subtotal, vatPercentage);
      final totalWithVat = CurrencyCalculator.calculateTotalWithVat(subtotal, vatPercentage);
      expect(vatAmount, 100000.0);
      expect(totalWithVat, 1100000.0);
    });

    // TC_CUR_04
    test('Nên trả về 0.0 nếu danh sách rỗng (Empty Data)', () {
      expect(CurrencyCalculator.calculateTotalIncome([]), 0.0);
      expect(CurrencyCalculator.calculateTotalExpense([]), 0.0);
    });

    // TC_CUR_05
    test('Nên ném lỗi ArgumentError khi tính thuế VAT với số tiền âm (Logic Validation)', () {
      expect(
        () => CurrencyCalculator.calculateVatAmount(-500000.0, 10.0),
        throwsA(isA<ArgumentError>().having((e) => e.message, 'message', contains('không được là số âm'))),
      );
      expect(
        () => CurrencyCalculator.calculateVatAmount(1000000.0, -10.0),
        throwsA(isA<ArgumentError>().having((e) => e.message, 'message', contains('không được là số âm'))),
      );
    });

    // TC_CUR_06
    test('Nên tính Tổng Thu với một phần tử', () {
      final incomes = [2500000.0];
      expect(CurrencyCalculator.calculateTotalIncome(incomes), 2500000.0);
    });

    // TC_CUR_07
    test('Nên tính Tổng Chi với giá trị bằng 0', () {
      final expenses = [0.0, 100000.0, 200000.0];
      expect(CurrencyCalculator.calculateTotalExpense(expenses), 300000.0);
    });

    // TC_CUR_08
    test('Nên tính VAT với thuế suất 0%', () {
      final vatAmount = CurrencyCalculator.calculateVatAmount(1000000.0, 0.0);
      final totalWithVat = CurrencyCalculator.calculateTotalWithVat(1000000.0, 0.0);
      expect(vatAmount, 0.0);
      expect(totalWithVat, 1000000.0);
    });

    // TC_CUR_09
    test('Nên tính VAT với số thập phân', () {
      final vatAmount = CurrencyCalculator.calculateVatAmount(999999.99, 8.0);
      final totalWithVat = CurrencyCalculator.calculateTotalWithVat(999999.99, 8.0);
      // expect close to since it's floating point math
      expect(vatAmount, closeTo(79999.9992, 0.0001));
      expect(totalWithVat, closeTo(1079999.9892, 0.0001));
    });

    // TC_CUR_10
    test('Nên bắt lỗi giá trị null', () {
      expect(() => CurrencyCalculator.calculateTotalIncome(null), throwsA(isA<ArgumentError>()));
      expect(() => CurrencyCalculator.calculateTotalExpense(null), throwsA(isA<ArgumentError>()));
      expect(() => CurrencyCalculator.calculateVatAmount(null, 10.0), throwsA(isA<ArgumentError>()));
      expect(() => CurrencyCalculator.calculateVatAmount(1000000.0, null), throwsA(isA<ArgumentError>()));
      expect(() => CurrencyCalculator.calculateTotalWithVat(null, 10.0), throwsA(isA<ArgumentError>()));
    });

    // TC_CUR_11
    test('Nên tính Tổng Thu với giá trị rất lớn', () {
      final largeValue = 1e15; // 1 quadrillion
      final incomes = [largeValue, largeValue];
      expect(CurrencyCalculator.calculateTotalIncome(incomes), 2e15);
    });

    // TC_CUR_12
    test('Đảm bảo độ chính xác phép cộng', () {
      final expenses = [100.5, 200.25, 300.25];
      expect(CurrencyCalculator.calculateTotalExpense(expenses), 601.0);
    });

  });
}
