import 'dart:io';
import '../entities/product.dart';
import '../entities/category.dart';
import '../repositories/product_repository.dart';

class ProductUseCases {
  final ProductRepository _productRepository;

  ProductUseCases(this._productRepository);

  // Product operations
  Future<List<Product>> getProducts({
    String? categoryId,
    String? search,
    int? page,
    int? limit,
  }) async {
    try {
      return await _productRepository.getProducts(
        categoryId: categoryId,
        search: search,
        page: page,
        limit: limit,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<Product> getProduct(String id) async {
    if (id.isEmpty) {
      throw Exception('Ürün ID\'si gerekli');
    }
    try {
      return await _productRepository.getProduct(id);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Product>> getProductsByCompany(String companyId) async {
    if (companyId.isEmpty) {
      throw Exception('Şirket ID\'si gerekli');
    }
    try {
      return await _productRepository.getProductsByCompany(companyId);
    } catch (e) {
      rethrow;
    }
  }

  Future<Product> createProduct({
    required String categoryId,
    required String name,
    required String description,
    required double price,
    required List<File> pictures,
  }) async {
    // Validation
    if (categoryId.isEmpty) {
      throw Exception('Kategori seçimi gerekli');
    }
    if (name.isEmpty) {
      throw Exception('Ürün adı gerekli');
    }
    if (description.isEmpty) {
      throw Exception('Ürün açıklaması gerekli');
    }
    if (price <= 0) {
      throw Exception('Geçerli bir fiyat girin');
    }
    if (pictures.isEmpty) {
      throw Exception('En az bir ürün görseli gerekli');
    }

    try {
      return await _productRepository.createProduct(
        categoryId: categoryId,
        name: name,
        description: description,
        price: price,
        pictures: pictures,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<Product> updateProduct({
    required String id,
    String? name,
    String? description,
    double? price,
    List<File>? newPictures,
    bool? isActive,
    String? categoryId,
    String? status,
  }) async {
    if (id.isEmpty) {
      throw Exception('Ürün ID\'si gerekli');
    }

    // Validation
    if (price != null && price <= 0) {
      throw Exception('Geçerli bir fiyat girin');
    }

    try {
      return await _productRepository.updateProduct(
        id: id,
        name: name,
        description: description,
        price: price,
        newPictures: newPictures,
        isActive: isActive,
        categoryId: categoryId,
        status: status,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteProduct(String id) async {
    if (id.isEmpty) {
      throw Exception('Ürün ID\'si gerekli');
    }
    try {
      await _productRepository.deleteProduct(id);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Product>> searchProducts(String query) async {
    if (query.isEmpty) {
      throw Exception('Arama terimi gerekli');
    }
    try {
      return await _productRepository.searchProducts(query);
    } catch (e) {
      rethrow;
    }
  }

  // Category operations
  Future<List<Category>> getCategories() async {
    try {
      return await _productRepository.getCategories();
    } catch (e) {
      rethrow;
    }
  }

  Future<Category> getCategory(String id) async {
    if (id.isEmpty) {
      throw Exception('Kategori ID\'si gerekli');
    }
    try {
      return await _productRepository.getCategory(id);
    } catch (e) {
      rethrow;
    }
  }

  Future<Category> createCategory({
    required Map<String, String> name,
    File? image,
  }) async {
    // Validation
    if (name['tr'] == null || name['tr']!.isEmpty) {
      throw Exception('Kategori adı (Türkçe) gerekli');
    }

    try {
      return await _productRepository.createCategory(
        name: name,
        image: image,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<Category> updateCategory({
    required String id,
    required Map<String, String> name,
    File? image,
  }) async {
    if (id.isEmpty) {
      throw Exception('Kategori ID\'si gerekli');
    }
    if (name['tr'] == null || name['tr']!.isEmpty) {
      throw Exception('Kategori adı (Türkçe) gerekli');
    }

    try {
      return await _productRepository.updateCategory(
        id: id,
        name: name,
        image: image,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteCategory(String id) async {
    if (id.isEmpty) {
      throw Exception('Kategori ID\'si gerekli');
    }
    try {
      await _productRepository.deleteCategory(id);
    } catch (e) {
      rethrow;
    }
  }

  Future<String> buyProduct({
    required String productId,
    required String cardNumber,
    required String cardExpirationMonth,
    required String cardExpirationYear,
    required String cardCvc,
    required String invoiceAddressId,
    required String deliveryAddressId,
  }) async {
    // Validation
    if (productId.isEmpty) {
      throw Exception('Ürün ID\'si gerekli');
    }
    if (cardNumber.isEmpty || cardNumber.length < 16) {
      throw Exception('Geçerli bir kart numarası girin');
    }
    if (cardExpirationMonth.isEmpty) {
      throw Exception('Kart son kullanma ayı gerekli');
    }
    if (cardExpirationYear.isEmpty) {
      throw Exception('Kart son kullanma yılı gerekli');
    }
    if (cardCvc.isEmpty || cardCvc.length < 3) {
      throw Exception('Geçerli bir CVV girin');
    }
    if (invoiceAddressId.isEmpty) {
      throw Exception('Fatura adresi seçimi gerekli');
    }
    if (deliveryAddressId.isEmpty) {
      throw Exception('Teslimat adresi seçimi gerekli');
    }

    try {
      return await _productRepository.buyProduct(
        productId: productId,
        cardNumber: cardNumber,
        cardExpirationMonth: cardExpirationMonth,
        cardExpirationYear: cardExpirationYear,
        cardCvc: cardCvc,
        invoiceAddressId: invoiceAddressId,
        deliveryAddressId: deliveryAddressId,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteProductPicture(String pictureId) async {
    if (pictureId.isEmpty) {
      throw Exception('Resim ID\'si gerekli');
    }
    try {
      await _productRepository.deleteProductPicture(pictureId);
    } catch (e) {
      rethrow;
    }
  }
}
