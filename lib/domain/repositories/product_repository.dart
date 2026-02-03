import 'dart:io';
import '../entities/product.dart';
import '../entities/category.dart';

abstract class ProductRepository {
  // Products
  Future<List<Product>> getProducts({
    String? categoryId,
    String? search,
    int? page,
    int? limit,
  });

  Future<Product> getProduct(String id);

  Future<List<Product>> getProductsByCompany(String companyId);

  Future<Product> createProduct({
    required String categoryId,
    required String name,
    required String description,
    required double price,
    required List<File> pictures,
  });

  Future<Product> updateProduct({
    required String id,
    String? name,
    String? description,
    double? price,
    List<File>? newPictures,
    bool? isActive,
    String? categoryId,
    String? status,
  });

  Future<void> deleteProduct(String id);

  Future<List<Product>> searchProducts(String query);

  Future<String> buyProduct({
    required String productId,
    required String cardNumber,
    required String cardExpirationMonth,
    required String cardExpirationYear,
    required String cardCvc,
    required String invoiceAddressId,
    required String deliveryAddressId,
  });

  Future<void> deleteProductPicture(String pictureId);

  // Categories
  Future<List<Category>> getCategories();

  Future<Category> getCategory(String id);

  Future<Category> createCategory({
    required Map<String, String> name,
    File? image,
  });

  Future<Category> updateCategory({
    required String id,
    required Map<String, String> name,
    File? image,
  });

  Future<void> deleteCategory(String id);
}
