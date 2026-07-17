class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String company;
  final String taxCode;
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
    required this.role,
    this.avatarUrl,
    this.budgetLimit = 20000000,
    this.revenueKpi = 500000000,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, String id) {
    return UserModel(
      id: id,
      email: json['email'] ?? '',
      fullName: json['fullName'] ?? '',
      company: json['company'] ?? '',
      taxCode: json['taxCode'] ?? '',
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
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      budgetLimit: budgetLimit ?? this.budgetLimit,
      revenueKpi: revenueKpi ?? this.revenueKpi,
    );
  }
}
