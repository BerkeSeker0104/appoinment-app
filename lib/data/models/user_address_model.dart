import '../../domain/entities/user_address.dart';

class UserAddressModel extends UserAddress {
  const UserAddressModel({
    required super.id,
    required super.type,
    required super.addressName,
    required super.firstName,
    required super.lastName,
    required super.phoneCode,
    required super.phone,
    required super.countryId,
    required super.cityId,
    required super.address,
    required super.createdAt,
    required super.updatedAt,
  });

  factory UserAddressModel.fromJson(Map<String, dynamic> json) {
    return UserAddressModel(
      id: json['id']?.toString() ?? '',
      type: _parseAddressType(json['type']),
      addressName: json['addressName'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      phoneCode: json['phoneCode'] as String? ?? '',
      phone: json['phone']?.toString() ?? '',
      countryId: _parseInt(json['countryId'] ?? json['country_id']),
      cityId: _parseInt(json['cityId'] ?? json['city_id']),
      address: json['address'] as String? ?? '',
      createdAt: _parseDateTime(json['createdAt'] ?? json['created_at']),
      updatedAt: _parseDateTime(json['updatedAt'] ?? json['updated_at']),
    );
  }

  static AddressType _parseAddressType(dynamic type) {
    if (type == null) return AddressType.delivery;

    final typeString = type.toString().toLowerCase();
    if (typeString == 'invoice') {
      return AddressType.invoice;
    }
    return AddressType.delivery;
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
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
      'type': type == AddressType.invoice ? 'invoice' : 'delivery',
      'addressName': addressName,
      'firstName': firstName,
      'lastName': lastName,
      'phoneCode': phoneCode,
      'phone': phone,
      'countryId': countryId,
      'cityId': cityId,
      'address': address,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory UserAddressModel.fromEntity(UserAddress entity) {
    return UserAddressModel(
      id: entity.id,
      type: entity.type,
      addressName: entity.addressName,
      firstName: entity.firstName,
      lastName: entity.lastName,
      phoneCode: entity.phoneCode,
      phone: entity.phone,
      countryId: entity.countryId,
      cityId: entity.cityId,
      address: entity.address,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  UserAddress toEntity() {
    return UserAddress(
      id: id,
      type: type,
      addressName: addressName,
      firstName: firstName,
      lastName: lastName,
      phoneCode: phoneCode,
      phone: phone,
      countryId: countryId,
      cityId: cityId,
      address: address,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

