import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:smart_finance/core/providers/role_provider.dart';
import 'package:smart_finance/domain/entities/invoice_entity.dart';
import 'package:smart_finance/domain/entities/invoice_item_entity.dart';
import 'package:smart_finance/domain/repositories/invoice_repository.dart';
import 'package:smart_finance/domain/services/invoice_creation_service.dart';

// --- MOCKS ---
class MockInvoiceRepository extends Mock implements InvoiceRepository {}

class FakeInvoiceEntity extends Fake implements InvoiceEntity {}

void main() {
  late InvoiceCreationService service;
  late MockInvoiceRepository mockRepo;

  setUpAll(() {
    // Đăng ký fallback value cho các argument custom khi dùng mocktail
    registerFallbackValue(FakeInvoiceEntity());
  });

  setUp(() {
    // Khởi tạo lại mock và service trước mỗi test để đảm bảo tính độc lập (Isolation)
    mockRepo = MockInvoiceRepository();
    service = InvoiceCreationService(mockRepo);
  });

  // Helper function để tạo một hóa đơn hợp lệ nhanh chóng
  // Giúp code test ngắn gọn và dễ đọc hơn, đồng thời dễ tái sử dụng
  InvoiceEntity _createValidInvoice({
    InvoiceType type = InvoiceType.outgoing,
    String invoiceNumber = 'INV-2023-001',
    String buyerName = 'Công ty TNHH Mua Hàng',
    List<InvoiceItemEntity>? items,
    int totalAmount = 100000,
  }) {
    return InvoiceEntity(
      id: 'inv_test_1',
      invoiceNumber: invoiceNumber,
      sellerName: 'SmartFinance',
      sellerTaxCode: '0123456789',
      buyerName: buyerName,
      buyerTaxCode: '987654321',
      subtotal: totalAmount,
      vatRate: 0,
      vatAmount: 0,
      totalAmount: totalAmount,
      ocrStatus: OcrStatus.notStarted,
      transactionStatus: InvoiceTransactionStatus.notCreated,
      issuedDate: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      type: type,
      items: items ?? [
        const InvoiceItemEntity(
          id: 'item_1',
          itemCode: 'SP01',
          itemName: 'Sản phẩm 1',
          unit: 'Cái',
          quantity: 1,
          unitPrice: 100000,
          totalAmount: 100000,
        )
      ],
    );
  }

  group('InvoiceCreationService - Tạo hóa đơn bán ra (Role: Kế toán doanh thu)', () {
    
    // CASE 1: Happy path - Tất cả dữ liệu và quyền đều đúng
    test('Nên tạo hóa đơn thành công khi user là kế toán doanh thu và dữ liệu hợp lệ', () async {
      // Arrange (Chuẩn bị dữ liệu)
      final validInvoice = _createValidInvoice();
      when(() => mockRepo.create(any())).thenAnswer((_) async {});

      // Act (Thực thi hành động)
      await service.createOutgoingInvoice(
        userRole: UserRole.revenueAccountant, // Kế toán doanh thu
        invoice: validInvoice,
      );

      // Assert (Kiểm tra kết quả)
      // Đảm bảo hàm create của repository được gọi đúng 1 lần với hóa đơn được truyền vào
      verify(() => mockRepo.create(validInvoice)).called(1);
    });

    // CASE 2: Kiểm tra quyền (Role Validation) - Kế toán chi phí
    test('Nên ném lỗi InvoiceCreationException khi user là Kế toán chi phí (không có quyền tạo bán ra)', () async {
      final invoice = _createValidInvoice();

      // Act & Assert
      expect(
        () => service.createOutgoingInvoice(
          userRole: UserRole.expenseAccountant, // Kế toán chi phí
          invoice: invoice,
        ),
        throwsA(isA<InvoiceCreationException>().having(
          (e) => e.message,
          'message',
          contains('không có quyền'),
        )),
      );

      // Đảm bảo repository.create KHÔNG bao giờ được gọi khi xảy ra lỗi quyền
      verifyNever(() => mockRepo.create(any()));
    });

    // CASE 3: Kiểm tra quyền (Role Validation) - Quản lý tài chính
    test('Nên ném lỗi InvoiceCreationException khi user là Quản lý tài chính (chỉ xem, không tạo bán ra)', () async {
      final invoice = _createValidInvoice();

      // Act & Assert
      expect(
        () => service.createOutgoingInvoice(
          userRole: UserRole.financeManager, // Quản lý tài chính
          invoice: invoice,
        ),
        throwsA(isA<InvoiceCreationException>()),
      );
      verifyNever(() => mockRepo.create(any()));
    });

    // CASE 4: Kiểm tra loại hóa đơn
    test('Nên ném lỗi InvoiceCreationException khi cố tình đưa loại hóa đơn là Mua vào (incoming)', () async {
      // Arrange
      final invalidTypeInvoice = _createValidInvoice(type: InvoiceType.incoming);

      // Act & Assert
      expect(
        () => service.createOutgoingInvoice(
          userRole: UserRole.revenueAccountant,
          invoice: invalidTypeInvoice,
        ),
        throwsA(isA<InvoiceCreationException>().having(
          (e) => e.message,
          'message',
          contains('Loại hóa đơn không hợp lệ'),
        )),
      );
    });

    // CASE 5: Kiểm tra dữ liệu - Bỏ trống số hóa đơn
    test('Nên ném lỗi InvoiceCreationException khi số hóa đơn bị bỏ trống', () async {
      // Arrange
      final invalidInvoice = _createValidInvoice(invoiceNumber: '');

      // Act & Assert
      expect(
        () => service.createOutgoingInvoice(
          userRole: UserRole.revenueAccountant,
          invoice: invalidInvoice,
        ),
        throwsA(isA<InvoiceCreationException>().having(
          (e) => e.message,
          'message',
          contains('Số hóa đơn không được để trống'),
        )),
      );
    });

    // CASE 6: Kiểm tra dữ liệu - Bỏ trống tên người mua
    test('Nên ném lỗi InvoiceCreationException khi tên người mua bị bỏ trống', () async {
      // Arrange
      final invalidInvoice = _createValidInvoice(buyerName: '');

      // Act & Assert
      expect(
        () => service.createOutgoingInvoice(
          userRole: UserRole.revenueAccountant,
          invoice: invalidInvoice,
        ),
        throwsA(isA<InvoiceCreationException>().having(
          (e) => e.message,
          'message',
          contains('Tên người mua không được để trống'),
        )),
      );
    });

    // CASE 7: Kiểm tra dữ liệu - Không có sản phẩm nào
    test('Nên ném lỗi InvoiceCreationException khi hóa đơn không có sản phẩm/dịch vụ nào', () async {
      // Arrange
      final invalidInvoice = _createValidInvoice(items: []);

      // Act & Assert
      expect(
        () => service.createOutgoingInvoice(
          userRole: UserRole.revenueAccountant,
          invoice: invalidInvoice,
        ),
        throwsA(isA<InvoiceCreationException>().having(
          (e) => e.message,
          'message',
          contains('Hóa đơn phải có ít nhất một sản phẩm'),
        )),
      );
    });

    // CASE 8: Kiểm tra dữ liệu - Tổng tiền <= 0
    test('Nên ném lỗi InvoiceCreationException khi tổng tiền nhỏ hơn hoặc bằng 0', () async {
      // Arrange
      final invalidInvoice = _createValidInvoice(totalAmount: 0);

      // Act & Assert
      expect(
        () => service.createOutgoingInvoice(
          userRole: UserRole.revenueAccountant,
          invoice: invalidInvoice,
        ),
        throwsA(isA<InvoiceCreationException>().having(
          (e) => e.message,
          'message',
          contains('Tổng tiền hóa đơn phải lớn hơn 0'),
        )),
      );
    });

    // CASE 9: Lỗi kết nối Database / Repository
    test('Nên ném lỗi trực tiếp nếu repository.create gặp lỗi (ví dụ: mất kết nối DB)', () async {
      // Arrange
      final validInvoice = _createValidInvoice();
      when(() => mockRepo.create(any())).thenThrow(Exception('Lỗi kết nối Firestore'));

      // Act & Assert
      expect(
        () => service.createOutgoingInvoice(
          userRole: UserRole.revenueAccountant,
          invoice: validInvoice,
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(), 
          'Exception message', 
          contains('Lỗi kết nối Firestore')
        )),
      );
    });
  });
}
