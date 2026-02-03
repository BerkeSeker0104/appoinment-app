import 'world_location_model.dart';

class OrderAddressModel {
  final String address;
  final String firstName;
  final String lastName;
  final String phoneCode;
  final String phone;
  final OrderCityModel city;

  const OrderAddressModel({
    required this.address,
    required this.firstName,
    required this.lastName,
    required this.phoneCode,
    required this.phone,
    required this.city,
  });

  factory OrderAddressModel.fromJson(Map<String, dynamic> json) {
    return OrderAddressModel(
      address: json['address'] as String? ?? '',
      firstName: json['firstName'] as String? ?? json['first_name'] as String? ?? '',
      lastName: json['lastName'] as String? ?? json['last_name'] as String? ?? '',
      phoneCode: json['phoneCode'] as String? ?? json['phone_code'] as String? ?? '',
      phone: json['phone']?.toString() ?? '',
      city: OrderCityModel.fromJson(json['city'] as Map<String, dynamic>? ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'firstName': firstName,
      'lastName': lastName,
      'phoneCode': phoneCode,
      'phone': phone,
      'city': city.toJson(),
    };
  }

  String get fullName => '$firstName $lastName';
  String get fullPhone => '$phoneCode$phone';
  String get fullAddress => '$address, ${city.name}, ${city.country.name}';
}

class OrderCityModel {
  final int id;
  final String name;
  final OrderCountryModel country;

  const OrderCityModel({
    required this.id,
    required this.name,
    required this.country,
  });

  factory OrderCityModel.fromJson(Map<String, dynamic> json) {
    return OrderCityModel(
      id: json['id'] is int ? json['id'] : (int.tryParse(json['id']?.toString() ?? '0') ?? 0),
      name: json['name'] as String? ?? '',
      country: OrderCountryModel.fromJson(json['country'] as Map<String, dynamic>? ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'country': country.toJson(),
    };
  }
}

class OrderCountryModel {
  final int id;
  final String name;

  const OrderCountryModel({
    required this.id,
    required this.name,
  });

  factory OrderCountryModel.fromJson(Map<String, dynamic> json) {
    return OrderCountryModel(
      id: json['id'] is int ? json['id'] : (int.tryParse(json['id']?.toString() ?? '0') ?? 0),
      name: json['name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}









