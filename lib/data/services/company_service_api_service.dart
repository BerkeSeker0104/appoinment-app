import 'dart:convert';
import 'package:dio/dio.dart';
import '../../core/services/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../models/company_service_model.dart';

class CompanyServiceApiService {
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

  // Get all company services
  Future<List<CompanyServiceModel>> getCompanyServices() async {
    try {
      final response = await _apiClient.get(ApiConstants.companyServices);
      final data = _asMap(response.data);

      List<dynamic> companyServicesList = [];
      if (data['data'] is List) {
        companyServicesList = data['data'] as List<dynamic>;
      } else if (data['companyServices'] is List) {
        companyServicesList = data['companyServices'] as List<dynamic>;
      } else if (data['items'] is List) {
        companyServicesList = data['items'] as List<dynamic>;
      } else if (data is List) {
        companyServicesList = data as List<dynamic>;
      }

      return companyServicesList
          .map((json) => CompanyServiceModel.fromJson(json))
          .toList();
    } catch (e) {
      // If endpoint doesn't exist yet (404), return empty list
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('404') || errorString.contains('bulunamadı')) {
        return [];
      }
      rethrow;
    }
  }

  // Get company services by company ID
  Future<List<CompanyServiceModel>> getCompanyServicesByCompanyId(
    String companyId, {
    String? parentCompanyId,
  }) async {
    try {
      // Backend query parametrelerini deneyelim
      final queryParams = <String, dynamic>{
        'companyId': companyId,
        'branchId': companyId,
        // Alternatif isimlendirmeler
        'company_id': companyId,
        'branch_id': companyId,
      };

      if (parentCompanyId != null) {
        queryParams['parentCompanyId'] = parentCompanyId;
        queryParams['mainCompanyId'] = parentCompanyId;
        queryParams['company_id'] = parentCompanyId; // Parent ID öncelikli olabilir
      }

      final response = await _apiClient.get(
        ApiConstants.companyServices,
        queryParameters: queryParams,
      );
      final data = _asMap(response.data);

      List<dynamic> companyServicesList = [];
      if (data['data'] is List) {
        companyServicesList = data['data'] as List<dynamic>;
      } else if (data['companyServices'] is List) {
        companyServicesList = data['companyServices'] as List<dynamic>;
      } else if (data['items'] is List) {
        companyServicesList = data['items'] as List<dynamic>;
      } else if (data is List) {
        companyServicesList = data as List<dynamic>;
      }

      // Parse all services
      final allServices =
          companyServicesList
              .map((json) => CompanyServiceModel.fromJson(json))
              .toList();

      // Filter by company ID - UUID veya sayısal ID olabilir
      final targetCompanyIdParsed = int.tryParse(companyId);
      final targetCompanyId = targetCompanyIdParsed != null && targetCompanyIdParsed > 0
          ? targetCompanyIdParsed
          : companyId; // UUID string olarak kullan

      final targetParentIdParsed = parentCompanyId != null ? int.tryParse(parentCompanyId) : null;
      final targetParentId = targetParentIdParsed != null && targetParentIdParsed > 0
          ? targetParentIdParsed
          : parentCompanyId;

      // Filter: UUID string veya int karşılaştırması yap
      final filteredServices = allServices.where((service) {
        // companyIds listesinde targetCompanyId'yi ara (int veya string olarak)
        return service.companyIds.any((id) {
          bool matches(dynamic targetId) {
             if (targetId == null) return false;
             
             // Hem int hem string karşılaştırması yap
            if (targetId is int) {
              // Sayısal ID arıyorsak
              if (id is int) {
                return id == targetId;
              } else if (id is String) {
                // String'den int'e çevirip karşılaştır
                final parsed = int.tryParse(id);
                return parsed != null && parsed == targetId;
              }
            } else if (targetId is String) {
              // UUID string arıyorsak
              if (id is String) {
                return id == targetId;
              } else if (id is int) {
                // int'den string'e çevirip karşılaştır
                return id.toString() == targetId;
              }
            }
            return false;
          }
          
          return matches(targetCompanyId) || (parentCompanyId != null && matches(targetParentId));
        });
      }).toList();

      return filteredServices;
    } catch (e) {
      return []; // Return empty list for better UX
    }
  }

  // Get a specific company service by ID
  Future<CompanyServiceModel> getCompanyService(String id) async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.companyServices}/$id',
      );
      final data = _asMap(response.data);

      CompanyServiceModel companyService;
      Map<String, dynamic> companyServiceData;

      if (data['data'] is Map<String, dynamic>) {
        companyServiceData = data['data'];
      } else if (data['companyService'] is Map<String, dynamic>) {
        companyServiceData = data['companyService'];
      } else if (data['company_service'] is Map<String, dynamic>) {
        companyServiceData = data['company_service'];
      } else if (data['data'] is List && (data['data'] as List).isNotEmpty) {
        // If response is a list, find the service with matching ID
        final servicesList = data['data'] as List;
        companyServiceData = servicesList.firstWhere(
          (s) => s['id'].toString() == id,
          orElse: () => servicesList.first,
        );
      } else {
        companyServiceData = data;
      }

      companyService = CompanyServiceModel.fromJson(companyServiceData);
      return companyService;
    } catch (e) {
      rethrow;
    }
  }

  // Create a new company service
  Future<CompanyServiceModel> createCompanyService(
    CompanyServiceModel companyService,
  ) async {
    try {
      final jsonData = companyService.toJson();

      final response = await _apiClient.post(
        ApiConstants.companyServices,
        data: jsonData,
      );

      final data = _asMap(response.data);

      // Backend returns created service or simple success message
      CompanyServiceModel createdService;
      if (data['data'] is Map<String, dynamic>) {
        createdService = CompanyServiceModel.fromJson(data['data']);
      } else if (data['companyService'] is Map<String, dynamic>) {
        createdService = CompanyServiceModel.fromJson(data['companyService']);
      } else if (data['company_service'] is Map<String, dynamic>) {
        createdService = CompanyServiceModel.fromJson(data['company_service']);
      } else {
        // Backend returns simple {status: true, message: "..."}
        // Return the service we sent with a generated ID
        final id =
            data['id']?.toString() ??
            DateTime.now().millisecondsSinceEpoch.toString();
        createdService = companyService.copyWith(
          id: id,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }

      return createdService;
    } on DioException catch (e) {
      // Special handling for 404 - feature not available
      if (e.response?.statusCode == 404) {
        throw Exception(
          'Firma hizmeti ekleme özelliği henüz aktif değil. Lütfen daha sonra tekrar deneyin.',
        );
      }
      // ApiClient already handles DioException and parses error messages
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  // Update an existing company service
  Future<CompanyServiceModel> updateCompanyService(
    String id,
    CompanyServiceModel companyService,
  ) async {
    try {
      // UPDATE: Backend muhtemelen companyId (tekil) bekliyor!
      // POST'ta companyIds (array) çalıştı ama PUT'te çalışmıyor
      final jsonData = companyService.toJson(
        isUpdate: true, // PUT için farklı format!
      );

      // Dio'ya gönder - JSON encode otomatik olarak yapılır
      final response = await _apiClient.put(
        '${ApiConstants.companyServices}/$id', // URL'de ID!
        data: jsonData, // Map<String, dynamic> - Dio JSON'a çevirecek
      );

      final data = _asMap(response.data);

      CompanyServiceModel updatedService;
      if (data['data'] is Map<String, dynamic>) {
        updatedService = CompanyServiceModel.fromJson(data['data']);
      } else if (data['companyService'] is Map<String, dynamic>) {
        updatedService = CompanyServiceModel.fromJson(data['companyService']);
      } else if (data['company_service'] is Map<String, dynamic>) {
        updatedService = CompanyServiceModel.fromJson(data['company_service']);
      } else {
        // Backend returns simple success message
        updatedService = companyService.copyWith(
          id: id,
          updatedAt: DateTime.now(),
        );
      }

      return updatedService;
    } on DioException catch (e) {
      // Backend'den gelen hata mesajını çıkar
      if (e.response?.data != null) {
        final responseData = _asMap(e.response!.data);

        // Errors array'ini kontrol et (validation errors)
        if (responseData['errors'] is List) {
          final errors = responseData['errors'] as List;
          if (errors.isNotEmpty) {
            final firstError = errors.first;
            final field = firstError['field'] ?? '';
            final message = firstError['message'] ?? '';

            // Field'a göre özel mesajlar
            if (field == 'companyIds' || field == 'company_ids') {
              throw Exception(
                'Firma seçimi geçersiz. Lütfen en az bir firma seçin',
              );
            }
            if (field == 'serviceId' || field == 'service_id') {
              throw Exception('Hizmet seçimi geçersiz');
            }
            if (field == 'id') {
              throw Exception('Geçersiz hizmet ID');
            }
            throw Exception('$field: $message');
          }
        }

        final message = responseData['message'] ?? 'Bilinmeyen hata';
        throw Exception(message);
      }

      if (e.response?.statusCode == 404) {
        throw Exception(
          'Firma hizmeti güncelleme özelliği henüz aktif değil. Lütfen daha sonra tekrar deneyin.',
        );
      }
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  // Delete a company service
  Future<void> deleteCompanyService(String id) async {
    try {
      await _apiClient.delete('${ApiConstants.companyServices}/$id');
    } catch (e) {
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('404') || errorString.contains('bulunamadı')) {
        throw Exception(
          'Firma hizmeti silme özelliği henüz aktif değil. Lütfen daha sonra tekrar deneyin.',
        );
      }
      throw Exception('Firma hizmeti silinirken hata oluştu: $e');
    }
  }

  // Search company services
  Future<List<CompanyServiceModel>> searchCompanyServices(String query) async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.companyServices}/search',
        queryParameters: {'q': query},
      );
      final data = _asMap(response.data);

      List<dynamic> companyServicesList = [];
      if (data['data'] is List) {
        companyServicesList = data['data'] as List<dynamic>;
      } else if (data['companyServices'] is List) {
        companyServicesList = data['companyServices'] as List<dynamic>;
      } else if (data['items'] is List) {
        companyServicesList = data['items'] as List<dynamic>;
      } else if (data is List) {
        companyServicesList = data as List<dynamic>;
      }

      return companyServicesList
          .map((json) => CompanyServiceModel.fromJson(json))
          .toList();
    } catch (e) {
      rethrow;
    }
  }
}
