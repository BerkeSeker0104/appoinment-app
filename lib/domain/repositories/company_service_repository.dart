import '../../data/models/company_service_model.dart';

abstract class CompanyServiceRepository {
  /// Get all company services
  Future<List<CompanyServiceModel>> getCompanyServices();

  /// Get a specific company service by ID
  Future<CompanyServiceModel> getCompanyService(String id);

  /// Create a new company service
  Future<CompanyServiceModel> createCompanyService({
    required List<dynamic> companyIds, // int (sayısal ID) veya String (UUID) olabilir
    required String serviceId,
    required double minPrice,
    double? maxPrice,
    required int duration,
  });

  /// Update an existing company service
  Future<CompanyServiceModel> updateCompanyService({
    required String id,
    required List<dynamic> companyIds, // int (sayısal ID) veya String (UUID) olabilir
    required String serviceId,
    required double minPrice,
    double? maxPrice,
    required int duration,
  });

  /// Delete a company service
  Future<void> deleteCompanyService(String id);

  /// Search company services
  Future<List<CompanyServiceModel>> searchCompanyServices(String query);

  /// Get company services by company ID
  Future<List<CompanyServiceModel>> getCompanyServicesByCompanyId(
    String companyId, {
    String? parentCompanyId,
  });
}
