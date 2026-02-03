import 'dart:convert';
import '../../core/services/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../models/cart_model.dart';

/// Cart API Service for /api/basket endpoint
/// Matches backend specification:
/// - POST /api/basket { productId: int, quantity: int }
/// - PUT /api/basket { productId: int, type: "increase"/"decrease", quantity: int }
/// - GET /api/basket -> { status: true, data: [...] }
/// - DELETE /api/basket/{productId}
class CartApiService {
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

  /// GET /api/basket - Get user's cart
  /// Returns: { status: true, data: [{userId, productId, quantity, createdAt, updatedAt, product: {id, name, price}}] }
  Future<CartModel> getCart() async {
    try {
      final response = await _apiClient.get(ApiConstants.cart);
      final data = _asMap(response.data);

      // Backend returns { status: true, data: [...] }
      return CartModel.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  /// POST /api/basket - Add item to cart
  /// Body: { productId: String (UUID), quantity: int }
  /// Returns: { status: true, message: "Başarıyla oluşturuldu" }
  Future<void> addToCart({
    required String productId,
    required int quantity,
  }) async {
    try {
      await _apiClient.post(
        ApiConstants.cart,
        data: {
          'productId': productId, // UUID string olarak gönder
          'quantity': quantity,
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  /// PUT /api/basket - Increase quantity
  /// Body: { productId: String (UUID), type: "increase", quantity: int }
  /// Returns: { status: true, message: "Updated successfully" }
  Future<void> increaseQuantity({
    required String productId,
    required int quantity,
  }) async {
    try {
      await _apiClient.put(
        ApiConstants.cart,
        data: {
          'productId': productId, // UUID string olarak gönder
          'type': 'increase',
          'quantity': quantity,
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  /// PUT /api/basket - Decrease quantity
  /// Body: { productId: String (UUID), type: "decrease", quantity: int }
  /// Returns: { status: true, message: "Updated successfully" }
  Future<void> decreaseQuantity({
    required String productId,
    required int quantity,
  }) async {
    try {
      await _apiClient.put(
        ApiConstants.cart,
        data: {
          'productId': productId, // UUID string olarak gönder
          'type': 'decrease',
          'quantity': quantity,
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  /// DELETE /api/basket/{productId} - Remove item from cart
  /// Returns: { status: true, message: "..." }
  Future<void> removeFromCart(String productId) async {
    try {
      await _apiClient.delete('${ApiConstants.cart}/$productId');
    } catch (e) {
      rethrow;
    }
  }

  /// POST /api/basket/buy - Buy all items in cart
  /// Body: { invoiceAddressId: String, deliveryAddressId: String }
  /// Returns: { status: true, data: { html: "..." } }
  Future<String> buyCart({
    required String invoiceAddressId,
    required String deliveryAddressId,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.cartBuy,
        data: {
          'invoiceAddressId': invoiceAddressId,
          'deliveryAddressId': deliveryAddressId,
        },
      );

      final data = _asMap(response.data);
      
      // Extract HTML from response
      String html = '';
      if (data['data'] != null) {
        if (data['data'] is Map<String, dynamic>) {
          final dataMap = data['data'] as Map<String, dynamic>;
          html = dataMap['html']?.toString() ?? '';
        } else if (data['data'] is String) {
          html = data['data'].toString();
        }
      }
      
      if (html.isEmpty && data['html'] != null) {
        html = data['html'].toString();
      }
      
      if (html.isEmpty && response.data is String) {
        html = response.data.toString();
      }

      if (html.isEmpty) {
        throw Exception('Ödeme yanıtı alınamadı');
      }

      return html;
    } catch (e) {
      throw Exception('Sepet satın alma işlemi başarısız: $e');
    }
  }
}
