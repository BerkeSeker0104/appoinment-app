import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../core/services/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../models/company_user_model.dart';

class CompanyUserApiService {
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

  // Get Company Users
  Future<Map<String, dynamic>> getCompanyUsers({
    int page = 1,
    int dataCount = 20,
  }) async {
    final response = await _apiClient.get(
      '/api/company-user',
      queryParameters: {
        'page': page.toString(),
        'dataCount': dataCount.toString(),
      },
    );

    final data = _asMap(response.data);

    List<CompanyUserModel> users = [];
    Map<String, dynamic> pagination = {};

    if (data['data'] != null && data['data'] is List) {
      if ((data['data'] as List).isNotEmpty) {
        debugPrint('DEBUG_GET_COMPANY_USERS_RAW: ${(data['data'] as List).first}');
      }
      users = (data['data'] as List)
          .map((e) => CompanyUserModel.fromJson(e))
          .toList();
    }

    if (data['pagination'] != null) {
      pagination = data['pagination'];
    }

    return {
      'data': users,
      'pagination': pagination,
    };
  }

  // Add Company User
  Future<void> addCompanyUser(Map<String, dynamic> userData) async {
    debugPrint('CompanyUserApiService: POST /api/company-user with data: $userData');
    
    dynamic requestData;
    
    // Check if picture is a file path
    if (userData.containsKey('picture') && 
        userData['picture'] != null && 
        userData['picture'].toString().isNotEmpty &&
        !userData['picture'].toString().startsWith('http')) {
      
      final formData = FormData();
      
      // Add text fields
      userData.forEach((key, value) {
        if (key != 'picture' && value != null) {
          formData.fields.add(MapEntry(key, value.toString()));
        }
      });
      
      // Add file
      final fileName = userData['picture'].toString().split('/').last;
      formData.files.add(
        MapEntry(
          'picture', // lowercase 'p' - consistent with other services
          await MultipartFile.fromFile(userData['picture'], filename: fileName),
        ),
      );
      
      requestData = formData;
    } else {
      // Normal JSON request
      requestData = userData;
    }

    await _apiClient.post(
      '/api/company-user',
      data: requestData,
    );
  }

  // Update Company User
  Future<void> updateCompanyUser(Map<String, dynamic> userData) async {
    debugPrint('CompanyUserApiService: PUT /api/company-user with data: $userData');
    
    dynamic requestData;
    
    // Check if picture is a NEW local file path (not a server path like /uploads/...)
    final hasPicture = userData.containsKey('picture');
    final pictureValue = userData['picture'];
    final isNotNull = pictureValue != null;
    final isNotEmpty = pictureValue?.toString().isNotEmpty == true;
    final isNotHttp = pictureValue?.toString().startsWith('http') != true;
    // Check if it's a server path (starts with /uploads/) - these should NOT be uploaded as files
    final isServerPath = pictureValue?.toString().startsWith('/uploads/') == true;
    // It's a local file only if it's not http AND not a server path
    final isLocalFile = isNotHttp && !isServerPath;
    
    debugPrint('DEBUG_PICTURE_CHECK: hasPicture=$hasPicture, isNotNull=$isNotNull, isNotEmpty=$isNotEmpty, isNotHttp=$isNotHttp, isServerPath=$isServerPath, isLocalFile=$isLocalFile, value=$pictureValue');
    
    if (hasPicture && isNotNull && isNotEmpty && isLocalFile) {
      debugPrint('DEBUG_UPLOAD: Creating FormData with picture file');
      
      final formData = FormData();
      
      // Add text fields
      userData.forEach((key, value) {
        if (key != 'picture' && value != null) {
          formData.fields.add(MapEntry(key, value.toString()));
        }
      });
      
      // Add file
      final fileName = userData['picture'].toString().split('/').last;
      debugPrint('DEBUG_UPLOAD: Adding file with name: $fileName');
      formData.files.add(
        MapEntry(
          'picture', // lowercase 'p' - consistent with other services
          await MultipartFile.fromFile(userData['picture'], filename: fileName),
        ),
      );
      
      debugPrint('DEBUG_UPLOAD: FormData fields: ${formData.fields}');
      debugPrint('DEBUG_UPLOAD: FormData files: ${formData.files.map((e) => "${e.key}: ${e.value.filename}").toList()}');
      
      requestData = formData;
    } else {
      debugPrint('DEBUG_UPLOAD: Sending as JSON (no file upload)');
      requestData = userData;
    }

    final response = await _apiClient.put(
      '/api/company-user',
      data: requestData,
    );
    debugPrint('DEBUG_UPLOAD: Response: ${response.data}');
  }

  // Delete Company User
  Future<void> deleteCompanyUser({
    required String userId,
    required String companyId,
  }) async {
    debugPrint('CompanyUserApiService: DELETE /api/company-user with userId: $userId, companyId: $companyId');
    await _apiClient.delete(
      '/api/company-user',
      data: {
        'userId': userId,
        'companyId': companyId,
      },
    );
  }

  // Get Company Employees
  Future<List<CompanyUserModel>> getCompanyEmployees(String companyId) async {
    final response = await _apiClient.get(
      '/api/company-user/list',
      queryParameters: {
        'companyId': companyId,
        'state': '2',
      },
    );

    final data = _asMap(response.data);
    
    // Debug: Log raw employee data
    if (data['data'] != null && data['data'] is List && (data['data'] as List).isNotEmpty) {
      debugPrint('DEBUG_GET_EMPLOYEES_RAW: ${(data['data'] as List).first}');
    }

    if (data['data'] != null && data['data'] is List) {
      return (data['data'] as List)
          .map((e) => CompanyUserModel.fromJson(e))
          .toList();
    }
    
    return [];
  }
}
