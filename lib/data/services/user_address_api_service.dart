import 'dart:convert';
import '../../core/services/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../models/user_address_model.dart';

class UserAddressApiService {
  final ApiClient _apiClient = ApiClient();

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is String) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map<String, dynamic>) return decoded;
      } catch (_) {}
    }
    return <String, dynamic>{};
  }

  /// POST /api/user-address - Add new address
  /// Body: { type, addressName, firstName, lastName, phoneCode, phone, countryId, cityId, address }
  Future<UserAddressModel> addAddress({
    required String type,
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
      final requestData = {
        'type': type,
        'addressName': addressName,
        'firstName': firstName,
        'lastName': lastName,
        'phoneCode': phoneCode,
        'phone': phone,
        'countryId': countryId,
        'cityId': cityId,
        'address': address,
      };
      
      print('AddAddress API Request: $requestData');
      
      final response = await _apiClient.post(
        ApiConstants.userAddress,
        data: requestData,
      );

      print('AddAddress API Response: ${response.data}');
      
      final data = _asMap(response.data);
      
      // Backend might return { data: {...} } or direct object
      final addressData = data['data'] ?? data;
      print('AddAddress parsed data: $addressData');
      
      final result = UserAddressModel.fromJson(addressData as Map<String, dynamic>);
      print('AddAddress result ID: ${result.id}');
      
      return result;
    } catch (e) {
      rethrow;
    }
  }

  /// PUT /api/user-address/{id} - Update address
  /// Body: { type, addressName, firstName, lastName, phoneCode, phone, countryId, cityId, address }
  Future<UserAddressModel> updateAddress({
    required String id,
    required String type,
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
      final response = await _apiClient.put(
        '${ApiConstants.userAddress}/$id',
        data: {
          'type': type,
          'addressName': addressName,
          'firstName': firstName,
          'lastName': lastName,
          'phoneCode': phoneCode,
          'phone': phone,
          'countryId': countryId,
          'cityId': cityId,
          'address': address,
        },
      );

      final data = _asMap(response.data);
      
      // Backend might return { data: {...} } or direct object
      final addressData = data['data'] ?? data;
      return UserAddressModel.fromJson(addressData as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  /// GET /api/user-address - Get all addresses
  /// Returns: List of addresses
  Future<List<UserAddressModel>> getAddresses() async {
    try {
      final response = await _apiClient.get(ApiConstants.userAddress);
      final data = _asMap(response.data);

      List<dynamic> addressesList = [];
      if (data['data'] is List) {
        addressesList = data['data'] as List<dynamic>;
      } else if (data['addresses'] is List) {
        addressesList = data['addresses'] as List<dynamic>;
      } else if (data['items'] is List) {
        addressesList = data['items'] as List<dynamic>;
      } else if (data is List) {
        addressesList = data as List<dynamic>;
      }

      return addressesList.map((json) {
        if (json is Map<String, dynamic>) {
          return UserAddressModel.fromJson(json);
        }
        return UserAddressModel.fromJson(<String, dynamic>{});
      }).toList();
    } catch (e) {
      // If endpoint doesn't exist yet (404), return empty list
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('404') || errorString.contains('bulunamadı')) {
        return [];
      }
      rethrow;
    }
  }

  /// GET /api/user-address/{id} - Get address by ID
  /// Returns: Single address
  Future<UserAddressModel> getAddressById(String id) async {
    try {
      final response = await _apiClient.get('${ApiConstants.userAddress}/$id');
      final data = _asMap(response.data);

      // Backend might return { data: {...} } or direct object
      final addressData = data['data'] ?? data;
      return UserAddressModel.fromJson(addressData as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  /// DELETE /api/user-address/{id} - Delete address
  Future<void> deleteAddress(String id) async {
    try {
      await _apiClient.delete('${ApiConstants.userAddress}/$id');
    } catch (e) {
      rethrow;
    }
  }
}

