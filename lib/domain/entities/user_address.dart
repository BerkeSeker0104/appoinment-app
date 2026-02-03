enum AddressType {
  delivery,
  invoice,
}

class UserAddress {
  final String id;
  final AddressType type;
  final String addressName;
  final String firstName;
  final String lastName;
  final String phoneCode;
  final String phone;
  final int countryId;
  final int cityId;
  final String address;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserAddress({
    required this.id,
    required this.type,
    required this.addressName,
    required this.firstName,
    required this.lastName,
    required this.phoneCode,
    required this.phone,
    required this.countryId,
    required this.cityId,
    required this.address,
    required this.createdAt,
    required this.updatedAt,
  });

  UserAddress copyWith({
    String? id,
    AddressType? type,
    String? addressName,
    String? firstName,
    String? lastName,
    String? phoneCode,
    String? phone,
    int? countryId,
    int? cityId,
    String? address,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserAddress(
      id: id ?? this.id,
      type: type ?? this.type,
      addressName: addressName ?? this.addressName,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phoneCode: phoneCode ?? this.phoneCode,
      phone: phone ?? this.phone,
      countryId: countryId ?? this.countryId,
      cityId: cityId ?? this.cityId,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get fullName => '$firstName $lastName';
  String get fullPhone => '$phoneCode$phone';
}

