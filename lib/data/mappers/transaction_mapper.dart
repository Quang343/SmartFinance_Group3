import '../../domain/entities/transaction_entity.dart';
import '../local/isar_models/isar_transaction.dart';

class TransactionMapper {
  static TransactionEntity toEntity(IsarTransaction model) {
    return TransactionEntity(
      id: model.uid,
      amount: model.amount,
      type: TransactionType.values.byName(model.type),
      categoryId: model.categoryId,
      transactionDate: model.transactionDate,
      status: TransactionStatus.values.byName(model.status),
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
      note: model.note,
      invoiceId: model.invoiceId,
    );
  }

  static IsarTransaction toIsarModel(TransactionEntity entity) {
    return IsarTransaction()
      ..uid = entity.id
      ..amount = entity.amount
      ..type = entity.type.name
      ..categoryId = entity.categoryId
      ..transactionDate = entity.transactionDate
      ..note = entity.note
      ..status = entity.status.name
      ..invoiceId = entity.invoiceId
      ..createdAt = entity.createdAt
      ..updatedAt = entity.updatedAt;
  }
}
