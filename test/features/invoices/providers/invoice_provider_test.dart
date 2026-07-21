import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_finance/domain/entities/invoice_entity.dart';
import 'package:smart_finance/domain/repositories/invoice_repository.dart';
import 'package:smart_finance/core/providers/app_providers.dart';
import 'package:smart_finance/features/invoices/providers/invoice_provider.dart';

class FakeInvoiceRepository extends Mock implements InvoiceRepository {}

InvoiceEntity _inv(String id) => InvoiceEntity(
      id: id,
      invoiceNumber: 'INV-$id',
      sellerName: 'Đối tác',
      sellerTaxCode: '000',
      buyerName: 'Người mua',
      buyerTaxCode: '001',
      subtotal: 100,
      vatRate: 10,
      vatAmount: 10,
      totalAmount: 110,
      ocrStatus: OcrStatus.extracted,
      transactionStatus: InvoiceTransactionStatus.notCreated,
      issuedDate: DateTime(2026),
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      type: InvoiceType.incoming,
      imagePath: 'path',
      ocrConfidence: 0.9,
    );

void main() {
  late FakeInvoiceRepository fake;
  late ProviderContainer container;

  setUp(() {
    fake = FakeInvoiceRepository();
    container = ProviderContainer(overrides: [invoiceRepositoryProvider.overrideWithValue(fake)]);
    registerFallbackValue(OcrStatus.extracted);
  });
  tearDown(() => container.dispose());

  test('allInvoicesProvider trả toàn bộ', () async {
    when(() => fake.getAll()).thenAnswer((_) async => [_inv('1'), _inv('2')]);
    final r = await container.read(allInvoicesProvider.future);
    expect(r.length, 2);
  });

  test('invoiceByIdProvider(id) gọi getById', () async {
    when(() => fake.getById('1')).thenAnswer((_) async => _inv('1'));
    final r = await container.read(invoiceByIdProvider('1').future);
    expect(r?.id, '1');
  });

  test('invoicesByOcrStatusProvider(status) gọi getByOcrStatus', () async {
    when(() => fake.getByOcrStatus(OcrStatus.extracted)).thenAnswer((_) async => [_inv('1')]);
    final r = await container.read(invoicesByOcrStatusProvider(OcrStatus.extracted).future);
    expect(r.first.ocrStatus, OcrStatus.extracted);
  });
}
