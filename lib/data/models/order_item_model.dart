class OrderItemModel {
  final String id;
  final String productId;
  final String productName;
  final int quantity;
  final double price;
  final double subtotal;
  final String? productImage;

  const OrderItemModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
    required this.subtotal,
    this.productImage,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    // Try to get product name from nested product object if available
    String? productName;
    String? productImage;

    if (json['product'] is Map<String, dynamic>) {
      final product = json['product'] as Map<String, dynamic>;
      productName =
          product['name'] as String? ?? product['productName'] as String?;
      productImage = product['image'] as String? ??
          product['picture'] as String? ??
          (product['pictures'] is List &&
                  (product['pictures'] as List).isNotEmpty
              ? (product['pictures'] as List).first.toString()
              : null);
    }

    return OrderItemModel(
      id: json['id']?.toString() ?? '',
      productId: json['productId']?.toString() ??
          json['product_id']?.toString() ??
          (json['product'] is Map
              ? (json['product'] as Map)['id']?.toString()
              : null) ??
          '',
      productName: productName ??
          json['productName'] as String? ??
          json['product_name'] as String? ??
          '',
      quantity: json['quantity'] as int? ?? 1,
      price: _parseDouble(json['price'] ??
          (json['product'] is Map ? (json['product'] as Map)['price'] : null)),
      subtotal: _parseDouble(json['subtotal'] ??
          (json['price'] != null && json['quantity'] != null
              ? (_parseDouble(json['price']) *
                  ((json['quantity'] as int?) ?? 1))
              : null)),
      productImage: productImage ??
          json['productImage'] as String? ??
          json['product_image'] as String?,
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'price': price,
      'subtotal': subtotal,
      if (productImage != null) 'productImage': productImage,
    };
  }

  OrderItemModel copyWith({
    String? id,
    String? productId,
    String? productName,
    int? quantity,
    double? price,
    double? subtotal,
    String? productImage,
  }) {
    return OrderItemModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      subtotal: subtotal ?? this.subtotal,
      productImage: productImage ?? this.productImage,
    );
  }
}
