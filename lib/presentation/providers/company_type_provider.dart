import 'package:flutter/foundation.dart';
import '../../data/services/company_api_service.dart';
import '../../data/models/company_type_model.dart';
import '../../core/services/app_lifecycle_service.dart';

class CompanyTypeProvider with ChangeNotifier implements LoadingStateResettable {
  final CompanyApiService _companyApiService = CompanyApiService();

  List<CompanyTypeModel> _companyTypes = [];
  String? _selectedCategoryId;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<CompanyTypeModel> get companyTypes => _companyTypes;
  String? get selectedCategoryId => _selectedCategoryId;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load company types from API
  Future<void> loadCompanyTypes() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final types = await _companyApiService.getCompanyTypes();

      _companyTypes = types;
      _error = null;
    } catch (e) {
      _error = 'Kategoriler yüklenirken hata oluştu';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Select a category for filtering
  void selectCategory(String? categoryId) {
    // Always set the selected category, no deselection
    _selectedCategoryId = categoryId;

    notifyListeners();
  }

  // Check if a category is selected
  bool isCategorySelected(String categoryId) {
    return _selectedCategoryId == categoryId;
  }

  // Get selected category name
  String get selectedCategoryName {
    if (_selectedCategoryId == null) return 'Tümü';

    final selectedType = _companyTypes.firstWhere(
      (type) => type.id == _selectedCategoryId,
      orElse: () => CompanyTypeModel(id: '', name: 'Tümü'),
    );

    return selectedType.name;
  }

  /// Reset loading states - called when app resumes from background
  @override
  void resetLoadingState() {
    if (_isLoading) {
      _isLoading = false;
      notifyListeners();
    }
  }
}
