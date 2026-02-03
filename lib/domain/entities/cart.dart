/// Cart domain entities matching backend /api/basket structure
class CartItem {
  final String userId;
  final String productId; // UUID string
  final String productName;
  final double productPrice;
  final int quantity;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CartItem({
    required this.userId,
    required this.productId,
    required this.productName,
    required this.productPrice,
    required this.quantity,
    required this.createdAt,
    required this.updatedAt,
  });

  CartItem copyWith({
    String? userId,
    String? productId, // UUID string
    String? productName,
    double? productPrice,
    int? quantity,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CartItem(
      userId: userId ?? this.userId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productPrice: productPrice ?? this.productPrice,
      quantity: quantity ?? this.quantity,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  double get subtotal => productPrice * quantity;
}

class Cart {
  final List<CartItem> items;

  const Cart({
    required this.items,
  });

  Cart copyWith({
    List<CartItem>? items,
  }) {
    return Cart(
      items: items ?? this.items,
    );
  }

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);
  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;

  double get totalAmount {
    return items.fold(0.0, (sum, item) => sum + item.subtotal);
  }

  double calculateTotal() => totalAmount;
}
