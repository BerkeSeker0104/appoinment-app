import 'dart:convert';
import 'package:dio/dio.dart';
import '../../core/services/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../models/branch_model.dart';

class BranchApiService {
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

  // Get all branches for a company
  Future<List<BranchModel>> getBranches() async {
    try {
      final response = await _apiClient.get(ApiConstants.branches);
      final data = _asMap(response.data);

      List<dynamic> branchesList = [];
      if (data['data'] is List) {
        branchesList = data['data'] as List<dynamic>;
      } else if (data['branches'] is List) {
        branchesList = data['branches'] as List<dynamic>;
      } else if (data['items'] is List) {
        branchesList = data['items'] as List<dynamic>;
      } else if (data is List) {
        branchesList = data as List<dynamic>;
      }

      return branchesList.map((json) => BranchModel.fromJson(json)).toList();
    } on DioException catch (e) {
      // Special handling: 404 means no branches available, return empty list
      if (e.response?.statusCode == 404) {
        return [];
      }
      // ApiClient already handles DioException and parses error messages
      rethrow;
    } catch (e) {
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('404') || errorString.contains('bulunamadı')) {
        return [];
      }
      throw Exception('Şubeler yüklenirken hata oluştu: $e');
    }
  }

  // Get a specific branch by ID
  Future<BranchModel> getBranch(String branchId) async {
    try {
      try {
        final response = await _apiClient.get(
          '${ApiConstants.branches}/$branchId',
        );
        final data = _asMap(response.data);

        Map<String, dynamic> branchData;
        if (data['data'] is Map<String, dynamic>) {
          branchData = data['data'];
        } else {
          branchData = data;
        }

        return BranchModel.fromJson(branchData);
      } on DioException catch (directError) {
        if (directError.response?.statusCode == 404) {
          // Fallback: get all branches and filter by ID
          final response = await _apiClient.get(ApiConstants.branches);
          final data = _asMap(response.data);

          List<dynamic> branchesList = [];
          if (data['data'] is List) {
            branchesList = data['data'] as List<dynamic>;
          } else if (data['companies'] is List) {
            branchesList = data['companies'] as List<dynamic>;
          } else if (data['branches'] is List) {
            branchesList = data['branches'] as List<dynamic>;
          } else if (data is List) {
            branchesList = data as List<dynamic>;
          }

          final branchData = branchesList.firstWhere(
            (branch) => branch['id'].toString() == branchId,
            orElse: () => null,
          );

          if (branchData == null) {
            throw Exception('Şube bulunamadı');
          }

          return BranchModel.fromJson(branchData);
        }

        if (directError.response?.data != null) {
          final errorData = directError.response!.data;
          if (errorData is Map<String, dynamic>) {
            final errorMessage = errorData['message'] ??
                errorData['error'] ??
                'Şube bilgileri yüklenirken hata oluştu';
            throw Exception(errorMessage);
          }
        }

        rethrow;
      }
    } on DioException catch (e) {
      if (e.response?.data != null) {
      }
      // ApiClient already handles DioException and parses error messages
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  // Create a new branch
  Future<BranchModel> createBranch(
    BranchModel branch, {
    String? profileImagePath,
    List<String>? interiorImagePaths,
    String? paidTypes, // YENİ - virgülle ayrılmış string
  }) async {
    try {
      final formData = FormData();
      final jsonData = branch.toJson(includeCoordinates: true);

      jsonData.forEach((key, value) {
        if (key == 'hours' && value is List) {
          for (var i = 0; i < value.length; i++) {
            final hour = value[i] as Map<String, dynamic>;
            if (hour.isEmpty) continue;
            hour.forEach((fieldKey, fieldValue) {
              final fieldValueStr = fieldValue.toString();
              final formKey = 'hours[$i][$fieldKey]';
              formData.fields.add(MapEntry(formKey, fieldValueStr));
            });
          }
        } else if (key == 'features' && value is List) {
          for (var i = 0; i < value.length; i++) {
            final featureId = value[i].toString();
            formData.fields.add(MapEntry('features[]', featureId));
          }
        } else if (value is! List) {
          final stringValue = value.toString();
          formData.fields.add(MapEntry(key, stringValue));
        }
      });

      if (paidTypes != null && paidTypes.isNotEmpty) {
        formData.fields.add(MapEntry('paidTypes', paidTypes));
      }

      if (profileImagePath != null && profileImagePath.isNotEmpty) {
        final fileName = profileImagePath.split('/').last;
        formData.files.add(
          MapEntry(
            'picture',
            await MultipartFile.fromFile(profileImagePath, filename: fileName),
          ),
        );
      }

      if (interiorImagePaths != null && interiorImagePaths.isNotEmpty) {
        for (var imagePath in interiorImagePaths) {
          final fileName = imagePath.split('/').last;
          formData.files.add(
            MapEntry(
              'pictures',
              await MultipartFile.fromFile(imagePath, filename: fileName),
            ),
          );
        }
      }

      final response = await _apiClient.post(
        ApiConstants.branches,
        data: formData,
      );

      final data = _asMap(response.data);

      // Backend returns simple success message, need to construct BranchModel
      // Using the data we sent + generated ID from backend if available
      BranchModel createdBranch;
      if (data['data'] is Map<String, dynamic>) {
        createdBranch = BranchModel.fromJson(data['data']);
      } else if (data['branch'] is Map<String, dynamic>) {
        createdBranch = BranchModel.fromJson(data['branch']);
      } else {
        // Backend returns simple {status: true, message: "..."}
        // Return a basic branch model with the data we sent
        createdBranch = branch;
      }

      return createdBranch;
    } on DioException catch (e) {
      // ApiClient already handles DioException and parses error messages
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  // Update an existing branch
  Future<BranchModel> updateBranch(
    String branchId,
    BranchModel branch, {
    String? paidTypes,
    String? profileImagePath,
    List<String>? newInteriorImagePaths,
  }) async {
    try {
      // FormData kullan (createBranch ile aynı format)
      final formData = FormData();
      final jsonData = branch.toJson(includeCoordinates: true);

      if (paidTypes != null && paidTypes.isNotEmpty) {
        jsonData['paidTypes'] = paidTypes;
      }

      jsonData.forEach((key, value) {
        if (key == 'hours' && value is List) {
          for (var i = 0; i < value.length; i++) {
            final hour = value[i] as Map<String, dynamic>;
            hour.forEach((fieldKey, fieldValue) {
              formData.fields.add(
                MapEntry('hours[$i][$fieldKey]', fieldValue.toString()),
              );
            });
          }
        } else if (key == 'features' && value is List) {
          if (value.isEmpty) {
            formData.fields.add(MapEntry('features', '[]'));
          } else {
            for (var i = 0; i < value.length; i++) {
              formData.fields.add(MapEntry('features[]', value[i].toString()));
            }
          }
        } else if (value is! List) {
          final stringValue = value.toString();
          formData.fields.add(MapEntry(key, stringValue));
        }
      });

      // Profile image (şube görseli) - createBranch ile aynı format
      if (profileImagePath != null && profileImagePath.isNotEmpty) {
        final fileName = profileImagePath.split('/').last;
        formData.files.add(
          MapEntry(
            'picture',
            await MultipartFile.fromFile(profileImagePath, filename: fileName),
          ),
        );
      }

      if (newInteriorImagePaths != null && newInteriorImagePaths.isNotEmpty) {
        for (var imagePath in newInteriorImagePaths) {
          if (imagePath.isEmpty) continue;
          final fileName = imagePath.split('/').last;
          formData.files.add(
            MapEntry(
              'pictures',
              await MultipartFile.fromFile(imagePath, filename: fileName),
            ),
          );
        }
      }

      final response = await _apiClient.put(
        '${ApiConstants.branches}/$branchId',
        data: formData,
      );

      final data = _asMap(response.data);

      BranchModel updatedBranch;
      if (data['data'] is Map<String, dynamic>) {
        updatedBranch = BranchModel.fromJson(data['data']);
      } else if (data['branch'] is Map<String, dynamic>) {
        updatedBranch = BranchModel.fromJson(data['branch']);
      } else {
        // Backend returns simple success message
        updatedBranch = branch;
      }

      return updatedBranch;
    } on DioException catch (e) {
      // ApiClient already handles DioException and parses error messages
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  // Delete a branch
  Future<void> deleteBranch(String branchId) async {
    try {
      await _apiClient.delete('${ApiConstants.branches}/$branchId');
    } on DioException catch (e) {
      // ApiClient already handles DioException and parses error messages
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  // Update branch status (active/inactive)
  Future<BranchModel> updateBranchStatus(String branchId, String status) async {
    try {
      final response = await _apiClient.put(
        '${ApiConstants.branches}/$branchId/status',
        data: {'status': status},
      );
      final data = _asMap(response.data);

      BranchModel updatedBranch;
      if (data['data'] is Map<String, dynamic>) {
        updatedBranch = BranchModel.fromJson(data['data']);
      } else if (data['branch'] is Map<String, dynamic>) {
        updatedBranch = BranchModel.fromJson(data['branch']);
      } else {
        updatedBranch = BranchModel.fromJson(data);
      }

      return updatedBranch;
    } catch (e) {
      throw Exception('Şube durumu güncellenirken hata oluştu: $e');
    }
  }

  // Upload branch image
  Future<String> uploadBranchImage(String branchId, String imagePath) async {
    try {
      final response = await _apiClient.post(
        '${ApiConstants.branches}/$branchId/image',
        data: {'image': imagePath},
      );
      final data = _asMap(response.data);

      return data['image_url'] ?? data['imageUrl'] ?? '';
    } catch (e) {
      throw Exception('Şube resmi yüklenirken hata oluştu: $e');
    }
  }

  // Search branches
  Future<List<BranchModel>> searchBranches(String query) async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.branches}/search',
        queryParameters: {'q': query},
      );
      final data = _asMap(response.data);

      List<dynamic> branchesList = [];
      if (data['data'] is List) {
        branchesList = data['data'] as List<dynamic>;
      } else if (data['branches'] is List) {
        branchesList = data['branches'] as List<dynamic>;
      } else if (data['items'] is List) {
        branchesList = data['items'] as List<dynamic>;
      } else if (data is List) {
        branchesList = data as List<dynamic>;
      }

      return branchesList.map((json) => BranchModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Şube arama yapılırken hata oluştu: $e');
    }
  }

  // getBranchFeatures() metodu kaldırıldı - backend API yok, sabit liste kullanılıyor
}
