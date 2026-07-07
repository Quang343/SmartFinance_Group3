class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String company;
  final String taxCode;
  final String role;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.company,
    required this.taxCode,
    required this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, String id) {
    return UserModel(
      id: id,
      email: json['email'] ?? '',
      fullName: json['fullName'] ?? '',
      company: json['company'] ?? '',
      taxCode: json['taxCode'] ?? '',
      role: json['role'] ?? 'Viewer',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'fullName': fullName,
      'company': company,
      'taxCode': taxCode,
      'role': role,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? fullName,
    String? company,
    String? taxCode,
    String? role,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      company: company ?? this.company,
      taxCode: taxCode ?? this.taxCode,
      role: role ?? this.role,
    );
  }
}
