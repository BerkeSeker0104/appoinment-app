import '../models/branch_model.dart';
import '../services/branch_api_service.dart';
import '../../domain/repositories/branch_repository.dart';

class BranchRepositoryImpl implements BranchRepository {
  final BranchApiService _branchApiService = BranchApiService();

  @override
  Future<List<BranchModel>> getBranches() async {
    try {
      return await _branchApiService.getBranches();
    } catch (e) {
      throw Exception('Şubeler yüklenirken hata oluştu: $e');
    }
  }

  @override
  Future<BranchModel> getBranch(String branchId) async {
    try {
      return await _branchApiService.getBranch(branchId);
    } catch (e) {
      throw Exception('Şube bilgileri yüklenirken hata oluştu: $e');
    }
  }

  @override
  Future<BranchModel> createBranch(
    BranchModel branch, {
    String? profileImagePath,
    List<String>? interiorImagePaths,
    String? paidTypes, // YENİ
  }) async {
    try {
      // Profil görseli ve iç görselleri API'ye ilet
      return await _branchApiService.createBranch(
        branch,
        profileImagePath: profileImagePath,
        interiorImagePaths: interiorImagePaths,
        paidTypes: paidTypes, // YENİ
      );
    } catch (e) {
      throw Exception('Şube oluşturulurken hata oluştu: $e');
    }
  }

  @override
  Future<BranchModel> updateBranch(
    String branchId,
    BranchModel branch, {
    String? paidTypes,
    String? profileImagePath,
    List<String>? newInteriorImagePaths,
  }) async {
    try {
      return await _branchApiService.updateBranch(
        branchId,
        branch,
        paidTypes: paidTypes,
        profileImagePath: profileImagePath,
        newInteriorImagePaths: newInteriorImagePaths,
      );
    } catch (e) {
      throw Exception('Şube güncellenirken hata oluştu: $e');
    }
  }

  @override
  Future<void> deleteBranch(String branchId) async {
    try {
      await _branchApiService.deleteBranch(branchId);
    } catch (e) {
      throw Exception('Şube silinirken hata oluştu: $e');
    }
  }

  @override
  Future<BranchModel> updateBranchStatus(String branchId, String status) async {
    try {
      return await _branchApiService.updateBranchStatus(branchId, status);
    } catch (e) {
      throw Exception('Şube durumu güncellenirken hata oluştu: $e');
    }
  }

  @override
  Future<String> uploadBranchImage(String branchId, String imagePath) async {
    try {
      return await _branchApiService.uploadBranchImage(branchId, imagePath);
    } catch (e) {
      throw Exception('Şube resmi yüklenirken hata oluştu: $e');
    }
  }

  @override
  Future<List<BranchModel>> searchBranches(String query) async {
    try {
      return await _branchApiService.searchBranches(query);
    } catch (e) {
      throw Exception('Şube arama yapılırken hata oluştu: $e');
    }
  }

  // getBranchFeatures() metodu kaldırıldı - backend API yok, sabit liste kullanılıyor
}
