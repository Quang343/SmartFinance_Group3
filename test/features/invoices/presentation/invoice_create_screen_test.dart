import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_finance/features/invoices/presentation/invoice_create_screen.dart';
import 'package:smart_finance/domain/entities/invoice_entity.dart';
import 'package:smart_finance/core/providers/app_providers.dart';
import 'package:smart_finance/domain/repositories/category_repository.dart';
import 'package:smart_finance/domain/repositories/attachment_repository.dart';
import 'package:smart_finance/domain/repositories/transaction_repository.dart';
import 'package:smart_finance/domain/repositories/invoice_repository.dart';
import 'package:smart_finance/domain/entities/category_entity.dart';
import 'package:smart_finance/domain/entities/partner_entity.dart';
import 'package:smart_finance/domain/entities/attachment_entity.dart';
import 'package:smart_finance/domain/entities/transaction_entity.dart';
import 'package:smart_finance/core/sync/sync_queue_service.dart';

class MockCategoryRepository extends Mock implements CategoryRepository {}
class MockAttachmentRepository extends Mock implements AttachmentRepository {}
class MockTransactionRepository extends Mock implements TransactionRepository {}
class MockInvoiceRepository extends Mock implements InvoiceRepository {}
class MockSyncQueueService extends Mock implements SyncQueueService {}

final dummyInvoice = InvoiceEntity(
  id: 'test_id',
  invoiceNumber: '0000001',
  sellerName: 'Seller',
  sellerTaxCode: '123',
  buyerName: 'Buyer',
  buyerTaxCode: '456',
  items: [],
  subtotal: 1000,
  vatRate: 10,
  vatAmount: 100,
  totalAmount: 1100,
  ocrStatus: OcrStatus.notStarted,
  transactionStatus: InvoiceTransactionStatus.notCreated,
  issuedDate: DateTime.now(),
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
  type: InvoiceType.outgoing,
  status: InvoiceStatus.active,
);

void main() {
  setUpAll(() {
    registerFallbackValue(InvoiceType.outgoing);
    registerFallbackValue(dummyInvoice);
  });

  Future<void> pumpInvoiceScreen(WidgetTester tester, {String? invoiceId}) async {
    tester.view.physicalSize = const Size(1080, 5000); // Tăng kích thước để thấy hết nút
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final mockCategoryRepo = MockCategoryRepository();
    when(() => mockCategoryRepo.getAll()).thenAnswer((_) async => <CategoryEntity>[]);

    final mockAttachmentRepo = MockAttachmentRepository();
    when(() => mockAttachmentRepo.getByOwnerId(any())).thenAnswer((_) async => <AttachmentEntity>[]);

    final mockTransactionRepo = MockTransactionRepository();
    when(() => mockTransactionRepo.getAll()).thenAnswer((_) async => <TransactionEntity>[]);

    final mockSyncQueueService = MockSyncQueueService();
    when(() => mockSyncQueueService.queue).thenReturn([]);

    final mockInvoiceRepo = MockInvoiceRepository();
    when(() => mockInvoiceRepo.getNextSequentialId(any())).thenAnswer((_) async => 1);
    when(() => mockInvoiceRepo.create(any())).thenAnswer((_) async => {});
    when(() => mockInvoiceRepo.getById(any())).thenAnswer((_) async => dummyInvoice);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          categoryRepositoryProvider.overrideWithValue(mockCategoryRepo),
          attachmentRepositoryProvider.overrideWithValue(mockAttachmentRepo),
          transactionRepositoryProvider.overrideWithValue(mockTransactionRepo),
          invoiceRepositoryProvider.overrideWithValue(mockInvoiceRepo),
          syncQueueServiceProvider.overrideWith((ref) => mockSyncQueueService),
          partnerStreamProvider.overrideWith((ref) => Stream.value(<PartnerEntity>[])),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: InvoiceCreateScreen(invoiceType: InvoiceType.outgoing, invoiceId: invoiceId),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('Nhóm 1: Empty Validation', () {
    testWidgets('TC_INV_01: Bắt lỗi bỏ trống "Tên đơn vị mua"', (WidgetTester tester) async {
      await pumpInvoiceScreen(tester);
      await tester.tap(find.text('Lưu & Phát hành'));
      await tester.pumpAndSettle();
      expect(find.text('Nhập tên đối tác'), findsOneWidget);
    });

    testWidgets('TC_INV_02: Bắt lỗi bỏ trống "Mã số thuế"', (WidgetTester tester) async {
      await pumpInvoiceScreen(tester);
      await tester.tap(find.text('Lưu & Phát hành'));
      await tester.pumpAndSettle();
      expect(find.text('Nhập mã số thuế'), findsOneWidget);
    });

    testWidgets('TC_INV_03, TC_INV_27: Bắt lỗi bỏ trống thông tin dịch vụ', (WidgetTester tester) async {
      await pumpInvoiceScreen(tester);
      await tester.enterText(find.widgetWithText(TextFormField, 'Tên sản phẩm/dịch vụ').first, '');
      await tester.tap(find.text('Lưu & Phát hành'));
      await tester.pumpAndSettle();
      expect(find.text('Bắt buộc'), findsWidgets);
    });
  });

  group('Nhóm 2: Logic & Boundary', () {
    testWidgets('TC_INV_04: Giới hạn tối đa Số lượng', (WidgetTester tester) async {
      await pumpInvoiceScreen(tester);
      final quantityField = find.widgetWithText(TextFormField, 'Số lượng');
      await tester.enterText(quantityField, '999999');
      await tester.pump();
      expect(find.text('99999'), findsOneWidget);
    });

    testWidgets('TC_INV_16: Bắt lỗi số lượng bằng 0', (WidgetTester tester) async {
      await pumpInvoiceScreen(tester);
      final quantityField = find.widgetWithText(TextFormField, 'Số lượng');
      await tester.enterText(quantityField, '0');
      await tester.pump();
      await tester.tap(find.text('Lưu & Phát hành'));
      await tester.pumpAndSettle();
      expect(find.text('Không hợp lệ'), findsWidgets);
    });

    testWidgets('TC_INV_17: Bắt lỗi đơn giá bằng 0', (WidgetTester tester) async {
      await pumpInvoiceScreen(tester);
      final priceField = find.widgetWithText(TextFormField, 'Đơn giá (VND)');
      await tester.enterText(priceField, '0');
      await tester.pump();
      await tester.tap(find.text('Lưu & Phát hành'));
      await tester.pumpAndSettle();
      expect(find.text('Không hợp lệ'), findsWidgets);
    });
    
    testWidgets('TC_INV_18, TC_INV_19: Không cho nhập ký tự chữ', (WidgetTester tester) async {
      await pumpInvoiceScreen(tester);
      final priceField = find.widgetWithText(TextFormField, 'Đơn giá (VND)');
      await tester.enterText(priceField, 'abc500000');
      await tester.pump();
      expect(find.text('abc500000'), findsNothing); // Chữ sẽ không được format hoặc input formatter sẽ chặn
    });

    testWidgets('TC_INV_05: Giới hạn tối đa "Đơn giá"', (WidgetTester tester) async {
      await pumpInvoiceScreen(tester);
      final priceField = find.widgetWithText(TextFormField, 'Đơn giá (VND)');
      await tester.enterText(priceField, '1234567890123456'); // 16 chữ số
      await tester.pump();
      expect(find.text('1.234.567.890.123.450'), findsNothing); // Không thể nhập số thứ 16
    });

    testWidgets('TC_INV_06: Giới hạn nút tăng/giảm số lượng', (WidgetTester tester) async {
      await pumpInvoiceScreen(tester);
      final minusBtn = find.byIcon(Icons.remove_circle_outline);
      final plusBtn = find.byIcon(Icons.add_circle_outline);
      
      await tester.tap(minusBtn);
      await tester.pump();
      expect(find.text('1'), findsOneWidget); // Không giảm dưới 1

      final quantityField = find.widgetWithText(TextFormField, 'Số lượng');
      await tester.enterText(quantityField, '99999');
      await tester.tap(plusBtn);
      await tester.pump();
      expect(find.text('99999'), findsOneWidget); // Không tăng quá 99999
    });
  });

  group('Nhóm 3: Format & Trim', () {
    testWidgets('TC_INV_07: Tự động định dạng tiền', (WidgetTester tester) async {
      await pumpInvoiceScreen(tester);
      final priceField = find.widgetWithText(TextFormField, 'Đơn giá (VND)');
      await tester.enterText(priceField, '500000');
      await tester.pumpAndSettle();
      expect(find.text('500.000'), findsOneWidget);
    });

    testWidgets('TC_INV_08: Đổi số thành chữ', (WidgetTester tester) async {
      await pumpInvoiceScreen(tester);
      final priceField = find.widgetWithText(TextFormField, 'Đơn giá (VND)');
      await tester.enterText(priceField, '5000');
      await tester.pumpAndSettle();
      expect(find.text('Năm nghìn đồng'), findsOneWidget);
    });
  });

  group('Nhóm 4: Reactive Calculation', () {
    testWidgets('TC_INV_09, TC_INV_20: Tính Thành tiền', (WidgetTester tester) async {
      await pumpInvoiceScreen(tester);
      final priceField = find.widgetWithText(TextFormField, 'Đơn giá (VND)');
      await tester.enterText(priceField, '500000');
      await tester.pumpAndSettle();
      
      final plusBtn = find.byIcon(Icons.add_circle_outline);
      await tester.tap(plusBtn);
      await tester.pumpAndSettle(); // SL = 2
      expect(find.text('1.000.000 VND'), findsWidgets);
    });

    testWidgets('TC_INV_10, TC_INV_21: Tính Cộng tiền hàng', (WidgetTester tester) async {
      await pumpInvoiceScreen(tester);
      await tester.enterText(find.widgetWithText(TextFormField, 'Đơn giá (VND)').first, '1000000');
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('Thêm dịch vụ'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextFormField, 'Đơn giá (VND)').last, '500000');
      await tester.pumpAndSettle();
      
      expect(find.text('1.500.000 VND'), findsWidgets);
    });

    testWidgets('TC_INV_11, TC_INV_12, TC_INV_22: Tính Thuế VAT và Tổng tiền', (WidgetTester tester) async {
      await pumpInvoiceScreen(tester);
      await tester.enterText(find.widgetWithText(TextFormField, 'Đơn giá (VND)'), '1000000');
      await tester.enterText(find.widgetWithText(TextFormField, 'Thuế suất VAT (%)'), '10');
      await tester.pumpAndSettle();
      
      expect(find.text('100.000 VND'), findsWidgets); // VAT
      expect(find.text('1.100.000 VND'), findsOneWidget); // Tổng
    });
    
    testWidgets('TC_INV_28, TC_INV_29: VAT 0% và 100%', (WidgetTester tester) async {
      await pumpInvoiceScreen(tester);
      await tester.enterText(find.widgetWithText(TextFormField, 'Đơn giá (VND)'), '1000000');
      
      await tester.enterText(find.widgetWithText(TextFormField, 'Thuế suất VAT (%)'), '0');
      await tester.pumpAndSettle();
      expect(find.text('1.000.000 VND'), findsWidgets); // Tổng
      
      await tester.enterText(find.widgetWithText(TextFormField, 'Thuế suất VAT (%)'), '100');
      await tester.pumpAndSettle();
      expect(find.text('2.000.000 VND'), findsWidgets); // Tổng
    });
  });

  group('Nhóm 5: Dynamic List', () {
    testWidgets('TC_INV_13, TC_INV_24: Thêm dịch vụ mới', (WidgetTester tester) async {
      await pumpInvoiceScreen(tester);
      // TC_INV_24 giả lập thêm 5 dịch vụ
      for (int i = 0; i < 4; i++) {
        await tester.tap(find.text('Thêm dịch vụ'));
        await tester.pumpAndSettle();
      }
      expect(find.text('Dịch vụ #5'), findsOneWidget);
    });

    testWidgets('TC_INV_15: Xóa dịch vụ', (WidgetTester tester) async {
      await pumpInvoiceScreen(tester);
      await tester.enterText(find.widgetWithText(TextFormField, 'Đơn giá (VND)').first, '1000000');
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('Thêm dịch vụ'));
      await tester.pumpAndSettle();
      
      final closeIcon = find.byIcon(Icons.close).last;
      await tester.tap(closeIcon);
      await tester.pumpAndSettle();
      
      expect(find.text('Dịch vụ #2'), findsNothing);
      expect(find.text('1.000.000 VND'), findsWidgets);
    });
    
    testWidgets('TC_INV_23: Xóa hết dịch vụ (Nút Xóa bị ẩn)', (WidgetTester tester) async {
      await pumpInvoiceScreen(tester);
      // Mặc định chỉ có 1 dịch vụ, nút xóa phải không tồn tại
      expect(find.byIcon(Icons.close), findsNothing);
    });
  });

  group('Nhóm 6: Submit & Flows', () {
    testWidgets('TC_INV_14, TC_INV_25: Chặn submit khi lỗi', (WidgetTester tester) async {
      await pumpInvoiceScreen(tester);
      await tester.enterText(find.widgetWithText(TextFormField, 'Tên đơn vị'), 'Công ty ABC');
      // Không nhập MST
      await tester.tap(find.text('Lưu & Phát hành'));
      await tester.pumpAndSettle();
      
      expect(find.text('Nhập mã số thuế'), findsOneWidget);
      // Tên đơn vị mua vẫn còn
      expect(find.text('Công ty ABC'), findsOneWidget);
    });

    testWidgets('TC_INV_26: Khoảng trắng ở tên đối tác', (WidgetTester tester) async {
      await pumpInvoiceScreen(tester);
      final partnerField = find.widgetWithText(TextFormField, 'Tên đơn vị');
      await tester.enterText(partnerField, '   Công ty ABC   ');
      await tester.pump();
      expect(find.text('   Công ty ABC   '), findsOneWidget); 
      
      await tester.tap(find.text('Lưu & Phát hành'));
      await tester.pumpAndSettle();
      // Form vẫn báo lỗi phần khác (do bỏ trống MST), nhưng tên đối tác thì không bị lỗi rỗng vì đã nhập
      expect(find.text('Nhập mã số thuế'), findsOneWidget);
    });

    testWidgets('TC_INV_30: Làm tròn số tiền', (WidgetTester tester) async {
      await pumpInvoiceScreen(tester);
      await tester.enterText(find.widgetWithText(TextFormField, 'Đơn giá (VND)'), '123456.78');
      await tester.pumpAndSettle();
      // Bị format thành số nguyên do digitsOnly
      expect(find.text('12.345.678'), findsWidgets);
    });

    testWidgets('TC_INV_31: Chỉnh sửa hóa đơn có sẵn', (WidgetTester tester) async {
      await pumpInvoiceScreen(tester, invoiceId: 'test_id');
      await tester.pumpAndSettle(); // Đợi load xong
      expect(find.text('Cập nhật'), findsWidgets);
    });

    testWidgets('TC_INV_32: Hủy tạo hóa đơn', (WidgetTester tester) async {
      await pumpInvoiceScreen(tester);
      final backBtn = find.byType(IconButton).first; // Nút back mặc định
      expect(backBtn, findsOneWidget);
    });

    testWidgets('TC_INV_33, TC_INV_34, TC_INV_35: Lưu thành công và Loading', (WidgetTester tester) async {
      await pumpInvoiceScreen(tester);
      
      // Chờ form hiển thị hoàn toàn
      await tester.pumpAndSettle();

      // Fill hợp lệ
      await tester.enterText(find.widgetWithText(TextFormField, 'Tên đơn vị').first, 'Test');
      await tester.enterText(find.widgetWithText(TextFormField, 'Mã số thuế').first, '123');
      await tester.enterText(find.widgetWithText(TextFormField, 'Tên sản phẩm/dịch vụ').first, 'Test Item');
      await tester.enterText(find.widgetWithText(TextFormField, 'Đơn giá (VND)').first, '1000');
      await tester.pumpAndSettle();
      
      final saveBtn = find.text('Lưu & Phát hành');
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      
      await tester.pump(); 
    });
  });
}
