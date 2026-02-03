import '../../domain/entities/cart.dart';
import '../../domain/repositories/cart_repository.dart';
import '../services/cart_api_service.dart';
import '../models/cart_model.dart';
import '../models/cart_item_model.dart';

class CartRepositoryImpl implements CartRepository {
  final CartApiService _cartApiService = CartApiService();

  // Convert Model to Entity
  Cart _modelToEntity(CartModel model) {
    return Cart(
      items: model.items.map(_itemModelToEntity).toList(),
    );
  }

  CartItem _itemModelToEntity(CartItemModel model) {
    return CartItem(
      userId: model.userId,
      productId: model.productId,
      productName: model.product?.name ?? '',
      productPrice: model.product?.price ?? 0.0,
      quantity: model.quantity,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
    );
  }

  @override
  Future<Cart> getCart() async {
    try {
      final model = await _cartApiService.getCart();
      return _modelToEntity(model);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> addToCart({
    required String productId, // UUID string
    required int quantity,
  }) async {
    try {
      await _cartApiService.addToCart(
        productId: productId,
        quantity: quantity,
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> increaseQuantity({
    required String productId, // UUID string
    required int quantity,
  }) async {
    try {
      await _cartApiService.increaseQuantity(
        productId: productId,
        quantity: quantity,
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> decreaseQuantity({
    required String productId, // UUID string
    required int quantity,
  }) async {
    try {
      await _cartApiService.decreaseQuantity(
        productId: productId,
        quantity: quantity,
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> removeFromCart(String productId) async {
    // UUID string
    try {
      await _cartApiService.removeFromCart(productId);
    } catch (e) {
      rethrow;
    }
  }
}
