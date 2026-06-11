import '../../domain/entities/invoice_entity.dart';
import '../local/isar_models/isar_invoice.dart';

class InvoiceMapper {
  static InvoiceEntity toEntity(IsarInvoice model) {
    return InvoiceEntity(
      id: model.uid,
      invoiceNumber: model.invoiceNumber,
      partnerName: model.partnerName,
      partnerTaxCode: model.partnerTaxCode,
      subtotal: model.subtotal,
      vatRate: model.vatRate,
      vatAmount: model.vatAmount,
      totalAmount: model.totalAmount,
      ocrStatus: OcrStatus.values.byName(model.ocrStatus),
      issuedDate: model.issuedDate,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
      imagePath: model.imagePath,
      ocrConfidence: model.ocrConfidence,
    );
  }

  static IsarInvoice toIsarModel(InvoiceEntity entity) {
    return IsarInvoice()
      ..uid = entity.id
      ..invoiceNumber = entity.invoiceNumber
      ..partnerName = entity.partnerName
      ..partnerTaxCode = entity.partnerTaxCode
      ..subtotal = entity.subtotal
      ..vatRate = entity.vatRate
      ..vatAmount = entity.vatAmount
      ..totalAmount = entity.totalAmount
      ..imagePath = entity.imagePath
      ..ocrStatus = entity.ocrStatus.name
      ..ocrConfidence = entity.ocrConfidence
      ..issuedDate = entity.issuedDate
      ..createdAt = entity.createdAt
      ..updatedAt = entity.updatedAt;
  }
}
