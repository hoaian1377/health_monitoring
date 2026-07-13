class AdminUser {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String avatar;
  final String birthday;
  final String gender;
  final String role;
  final String status;
  final String createdAt;

  AdminUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.avatar,
    required this.birthday,
    required this.gender,
    required this.role,
    required this.status,
    required this.createdAt,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id']?.toString() ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      avatar: json['avatar'] ?? '',
      birthday: json['birthday'] ?? '',
      gender: json['gender'] ?? '',
      role: json['role'] ?? '',
      status: json['status'] ?? '',
      createdAt: json['createdAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'avatar': avatar,
      'birthday': birthday,
      'gender': gender,
      'role': role,
      'status': status,
      'createdAt': createdAt,
    };
  }

  AdminUser copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phone,
    String? avatar,
    String? birthday,
    String? gender,
    String? role,
    String? status,
    String? createdAt,
  }) {
    return AdminUser(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatar: avatar ?? this.avatar,
      birthday: birthday ?? this.birthday,
      gender: gender ?? this.gender,
      role: role ?? this.role,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
