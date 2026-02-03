import 'package:flutter/foundation.dart';
import '../../domain/entities/cart.dart';
import '../../domain/usecases/cart_usecases.dart';
import '../../data/repositories/cart_repository_impl.dart';
import '../../core/services/app_lifecycle_service.dart';

/// Cart Provider - Backend-only (no local storage)
/// Uses /api/basket endpoint
class CartProvider with ChangeNotifier implements LoadingStateResettable {
  final CartUseCases _cartUseCases = CartUseCases(CartRepositoryImpl());

  Cart? _cart;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<CartItem> get items => _cart?.items ?? [];
  bool get isLoading => _isLoading;
  bool get isEmpty => _cart?.isEmpty ?? true;
  int get itemCount => _cart?.itemCount ?? 0;
  double get totalAmount => _cart?.totalAmount ?? 0.0;
  String? get error => _error;

  /// Load cart from backend
  Future<void> loadCart() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _cart = await _cartUseCases.getCart();
      _error = null;
    } catch (e) {
      _error = null; // Backend error message will be shown via exception
      _cart = const Cart(items: []); // Empty cart on error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add product to cart
  Future<bool> addToCart(String productId, {int quantity = 1}) async {
    // UUID string
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _cartUseCases.addToCart(
        productId: productId,
        quantity: quantity,
      );

      // Reload cart to get updated data
      await loadCart();
      return true;
    } catch (e) {
      _error = null; // Backend error message will be shown via exception
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Increase quantity
  Future<bool> increaseQuantity(String productId, {int quantity = 1}) async {
    // UUID string
    _error = null;

    try {
      await _cartUseCases.increaseQuantity(
        productId: productId,
        quantity: quantity,
      );

      // Reload cart to get updated data
      await loadCart();
      return true;
    } catch (e) {
      _error = null; // Backend error message will be shown via exception
      notifyListeners();
      return false;
    }
  }

  /// Decrease quantity
  Future<bool> decreaseQuantity(String productId, {int quantity = 1}) async {
    // UUID string
    _error = null;

    try {
      await _cartUseCases.decreaseQuantity(
        productId: productId,
        quantity: quantity,
      );

      // Reload cart to get updated data
      await loadCart();
      return true;
    } catch (e) {
      _error = null; // Backend error message will be shown via exception
      notifyListeners();
      return false;
    }
  }

  /// Remove item from cart
  Future<bool> removeFromCart(String productId) async {
    // UUID string
    _error = null;

    try {
      await _cartUseCases.removeItem(productId);

      // Reload cart to get updated data
      await loadCart();
      return true;
    } catch (e) {
      _error = null; // Backend error message will be shown via exception
      notifyListeners();
      return false;
    }
  }

  /// Get item quantity by productId
  int getItemQuantity(String productId) {
    // UUID string
    final item = items.firstWhere(
      (item) => item.productId == productId,
      orElse: () => CartItem(
        userId: '',
        productId: '', // UUID string
        productName: '',
        productPrice: 0,
        quantity: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    return item.quantity;
  }

  /// Check if product is in cart
  bool isInCart(String productId) {
    // UUID string
    return items.any((item) => item.productId == productId);
  }

  /// Clear error
  void clearError() {
    _error = null;
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
