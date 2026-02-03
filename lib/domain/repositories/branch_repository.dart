import '../../data/models/branch_model.dart';

abstract class BranchRepository {
  Future<List<BranchModel>> getBranches();
  Future<BranchModel> getBranch(String branchId);
  Future<BranchModel> createBranch(
    BranchModel branch, {
    String? profileImagePath,
    List<String>? interiorImagePaths,
    String? paidTypes, // YENİ
  });
  Future<BranchModel> updateBranch(
    String branchId,
    BranchModel branch, {
    String? paidTypes,
    String? profileImagePath,
    List<String>? newInteriorImagePaths,
  });
  Future<void> deleteBranch(String branchId);
  Future<BranchModel> updateBranchStatus(String branchId, String status);
  Future<String> uploadBranchImage(String branchId, String imagePath);
  Future<List<BranchModel>> searchBranches(String query);
  // getBranchFeatures() metodu kaldırıldı - backend API yok, sabit liste kullanılıyor
}
