/// Backend cart item model matching /api/basket response
/// Response format: { userId, productId, quantity, createdAt, updatedAt, product: { id, name, price } }
class CartItemModel {
  final String userId;
  final String productId; // UUID string
  final int quantity;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ProductBasicInfo? product;

  const CartItemModel({
    required this.userId,
    required this.productId,
    required this.quantity,
    required this.createdAt,
    required this.updatedAt,
    this.product,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      userId: json['userId']?.toString() ?? '',
      productId:
          json['productId']?.toString() ?? '', // UUID string olarak parse et
      quantity: json['quantity'] as int? ?? 1,
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
      product: json['product'] != null
          ? ProductBasicInfo.fromJson(json['product'])
          : null,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'productId': productId,
      'quantity': quantity,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      if (product != null) 'product': product!.toJson(),
    };
  }

  CartItemModel copyWith({
    String? userId,
    String? productId, // UUID string
    int? quantity,
    DateTime? createdAt,
    DateTime? updatedAt,
    ProductBasicInfo? product,
  }) {
    return CartItemModel(
      userId: userId ?? this.userId,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      product: product ?? this.product,
    );
  }

  double get subtotal => (product?.price ?? 0.0) * quantity;
}

/// Minimal product info returned by basket API
class ProductBasicInfo {
  final String id; // UUID string
  final String name;
  final double price;

  const ProductBasicInfo({
    required this.id,
    required this.name,
    required this.price,
  });

  factory ProductBasicInfo.fromJson(Map<String, dynamic> json) {
    return ProductBasicInfo(
      id: json['id']?.toString() ?? '', // UUID string olarak parse et
      name: json['name']?.toString() ?? '',
      price: CartItemModel._parseDouble(json['price']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
    };
  }
}
