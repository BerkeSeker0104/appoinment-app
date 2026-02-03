import 'order_item_model.dart';
import 'order_address_model.dart';
import '../../core/constants/api_constants.dart';
import '../../domain/entities/order.dart'
    show OrderStatus, PaymentStatus, DeliveryType;

class OrderModel {
  final String id;
  final String userId;
  final String orderNumber;
  final List<OrderItemModel> items;
  final double totalAmount;
  final double? commissionPrice; // Sadece company tarafında gösterilecek
  final OrderStatus status;
  final PaymentStatus paymentStatus;
  final DeliveryType deliveryType;
  final String? pickupBranchId;
  final String? pickupBranchName;
  final String? deliveryAddress; // Deprecated: Use deliveryAddressModel instead
  final OrderAddressModel? deliveryAddressModel;
  final OrderAddressModel? invoiceAddress;
  final String? notes;
  final String? paymentMethod;
  final DateTime createdAt;
  final DateTime updatedAt;

  const OrderModel({
    required this.id,
    required this.userId,
    required this.orderNumber,
    required this.items,
    required this.totalAmount,
    this.commissionPrice,
    required this.status,
    required this.paymentStatus,
    required this.deliveryType,
    this.pickupBranchId,
    this.pickupBranchName,
    this.deliveryAddress,
    this.deliveryAddressModel,
    this.invoiceAddress,
    this.notes,
    this.paymentMethod,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    // Backend'den gelen yeni format: Her order direkt bir obje, items array değil
    // productDetail içinde product bilgileri var
    List<OrderItemModel> items = [];

    // Eğer items array varsa (eski format)
    final itemsList = json['items'] as List<dynamic>? ??
        json['orderItems'] as List<dynamic>? ??
        json['order_items'] as List<dynamic>?;

    if (itemsList != null) {
      items = itemsList
          .map((item) {
            try {
              if (item is Map<String, dynamic>) {
                return OrderItemModel.fromJson(item);
              }
              return null;
            } catch (e) {
              return null;
            }
          })
          .whereType<OrderItemModel>()
          .toList();
    } else if (json['productDetail'] != null) {
      // Yeni format: productDetail içinde tek bir ürün var
      // Order seviyesinde price, quantity, totalPrice var
      final productDetail = json['productDetail'] as Map<String, dynamic>;
      final productPictures = json['productPictures'] as List<dynamic>? ?? [];

      // İlk resmi al (order'a göre sıralı)
      String? productImage;
      if (productPictures.isNotEmpty) {
        final sortedPictures = List<Map<String, dynamic>>.from(productPictures)
          ..sort((a, b) =>
              (a['order'] as int? ?? 0).compareTo(b['order'] as int? ?? 0));
        final firstPicture = sortedPictures.first;
        final picturePath = firstPicture['picture'] as String?;
        if (picturePath != null && picturePath.isNotEmpty) {
          // FILE_URL ekle
          productImage = picturePath.startsWith('http')
              ? picturePath
              : '${ApiConstants.fileUrl}$picturePath';
        }
      }

      final quantity = json['quantity'] as int? ?? 1;
      final price = _parseDouble(json['price'] ?? productDetail['price']);
      final totalPrice =
          _parseDouble(json['totalPrice'] ?? json['total_price']);

      items = [
        OrderItemModel(
          id: json['id']?.toString() ?? '',
          productId: productDetail['id']?.toString() ?? '',
          productName: productDetail['name'] as String? ?? '',
          quantity: quantity,
          price: price,
          subtotal: totalPrice,
          productImage: productImage,
        ),
      ];
    }

    // Buyer bilgisinden userId'yi al
    String userId = '';
    if (json['buyer'] is Map) {
      userId = (json['buyer'] as Map)['id']?.toString() ?? '';
    } else {
      userId = json['userId']?.toString() ?? json['user_id']?.toString() ?? '';
    }

    return OrderModel(
      id: json['id']?.toString() ?? '',
      userId: userId,
      orderNumber: json['orderNumber'] as String? ??
          json['order_number'] as String? ??
          '',
      items: items,
      totalAmount: _parseDouble(json['totalPrice'] ??
          json['total_price'] ??
          json['totalAmount'] ??
          json['total_amount']),
      commissionPrice: json['commissionPrice'] != null
          ? _parseDouble(json['commissionPrice'])
          : null,
      status: _parseOrderStatus(json['status']),
      paymentStatus: _parsePaymentStatus(
        json['paymentStatus'] ?? 
        json['payment_status'] ?? 
        json['paymentStatusId'] ?? 
        json['payment_status_id'],
        // Fallback: Eğer paymentStatus gelmiyorsa, order status'e göre belirle
        orderStatus: json['status'],
      ),
      deliveryType:
          _parseDeliveryType(json['deliveryType'] ?? json['delivery_type']),
      pickupBranchId: json['pickupBranchId']?.toString() ??
          json['pickup_branch_id']?.toString(),
      pickupBranchName: json['pickupBranchName'] as String? ??
          json['pickup_branch_name'] as String?,
      deliveryAddress: json['deliveryAddress'] is Map
          ? null
          : (json['deliveryAddress'] as String? ??
              json['delivery_address'] as String?),
      deliveryAddressModel: json['deliveryAddress'] is Map
          ? OrderAddressModel.fromJson(json['deliveryAddress'] as Map<String, dynamic>)
          : null,
      invoiceAddress: json['invoiceAddress'] is Map
          ? OrderAddressModel.fromJson(json['invoiceAddress'] as Map<String, dynamic>)
          : null,
      notes: json['notes'] as String?,
      paymentMethod: json['paymentMethod'] as String? ??
          json['payment_method'] as String? ??
          json['paidType'] as String? ??
          json['paid_type'] as String?,
      createdAt: _parseDateTime(json['createdAt'] ?? json['created_at']),
      updatedAt: _parseDateTime(json['updatedAt'] ??
          json['updated_at'] ??
          json['createdAt'] ??
          json['created_at']),
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

  static OrderStatus _parseOrderStatus(dynamic status) {
    if (status == null) return OrderStatus.pending;

    // Numeric status değerleri (backend "0" gibi gönderiyor)
    if (status is int ||
        (status is String && int.tryParse(status.toString()) != null)) {
      final statusInt =
          status is int ? status : int.tryParse(status.toString()) ?? 0;
      switch (statusInt) {
        case 0:
          return OrderStatus.pending; // Sipariş Ödenmedi
        case 1:
          return OrderStatus.confirmed; // Sipariş Alındı
        case 2:
          return OrderStatus.completed; // Sipariş Teslim edildi
        case 3:
          return OrderStatus.preparing;
        case 4:
          return OrderStatus.readyForPickup;
        case 5:
          return OrderStatus.cancelled;
        default:
          return OrderStatus.pending;
      }
    }

    final statusString = status.toString().toLowerCase();

    switch (statusString) {
      case 'pending':
      case 'beklemede':
      case '0':
        return OrderStatus.pending;
      case 'confirmed':
      case 'onaylandi':
      case 'onaylandı':
      case '1':
        return OrderStatus.confirmed;
      case 'preparing':
      case 'hazirlaniyor':
      case 'hazırlanıyor':
      case '2':
        return OrderStatus.preparing;
      case 'ready_for_pickup':
      case 'readyforpickup':
      case 'teslime_hazir':
      case 'teslime hazır':
      case '3':
        return OrderStatus.readyForPickup;
      case 'completed':
      case 'tamamlandi':
      case 'tamamlandı':
      case '4':
        return OrderStatus.completed;
      case 'cancelled':
      case 'iptal':
      case '5':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
  }

  static PaymentStatus _parsePaymentStatus(dynamic status, {dynamic orderStatus}) {
    // Eğer paymentStatus geliyorsa onu kullan
    if (status != null) {
      // Debug: Backend'den gelen değeri logla
      print('🔍 Parsing PaymentStatus: $status (type: ${status.runtimeType})');

      // Numeric status değerleri (backend sayısal değer gönderebilir)
      if (status is int ||
          (status is String && int.tryParse(status.toString()) != null)) {
        final statusInt =
            status is int ? status : int.tryParse(status.toString()) ?? 0;
        print('📊 PaymentStatus numeric value: $statusInt');
        switch (statusInt) {
          case 0:
            return PaymentStatus.pending;
          case 1:
            return PaymentStatus.paid;
          case 2:
            return PaymentStatus.failed;
          case 3:
            return PaymentStatus.refunded;
          default:
            print('⚠️ Unknown PaymentStatus numeric value: $statusInt, defaulting to pending');
            return PaymentStatus.pending;
        }
      }

      final statusString = status.toString().toLowerCase();
      print('📝 PaymentStatus string value: "$statusString"');

      switch (statusString) {
        case 'pending':
        case 'beklemede':
        case '0':
          return PaymentStatus.pending;
        case 'paid':
        case 'odendi':
        case 'ödendi':
        case '1':
          return PaymentStatus.paid;
        case 'failed':
        case 'basarisiz':
        case 'başarısız':
        case '2':
          return PaymentStatus.failed;
        case 'refunded':
        case 'iade':
        case '3':
          return PaymentStatus.refunded;
        default:
          print('⚠️ Unknown PaymentStatus string value: "$statusString", defaulting to pending');
          return PaymentStatus.pending;
      }
    }

    // Fallback: PaymentStatus gelmiyorsa, order status'e göre belirle
    print('⚠️ PaymentStatus is null, inferring from order status: $orderStatus');
    if (orderStatus != null) {
      final orderStatusInt = orderStatus is int
          ? orderStatus
          : (orderStatus is String ? int.tryParse(orderStatus.toString()) : null);
      
      if (orderStatusInt != null) {
        // Backend mantığı: status "0" = ödenmedi, "1" ve üzeri = ödendi
        if (orderStatusInt == 0) {
          print('📊 Order status is 0 (pending), payment status: pending');
          return PaymentStatus.pending;
        } else {
          // Status 1 veya daha yüksek = sipariş alındı, ödeme yapılmış demektir
          print('📊 Order status is $orderStatusInt (confirmed+), payment status: paid');
          return PaymentStatus.paid;
        }
      }
    }

    print('⚠️ Could not determine PaymentStatus, defaulting to pending');
    return PaymentStatus.pending;
  }

  static DeliveryType _parseDeliveryType(dynamic type) {
    if (type == null) return DeliveryType.pickup;
    final typeString = type.toString().toLowerCase();

    switch (typeString) {
      case 'pickup':
      case 'magazadan_teslim':
        return DeliveryType.pickup;
      case 'delivery':
      case 'teslimat':
        return DeliveryType.delivery;
      default:
        return DeliveryType.pickup;
    }
  }

  static DateTime _parseDateTime(dynamic dateString) {
    if (dateString == null) return DateTime.now();
    try {
      final dateStr = dateString.toString();
      // Backend "2025-12-09 15:07:01" formatında gönderiyor, ISO formatına çevir
      if (dateStr.contains(' ') && !dateStr.contains('T')) {
        return DateTime.parse(dateStr.replaceFirst(' ', 'T'));
      }
      return DateTime.parse(dateStr);
    } catch (e) {
      return DateTime.now();
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'orderNumber': orderNumber,
      'items': items.map((item) => item.toJson()).toList(),
      'totalAmount': totalAmount,
      'status': status.name,
      'paymentStatus': paymentStatus.name,
      'deliveryType': deliveryType.name,
      if (pickupBranchId != null) 'pickupBranchId': pickupBranchId,
      if (pickupBranchName != null) 'pickupBranchName': pickupBranchName,
      if (deliveryAddress != null) 'deliveryAddress': deliveryAddress,
      if (deliveryAddressModel != null) 'deliveryAddressModel': deliveryAddressModel!.toJson(),
      if (invoiceAddress != null) 'invoiceAddress': invoiceAddress!.toJson(),
      if (notes != null) 'notes': notes,
      if (paymentMethod != null) 'paymentMethod': paymentMethod,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  OrderModel copyWith({
    String? id,
    String? userId,
    String? orderNumber,
    List<OrderItemModel>? items,
    double? totalAmount,
    double? commissionPrice,
    OrderStatus? status,
    PaymentStatus? paymentStatus,
    DeliveryType? deliveryType,
    String? pickupBranchId,
    String? pickupBranchName,
    String? deliveryAddress,
    OrderAddressModel? deliveryAddressModel,
    OrderAddressModel? invoiceAddress,
    String? notes,
    String? paymentMethod,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OrderModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      orderNumber: orderNumber ?? this.orderNumber,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      commissionPrice: commissionPrice ?? this.commissionPrice,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      deliveryType: deliveryType ?? this.deliveryType,
      pickupBranchId: pickupBranchId ?? this.pickupBranchId,
      pickupBranchName: pickupBranchName ?? this.pickupBranchName,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      deliveryAddressModel: deliveryAddressModel ?? this.deliveryAddressModel,
      invoiceAddress: invoiceAddress ?? this.invoiceAddress,
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
