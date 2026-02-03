import '../entities/cart.dart';
import '../repositories/cart_repository.dart';

class CartUseCases {
  final CartRepository _cartRepository;

  CartUseCases(this._cartRepository);

  Future<Cart> getCart() async {
    try {
      return await _cartRepository.getCart();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> addToCart({
    required String productId, // UUID string
    required int quantity,
  }) async {
    // Validation
    if (productId.isEmpty) {
      throw Exception('Ürün ID\'si gerekli');
    }
    if (quantity <= 0) {
      throw Exception('Miktar sıfırdan büyük olmalı');
    }

    try {
      await _cartRepository.addToCart(
        productId: productId,
        quantity: quantity,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> increaseQuantity({
    required String productId, // UUID string
    required int quantity,
  }) async {
    // Validation
    if (productId.isEmpty) {
      throw Exception('Ürün ID\'si gerekli');
    }
    if (quantity <= 0) {
      throw Exception('Miktar sıfırdan büyük olmalı');
    }

    try {
      await _cartRepository.increaseQuantity(
        productId: productId,
        quantity: quantity,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> decreaseQuantity({
    required String productId, // UUID string
    required int quantity,
  }) async {
    // Validation
    if (productId.isEmpty) {
      throw Exception('Ürün ID\'si gerekli');
    }
    if (quantity <= 0) {
      throw Exception('Miktar sıfırdan büyük olmalı');
    }

    try {
      await _cartRepository.decreaseQuantity(
        productId: productId,
        quantity: quantity,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> removeItem(String productId) async {
    // UUID string
    if (productId.isEmpty) {
      throw Exception('Ürün ID\'si gerekli');
    }

    try {
      await _cartRepository.removeFromCart(productId);
    } catch (e) {
      rethrow;
    }
  }

  double getTotal(Cart cart) {
    return cart.calculateTotal();
  }

  int getItemCount(Cart cart) {
    return cart.itemCount;
  }

  bool isCartEmpty(Cart cart) {
    return cart.isEmpty;
  }
}
