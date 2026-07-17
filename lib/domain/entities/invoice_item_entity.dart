import 'package:equatable/equatable.dart';

class InvoiceItemEntity extends Equatable {
  final String id;
  final String itemCode;
  final String itemName;
  final String unit;
  final double quantity;
  final int unitPrice;
  final int totalAmount;

  const InvoiceItemEntity({
    required this.id,
    required this.itemCode,
    required this.itemName,
    required this.unit,
    required this.quantity,
    required this.unitPrice,
    required this.totalAmount,
  });

  InvoiceItemEntity copyWith({
    String? id,
    String? itemCode,
    String? itemName,
    String? unit,
    double? quantity,
    int? unitPrice,
    int? totalAmount,
  }) {
    return InvoiceItemEntity(
      id: id ?? this.id,
      itemCode: itemCode ?? this.itemCode,
      itemName: itemName ?? this.itemName,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalAmount: totalAmount ?? this.totalAmount,
    );
  }

  @override
  List<Object?> get props => [
        id,
        itemCode,
        itemName,
        unit,
        quantity,
        unitPrice,
        totalAmount,
      ];
}
