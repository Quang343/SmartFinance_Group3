import '../../domain/entities/transaction_entity.dart';

class TransactionModel extends TransactionEntity {
  const TransactionModel({
    required super.id,
    required super.amount,
    required super.type,
    required super.categoryId,
    required super.transactionDate,
    required super.status,
    required super.createdAt,
    required super.updatedAt,
    super.note,
    super.invoiceId,
  });
}
