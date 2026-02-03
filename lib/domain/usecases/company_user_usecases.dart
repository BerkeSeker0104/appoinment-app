import '../repositories/company_user_repository.dart';
import '../../data/repositories/company_user_repository_impl.dart';

class CompanyUserUseCases {
  final CompanyUserRepository _repository = CompanyUserRepositoryImpl();

  Future<Map<String, dynamic>> getCompanyUsers({int page = 1, int dataCount = 20}) {
    return _repository.getCompanyUsers(page: page, dataCount: dataCount);
  }

  Future<void> addCompanyUser(Map<String, dynamic> userData) {
    return _repository.addCompanyUser(userData);
  }

  Future<void> updateCompanyUser(Map<String, dynamic> userData) {
    return _repository.updateCompanyUser(userData);
  }

  Future<void> deleteCompanyUser({required String userId, required String companyId}) {
    return _repository.deleteCompanyUser(userId: userId, companyId: companyId);
  }
}
