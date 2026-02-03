import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import '../../core/services/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../models/user_model.dart';
import '../../domain/entities/user.dart';

class AuthApiService {
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

  ({String? token, Map<String, dynamic>? user}) _extractAuth(
    Map<String, dynamic> data,
  ) {
    final root = data;
    final dataNode = _asMap(root['data']);
    final token =
        (root['token'] ??
                dataNode['token'] ??
                root['access_token'] ??
                dataNode['access_token'])
            as String?;
    final user =
        (root['userData'] ?? root['user'] ?? dataNode['user'])
            as Map<String, dynamic>?;
    return (token: token, user: user);
  }

  // Customer Register
  Future<User> customerRegister({
    required String name,
    required String surname,
    required String email,
    required String phoneCode,
    required String phone,
    required String password,
    required String gender,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.customerRegister,
        data: {
          'name': name,
          'surname': surname,
          'email': email,
          'phone_code': phoneCode,
          'phone': phone,
          'password': password,
          'gender': gender,
        },
      );

      final data = _asMap(response.data);
      final auth = _extractAuth(data);
      final token = auth.token;
      final userMap = auth.user;
      if (token != null) {
        await _apiClient.saveToken(token);
      }
      if (userMap != null) {
        await _apiClient.saveUserJson(jsonEncode(userMap));
        return UserModel.fromJson(userMap).toEntity();
      }
      throw Exception('Kullanıcı bilgisi alınamadı');
    } catch (e) {
      rethrow;
    }
  }

  // Company Register - DÜZELTİLDİ
  Future<User> companyRegister({
    required String name,
    required String surname,
    required String email,
    required String phoneCode,
    required String phone,
    required String password,
    required String gender,
    required String companyName,
    required String companyType,
    required String companyAddress,
    required String companyPhoneCode,
    required String companyPhone,
    required String companyEmail,
    File? proQualification,
    File? masterCertificate,
    File? idCardFront,
    File? idCardBack,
  }) async {
    try {
      // FormData oluştur - dosya yükleme için
      final formData = FormData.fromMap({
        'name': name,
        'surname': surname,
        'email': email,
        'phone_code': phoneCode,
        'phone': phone,
        'password': password,
        'gender': gender,
        'company_name': companyName,
        'company_type': companyType,
        'company_address': companyAddress,
        'company_phone_code': companyPhoneCode,
        'company_phone': companyPhone,
        'company_email': companyEmail,
      });

      // Dosyaları ekle
      if (proQualification != null) {
        formData.files.add(
          MapEntry(
            'pro_qualification',
            await MultipartFile.fromFile(proQualification.path),
          ),
        );
      }
      if (masterCertificate != null) {
        formData.files.add(
          MapEntry(
            'master_certificate',
            await MultipartFile.fromFile(masterCertificate.path),
          ),
        );
      }
      if (idCardFront != null) {
        formData.files.add(
          MapEntry(
            'id_card_front',
            await MultipartFile.fromFile(idCardFront.path),
          ),
        );
      }
      if (idCardBack != null) {
        formData.files.add(
          MapEntry(
            'id_card_back',
            await MultipartFile.fromFile(idCardBack.path),
          ),
        );
      }

      final response = await _apiClient.post(
        ApiConstants.companyRegister,
        data: formData,
      );

      final data = _asMap(response.data);
      final auth = _extractAuth(data);
      final token = auth.token;
      final userMap = auth.user;
      if (token != null) {
        await _apiClient.saveToken(token);
      }
      if (userMap != null) {
        await _apiClient.saveUserJson(jsonEncode(userMap));
        return UserModel.fromJson(userMap).toEntity();
      }
      throw Exception('Kullanıcı bilgisi alınamadı');
    } catch (e) {
      rethrow;
    }
  }

  // Login
  Future<User> login({
    required String phoneCode,
    required String phone,
    required String password,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.login,
        data: {
          // Backend formatı: phoneCode, phone, password
          'phoneCode': phoneCode,
          'phone': phone,
          'password': password,
        },
      );

      final data = _asMap(response.data);
      final auth = _extractAuth(data);
      final token = auth.token;
      final userMap = auth.user;
      if (token != null) {
        await _apiClient.saveToken(token);
      }
      if (userMap != null) {
        await _apiClient.saveUserJson(jsonEncode(userMap));
        return UserModel.fromJson(userMap).toEntity();
      }
      throw Exception('Giriş başarısız: kullanıcı veya token eksik');
    } catch (e) {
      rethrow;
    }
  }

  // Send SMS
  Future<void> sendSms({
    required String phoneCode,
    required String phone,
  }) async {
    try {
      await _apiClient.post(
        ApiConstants.smsSend,
        data: {'phone_code': phoneCode, 'phone': phone},
      );
    } catch (e) {
      rethrow;
    }
  }

  // Check SMS Code
  Future<User> checkSmsCode({
    required String phoneCode,
    required String phone,
    required String smsCode,
    String? name,
    String? surname,
    String? email,
    String? gender,
    String? companyName,
    String? companyType,
    String? companyAddress,
    String? companyPhoneCode,
    String? companyPhone,
    String? companyEmail,
    bool isCompanyRegistration = false,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.smsCheck,
        data: {
          'phone_code': phoneCode,
          'phone': phone,
          'code': smsCode,
          'name': name,
          'surname': surname,
          'email': email,
          'gender': gender,
          'company_name': companyName,
          'company_type': companyType,
          'company_address': companyAddress,
          'company_phone_code': companyPhoneCode,
          'company_phone': companyPhone,
          'company_email': companyEmail,
          'is_company_registration': isCompanyRegistration,
        },
      );

      final data = _asMap(response.data);
      final auth = _extractAuth(data);
      final token = auth.token;
      final userMap = auth.user;
      if (token != null) {
        await _apiClient.saveToken(token);
      }
      if (userMap != null) {
        // SMS doğrulama başarılı olduğunda kullanıcıyı doğrulanmış olarak işaretle
        userMap['isVerified'] = true;
        userMap['verified'] = true;
        await _apiClient.saveUserJson(jsonEncode(userMap));
        return UserModel.fromJson(userMap).toEntity();
      }
      throw Exception('Doğrulama başarısız: kullanıcı veya token eksik');
    } catch (e) {
      rethrow;
    }
  }

  // Get current user
  Future<User?> getCurrentUser() async {
    try {
      final token = await _apiClient.getToken();
      if (token == null) {
        return null;
      }

      final response = await _apiClient.get('/api/user');
      final data = _asMap(response.data);
      final userMap = data['user'] ?? data['userData'];
      if (userMap != null) {
        return UserModel.fromJson(userMap).toEntity();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await _apiClient.post('/api/logout');
    } catch (e) {
      // Logout endpoint might not exist, that's okay
    } finally {
      await _apiClient.clearTokens();
    }
  }
}
