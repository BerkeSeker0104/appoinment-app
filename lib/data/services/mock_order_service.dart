import 'dart:math';
import '../../domain/entities/order.dart';
import '../models/order_model.dart';
import '../models/order_item_model.dart';

/// Mock Order Service - Stores orders in memory
/// Used when backend is not ready
class MockOrderService {
  static final MockOrderService _instance = MockOrderService._internal();
  factory MockOrderService() => _instance;
  MockOrderService._internal();

  final List<OrderModel> _orders = [];
  final Random _random = Random();

  /// Generate a mock UUID-like string
  String _generateId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = _random.nextInt(10000);
    return 'mock_${timestamp}_$random';
  }

  /// Generate order number
  String _generateOrderNumber() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = _random.nextInt(1000);
    return 'ORD-${timestamp.toString().substring(5)}-$random';
  }

  /// Create a mock order
  Future<OrderModel> createOrder({
    required String userId,
    required List<Map<String, dynamic>> items,
    required String deliveryType,
    String? pickupBranchId,
    String? pickupBranchName,
    String? deliveryAddress,
    String? notes,
    required String paymentMethod,
    PaymentStatus paymentStatus = PaymentStatus.pending,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    final now = DateTime.now();
    final orderId = _generateId();
    final orderNumber = _generateOrderNumber();

    // Convert items to OrderItemModel
    final orderItems = items.map((item) {
      final productId = item['productId']?.toString() ?? item['id']?.toString() ?? '';
      final quantity = item['quantity'] as int? ?? 1;
      final price = _parseDouble(item['price'] ?? item['productPrice'] ?? 0);
      final productName = item['productName']?.toString() ?? 'Ürün';
      
      return OrderItemModel(
        id: _generateId(),
        productId: productId,
        productName: productName,
        quantity: quantity,
        price: price,
        subtotal: price * quantity,
        productImage: item['productImage']?.toString(),
      );
    }).toList();

    // Calculate total amount
    final totalAmount = orderItems.fold<double>(
      0.0,
      (sum, item) => sum + item.subtotal,
    );

    final order = OrderModel(
      id: orderId,
      userId: userId,
      orderNumber: orderNumber,
      items: orderItems,
      totalAmount: totalAmount,
      status: OrderStatus.pending,
      paymentStatus: paymentStatus,
      deliveryType: _parseDeliveryType(deliveryType),
      pickupBranchId: pickupBranchId,
      pickupBranchName: pickupBranchName,
      deliveryAddress: deliveryAddress,
      notes: notes,
      createdAt: now,
      updatedAt: now,
    );

    _orders.add(order);
    return order;
  }

  /// Get all orders for a user
  Future<List<OrderModel>> getOrders({
    required String userId,
    OrderStatus? status,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    var filteredOrders = _orders.where((order) => order.userId == userId).toList();

    if (status != null) {
      filteredOrders = filteredOrders.where((order) => order.status == status).toList();
    }

    // Sort by created date (newest first)
    filteredOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return filteredOrders;
  }

  /// Get order by ID
  Future<OrderModel> getOrderById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));

    final order = _orders.firstWhere(
      (order) => order.id == id,
      orElse: () => throw Exception('Sipariş bulunamadı'),
    );

    return order;
  }

  /// Get orders by company
  Future<List<OrderModel>> getOrdersByCompany({
    required String companyId,
    OrderStatus? status,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    // In mock, we don't have company association in orders
    // So we return empty list or all orders (for testing)
    var filteredOrders = List<OrderModel>.from(_orders);

    if (status != null) {
      filteredOrders = filteredOrders.where((order) => order.status == status).toList();
    }

    filteredOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return filteredOrders;
  }

  /// Update order status
  Future<OrderModel> updateOrderStatus({
    required String id,
    required OrderStatus status,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final index = _orders.indexWhere((order) => order.id == id);
    if (index == -1) {
      throw Exception('Sipariş bulunamadı');
    }

    final order = _orders[index];
    final updatedOrder = order.copyWith(
      status: status,
      updatedAt: DateTime.now(),
    );

    _orders[index] = updatedOrder;
    return updatedOrder;
  }

  /// Cancel order
  Future<OrderModel> cancelOrder(String id) async {
    return await updateOrderStatus(
      id: id,
      status: OrderStatus.cancelled,
    );
  }

  /// Update payment status
  Future<OrderModel> updatePaymentStatus({
    required String id,
    required PaymentStatus paymentStatus,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));

    final index = _orders.indexWhere((order) => order.id == id);
    if (index == -1) {
      throw Exception('Sipariş bulunamadı');
    }

    final order = _orders[index];
    final updatedOrder = order.copyWith(
      paymentStatus: paymentStatus,
      updatedAt: DateTime.now(),
    );

    _orders[index] = updatedOrder;
    return updatedOrder;
  }

  // Helper methods
  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  DeliveryType _parseDeliveryType(String type) {
    final typeString = type.toLowerCase();
    if (typeString == 'pickup' || typeString == 'magazadan_teslim') {
      return DeliveryType.pickup;
    }
    return DeliveryType.delivery;
  }

  /// Clear all orders (for testing)
  void clear() {
    _orders.clear();
  }
}



























