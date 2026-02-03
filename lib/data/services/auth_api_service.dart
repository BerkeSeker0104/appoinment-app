import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

import '../../core/constants/api_constants.dart';
import '../../core/services/api_client.dart';
import '../../domain/entities/user.dart';
import '../models/user_model.dart';

// Company registration başarılı ama SMS doğrulama gerektiren durum için özel exception
class CompanyRegistrationSuccessException implements Exception {
  final String message;
  CompanyRegistrationSuccessException({required this.message});

  @override
  String toString() => message;
}

// Login sırasında hesap doğrulanmamış durumu için özel exception
class AccountNotVerifiedException implements Exception {
  final String message;
  final String phoneCode;
  final String phone;

  AccountNotVerifiedException({
    required this.message,
    required this.phoneCode,
    required this.phone,
  });

  @override
  String toString() => message;
}

class AuthApiService {
  final ApiClient _apiClient = ApiClient();

  // Görsel sıkıştırma ve format dönüştürme
  Future<File?> _compressImage(File file) async {
    try {
      final filePath = file.absolute.path;
      final lastIndex = filePath.lastIndexOf('.');
      final extension = filePath.substring(lastIndex + 1).toLowerCase();

      // Desteklenen formatları kontrol et
      const supportedFormats = [
        '.jpg',
        '.jpeg',
        '.png',
        '.gif',
        '.webp',
        '.avif'
      ];
      final supportedExtension = supportedFormats.firstWhere(
        (format) => extension == format.substring(1),
        orElse: () => '.jpg', // Varsayılan olarak jpg
      );

      final outPath =
          '${filePath.substring(0, lastIndex)}_compressed$supportedExtension';

      // Format'a göre CompressFormat belirle
      CompressFormat compressFormat;
      switch (supportedExtension) {
        case '.png':
          compressFormat = CompressFormat.png;
          break;
        case '.webp':
          compressFormat = CompressFormat.webp;
          break;
        default:
          compressFormat = CompressFormat.jpeg; // jpg, jpeg, gif, avif için
      }

      final result = await FlutterImageCompress.compressAndGetFile(
        filePath,
        outPath,
        quality: 85,
        format: compressFormat,
      );

      if (result != null) {
        return File(result.path);
      }
      return file;
    } catch (e) {
      return file;
    }
  }

  // Dosya uzantısını al
  String _getFileExtension(String filePath) {
    final lastIndex = filePath.lastIndexOf('.');
    if (lastIndex == -1) return '.jpg';

    final extension = filePath.substring(lastIndex).toLowerCase();
    const supportedFormats = [
      '.jpg',
      '.jpeg',
      '.png',
      '.gif',
      '.webp',
      '.avif'
    ];

    return supportedFormats.contains(extension) ? extension : '.jpg';
  }

  // Dosya formatının geçerli olup olmadığını kontrol et
  bool _isValidImageFormat(String filePath) {
    final extension = _getFileExtension(filePath);
    const supportedFormats = [
      '.jpg',
      '.jpeg',
      '.png',
      '.gif',
      '.webp',
      '.avif'
    ];
    return supportedFormats.contains(extension);
  }

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

  Map<String, dynamic> _decodeJwtPayload(String? token) {
    if (token == null || token.isEmpty) return const {};
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        return const {};
      }
      final payloadSegment = base64Url.normalize(parts[1]);
      final payloadString =
          utf8.decode(base64Url.decode(payloadSegment), allowMalformed: true);
      final payload = jsonDecode(payloadString);
      if (payload is Map<String, dynamic>) {
        return payload;
      }
    } catch (_) {
      // ignore malformed token
    }
    return const {};
  }

  Map<String, dynamic>? _userMapFromToken(String? token) {
    final payload = _decodeJwtPayload(token);
    if (payload.isEmpty) return null;

    final id = payload['id'] ??
        payload['userId'] ??
        payload['sub'] ??
        payload['user_id'];
    final name = payload['name'] ?? payload['fullName'];
    final email = payload['email'];

    if ((id == null || id.toString().isEmpty) &&
        (email == null || email.toString().isEmpty)) {
      return null;
    }

    return <String, dynamic>{
      'id': id?.toString() ?? '',
      'name': name?.toString() ?? '',
      'email': email?.toString() ?? '',
      'type': payload['type'] ?? payload['userType'] ?? payload['role'],
      'userType': payload['userType'] ?? payload['type'] ?? payload['role'],
      'phone': payload['phone'] ?? payload['phoneNumber'],
      'avatar': payload['avatar'] ?? payload['photoUrl'],
      'createdAt': payload['createdAt'] ??
          payload['created_at'] ??
          payload['iat']?.toString(),
      'lastLoginAt': payload['lastLoginAt'] ??
          payload['last_login_at'] ??
          payload['auth_time']?.toString(),
      'isVerified': payload['verified'] ?? payload['isVerified'] ?? true,
    };
  }

  ({String? token, Map<String, dynamic>? user}) _extractAuth(
    Map<String, dynamic> data,
  ) {
    final root = data;
    final dataNode = _asMap(root['data']);
    final token = (root['token'] ??
        dataNode['token'] ??
        root['access_token'] ??
        dataNode['access_token']) as String?;

    final user = (root['userData'] ??
        root['user'] ??
        dataNode['userData'] ??
        dataNode['user']) as Map<String, dynamic>?;
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
    String? deviceToken,
    String? referenceNumber,
  }) async {
    try {
      final requestData = {
        'name': name,
        'surname': surname,
        'email': email,
        'phoneCode': phoneCode,
        'phone': phone,
        'password': password,
        'gender': gender,
        if (deviceToken != null && deviceToken.isNotEmpty)
          'deviceToken': deviceToken,
        if (referenceNumber != null && referenceNumber.isNotEmpty)
          'referenceNumber': referenceNumber,
      };

      if (kDebugMode) {
        final maskedData = Map.of(requestData)..remove('password');
        debugPrint('AuthApiService.customerRegister payload: $maskedData');
      }

      final response = await _apiClient.post(
        ApiConstants.customerRegister,
        data: requestData,
      );

      final data = _asMap(response.data);
      final auth = _extractAuth(data);
      final token = auth.token;
      var userMap = auth.user;
      if (token != null) {
        await _apiClient.saveToken(token);
      }
      if (userMap != null) {
        // Eğer backend'den telefon numarası gelmiyorsa, register sırasında kullanılan telefon numarasını ekle
        if ((userMap['phone'] == null || userMap['phone'].toString().isEmpty) &&
            phone.isNotEmpty) {
          // Telefon numarasını birleştir: phoneCode + phone
          final fullPhone = '$phoneCode$phone';
          userMap['phone'] = fullPhone;
          userMap['phoneCode'] = phoneCode;
        }
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
    required int companyType,
    required String companyAddress,
    required String companyPhoneCode,
    required String companyPhone,
    required String companyEmail,
    double? companyLatitude,
    double? companyLongitude,
    required int countryId, // YENİ
    required int cityId, // YENİ
    required int stateId, // YENİ
    required String iban, // YENİ
    required String taxNumber, // YENİ
    File? taxPlate, // YENİ
    File? masterCertificate,
    String? deviceToken, // OPSİYONEL - token varsa gönderilir
    String? paidTypes, // YENİ - virgülle ayrılmış string
    String? referenceNumber, // REFERANS KODU - opsiyonel
    // proQualification, idCardFront, idCardBack KALDIRILDI
  }) async {
    try {
      // FormData oluştur - backend formatına göre
      final formData = FormData.fromMap({
        'name': name,
        'surname': surname,
        'email': email,
        'phoneCode': phoneCode,
        'phone': phone,
        'password': password,
        'rePassword': password,
        'gender': gender,
        'companyName': companyName,
        'companyType': companyType,
        'companyAddress': companyAddress,
        'companyPhoneCode': companyPhoneCode,
        'companyPhone': companyPhone,
        'companyEmail': companyEmail,
        if (companyLatitude != null) 'companyLat': companyLatitude,
        if (companyLongitude != null) 'companyLng': companyLongitude,
        'countryId': countryId, // YENİ
        'cityId': cityId, // YENİ
        'stateId': stateId, // YENİ
        'iban': iban, // YENİ
        'taxNumber': taxNumber, // YENİ
        if (deviceToken != null && deviceToken.isNotEmpty)
          'deviceToken': deviceToken, // OPSİYONEL
        if (paidTypes != null && paidTypes.isNotEmpty)
          'paidTypes': paidTypes, // YENİ
        if (referenceNumber != null && referenceNumber.isNotEmpty)
          'referenceNumber': referenceNumber, // REFERANS KODU
      });

      if (kDebugMode) {
        final maskedFields = {
          for (final entry in formData.fields) entry.key: entry.value,
        };
        debugPrint('AuthApiService.companyRegister fields: $maskedFields');
      }

      // Dosyaları ekle - Backend formatına uygun
      if (taxPlate != null) {
        // Dosya formatını kontrol et
        if (!_isValidImageFormat(taxPlate.path)) {
          throw Exception(
              'taxPlate dosyası desteklenmeyen format. Desteklenen formatlar: .jpg, .jpeg, .png, .gif, .webp, .avif');
        }

        // Görseli sıkıştır ve format dönüştür
        final compressedFile = await _compressImage(taxPlate);
        if (compressedFile == null) {
          throw Exception('Dosya sıkıştırma başarısız oldu.');
        }

        // Dosya boyutu kontrolü
        final fileSize = await compressedFile.length();
        if (fileSize > 10 * 1024 * 1024) {
          // 10MB limit
          throw Exception('Dosya boyutu çok büyük. Maksimum 10MB olmalıdır.');
        }

        formData.files.add(
          MapEntry(
            'taxPlate',
            await MultipartFile.fromFile(
              compressedFile.path,
              filename: 'taxPlate${_getFileExtension(compressedFile.path)}',
            ),
          ),
        );
      }
      if (masterCertificate != null) {
        // Dosya formatını kontrol et
        if (!_isValidImageFormat(masterCertificate.path)) {
          throw Exception(
              'masterCertificate dosyası desteklenmeyen format. Desteklenen formatlar: .jpg, .jpeg, .png, .gif, .webp, .avif');
        }

        // Görseli sıkıştır ve format dönüştür
        final compressedFile = await _compressImage(masterCertificate);
        if (compressedFile == null) {
          throw Exception('Dosya sıkıştırma başarısız oldu.');
        }

        // Dosya boyutu kontrolü
        final fileSize = await compressedFile.length();
        if (fileSize > 10 * 1024 * 1024) {
          // 10MB limit
          throw Exception('Dosya boyutu çok büyük. Maksimum 10MB olmalıdır.');
        }

        formData.files.add(
          MapEntry(
            'masterCertificate',
            await MultipartFile.fromFile(
              compressedFile.path,
              filename:
                  'masterCertificate${_getFileExtension(compressedFile.path)}',
            ),
          ),
        );
      }

      if (kDebugMode) {
        debugPrint('AuthApiService.companyRegister: Sending request to ${ApiConstants.companyRegister}');
      }

      final response = await _apiClient.post(
        ApiConstants.companyRegister,
        data: formData,
      );

      if (kDebugMode) {
        debugPrint('AuthApiService.companyRegister: Received response with status ${response.statusCode}');
      }

      final data = _asMap(response.data);

      // Eğer response'da userData/user yoksa, nested data içinde olabilir
      final nestedData = _asMap(data['data']);

      // Company register için user type'ı ayarla
      final userDataNode = _asMap(data['userData'] ??
          data['user'] ??
          nestedData['userData'] ??
          nestedData['user']);

      if (userDataNode.isNotEmpty &&
          !userDataNode.containsKey('type') &&
          !userDataNode.containsKey('userType')) {
        userDataNode['type'] = 'company';
        data['userData'] = userDataNode;
        data['user'] = userDataNode;
      }

      final auth = _extractAuth(data);
      final token = auth.token;
      final userMap = auth.user;

      // Eğer userData/user yoksa ama status true ise, kayıt başarılıdır
      // Ancak yeni kayıt olan hesaplar doğrulanmamış olabilir, bu yüzden otomatik login yapmayız
      // Bunun yerine SMS doğrulama sayfasına yönlendirilmesi gerekiyor
      if (userMap == null && data['status'] == true) {
        // Özel exception fırlat - company register page'de yakalanıp SMS sayfasına yönlendirilecek
        throw CompanyRegistrationSuccessException(
          message: 'Kayıt başarılı. SMS doğrulama için yönlendiriliyorsunuz...',
        );
      }

      if (token != null) {
        await _apiClient.saveToken(token);
      }

      if (userMap != null) {
        await _apiClient.saveUserJson(jsonEncode(userMap));
        return UserModel.fromJson(userMap).toEntity();
      }
      throw Exception('Kullanıcı bilgisi alınamadı');
    } catch (e) {
      // ApiClient already handles DioException and parses error messages
      rethrow;
    }
  }

  // Login
  Future<User> login({
    required String phoneCode,
    required String phone,
    required String password,
    String? deviceToken,
  }) async {
    try {
      final requestData = {
        // Backend formatı: phoneCode, phone, password
        'phoneCode': phoneCode,
        'phone': phone,
        'password': password,
        if (deviceToken != null && deviceToken.isNotEmpty)
          'deviceToken': deviceToken,
      };

      if (kDebugMode) {
        final maskedData = Map.of(requestData)..remove('password');
        debugPrint('AuthApiService.login payload: $maskedData');
      }

      final response = await _apiClient.post(
        ApiConstants.login,
        data: requestData,
      );

      final data = _asMap(response.data);

      // Hesap doğrulanmamış kontrolü: isCheck: 1 ve status: false
      final isCheck = data['isCheck'];
      final status = data['status'];
      if (isCheck == 1 && status == false) {
        throw AccountNotVerifiedException(
          message: data['message']?.toString() ?? 'Hesap doğrulanmamış',
          phoneCode: phoneCode,
          phone: phone,
        );
      }

      // Eğer companyData varsa, user type'ı company olarak ayarla
      if (data.containsKey('companyData') || data.containsKey('company')) {
        final userDataNode = _asMap(data['userData'] ?? data['user']);
        if (userDataNode.isNotEmpty &&
            !userDataNode.containsKey('type') &&
            !userDataNode.containsKey('userType')) {
          userDataNode['type'] = 'company';
          data['userData'] = userDataNode;
          data['user'] = userDataNode;
        }
      }

      final auth = _extractAuth(data);
      final token = auth.token;
      var userMap = auth.user;
      if (token != null) {
        await _apiClient.saveToken(token);
      }
      if (userMap != null) {
        // Eğer backend'den telefon numarası gelmiyorsa, login sırasında kullanılan telefon numarasını ekle
        if ((userMap['phone'] == null || userMap['phone'].toString().isEmpty) &&
            phone.isNotEmpty) {
          // Telefon numarasını birleştir: phoneCode + phone
          final fullPhone = '$phoneCode$phone';
          userMap['phone'] = fullPhone;
          userMap['phoneCode'] = phoneCode;
        }
        await _apiClient.saveUserJson(jsonEncode(userMap));
        return UserModel.fromJson(userMap).toEntity();
      }
      throw Exception('Giriş başarısız: kullanıcı veya token eksik');
    } catch (e) {
      rethrow;
    }
  }

  Future<User> googleRegister({
    required String idToken,
    String? accessToken,
    String? email,
    String? name,
    String? avatar,
    required String deviceToken,
  }) async {
    try {
      final requestData = <String, dynamic>{
        'idToken': idToken,
        'token': idToken,
        'deviceToken': deviceToken,
      };

      final response = await _apiClient.post(
        ApiConstants.googleMobileRegister,
        data: requestData,
      );

      final data = _asMap(response.data);
      final auth = _extractAuth(data);
      final token = auth.token;
      final userMap = auth.user;

      if (userMap != null) {
        userMap.putIfAbsent('type', () => 'customer');
        userMap.putIfAbsent('userType', () => 'customer');
      }

      if (token != null) {
        await _apiClient.saveToken(token);
      }
      final resolvedUserMap = userMap ?? _userMapFromToken(token);
      if (resolvedUserMap != null) {
        if (resolvedUserMap['type'] == null &&
            resolvedUserMap['userType'] == null) {
          resolvedUserMap['type'] = 'customer';
          resolvedUserMap['userType'] = 'customer';
        }
        await _apiClient.saveUserJson(jsonEncode(resolvedUserMap));
        return UserModel.fromJson(resolvedUserMap).toEntity();
      }

      final message = data['message'] as String?;
      throw Exception(message ?? 'Google ile giriş başarısız oldu.');
    } catch (e) {
      // ApiClient already handles DioException and parses error messages
      rethrow;
    }
  }

  Future<User> appleRegister({
    required String identityToken,
    required String authorizationCode,
    String? email,
    String? name,
    required String deviceToken,
  }) async {
    try {
      final requestData = <String, dynamic>{
        'idToken': identityToken,
        'identityToken': identityToken,
        'authorizationCode': authorizationCode,
        'token': identityToken,
        'deviceToken': deviceToken,
        if (email != null && email.isNotEmpty) 'email': email,
        if (name != null && name.isNotEmpty) 'name': name,
      };

      final response = await _apiClient.post(
        ApiConstants.appleMobileRegister,
        data: requestData,
      );

      final data = _asMap(response.data);
      final auth = _extractAuth(data);
      final token = auth.token;
      final userMap = auth.user;

      if (userMap != null) {
        userMap.putIfAbsent('type', () => 'customer');
        userMap.putIfAbsent('userType', () => 'customer');
      }

      if (token != null) {
        await _apiClient.saveToken(token);
      }
      final resolvedUserMap = userMap ?? _userMapFromToken(token);
      if (resolvedUserMap != null) {
        if (resolvedUserMap['type'] == null &&
            resolvedUserMap['userType'] == null) {
          resolvedUserMap['type'] = 'customer';
          resolvedUserMap['userType'] = 'customer';
        }
        await _apiClient.saveUserJson(jsonEncode(resolvedUserMap));
        return UserModel.fromJson(resolvedUserMap).toEntity();
      }

      final message = data['message'] as String?;
      throw Exception(message ?? 'Apple ile giriş başarısız oldu.');
    } catch (e) {
      // ApiClient already handles DioException and parses error messages
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
        data: {'phoneCode': phoneCode, 'phone': phone},
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
      // Backend camelCase bekliyor: phoneCode, smsCode (customer register için)
      // Company register için ek parametreler var ama temel format aynı
      final requestData = <String, dynamic>{
        'phoneCode': phoneCode, // Backend camelCase bekliyor
        'phone': phone
            .replaceAll(' ', '')
            .replaceAll('-', '')
            .replaceAll('(', '')
            .replaceAll(')', ''), // Telefon numarasını temizle
        'smsCode': smsCode, // Backend 'smsCode' bekliyor, 'code' değil
      };

      // Sadece null olmayan company registration parametrelerini ekle
      if (isCompanyRegistration) {
        if (name != null && name.isNotEmpty) {
          requestData['name'] = name;
        }
        if (surname != null && surname.isNotEmpty) {
          requestData['surname'] = surname;
        }
        if (email != null && email.isNotEmpty) {
          requestData['email'] = email;
        }
        if (gender != null && gender.isNotEmpty) {
          requestData['gender'] = gender;
        }
        if (companyName != null && companyName.isNotEmpty) {
          requestData['company_name'] = companyName;
        }
        if (companyType != null && companyType.toString().isNotEmpty) {
          requestData['company_type'] = companyType;
        }
        if (companyAddress != null && companyAddress.isNotEmpty) {
          requestData['company_address'] = companyAddress;
        }
        if (companyPhoneCode != null && companyPhoneCode.isNotEmpty) {
          requestData['company_phone_code'] = companyPhoneCode;
        }
        if (companyPhone != null && companyPhone.isNotEmpty) {
          requestData['company_phone'] = companyPhone
              .replaceAll(' ', '')
              .replaceAll('-', '')
              .replaceAll('(', '')
              .replaceAll(')', '');
        }
        if (companyEmail != null && companyEmail.isNotEmpty) {
          requestData['company_email'] = companyEmail;
        }
        requestData['is_company_registration'] = true;
      }

      final response = await _apiClient.post(
        ApiConstants.smsCheck,
        data: requestData,
      );

      final data = _asMap(response.data);

      // Backend başarılı döndüyse ama token/userData yoksa, company registration için özel durum
      if (data['status'] == true) {
        final auth = _extractAuth(data);
        final token = auth.token;
        final userMap = auth.user;

        // Eğer token ve userMap varsa, normal flow devam eder
        if (token != null && userMap != null) {
          // Berber kaydı için user type'ı ayarla
          if (isCompanyRegistration) {
            if (!userMap.containsKey('type') &&
                !userMap.containsKey('userType')) {
              userMap['type'] = 'company';
            }
          }

          await _apiClient.saveToken(token);

          // SMS doğrulama başarılı olduğunda kullanıcıyı doğrulanmış olarak işaretle
          userMap['isVerified'] = true;
          userMap['verified'] = true;
          await _apiClient.saveUserJson(jsonEncode(userMap));

          final user = UserModel.fromJson(userMap).toEntity();
          return user;
        }

        // Token/userData yoksa ama status true ise - company registration onay bekliyor olabilir
        // İlk önce company registration kontrolü yap - çünkü bu durumda token/userData olmayabilir
        final message = data['message'] as String?;
        final messageLower = message?.toLowerCase() ?? '';

        // Company registration kontrolü - isCompanyRegistration true ise veya mesaj company registration'a işaret ediyorsa
        final isCompanyReg = isCompanyRegistration ||
            messageLower.contains('değerlendirme') ||
            messageLower.contains('değerlendirmeye') ||
            messageLower.contains('evaluation') ||
            messageLower.contains('company');

        if (isCompanyReg) {
          // Berber hesabı değerlendirme aşamasındaysa
          if (message == 'auth.accountIsEvaluationCompany' ||
              messageLower.contains('evaluation') ||
              messageLower.contains('pending') ||
              messageLower.contains('onay') ||
              messageLower.contains('değerlendirme') ||
              messageLower.contains('değerlendirmeye')) {
            // Backend mesajını kullanıcıya göster
            final userMessage = message != null && message.isNotEmpty
                ? message
                : 'İşletme kaydınız başarıyla tamamlandı! Hesabınız yönetici onayı bekliyor. Onaylandığında size bildirim göndereceğiz.';
            throw Exception(
              'COMPANY_PENDING_APPROVAL|$userMessage',
            );
          }

          // Company registration için status true ama token/userData yok
          // Bu durumda backend işlemi başarılı yapmış ama henüz login yapılamıyor
          // Backend mesajını da kullanıcıya göster
          final userMessage = message != null && message.isNotEmpty
              ? message
              : 'SMS doğrulamanız başarıyla tamamlandı! Hesabınız yönetici onayı bekliyor. Onaylandığında size bildirim göndereceğiz.';
          throw Exception(
            'COMPANY_PENDING_APPROVAL|$userMessage',
          );
        }
      }

      // Status false veya status yoksa, backend'den gelen mesajı kontrol et
      final auth = _extractAuth(data);
      final token = auth.token;
      final userMap = auth.user;

      if (token != null && userMap != null) {
        if (isCompanyRegistration) {
          if (!userMap.containsKey('type') &&
              !userMap.containsKey('userType')) {
            userMap['type'] = 'company';
          }
        }

        await _apiClient.saveToken(token);
        userMap['isVerified'] = true;
        userMap['verified'] = true;
        await _apiClient.saveUserJson(jsonEncode(userMap));

        final user = UserModel.fromJson(userMap).toEntity();
        return user;
      }

      // Backend'den gelen hata mesajını kontrol et
      final errorMessage = data['message'] as String?;
      if (errorMessage != null && errorMessage.isNotEmpty) {
        throw Exception(errorMessage);
      }

      throw Exception('Doğrulama başarısız: kullanıcı veya token eksik');
    } on DioException catch (e) {
      // Special handling for company registration approval status
      if (e.response?.data != null) {
        final responseData = _asMap(e.response!.data);
        
        // Backend başarılı döndüyse ama hata kodu ile geldiyse (company registration özel durumu)
        if (responseData['status'] == true && isCompanyRegistration) {
          throw Exception(
            'COMPANY_PENDING_APPROVAL|SMS doğrulamanız başarıyla tamamlandı! Hesabınız yönetici onayı bekliyor. Onaylandığında size bildirim göndereceğiz.',
          );
        }
      }
      // ApiClient already handles DioException and parses error messages
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  // Get current user
  // NOT: Bu metod kullanılmamaktadır çünkü backend'de /api/user endpoint'i yoktur.
  // Login ve register işlemleri zaten user bilgilerini döndürür ve local storage'a kaydeder.
  @Deprecated(
    "Backend'de /api/user endpoint'i mevcut değil. Login/register user bilgilerini zaten döndürür.",
  )
  Future<User?> getCurrentUser() async {
    try {
      final token = await _apiClient.getToken();
      if (token == null) {
        return null;
      }

      // Backend'de bu endpoint mevcut değil (404 hatası verir)
      final response = await _apiClient.get('/api/user');
      final data = _asMap(response.data);

      // Eğer companyData varsa, user type'ı company olarak ayarla
      if (data.containsKey('companyData') || data.containsKey('company')) {
        final userDataNode = _asMap(data['userData'] ?? data['user']);
        if (userDataNode.isNotEmpty &&
            !userDataNode.containsKey('type') &&
            !userDataNode.containsKey('userType')) {
          userDataNode['type'] = 'company';
          data['userData'] = userDataNode;
          data['user'] = userDataNode;
        }
      }

      final userMap = data['user'] ?? data['userData'];
      if (userMap != null) {
        // User bilgisini local storage'a kaydet
        await _apiClient.saveUserJson(jsonEncode(userMap));
        return UserModel.fromJson(userMap).toEntity();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Logout - Call API endpoint and clear local tokens
  Future<void> logout() async {
    try {
      // Call logout API endpoint with short timeout - don't wait too long
      await _apiClient.post(ApiConstants.logout).timeout(
        const Duration(seconds: 3),
        onTimeout: () => throw TimeoutException('Logout timeout'),
      );
    } catch (e) {
      // Log error in debug mode but don't throw - we still want to clear local tokens
      if (kDebugMode) {
        debugPrint('AuthApiService.logout: API call failed: $e');
      }
      // Continue to clear tokens even if API call fails
    } finally {
      // Always clear tokens locally, even if API call failed
      // This ensures users can always log out, even with poor connectivity
      await _apiClient.clearTokens();
    }
  }

  // Get user JSON from local storage
  Future<String?> getUserJson() async {
    return await _apiClient.getUserJson();
  }

  // Forgot Password - Request SMS Code
  Future<void> forgotPasswordRequest({
    required String phoneCode,
    required String phone,
  }) async {
    try {
      await _apiClient.post(
        ApiConstants.forgotPasswordRequest,
        data: {
          'phoneCode': phoneCode,
          'phone': phone,
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  // Forgot Password - Verify SMS Code
  Future<void> forgotPasswordVerify({
    required String phoneCode,
    required String phone,
    required String smsCode,
  }) async {
    try {
      await _apiClient.post(
        ApiConstants.forgotPasswordVerify,
        data: {
          'phoneCode': phoneCode,
          'phone': phone
              .replaceAll(' ', '')
              .replaceAll('-', '')
              .replaceAll('(', '')
              .replaceAll(')', ''), // Telefon numarasını temizle
          'smsCode': smsCode,
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  // Forgot Password - Reset Password
  // Only requires password
  Future<void> forgotPasswordReset({
    required String phoneCode,
    required String phone,
    required String smsCode,
    required String password,
  }) async {
    try {
      await _apiClient.post(
        ApiConstants.forgotPasswordReset,
        data: {
          'phoneCode': phoneCode,
          'phone': phone,
          'smsCode': smsCode,
          'password': password,
        },
      );
    } catch (e) {
      rethrow;
    }
  }
}
