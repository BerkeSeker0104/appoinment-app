import '../entities/user_address.dart';
import '../repositories/user_address_repository.dart';

class UserAddressUseCases {
  final UserAddressRepository _repository;

  UserAddressUseCases(this._repository);

  /// Add a new address with validation
  Future<UserAddress> addAddress({
    required AddressType type,
    required String addressName,
    required String firstName,
    required String lastName,
    required String phoneCode,
    required String phone,
    required int countryId,
    required int cityId,
    required String address,
  }) async {
    // Validation
    if (addressName.trim().isEmpty) {
      throw Exception('Adres adı gereklidir');
    }
    if (firstName.trim().isEmpty) {
      throw Exception('Ad gereklidir');
    }
    if (lastName.trim().isEmpty) {
      throw Exception('Soyad gereklidir');
    }
    if (phoneCode.trim().isEmpty) {
      throw Exception('Telefon kodu gereklidir');
    }
    if (phone.trim().isEmpty) {
      throw Exception('Telefon numarası gereklidir');
    }
    if (countryId <= 0) {
      throw Exception('Ülke seçimi gereklidir');
    }
    if (cityId <= 0) {
      throw Exception('Şehir seçimi gereklidir');
    }
    if (address.trim().isEmpty) {
      throw Exception('Adres gereklidir');
    }

    try {
      return await _repository.addAddress(
        type: type,
        addressName: addressName.trim(),
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        phoneCode: phoneCode.trim(),
        phone: phone.trim(),
        countryId: countryId,
        cityId: cityId,
        address: address.trim(),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Update an existing address with validation
  Future<UserAddress> updateAddress({
    required String id,
    required AddressType type,
    required String addressName,
    required String firstName,
    required String lastName,
    required String phoneCode,
    required String phone,
    required int countryId,
    required int cityId,
    required String address,
  }) async {
    // Validation
    if (id.isEmpty) {
      throw Exception('Adres ID\'si gereklidir');
    }
    if (addressName.trim().isEmpty) {
      throw Exception('Adres adı gereklidir');
    }
    if (firstName.trim().isEmpty) {
      throw Exception('Ad gereklidir');
    }
    if (lastName.trim().isEmpty) {
      throw Exception('Soyad gereklidir');
    }
    if (phoneCode.trim().isEmpty) {
      throw Exception('Telefon kodu gereklidir');
    }
    if (phone.trim().isEmpty) {
      throw Exception('Telefon numarası gereklidir');
    }
    if (countryId <= 0) {
      throw Exception('Ülke seçimi gereklidir');
    }
    if (cityId <= 0) {
      throw Exception('Şehir seçimi gereklidir');
    }
    if (address.trim().isEmpty) {
      throw Exception('Adres gereklidir');
    }

    try {
      return await _repository.updateAddress(
        id: id,
        type: type,
        addressName: addressName.trim(),
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        phoneCode: phoneCode.trim(),
        phone: phone.trim(),
        countryId: countryId,
        cityId: cityId,
        address: address.trim(),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Get all addresses
  Future<List<UserAddress>> getAddresses() async {
    try {
      return await _repository.getAddresses();
    } catch (e) {
      rethrow;
    }
  }

  /// Get address by ID
  Future<UserAddress> getAddressById(String id) async {
    if (id.isEmpty) {
      throw Exception('Adres ID\'si gereklidir');
    }

    try {
      return await _repository.getAddressById(id);
    } catch (e) {
      rethrow;
    }
  }

  /// Delete an address
  Future<void> deleteAddress(String id) async {
    if (id.isEmpty) {
      throw Exception('Adres ID\'si gereklidir');
    }

    try {
      await _repository.deleteAddress(id);
    } catch (e) {
      rethrow;
    }
  }

  /// Get addresses filtered by type
  Future<List<UserAddress>> getAddressesByType(AddressType type) async {
    try {
      final addresses = await _repository.getAddresses();
      return addresses.where((address) => address.type == type).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get delivery addresses
  Future<List<UserAddress>> getDeliveryAddresses() async {
    return getAddressesByType(AddressType.delivery);
  }

  /// Get invoice addresses
  Future<List<UserAddress>> getInvoiceAddresses() async {
    return getAddressesByType(AddressType.invoice);
  }
}

