import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/partner_entity.dart';

class PartnerModel extends PartnerEntity {
  const PartnerModel({
    required super.id,
    required super.name,
    required super.taxCode,
    super.address,
    super.phone,
    super.bankName,
    super.bankAccount,
    super.createdByUid = '',
    super.company = '',
    required super.createdAt,
    required super.updatedAt,
  });

  factory PartnerModel.fromJson(Map<String, dynamic> json, String id) {
    return PartnerModel(
      id: id,
      name: json['name'] as String? ?? '',
      taxCode: json['taxCode'] as String? ?? '',
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      bankName: json['bankName'] as String?,
      bankAccount: json['bankAccount'] as String?,
      createdByUid: json['createdByUid'] as String? ?? '',
      company: json['company'] as String? ?? '',
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'taxCode': taxCode,
      'address': address,
      'phone': phone,
      'bankName': bankName,
      'bankAccount': bankAccount,
      'createdByUid': createdByUid,
      'company': company,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
