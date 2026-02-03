import 'package:flutter/foundation.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/category.dart' as entity;
import '../../domain/usecases/product_usecases.dart';
import '../../data/repositories/product_repository_impl.dart';
import '../../core/services/app_lifecycle_service.dart';

class ProductProvider with ChangeNotifier implements LoadingStateResettable {
  final ProductUseCases _productUseCases =
      ProductUseCases(ProductRepositoryImpl());

  List<Product> _products = [];
  List<Product> _allProducts =
      []; // Keep all products for client-side filtering
  List<entity.Category> _categories = [];
  Product? _selectedProduct;
  String? _selectedCategoryId;
  String _searchQuery = '';
  bool _isLoading = false;
  String? _error;

  List<Product> get products => _products;
  List<entity.Category> get categories => _categories;
  Product? get selectedProduct => _selectedProduct;
  String? get selectedCategoryId => _selectedCategoryId;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load categories
  Future<void> loadCategories() async {
    try {
      _categories = await _productUseCases.getCategories();
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Load products with optional filters
  Future<void> loadProducts({
    String? categoryId,
    String? search,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final fetchedProducts = await _productUseCases.getProducts(
        categoryId: categoryId,
        search: search,
      );

      // If loading without filters, update both _products and _allProducts
      if (categoryId == null && search == null) {
        _allProducts = fetchedProducts;
        _products = fetchedProducts;
      } else {
        // If loading with filters, update _products but keep _allProducts if empty
        // This allows client-side filtering as fallback
        _products = fetchedProducts;
        // Only update _allProducts if it's empty (first load with filter)
        if (_allProducts.isEmpty && fetchedProducts.isNotEmpty) {
          // Try to load all products in background for client-side filtering
          _loadAllProductsInBackground();
        }
      }

      _error = null;
    } catch (e) {
      _error = e.toString();
      // If API call fails and we have products in _allProducts, use client-side filtering
      if (_allProducts.isNotEmpty) {
        _products = _allProducts;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load all products in background (for client-side filtering fallback)
  Future<void> _loadAllProductsInBackground() async {
    try {
      _allProducts = await _productUseCases.getProducts();
      // If current products list is empty but we have all products, apply filters
      if (_products.isEmpty && _allProducts.isNotEmpty) {
        _products = getFilteredProducts();
        notifyListeners();
      }
    } catch (e) {
      // Silently fail - this is just a background operation
    }
  }

  // Load product by ID
  Future<void> loadProduct(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedProduct = await _productUseCases.getProduct(id);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load products by company
  Future<void> loadProductsByCompany(String companyId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _products = await _productUseCases.getProductsByCompany(companyId);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Search products
  Future<void> searchProducts(String query) async {
    _searchQuery = query;
    await loadProducts(search: query);
  }

  // Filter by category
  Future<void> filterByCategory(String? categoryId) async {
    _selectedCategoryId = categoryId;

    // If no category is selected, show all products
    if (categoryId == null) {
      // Ensure we have all products loaded
      if (_allProducts.isEmpty) {
        await loadProducts(); // This will load all products and update _allProducts
      } else {
        // If we already have all products, just update _products to show all
        _products = _allProducts;
        notifyListeners();
      }
      return;
    }

    // If we don't have all products loaded, load them first for client-side filtering
    if (_allProducts.isEmpty) {
      try {
        _allProducts = await _productUseCases.getProducts();
      } catch (e) {
        // If loading all products fails, continue with API filtering
      }
    }

    // Try to load from API first (for fresh data)
    await loadProducts(
        categoryId: categoryId,
        search: _searchQuery.isNotEmpty ? _searchQuery : null);

    // Also apply client-side filtering as backup
    // This ensures products are shown even if API filtering fails or returns empty
    if (_allProducts.isNotEmpty) {
      final filtered = getFilteredProducts();
      // Use client-side filtered products if API returned empty or fewer products
      // This handles cases where API filtering doesn't work correctly
      if (_products.isEmpty || filtered.length > _products.length) {
        _products = filtered;
        notifyListeners();
      }
    }
  }

  // Clear filters
  void clearFilters() {
    _selectedCategoryId = null;
    _searchQuery = '';

    // If we have all products, use them directly
    if (_allProducts.isNotEmpty) {
      _products = _allProducts;
      notifyListeners();
    } else {
      // Otherwise, load from API
      loadProducts();
    }
  }

  // Get filtered products (client-side filtering for backup)
  // Uses _allProducts if available, otherwise falls back to _products
  // If no category is selected, returns all products
  List<Product> getFilteredProducts() {
    // If no category is selected and no search query, return all products
    if (_selectedCategoryId == null && _searchQuery.isEmpty) {
      // Prefer _allProducts if available, otherwise use _products
      return _allProducts.isNotEmpty ? _allProducts : _products;
    }

    // Use _allProducts for filtering if available, otherwise use _products
    var sourceProducts = _allProducts.isNotEmpty ? _allProducts : _products;
    var filtered = sourceProducts;

    // Filter by category if selected
    if (_selectedCategoryId != null) {
      filtered = filtered
          .where((product) => product.categoryId == _selectedCategoryId)
          .toList();
    }

    // Filter by search query if provided
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered
          .where((product) =>
              product.name.toLowerCase().contains(query) ||
              product.description.toLowerCase().contains(query))
          .toList();
    }

    return filtered;
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Clear selected product
  void clearSelectedProduct() {
    _selectedProduct = null;
    notifyListeners();
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
