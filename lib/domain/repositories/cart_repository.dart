import '../entities/cart.dart';

abstract class CartRepository {
  Future<Cart> getCart();

  Future<void> addToCart({
    required String productId, // UUID string
    required int quantity,
  });

  Future<void> increaseQuantity({
    required String productId, // UUID string
    required int quantity,
  });

  Future<void> decreaseQuantity({
    required String productId, // UUID string
    required int quantity,
  });

  Future<void> removeFromCart(String productId); // UUID string
}
