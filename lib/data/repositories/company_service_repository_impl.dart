import '../../domain/repositories/company_service_repository.dart';
import '../models/company_service_model.dart';
import '../services/company_service_api_service.dart';

class CompanyServiceRepositoryImpl implements CompanyServiceRepository {
  final CompanyServiceApiService _apiService = CompanyServiceApiService();

  @override
  Future<List<CompanyServiceModel>> getCompanyServices() async {
    try {
      return await _apiService.getCompanyServices();
    } catch (e) {
      throw Exception('Firma hizmetleri yüklenirken hata oluştu: $e');
    }
  }

  @override
  Future<CompanyServiceModel> getCompanyService(String id) async {
    try {
      return await _apiService.getCompanyService(id);
    } catch (e) {
      throw Exception('Firma hizmeti bilgileri yüklenirken hata oluştu: $e');
    }
  }

  @override
  Future<CompanyServiceModel> createCompanyService({
    required List<dynamic> companyIds, // int (sayısal ID) veya String (UUID) olabilir
    required String serviceId,
    required double minPrice,
    double? maxPrice,
    required int duration,
  }) async {
    try {
      // Validation
      if (companyIds.isEmpty) {
        throw Exception('En az bir firma seçilmelidir');
      }
      if (serviceId.isEmpty) {
        throw Exception('Hizmet seçilmelidir');
      }
      if (minPrice <= 0) {
        throw Exception('Geçerli bir fiyat giriniz');
      }
      if (maxPrice != null && maxPrice <= minPrice) {
        throw Exception('Maksimum fiyat minimum fiyattan büyük olmalıdır');
      }
      if (duration <= 0) {
        throw Exception('Geçerli bir süre giriniz');
      }

      final companyService = CompanyServiceModel(
        id: '', // Backend tarafından atanacak
        companyIds: companyIds,
        serviceId: serviceId,
        minPrice: minPrice,
        maxPrice: maxPrice,
        duration: duration,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      return await _apiService.createCompanyService(companyService);
    } catch (e) {
      throw Exception('Firma hizmeti oluşturulurken hata oluştu: $e');
    }
  }

  @override
  Future<CompanyServiceModel> updateCompanyService({
    required String id,
    required List<dynamic> companyIds, // int (sayısal ID) veya String (UUID) olabilir
    required String serviceId,
    required double minPrice,
    double? maxPrice,
    required int duration,
  }) async {
    try {
      // Validation
      if (companyIds.isEmpty) {
        throw Exception('En az bir firma seçilmelidir');
      }
      if (serviceId.isEmpty) {
        throw Exception('Hizmet seçilmelidir');
      }
      if (minPrice <= 0) {
        throw Exception('Geçerli bir fiyat giriniz');
      }
      if (maxPrice != null && maxPrice <= minPrice) {
        throw Exception('Maksimum fiyat minimum fiyattan büyük olmalıdır');
      }
      if (duration <= 0) {
        throw Exception('Geçerli bir süre giriniz');
      }

      final companyService = CompanyServiceModel(
        id: id,
        companyIds: companyIds,
        serviceId: serviceId,
        minPrice: minPrice,
        maxPrice: maxPrice,
        duration: duration,
        createdAt: DateTime.now(), // Backend'den gelecek
        updatedAt: DateTime.now(),
      );

      return await _apiService.updateCompanyService(id, companyService);
    } catch (e) {
      throw Exception('Firma hizmeti güncellenirken hata oluştu: $e');
    }
  }

  @override
  Future<void> deleteCompanyService(String id) async {
    try {
      await _apiService.deleteCompanyService(id);
    } catch (e) {
      throw Exception('Firma hizmeti silinirken hata oluştu: $e');
    }
  }

  @override
  Future<List<CompanyServiceModel>> searchCompanyServices(String query) async {
    try {
      return await _apiService.searchCompanyServices(query);
    } catch (e) {
      throw Exception('Firma hizmeti arama yapılırken hata oluştu: $e');
    }
  }

  @override
  Future<List<CompanyServiceModel>> getCompanyServicesByCompanyId(
    String companyId, {
    String? parentCompanyId,
  }) async {
    try {
      return await _apiService.getCompanyServicesByCompanyId(
        companyId,
        parentCompanyId: parentCompanyId,
      );
    } catch (e) {
      throw Exception('Şube hizmetleri yüklenirken hata oluştu: $e');
    }
  }
}
