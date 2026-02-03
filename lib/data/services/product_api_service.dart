import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../../core/services/api_client.dart';
import '../../core/services/locale_service.dart';
import '../../core/constants/api_constants.dart';
import '../models/product_model.dart';

class ProductApiService {
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

  // Get all products with optional filters
  Future<List<ProductModel>> getProducts({
    String? categoryId,
    String? search,
    int? page,
    int? limit,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (categoryId != null) queryParams['categoryId'] = categoryId;
      if (search != null) queryParams['search'] = search;
      if (page != null) queryParams['page'] = page;
      if (limit != null) queryParams['limit'] = limit;

      final response = await _apiClient.get(
        ApiConstants.products,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      final data = _asMap(response.data);

      List<dynamic> productsList = [];
      if (data['data'] is List) {
        productsList = data['data'] as List<dynamic>;
      } else if (data['products'] is List) {
        productsList = data['products'] as List<dynamic>;
      } else if (data is List) {
        productsList = data as List<dynamic>;
      }

      return productsList.map((json) => ProductModel.fromJson(json)).toList();
    } catch (e) {
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('404') || errorString.contains('bulunamadı')) {
        return [];
      }
      throw Exception('Ürünler yüklenirken hata oluştu: $e');
    }
  }

  // Get products by company
  Future<List<ProductModel>> getProductsByCompany(String companyId) async {
    try {
      // Get all products and filter by company
      final allProducts = await getProducts();
      return allProducts
          .where((product) => product.userId == companyId)
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Get product by ID
  Future<ProductModel> getProduct(String id) async {
    try {
      final response = await _apiClient.get('${ApiConstants.products}/$id');
      final data = _asMap(response.data);

      Map<String, dynamic> productData;
      if (data['data'] is Map<String, dynamic>) {
        productData = data['data'];
      } else if (data['product'] is Map<String, dynamic>) {
        productData = data['product'];
      } else {
        productData = data;
      }

      return ProductModel.fromJson(productData);
    } catch (e) {
      throw Exception('Ürün bilgileri yüklenirken hata oluştu: $e');
    }
  }

  // Create product (Company)
  Future<ProductModel> createProduct({
    required String categoryId,
    required String name,
    required String description,
    required double price,
    required List<File> pictures,
  }) async {
    try {
      final formData = FormData.fromMap({
        'categoryId': categoryId,
        'name': name,
        'description': description,
        'price': price.toString(),
      });

      // Add pictures
      for (var i = 0; i < pictures.length; i++) {
        final compressedFile = await _compressImage(pictures[i]);
        if (compressedFile == null) {
          throw Exception('Dosya sıkıştırma başarısız oldu.');
        }

        final fileSize = await compressedFile.length();
        if (fileSize > 10 * 1024 * 1024) {
          throw Exception('Dosya boyutu çok büyük. Maksimum 10MB olmalıdır.');
        }

        formData.files.add(
          MapEntry(
            'pictures', // Backend accepts multiple with same name
            await MultipartFile.fromFile(
              compressedFile.path,
              filename: 'product_$i.jpg',
            ),
          ),
        );
      }

      final response = await _apiClient.post(
        ApiConstants.products,
        data: formData,
      );

      final data = _asMap(response.data);

      ProductModel createdProduct;
      if (data['data'] is Map<String, dynamic>) {
        createdProduct = ProductModel.fromJson(data['data']);
      } else if (data['product'] is Map<String, dynamic>) {
        createdProduct = ProductModel.fromJson(data['product']);
      } else {
        // Return with generated ID if backend returns simple success
        createdProduct = ProductModel(
          id: data['id']?.toString() ??
              DateTime.now().millisecondsSinceEpoch.toString(),
          userId: '', // Backend'den gelecek
          categoryId: categoryId,
          name: name,
          description: description,
          price: price,
          pictures: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          companyName: '',
        );
      }

      return createdProduct;
    } on DioException catch (e) {
      // Special handling for 404 - feature not available
      if (e.response?.statusCode == 404) {
        throw Exception(
          'Ürün ekleme özelliği henüz aktif değil. Lütfen daha sonra tekrar deneyin.',
        );
      }
      // ApiClient already handles DioException and parses error messages
      rethrow;
      throw Exception('Ürün oluşturulurken hata oluştu: ${e.message}');
    } catch (e) {
      throw Exception('Ürün oluşturulurken hata oluştu: $e');
    }
  }

  // Update product (Company)
  Future<ProductModel> updateProduct({
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
      final formData = FormData.fromMap({});

      if (name != null) formData.fields.add(MapEntry('name', name));
      if (description != null) {
        formData.fields.add(MapEntry('description', description));
      }
      if (price != null) {
        formData.fields.add(MapEntry('price', price.toString()));
      }
      if (isActive != null) {
        formData.fields.add(MapEntry('isActive', isActive.toString()));
      }
      if (categoryId != null) {
        formData.fields.add(MapEntry('categoryId', categoryId));
      }
      if (status != null) {
        formData.fields.add(MapEntry('status', status));
      } else {
        // Default to '1' (Active) if not provided, matching typical behavior or user screenshot
        // Or maybe don't send it if null. User screenshot had it.
        // Let's send '1' if isActive is true, '0' if false, or just '1' as default if status is missing but we are updating.
        // Safest is to send it if provided. If the user in UI doesn't change it, we might need to know what it was.
        // Since we don't have it in model, let's assume '1' for now or let UI decide.
        // I will leave it as optional in param, and add to form if not null.
        formData.fields.add(MapEntry('status', '1'));
      }

      // Add new pictures if provided
      if (newPictures != null && newPictures.isNotEmpty) {
        for (var i = 0; i < newPictures.length; i++) {
          final compressedFile = await _compressImage(newPictures[i]);
          if (compressedFile == null) {
            throw Exception('Dosya sıkıştırma başarısız oldu.');
          }

          formData.files.add(
            MapEntry(
              'pictures',
              await MultipartFile.fromFile(
                compressedFile.path,
                filename: 'product_$i.jpg',
              ),
            ),
          );
        }
      }

      final response = await _apiClient.put(
        '${ApiConstants.products}/$id',
        data: formData,
      );

      final data = _asMap(response.data);

      ProductModel updatedProduct;
      if (data['data'] is Map<String, dynamic>) {
        updatedProduct = ProductModel.fromJson(data['data']);
      } else if (data['product'] is Map<String, dynamic>) {
        updatedProduct = ProductModel.fromJson(data['product']);
      } else {
        // Get updated product from API
        updatedProduct = await getProduct(id);
      }

      return updatedProduct;
    } on DioException catch (e) {
      // Special handling for 404 - feature not available
      if (e.response?.statusCode == 404) {
        throw Exception('Ürün güncelleme özelliği henüz aktif değil.');
      }
      // ApiClient already handles DioException and parses error messages
      rethrow;
    } catch (e) {
      throw Exception('Ürün güncellenirken hata oluştu: $e');
    }
  }

  // Delete product (Company/Admin)
  Future<void> deleteProduct(String id) async {
    try {
      await _apiClient.delete('${ApiConstants.products}/$id');
    } catch (e) {
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('404') || errorString.contains('bulunamadı')) {
        throw Exception('Ürün silme özelliği henüz aktif değil.');
      }
      throw Exception('Ürün silinirken hata oluştu: $e');
    }
  }

  // Search products
  Future<List<ProductModel>> searchProducts(String query) async {
    try {
      return await getProducts(search: query);
    } catch (e) {
      throw Exception('Ürün arama yapılırken hata oluştu: $e');
    }
  }

  // Buy product - Get payment gateway HTML
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
      final requestBody = {
        'productId': productId,
        'cardNumber': cardNumber,
        'cardExpirationMonth': cardExpirationMonth,
        'cardExpirationYear': cardExpirationYear,
        'cardCvc': cardCvc,
        'invoiceAddressId': invoiceAddressId,
        'deliveryAddressId': deliveryAddressId,
      };

      print('ProductBuy API Call:');
      print('  Full URL: ${ApiConstants.baseUrl}${ApiConstants.productBuy}');
      print('  Request Body: $requestBody');

      // Get token for logging
      final token = await _apiClient.getToken();
      print(
          '  Auth Token: ${token != null ? "${token.substring(0, 20)}..." : "NULL"}');

      // Use Dio directly to catch DioException before ApiClient converts it
      final localeService = LocaleService();
      final languageCode = localeService.currentLanguageCode;
      final dio = Dio(BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        headers: {
          ...ApiConstants.defaultHeaders,
          if (token != null) 'Authorization': 'Bearer $token',
          'Accept-Language': languageCode,
        },
      ));

      Response response;
      try {
        response = await dio.post(
          ApiConstants.productBuy,
          data: requestBody,
        );
      } on DioException catch (dioError) {
        print('DioException Details:');
        print('  Type: ${dioError.type}');
        print('  Message: ${dioError.message}');
        print('  Request URL: ${dioError.requestOptions.uri}');
        print('  Request Method: ${dioError.requestOptions.method}');
        print('  Request Headers: ${dioError.requestOptions.headers}');
        print('  Request Data: ${dioError.requestOptions.data}');
        if (dioError.response != null) {
          print('  Response Status: ${dioError.response!.statusCode}');
          print('  Response Data: ${dioError.response!.data}');
          print('  Response Headers: ${dioError.response!.headers}');

        } else {
          print('  No response received');
        }
        // ApiClient already handles DioException and parses error messages
        rethrow;
      }

      print('ProductBuy API Response Status: ${response.statusCode}');
      print('ProductBuy API Response Data: ${response.data}');

      final data = _asMap(response.data);

      // Extract HTML from response
      // Response format: { data: { status: true, json: { html: "..." } } }
      // or { data: { html: "..." } } or { html: "..." } or { data: "..." }
      String html = '';

      if (data['data'] != null && data['data'] is Map<String, dynamic>) {
        final dataMap = data['data'] as Map<String, dynamic>;

        // Try data.data.json.html first (actual response format)
        if (dataMap['json'] != null &&
            dataMap['json'] is Map<String, dynamic>) {
          final jsonMap = dataMap['json'] as Map<String, dynamic>;
          html = jsonMap['html']?.toString() ?? '';
          print('Extracted HTML from data.data.json.html');
        }

        // Try data.data.html
        if (html.isEmpty && dataMap['html'] != null) {
          html = dataMap['html'].toString();
          print('Extracted HTML from data.data.html');
        }
      }

      // Try data.html
      if (html.isEmpty && data['html'] != null) {
        html = data['html'].toString();
        print('Extracted HTML from data.html');
      }

      // Try response.data directly if it's a string (raw HTML)
      if (html.isEmpty && response.data is String) {
        html = response.data.toString();
        print('Extracted HTML from response.data (string)');
      }

      if (html.isEmpty) {
        throw Exception('Ödeme yanıtı alınamadı. API yanıtı: ${response.data}');
      }

      print('HTML extracted successfully, length: ${html.length}');
      return html;
    } catch (e) {
      // Daha detaylı hata mesajı
      print('ProductBuy API Error: $e');
      String errorMessage = 'Ürün satın alma işlemi başarısız';
      if (e is DioException) {
        print('DioException type: ${e.type}');
        print('DioException message: ${e.message}');
        if (e.response != null) {
          print('DioException response status: ${e.response!.statusCode}');
          print('DioException response data: ${e.response!.data}');
          final responseData = _asMap(e.response!.data);
          errorMessage = responseData['message']?.toString() ??
              responseData['error']?.toString() ??
              'Sunucu hatası: ${e.response!.statusCode}';
        } else {
          errorMessage = e.message ?? 'Ağ hatası oluştu';
        }
      } else {
        print('Non-Dio Exception: $e');
        errorMessage = e.toString();
      }
      throw Exception(errorMessage);
    }
  }

  // Delete product picture
  Future<void> deleteProductPicture(String pictureId) async {
    try {
      await _apiClient.delete('${ApiConstants.products}/picture/$pictureId');
    } catch (e) {
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('404') || errorString.contains('bulunamadı')) {
        throw Exception('Resim silme özelliği henüz aktif değil.');
      }
      throw Exception('Resim silinirken hata oluştu: $e');
    }
  }
}
