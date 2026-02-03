import '../../data/models/branch_model.dart';
import '../repositories/branch_repository.dart';

class BranchUseCases {
  final BranchRepository _branchRepository;

  BranchUseCases(this._branchRepository);

  // Get all branches
  Future<List<BranchModel>> getBranches() async {
    return await _branchRepository.getBranches();
  }

  // Get a specific branch
  Future<BranchModel> getBranch(String branchId) async {
    if (branchId.isEmpty) {
      throw Exception('Şube ID gerekli');
    }
    return await _branchRepository.getBranch(branchId);
  }

  // Create a new branch
  Future<BranchModel> createBranch({
    required String name,
    required String type,
    required String address,
    required String phone,
    required String email,
    required String profileImage, // Profil görseli - zorunlu
    required List<String> interiorImages, // İç görseller - zorunlu
    double? latitude,
    double? longitude,
    required int countryId, // YENİ
    required int cityId, // YENİ
    required int stateId, // YENİ
    required String
        companyId, // User ID - Backend'in beklediği id alanı (UUID string)
    Map<String, String>? workingHours,
    List<int>? featureIds,
    String? paidTypes, // YENİ - virgülle ayrılmış string
  }) async {
    if (name.isEmpty ||
        type.isEmpty ||
        address.isEmpty ||
        phone.isEmpty ||
        email.isEmpty) {
      throw Exception('Tüm gerekli alanlar doldurulmalı');
    }

    if (!email.contains('@')) {
      throw Exception('Geçerli bir e-posta adresi girin');
    }

    // Profil görseli kontrolü
    if (profileImage.isEmpty) {
      throw Exception('Profil görseli gerekli');
    }

    // İç görseller kontrolü
    if (interiorImages.length < 3) {
      throw Exception('En az 3 iç görsel eklemelisiniz');
    }

    if (interiorImages.length > 10) {
      throw Exception('Maksimum 10 iç görsel ekleyebilirsiniz');
    }

    final branch = BranchModel(
      id: '', // Will be set by the API
      name: name,
      type: type,
      address: address,
      phone: phone,
      email: email,
      status: 'active',
      image: profileImage, // Profil görseli path'i
      latitude: latitude,
      longitude: longitude,
      countryId: countryId, // YENİ
      cityId: cityId, // YENİ
      stateId: stateId, // YENİ
      companyId: companyId, // User ID - Backend'in beklediği id alanı
      workingHours: workingHours ??
          {
            'monday': '09:00 - 18:00',
            'tuesday': '09:00 - 18:00',
            'wednesday': '09:00 - 18:00',
            'thursday': '09:00 - 18:00',
            'friday': '09:00 - 18:00',
            'saturday': '10:00 - 16:00',
            'sunday': 'Kapalı',
          },
      services: const [],
      featureIds: featureIds,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return await _branchRepository.createBranch(
      branch,
      profileImagePath: profileImage,
      interiorImagePaths: interiorImages,
      paidTypes: paidTypes, // YENİ
    );
  }

  // Update an existing branch
  Future<BranchModel> updateBranch({
    required String branchId,
    String? name,
    String? type,
    String? address,
    String? phone,
    String? email,
    String? status,
    String? image,
    double? latitude,
    double? longitude,
    int? countryId, // YENİ
    int? cityId, // YENİ
    int? stateId, // YENİ
    Map<String, String>? workingHours,
    List<int>? featureIds, // YENİ - Backend feature ID array bekliyor
    String? paidTypes, // YENİ - virgülle ayrılmış string
    String? profileImagePath, // YENİ - şube görseli dosya yolu
    List<String>? newInteriorImagePaths,
  }) async {
    if (branchId.isEmpty) {
      throw Exception('Şube ID gerekli');
    }

    // Get current branch data
    final currentBranch = await _branchRepository.getBranch(branchId);

    // Create updated branch with new data
    final updatedBranch = currentBranch.copyWith(
      name: name,
      type: type,
      address: address,
      phone: phone,
      email: email,
      status: status,
      image: image,
      latitude: latitude,
      longitude: longitude,
      countryId: countryId, // YENİ
      cityId: cityId, // YENİ
      stateId: stateId, // YENİ
      workingHours: workingHours,
      featureIds: featureIds, // YENİ - Backend feature ID array bekliyor
      updatedAt: DateTime.now(),
    );

    return await _branchRepository.updateBranch(
      branchId,
      updatedBranch,
      paidTypes: paidTypes,
      profileImagePath: profileImagePath,
      newInteriorImagePaths: newInteriorImagePaths,
    );
  }

  // Delete a branch
  Future<void> deleteBranch(String branchId) async {
    if (branchId.isEmpty) {
      throw Exception('Şube ID gerekli');
    }
    await _branchRepository.deleteBranch(branchId);
  }

  // Update branch status
  Future<BranchModel> updateBranchStatus(String branchId, String status) async {
    if (branchId.isEmpty) {
      throw Exception('Şube ID gerekli');
    }
    if (status != 'active' && status != 'inactive') {
      throw Exception(
        'Geçersiz durum. Sadece "active" veya "inactive" olabilir',
      );
    }
    return await _branchRepository.updateBranchStatus(branchId, status);
  }

  // Upload branch image
  Future<String> uploadBranchImage(String branchId, String imagePath) async {
    if (branchId.isEmpty) {
      throw Exception('Şube ID gerekli');
    }
    if (imagePath.isEmpty) {
      throw Exception('Resim yolu gerekli');
    }
    return await _branchRepository.uploadBranchImage(branchId, imagePath);
  }

  // Search branches
  Future<List<BranchModel>> searchBranches(String query) async {
    if (query.isEmpty) {
      return await _branchRepository.getBranches();
    }
    return await _branchRepository.searchBranches(query);
  }

  // Toggle branch status
  Future<BranchModel> toggleBranchStatus(String branchId) async {
    if (branchId.isEmpty) {
      throw Exception('Şube ID gerekli');
    }

    final currentBranch = await _branchRepository.getBranch(branchId);
    final newStatus = currentBranch.status == 'active' ? 'inactive' : 'active';

    return await _branchRepository.updateBranchStatus(branchId, newStatus);
  }

  // Get active branches only
  Future<List<BranchModel>> getActiveBranches() async {
    final allBranches = await _branchRepository.getBranches();
    return allBranches.where((branch) => branch.isActive).toList();
  }

  // Get inactive branches only
  Future<List<BranchModel>> getInactiveBranches() async {
    final allBranches = await _branchRepository.getBranches();
    return allBranches.where((branch) => !branch.isActive).toList();
  }

  // getBranchFeatures() metodu kaldırıldı - backend API yok, sabit liste kullanılıyor
}
