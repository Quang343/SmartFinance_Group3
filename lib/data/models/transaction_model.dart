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
    required super.title,
    super.note,
    super.invoiceId,
    super.createdByUid,
    super.company,
    super.tags = const [],
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String? ?? '',
      amount: json['amount'] as int? ?? 0,
      type: TransactionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => TransactionType.expense,
      ),
      categoryId: json['categoryId'] as String? ?? '',
      transactionDate: json['transactionDate'] != null 
          ? DateTime.parse(json['transactionDate'] as String) 
          : DateTime.now(),
      status: TransactionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TransactionStatus.draft,
      ),
      title: json['title'] as String? ?? json['note'] as String? ?? 'Chưa có tiêu đề',
      note: json['note'] as String?,
      invoiceId: json['invoiceId'] as String?,
      createdByUid: json['createdByUid'] as String? ?? '',
      company: json['company'] as String? ?? '',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String) 
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'] as String) 
          : DateTime.now(),
      tags: json['tags'] != null 
          ? List<String>.from(json['tags'] as List<dynamic>) 
          : const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'type': type.name,
      'categoryId': categoryId,
      'transactionDate': transactionDate.toIso8601String(),
      'status': status.name,
      'title': title,
      'note': note,
      'invoiceId': invoiceId,
      'createdByUid': createdByUid,
      'company': company,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'tags': tags,
    };
  }
}
