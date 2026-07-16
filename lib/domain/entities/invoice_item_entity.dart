class InvoiceItemEntity {
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
}
