import 'dart:convert';
import '../../core/services/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../models/user_model.dart';

class ProfileApiService {
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

  // Get profile information (raw response)
  Future<Map<String, dynamic>> getProfileRaw() async {
    try {
      final response = await _apiClient.get(ApiConstants.profile);
      final data = _asMap(response.data);

      // Response format: { data: {...} } or { userData: {...} } or direct user object
      Map<String, dynamic> userData;
      if (data['data'] is Map<String, dynamic>) {
        userData = data['data'] as Map<String, dynamic>;
      } else if (data['userData'] is Map<String, dynamic>) {
        userData = data['userData'] as Map<String, dynamic>;
      } else if (data['user'] is Map<String, dynamic>) {
        userData = data['user'] as Map<String, dynamic>;
      } else {
        userData = data;
      }

      return userData;
    } catch (e) {
      throw Exception('Profil bilgileri yüklenirken hata oluştu: $e');
    }
  }

  // Get profile information
  Future<UserModel> getProfile() async {
    final userData = await getProfileRaw();
    return UserModel.fromJson(userData);
  }

  // Update customer profile
  Future<UserModel> updateCustomerProfile({
    required String name,
    required String surname,
    required String email,
    required String gender,
    String? password,
  }) async {
    try {
      final body = <String, dynamic>{
        'name': name,
        'surname': surname,
        'email': email,
        'gender': gender,
        'password': password ?? '',
      };

      final response = await _apiClient.put(
        ApiConstants.profile,
        data: body,
      );

      final data = _asMap(response.data);

      // Response format: { data: {...} } or { userData: {...} } or direct user object
      Map<String, dynamic> userData;
      if (data['data'] is Map<String, dynamic>) {
        userData = data['data'] as Map<String, dynamic>;
      } else if (data['userData'] is Map<String, dynamic>) {
        userData = data['userData'] as Map<String, dynamic>;
      } else if (data['user'] is Map<String, dynamic>) {
        userData = data['user'] as Map<String, dynamic>;
      } else {
        userData = data;
      }

      return UserModel.fromJson(userData);
    } catch (e) {
      throw Exception('Profil güncellenirken hata oluştu: $e');
    }
  }

  // Update company profile
  Future<UserModel> updateCompanyProfile({
    required String iban,
  }) async {
    try {
      final body = <String, dynamic>{
        'iban': iban,
      };

      final response = await _apiClient.put(
        ApiConstants.profile,
        data: body,
      );

      final data = _asMap(response.data);

      // Response format: { data: {...} } or { userData: {...} } or direct user object
      Map<String, dynamic> userData;
      if (data['data'] is Map<String, dynamic>) {
        userData = data['data'] as Map<String, dynamic>;
      } else if (data['userData'] is Map<String, dynamic>) {
        userData = data['userData'] as Map<String, dynamic>;
      } else if (data['user'] is Map<String, dynamic>) {
        userData = data['user'] as Map<String, dynamic>;
      } else {
        userData = data;
      }

      return UserModel.fromJson(userData);
    } catch (e) {
      throw Exception('Profil güncellenirken hata oluştu: $e');
    }
  }

  // Request phone number change
  Future<Map<String, dynamic>> requestPhoneChange({
    required String phoneCode,
    required String phone,
  }) async {
    final body = <String, dynamic>{
      'phoneCode': phoneCode,
      'newPhone': phone,
    };

    final response = await _apiClient.put(
      ApiConstants.phoneChange,
      data: body,
    );

    final data = _asMap(response.data);
    return {
      'success': true,
      'message': data['message'] ?? '',
      'data': data,
    };
  }

  // Approve phone number change with SMS code
  Future<Map<String, dynamic>> approvePhoneChange({
    required String smsCode,
  }) async {
    final body = <String, dynamic>{
      'code': smsCode,
    };

    final response = await _apiClient.put(
      ApiConstants.phoneChangeApprove,
      data: body,
    );

    final data = _asMap(response.data);
    return {
      'success': true,
      'message': data['message'] ?? '',
      'data': data,
    };
  }

  // Delete user account
  Future<void> deleteUser(String userId) async {
    try {
      await _apiClient.delete('${ApiConstants.users}/$userId');
    } catch (e) {
      throw Exception('Hesap silinirken hata oluştu: $e');
    }
  }
}

