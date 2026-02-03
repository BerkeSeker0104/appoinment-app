import '../entities/user_address.dart';

abstract class UserAddressRepository {
  /// Add a new address
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
  });

  /// Update an existing address
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
  });

  /// Get all addresses for the current user
  Future<List<UserAddress>> getAddresses();

  /// Get address by ID
  Future<UserAddress> getAddressById(String id);

  /// Delete an address
  Future<void> deleteAddress(String id);
}

