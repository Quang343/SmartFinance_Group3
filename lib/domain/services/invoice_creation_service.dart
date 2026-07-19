import '../../core/providers/role_provider.dart';
import '../entities/invoice_entity.dart';
import '../repositories/invoice_repository.dart';

class InvoiceCreationException implements Exception {
  final String message;
  InvoiceCreationException(this.message);

  @override
  String toString() => message;
}

class InvoiceCreationService {
  final InvoiceRepository _invoiceRepository;

  InvoiceCreationService(this._invoiceRepository);

  /// Tạo hóa đơn bán ra (Outgoing Invoice)
  /// Yêu cầu:
  /// - Người dùng phải có quyền quản lý hóa đơn bán ra (revenueAccountant)
  /// - Hóa đơn phải là loại bán ra (outgoing)
  /// - Dữ liệu hóa đơn phải đầy đủ và hợp lệ
  Future<void> createOutgoingInvoice({
    required UserRole userRole,
    required InvoiceEntity invoice,
  }) async {
    // 1. Kiểm tra quyền của người dùng
    if (!userRole.canManageOutgoingInvoices) {
      throw InvoiceCreationException(
        'Bạn không có quyền tạo hóa đơn bán ra. Chỉ kế toán doanh thu mới được phép thực hiện.',
      );
    }

    // 2. Kiểm tra loại hóa đơn
    if (invoice.type != InvoiceType.outgoing) {
      throw InvoiceCreationException(
        'Loại hóa đơn không hợp lệ. Phải là hóa đơn bán ra (outgoing).',
      );
    }

    // 3. Kiểm tra tính hợp lệ của dữ liệu hóa đơn
    if (invoice.invoiceNumber.isEmpty) {
      throw InvoiceCreationException('Số hóa đơn không được để trống.');
    }
    if (invoice.buyerName.isEmpty) {
      throw InvoiceCreationException('Tên người mua không được để trống.');
    }
    if (invoice.items.isEmpty) {
      throw InvoiceCreationException('Hóa đơn phải có ít nhất một sản phẩm/dịch vụ.');
    }
    if (invoice.totalAmount <= 0) {
      throw InvoiceCreationException('Tổng tiền hóa đơn phải lớn hơn 0.');
    }

    // 4. Thực hiện lưu hóa đơn thông qua repository
    await _invoiceRepository.create(invoice);
  }
}
