enum TransactionType { income, expense }
enum TransactionStatus { draft, confirmed, deleted }

class TransactionEntity {
  final String id;
  final int amount;
  final TransactionType type;
  final String categoryId;
  final DateTime transactionDate;
  final String? note;
  final TransactionStatus status;
  final String? invoiceId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TransactionEntity({
    required this.id,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.transactionDate,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.note,
    this.invoiceId,
  });
}
