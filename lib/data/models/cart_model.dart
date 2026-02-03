import 'cart_item_model.dart';

/// Backend cart model matching /api/basket GET response
/// Response format: { status: true, data: [...items] }
class CartModel {
  final List<CartItemModel> items;

  const CartModel({
    required this.items,
  });

  /// Parse backend response: { status: true, data: [...] }
  factory CartModel.fromJson(Map<String, dynamic> json) {
    // Extract data array from response
    final dataList = json['data'] as List<dynamic>? ?? [];
    final items = dataList
        .map((item) => CartItemModel.fromJson(item as Map<String, dynamic>))
        .toList();

    return CartModel(items: items);
  }

  /// Parse list directly (for testing or other uses)
  factory CartModel.fromList(List<dynamic> list) {
    final items = list
        .map((item) => CartItemModel.fromJson(item as Map<String, dynamic>))
        .toList();
    return CartModel(items: items);
  }

  Map<String, dynamic> toJson() {
    return {
      'data': items.map((item) => item.toJson()).toList(),
    };
  }

  CartModel copyWith({
    List<CartItemModel>? items,
  }) {
    return CartModel(
      items: items ?? this.items,
    );
  }

  // Computed properties
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);
  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;

  /// Calculate total amount from items (backend doesn't return total)
  double get totalAmount {
    return items.fold(0.0, (sum, item) => sum + item.subtotal);
  }

  double calculateTotal() => totalAmount;
}
