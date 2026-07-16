import '../../domain/entities/invoice_item_entity.dart';

class InvoiceItemModel extends InvoiceItemEntity {
  const InvoiceItemModel({
    required super.id,
    required super.itemCode,
    required super.itemName,
    required super.unit,
    required super.quantity,
    required super.unitPrice,
    required super.totalAmount,
  });

  factory InvoiceItemModel.fromJson(Map<String, dynamic> json) {
    return InvoiceItemModel(
      id: json['id'] as String,
      itemCode: json['itemCode'] as String,
      itemName: json['itemName'] as String,
      unit: json['unit'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      unitPrice: json['unitPrice'] as int,
      totalAmount: json['totalAmount'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'itemCode': itemCode,
      'itemName': itemName,
      'unit': unit,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalAmount': totalAmount,
    };
  }

  factory InvoiceItemModel.fromEntity(InvoiceItemEntity entity) {
    return InvoiceItemModel(
      id: entity.id,
      itemCode: entity.itemCode,
      itemName: entity.itemName,
      unit: entity.unit,
      quantity: entity.quantity,
      unitPrice: entity.unitPrice,
      totalAmount: entity.totalAmount,
    );
  }
}
