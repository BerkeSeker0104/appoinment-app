import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../../core/services/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../models/product_category_model.dart';
import '../models/localized_text.dart';

class CategoryApiService {
  final ApiClient _apiClient = ApiClient();

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is String) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map<String, dynamic>) return decoded;
      } catch (_) {}
    }
    return <String, dynamic>{};
  }

  // Görsel sıkıştırma
  Future<File?> _compressImage(File file) async {
    try {
      final filePath = file.absolute.path;
      final lastIndex = filePath.lastIndexOf('.');
      final outPath = '${filePath.substring(0, lastIndex)}_compressed.jpg';

      final result = await FlutterImageCompress.compressAndGetFile(
        filePath,
        outPath,
        quality: 85,
        format: CompressFormat.jpeg,
      );

      if (result != null) {
        return File(result.path);
      }
      return file;
    } catch (e) {
      return file;
    }
  }

  // Get all categories
  Future<List<ProductCategoryModel>> getCategories() async {
    try {
      final response = await _apiClient.get(ApiConstants.productCategories);
      final data = _asMap(response.data);

      List<dynamic> categoriesList = [];
      if (data['data'] is List) {
        categoriesList = data['data'] as List<dynamic>;
      } else if (data['categories'] is List) {
        categoriesList = data['categories'] as List<dynamic>;
      } else if (data is List) {
        categoriesList = data as List<dynamic>;
      }

      return categoriesList
          .map((json) => ProductCategoryModel.fromJson(json))
          .toList();
    } catch (e) {
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('404') || errorString.contains('bulunamadı')) {
        return [];
      }
      throw Exception('Kategoriler yüklenirken hata oluştu: $e');
    }
  }

  // Get category by ID
  Future<ProductCategoryModel> getCategory(String id) async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.productCategories}/$id',
      );
      final data = _asMap(response.data);

      Map<String, dynamic> categoryData;
      if (data['data'] is Map<String, dynamic>) {
        categoryData = data['data'];
      } else if (data['category'] is Map<String, dynamic>) {
        categoryData = data['category'];
      } else {
        categoryData = data;
      }

      return ProductCategoryModel.fromJson(categoryData);
    } catch (e) {
      throw Exception('Kategori bilgileri yüklenirken hata oluştu: $e');
    }
  }

  // Create category (Admin only)
  Future<ProductCategoryModel> createCategory({
    required Map<String, String> name, // {tr: "...", en: "..."}
    File? image,
  }) async {
    try {

      Map<String, dynamic> requestData = {
        'name': jsonEncode(name),
      };

      dynamic response;

      // Add image if provided
      if (image != null) {

        final compressedFile = await _compressImage(image);
        if (compressedFile == null) {
          throw Exception('Dosya sıkıştırma başarısız oldu.');
        }

        final fileSize = await compressedFile.length();
        if (fileSize > 10 * 1024 * 1024) {
          throw Exception('Dosya boyutu çok büyük. Maksimum 10MB olmalıdır.');
        }

        // Try different field names for image upload
        final formData = FormData.fromMap(requestData);
        formData.files.add(
          MapEntry(
            'picture', // Try 'picture' field name
            await MultipartFile.fromFile(
              compressedFile.path,
              filename: 'category_image.jpg',
            ),
          ),
        );

        response = await _apiClient.post(
          ApiConstants.productCategories,
          data: formData,
        );
      } else {
        // No image, send as regular JSON
        response = await _apiClient.post(
          ApiConstants.productCategories,
          data: requestData,
        );
      }

      final data = _asMap(response.data);

      ProductCategoryModel createdCategory;
      if (data['data'] is Map<String, dynamic>) {
        createdCategory = ProductCategoryModel.fromJson(data['data']);
      } else if (data['category'] is Map<String, dynamic>) {
        createdCategory = ProductCategoryModel.fromJson(data['category']);
      } else {
        // Return with generated ID if backend returns simple success
        createdCategory = ProductCategoryModel(
          id: data['id']?.toString() ??
              DateTime.now().millisecondsSinceEpoch.toString(),
          name: LocalizedText(tr: name['tr'] ?? '', en: name['en'] ?? ''),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }

      return createdCategory;
    } on DioException catch (e) {
      // Special handling for 404 - feature not available
      if (e.response?.statusCode == 404) {
        throw Exception(
          'Kategori ekleme özelliği henüz aktif değil. Lütfen daha sonra tekrar deneyin.',
        );
      }
      // ApiClient already handles DioException and parses error messages
      rethrow;
    } catch (e) {
      throw Exception('Kategori oluşturulurken hata oluştu: $e');
    }
  }

  // Update category (Admin only)
  Future<ProductCategoryModel> updateCategory({
    required String id,
    required Map<String, String> name,
    File? image,
  }) async {
    try {

      Map<String, dynamic> requestData = {
        'name': jsonEncode(name),
      };

      dynamic response;

      // Add image if provided
      if (image != null) {

        final compressedFile = await _compressImage(image);
        if (compressedFile == null) {
          throw Exception('Dosya sıkıştırma başarısız oldu.');
        }

        final formData = FormData.fromMap(requestData);
        formData.files.add(
          MapEntry(
            'picture', // Try 'picture' field name
            await MultipartFile.fromFile(
              compressedFile.path,
              filename: 'category_image.jpg',
            ),
          ),
        );

        response = await _apiClient.put(
          '${ApiConstants.productCategories}/$id',
          data: formData,
        );
      } else {
        // No image, send as regular JSON
        response = await _apiClient.put(
          '${ApiConstants.productCategories}/$id',
          data: requestData,
        );
      }

      final data = _asMap(response.data);

      ProductCategoryModel updatedCategory;
      if (data['data'] is Map<String, dynamic>) {
        updatedCategory = ProductCategoryModel.fromJson(data['data']);
      } else if (data['category'] is Map<String, dynamic>) {
        updatedCategory = ProductCategoryModel.fromJson(data['category']);
      } else {
        updatedCategory = ProductCategoryModel(
          id: id,
          name: LocalizedText(tr: name['tr'] ?? '', en: name['en'] ?? ''),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }

      return updatedCategory;
    } on DioException catch (e) {
      // Special handling for 404 - feature not available
      if (e.response?.statusCode == 404) {
        throw Exception(
          'Kategori güncelleme özelliği henüz aktif değil.',
        );
      }
      // ApiClient already handles DioException and parses error messages
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  // Delete category (Admin only)
  Future<void> deleteCategory(String id) async {
    try {

      await _apiClient.delete('${ApiConstants.productCategories}/$id');

    } catch (e) {
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('404') || errorString.contains('bulunamadı')) {
        throw Exception(
          'Kategori silme özelliği henüz aktif değil.',
        );
      }
      throw Exception('Kategori silinirken hata oluştu: $e');
    }
  }
}
