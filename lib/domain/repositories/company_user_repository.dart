import '../../data/models/company_user_model.dart';

abstract class CompanyUserRepository {
  Future<Map<String, dynamic>> getCompanyUsers({int page = 1, int dataCount = 20});
  Future<void> addCompanyUser(Map<String, dynamic> userData);
  Future<void> updateCompanyUser(Map<String, dynamic> userData);
  Future<void> deleteCompanyUser({required String userId, required String companyId});
}
