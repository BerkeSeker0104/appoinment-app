enum OrderStatus {
  pending,
  confirmed,
  preparing,
  readyForPickup,
  completed,
  cancelled,
}

enum PaymentStatus {
  pending,
  paid,
  failed,
  refunded,
}

enum DeliveryType {
  pickup,
  delivery,
}

class OrderItem {
  final String id;
  final String productId;
  final String productName;
  final int quantity;
  final double price;
  final double subtotal;
  final String? productImage;

  const OrderItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
    required this.subtotal,
    this.productImage,
  });

  OrderItem copyWith({
    String? id,
    String? productId,
    String? productName,
    int? quantity,
    double? price,
    double? subtotal,
    String? productImage,
  }) {
    return OrderItem(
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

class OrderDeliveryAddress {
  final String address;
  final String firstName;
  final String lastName;
  final String phoneCode;
  final String phone;
  final String cityName;
  final String countryName;

  const OrderDeliveryAddress({
    required this.address,
    required this.firstName,
    required this.lastName,
    required this.phoneCode,
    required this.phone,
    required this.cityName,
    required this.countryName,
  });

  String get fullName => '$firstName $lastName';
  String get fullPhone => '$phoneCode$phone';
  String get fullAddress => '$address, $cityName, $countryName';
}

class Order {
  final String id;
  final String userId;
  final String orderNumber;
  final List<OrderItem> items;
  final double totalAmount;
  final OrderStatus status;
  final PaymentStatus paymentStatus;
  final DeliveryType deliveryType;
  final String? pickupBranchId;
  final String? pickupBranchName;
  final String? deliveryAddress;
  final OrderDeliveryAddress? deliveryAddressModel;
  final String? notes;
  final String? paymentMethod;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Order({
    required this.id,
    required this.userId,
    required this.orderNumber,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.paymentStatus,
    required this.deliveryType,
    this.pickupBranchId,
    this.pickupBranchName,
    this.deliveryAddress,
    this.deliveryAddressModel,
    this.notes,
    this.paymentMethod,
    required this.createdAt,
    required this.updatedAt,
  });

  Order copyWith({
    String? id,
    String? userId,
    String? orderNumber,
    List<OrderItem>? items,
    double? totalAmount,
    OrderStatus? status,
    PaymentStatus? paymentStatus,
    DeliveryType? deliveryType,
    String? pickupBranchId,
    String? pickupBranchName,
    String? deliveryAddress,
    OrderDeliveryAddress? deliveryAddressModel,
    String? notes,
    String? paymentMethod,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Order(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      orderNumber: orderNumber ?? this.orderNumber,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      deliveryType: deliveryType ?? this.deliveryType,
      pickupBranchId: pickupBranchId ?? this.pickupBranchId,
      pickupBranchName: pickupBranchName ?? this.pickupBranchName,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      deliveryAddressModel: deliveryAddressModel ?? this.deliveryAddressModel,
      notes: notes ?? this.notes,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  String get statusText {
    switch (status) {
      case OrderStatus.pending:
        return 'Sipariş Ödenmedi';
      case OrderStatus.confirmed:
        return 'Sipariş Alındı';
      case OrderStatus.preparing:
        return 'Hazırlanıyor';
      case OrderStatus.readyForPickup:
        return 'Teslime Hazır';
      case OrderStatus.completed:
        return 'Sipariş Teslim edildi';
      case OrderStatus.cancelled:
        return 'İptal Edildi';
    }
  }

  String get paymentStatusText {
    switch (paymentStatus) {
      case PaymentStatus.pending:
        return 'Beklemede';
      case PaymentStatus.paid:
        return 'Ödeme Alındı';
      case PaymentStatus.failed:
        return 'Başarısız';
      case PaymentStatus.refunded:
        return 'İade Edildi';
    }
  }
}
