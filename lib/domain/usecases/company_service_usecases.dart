import '../../data/models/company_service_model.dart';
import '../repositories/company_service_repository.dart';

class CompanyServiceUseCases {
  final CompanyServiceRepository _repository;

  CompanyServiceUseCases(this._repository);

  /// Get all company services
  Future<List<CompanyServiceModel>> getCompanyServices() async {
    try {
      final services = await _repository.getCompanyServices();
      // Sort by created date (newest first)
      services.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return services;
    } catch (e) {
      throw Exception('Firma hizmetleri yüklenirken hata oluştu: $e');
    }
  }

  /// Get a specific company service by ID
  Future<CompanyServiceModel> getCompanyService(String id) async {
    try {
      return await _repository.getCompanyService(id);
    } catch (e) {
      throw Exception('Firma hizmeti bilgileri yüklenirken hata oluştu: $e');
    }
  }

  /// Create a new company service
  Future<CompanyServiceModel> createCompanyService({
    required List<dynamic> companyIds, // int (sayısal ID) veya String (UUID) olabilir
    required String serviceId,
    required double minPrice,
    double? maxPrice,
    required int duration,
  }) async {
    try {
      return await _repository.createCompanyService(
        companyIds: companyIds,
        serviceId: serviceId,
        minPrice: minPrice,
        maxPrice: maxPrice,
        duration: duration,
      );
    } catch (e) {
      throw Exception('Firma hizmeti oluşturulurken hata oluştu: $e');
    }
  }

  /// Update an existing company service
  Future<CompanyServiceModel> updateCompanyService({
    required String id,
    required List<dynamic> companyIds, // int (sayısal ID) veya String (UUID) olabilir
    required String serviceId,
    required double minPrice,
    double? maxPrice,
    required int duration,
  }) async {
    try {
      return await _repository.updateCompanyService(
        id: id,
        companyIds: companyIds,
        serviceId: serviceId,
        minPrice: minPrice,
        maxPrice: maxPrice,
        duration: duration,
      );
    } catch (e) {
      throw Exception('Firma hizmeti güncellenirken hata oluştu: $e');
    }
  }

  /// Delete a company service
  Future<void> deleteCompanyService(String id) async {
    try {
      await _repository.deleteCompanyService(id);
    } catch (e) {
      throw Exception('Firma hizmeti silinirken hata oluştu: $e');
    }
  }

  /// Search company services
  Future<List<CompanyServiceModel>> searchCompanyServices(String query) async {
    try {
      if (query.isEmpty) {
        return await getCompanyServices();
      }
      return await _repository.searchCompanyServices(query);
    } catch (e) {
      throw Exception('Firma hizmeti arama yapılırken hata oluştu: $e');
    }
  }

  /// Get company services by company ID
  Future<List<CompanyServiceModel>> getCompanyServicesByCompanyId(
    String companyId, {
    String? parentCompanyId,
  }) async {
    try {
      return await _repository.getCompanyServicesByCompanyId(
        companyId,
        parentCompanyId: parentCompanyId,
      );
    } catch (e) {
      throw Exception('Şube hizmetleri yüklenirken hata oluştu: $e');
    }
  }
}
