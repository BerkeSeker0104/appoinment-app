enum UserType { customer, company }

class User {
  final String id;
  final String email;
  final String name;
  final UserType type;
  final String? phone;
  final String? avatar;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final bool isVerified;
  final String? referenceNumber;

  const User({
    required this.id,
    required this.email,
    required this.name,
    required this.type,
    this.phone,
    this.avatar,
    required this.createdAt,
    this.lastLoginAt,
    this.isVerified = false,
    this.referenceNumber,
  });

  User copyWith({
    String? id,
    String? email,
    String? name,
    UserType? type,
    String? phone,
    String? avatar,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? isVerified,
    String? referenceNumber,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      type: type ?? this.type,
      phone: phone ?? this.phone,
      avatar: avatar ?? this.avatar,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isVerified: isVerified ?? this.isVerified,
      referenceNumber: referenceNumber ?? this.referenceNumber,
    );
  }

  bool get isCustomer => type == UserType.customer;
  bool get isCompany => type == UserType.company;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
