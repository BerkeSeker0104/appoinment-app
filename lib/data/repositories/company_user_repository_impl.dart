import '../../domain/repositories/company_user_repository.dart';
import '../../data/services/company_user_api_service.dart';

class CompanyUserRepositoryImpl implements CompanyUserRepository {
  final CompanyUserApiService _apiService = CompanyUserApiService();

  @override
  Future<Map<String, dynamic>> getCompanyUsers({int page = 1, int dataCount = 20}) {
    return _apiService.getCompanyUsers(page: page, dataCount: dataCount);
  }

  @override
  Future<void> addCompanyUser(Map<String, dynamic> userData) {
    return _apiService.addCompanyUser(userData);
  }

  @override
  Future<void> updateCompanyUser(Map<String, dynamic> userData) {
    return _apiService.updateCompanyUser(userData);
  }

  @override
  Future<void> deleteCompanyUser({required String userId, required String companyId}) {
    return _apiService.deleteCompanyUser(userId: userId, companyId: companyId);
  }
}
