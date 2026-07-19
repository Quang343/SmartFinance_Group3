class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String company;
  final String taxCode;
  final String phone;
  final String address;
  final String bankName;
  final String bankAccount;
  final String role;
  final String? avatarUrl;
  final int budgetLimit;
  final int revenueKpi;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.company,
    required this.taxCode,
    required this.phone,
    required this.address,
    required this.bankName,
    required this.bankAccount,
    required this.role,
    this.avatarUrl,
    this.budgetLimit = 20000000,
    this.revenueKpi = 500000000,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, String id) {
    String comp = json['company'] ?? '';
    String tax = json['taxCode'] ?? '';
    if (comp == 'Smart Finance Corp') comp = 'CÔNG TY CỔ PHẦN SMART FINANCE';
    if (['000000', '111111', '222222'].contains(tax)) tax = '0312345678';
    
    return UserModel(
      id: id,
      email: json['email'] ?? '',
      fullName: json['fullName'] ?? '',
      company: comp,
      taxCode: tax,
      phone: json['phone'] ?? '0909123456',
      address: json['address'] ?? 'Tầng 3, Tòa nhà FPT, Khu Công nghệ cao Hòa Lạc',
      bankName: json['bankName'] ?? 'Vietcombank',
      bankAccount: json['bankAccount'] ?? '1010101010',
      role: json['role'] ?? 'Viewer',
      avatarUrl: json['avatarUrl'],
      budgetLimit: (json['budgetLimit'] as num?)?.toInt() ?? 20000000,
      revenueKpi: (json['revenueKpi'] as num?)?.toInt() ?? 500000000,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'fullName': fullName,
      'company': company,
      'taxCode': taxCode,
      'phone': phone,
      'address': address,
      'bankName': bankName,
      'bankAccount': bankAccount,
      'role': role,
      'budgetLimit': budgetLimit,
      'revenueKpi': revenueKpi,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? fullName,
    String? company,
    String? taxCode,
    String? phone,
    String? address,
    String? bankName,
    String? bankAccount,
    String? role,
    String? avatarUrl,
    int? budgetLimit,
    int? revenueKpi,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      company: company ?? this.company,
      taxCode: taxCode ?? this.taxCode,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      bankName: bankName ?? this.bankName,
      bankAccount: bankAccount ?? this.bankAccount,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      budgetLimit: budgetLimit ?? this.budgetLimit,
      revenueKpi: revenueKpi ?? this.revenueKpi,
    );
  }
}
