import 'dart:io';
import '../../domain/entities/product.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/product_repository.dart';
import '../services/product_api_service.dart';
import '../services/category_api_service.dart';
import '../models/product_model.dart';
import '../models/product_category_model.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductApiService _productApiService = ProductApiService();
  final CategoryApiService _categoryApiService = CategoryApiService();

  // Convert Model to Entity
  Product _modelToEntity(ProductModel model) {
    return Product(
      id: model.id,
      userId: model.userId,
      categoryId: model.categoryId,
      name: model.name,
      description: model.description,
      price: model.price,
      pictures: model.pictures,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
      companyName: model.companyName,
    );
  }

  Category _categoryModelToEntity(ProductCategoryModel model) {
    return Category(
      id: model.id,
      nameTr: model.name.tr,
      nameEn: model.name.en,
      imageUrl: model.imageUrl,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
    );
  }

  @override
  Future<List<Product>> getProducts({
    String? categoryId,
    String? search,
    int? page,
    int? limit,
  }) async {
    try {
      final models = await _productApiService.getProducts(
        categoryId: categoryId,
        search: search,
        page: page,
        limit: limit,
      );
      return models.map(_modelToEntity).toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Product> getProduct(String id) async {
    try {
      final model = await _productApiService.getProduct(id);
      return _modelToEntity(model);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<Product>> getProductsByCompany(String companyId) async {
    try {
      final models = await _productApiService.getProductsByCompany(companyId);
      return models.map(_modelToEntity).toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Product> createProduct({
    required String categoryId,
    required String name,
    required String description,
    required double price,
    required List<File> pictures,
  }) async {
    try {
      final model = await _productApiService.createProduct(
        categoryId: categoryId,
        name: name,
        description: description,
        price: price,
        pictures: pictures,
      );
      return _modelToEntity(model);
    } catch (e) {
      rethrow;
    }
  }

  @override
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
    try {
      final model = await _productApiService.updateProduct(
        id: id,
        name: name,
        description: description,
        price: price,
        newPictures: newPictures,
        isActive: isActive,
        categoryId: categoryId,
        status: status,
      );
      return _modelToEntity(model);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> deleteProduct(String id) async {
    try {
      await _productApiService.deleteProduct(id);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<Product>> searchProducts(String query) async {
    try {
      final models = await _productApiService.searchProducts(query);
      return models.map(_modelToEntity).toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<String> buyProduct({
    required String productId,
    required String cardNumber,
    required String cardExpirationMonth,
    required String cardExpirationYear,
    required String cardCvc,
    required String invoiceAddressId,
    required String deliveryAddressId,
  }) async {
    try {
      return await _productApiService.buyProduct(
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

  @override
  Future<void> deleteProductPicture(String pictureId) async {
    try {
      await _productApiService.deleteProductPicture(pictureId);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<Category>> getCategories() async {
    try {
      final models = await _categoryApiService.getCategories();
      return models.map(_categoryModelToEntity).toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Category> getCategory(String id) async {
    try {
      final model = await _categoryApiService.getCategory(id);
      return _categoryModelToEntity(model);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Category> createCategory({
    required Map<String, String> name,
    File? image,
  }) async {
    try {
      final model = await _categoryApiService.createCategory(
        name: name,
        image: image,
      );
      return _categoryModelToEntity(model);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Category> updateCategory({
    required String id,
    required Map<String, String> name,
    File? image,
  }) async {
    try {
      final model = await _categoryApiService.updateCategory(
        id: id,
        name: name,
        image: image,
      );
      return _categoryModelToEntity(model);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> deleteCategory(String id) async {
    try {
      await _categoryApiService.deleteCategory(id);
    } catch (e) {
      rethrow;
    }
  }
}
