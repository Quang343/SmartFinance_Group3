class PartnerEntity {
  final String id;
  final String name;
  final String taxCode;
  final String? address;
  final String? phone;
  final String? bankName;
  final String? bankAccount;
  final String createdByUid;
  final String company;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PartnerEntity({
    required this.id,
    required this.name,
    required this.taxCode,
    this.address,
    this.phone,
    this.bankName,
    this.bankAccount,
    this.createdByUid = '',
    this.company = '',
    required this.createdAt,
    required this.updatedAt,
  });
}
