import '../entities/order.dart';

abstract class OrderRepository {
  Future<Order> createOrder({
    required List<Map<String, dynamic>> items,
    required String deliveryType,
    String? pickupBranchId,
    String? deliveryAddress,
    String? notes,
    required String paymentMethod,
  });

  Future<List<Order>> getOrders({
    OrderStatus? status,
    int? page,
    int? limit,
  });

  Future<Order> getOrder(String id);

  Future<List<Order>> getOrdersByCompany({
    required String companyId,
    OrderStatus? status,
    int? page,
    int? limit,
  });

  Future<Order> updateOrderStatus({
    required String id,
    required OrderStatus status,
  });

  Future<Order> cancelOrder(String id);
}
