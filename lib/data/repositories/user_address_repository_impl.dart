import '../../domain/entities/user_address.dart';
import '../../domain/repositories/user_address_repository.dart';
import '../services/user_address_api_service.dart';
import '../models/user_address_model.dart';

class UserAddressRepositoryImpl implements UserAddressRepository {
  final UserAddressApiService _apiService = UserAddressApiService();

  // Convert Model to Entity
  UserAddress _modelToEntity(UserAddressModel model) {
    return model.toEntity();
  }

  @override
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
    try {
      final model = await _apiService.addAddress(
        type: type == AddressType.invoice ? 'invoice' : 'delivery',
        addressName: addressName,
        firstName: firstName,
        lastName: lastName,
        phoneCode: phoneCode,
        phone: phone,
        countryId: countryId,
        cityId: cityId,
        address: address,
      );
      return _modelToEntity(model);
    } catch (e) {
      rethrow;
    }
  }

  @override
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
    try {
      final model = await _apiService.updateAddress(
        id: id,
        type: type == AddressType.invoice ? 'invoice' : 'delivery',
        addressName: addressName,
        firstName: firstName,
        lastName: lastName,
        phoneCode: phoneCode,
        phone: phone,
        countryId: countryId,
        cityId: cityId,
        address: address,
      );
      return _modelToEntity(model);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<UserAddress>> getAddresses() async {
    try {
      final models = await _apiService.getAddresses();
      return models.map((model) => _modelToEntity(model)).toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<UserAddress> getAddressById(String id) async {
    try {
      final model = await _apiService.getAddressById(id);
      return _modelToEntity(model);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> deleteAddress(String id) async {
    try {
      await _apiService.deleteAddress(id);
    } catch (e) {
      rethrow;
    }
  }
}

