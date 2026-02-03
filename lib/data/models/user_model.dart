import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.email,
    required super.name,
    required super.type,
    super.phone,
    super.avatar,
    required super.createdAt,
    super.lastLoginAt,
    super.isVerified,
    super.referenceNumber,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Telefon numarasını farklı field'lardan almayı dene
    String? phone;
    if (json['phone'] != null && json['phone'].toString().isNotEmpty) {
      phone = json['phone'].toString();
    } else if (json['phoneCode'] != null && json['phone'] != null) {
      // phoneCode ve phone ayrı ayrı geliyorsa birleştir
      final phoneCode = json['phoneCode'].toString();
      final phoneNumber = json['phone'].toString();
      if (phoneCode.isNotEmpty && phoneNumber.isNotEmpty) {
        phone = '$phoneCode$phoneNumber';
      }
    }
    
    return UserModel(
      id: json['id']?.toString() ?? json['userId']?.toString() ?? '',
      email: json['email'] as String? ?? '',
      name: json['name'] as String? ?? '',
      type: _parseUserType(json['type'] ?? json['userType']),
      phone: phone,
      avatar: json['avatar'] as String?,
      createdAt: _parseDateTime(json['createdAt'] ?? json['created_at']),
      lastLoginAt: _parseDateTime(json['lastLoginAt'] ?? json['last_login_at']),
      isVerified:
          json['isVerified'] as bool? ?? json['verified'] as bool? ?? false,
      referenceNumber: json['referenceNumber'] as String?,
    );
  }

  static UserType _parseUserType(dynamic type) {
    if (type == null) return UserType.customer;

    final typeString = type.toString().toLowerCase();
    if (typeString == 'company' || typeString == 'barber') {
      return UserType.company;
    }
    return UserType.customer;
  }

  static DateTime _parseDateTime(dynamic dateString) {
    if (dateString == null) return DateTime.now();

    try {
      return DateTime.parse(dateString.toString());
    } catch (e) {
      return DateTime.now();
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'type': type.name,
      'phone': phone,
      'avatar': avatar,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'isVerified': isVerified,
      'referenceNumber': referenceNumber,
    };
  }

  factory UserModel.fromEntity(User user) {
    return UserModel(
      id: user.id,
      email: user.email,
      name: user.name,
      type: user.type,
      phone: user.phone,
      avatar: user.avatar,
      createdAt: user.createdAt,
      lastLoginAt: user.lastLoginAt,
      isVerified: user.isVerified,
      referenceNumber: user.referenceNumber,
    );
  }

  User toEntity() {
    return User(
      id: id,
      email: email,
      name: name,
      type: type,
      phone: phone,
      avatar: avatar,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt,
      isVerified: isVerified,
      referenceNumber: referenceNumber,
    );
  }
}
