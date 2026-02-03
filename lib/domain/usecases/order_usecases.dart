import '../entities/order.dart';
import '../repositories/order_repository.dart';

class OrderUseCases {
  final OrderRepository _orderRepository;

  OrderUseCases(this._orderRepository);

  Future<Order> createOrder({
    required List<Map<String, dynamic>> items,
    required String deliveryType,
    String? pickupBranchId,
    String? deliveryAddress,
    String? notes,
    required String paymentMethod,
  }) async {
    // Validation
    if (items.isEmpty) {
      throw Exception('Sipariş öğeleri gerekli');
    }

    if (deliveryType == 'pickup' &&
        (pickupBranchId == null || pickupBranchId.isEmpty)) {
      throw Exception('Teslim alınacak şube seçimi gerekli');
    }

    if (deliveryType == 'delivery' &&
        (deliveryAddress == null || deliveryAddress.isEmpty)) {
      throw Exception('Teslimat adresi gerekli');
    }

    try {
      return await _orderRepository.createOrder(
        items: items,
        deliveryType: deliveryType,
        pickupBranchId: pickupBranchId,
        deliveryAddress: deliveryAddress,
        notes: notes,
        paymentMethod: paymentMethod,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Order>> getOrders({
    OrderStatus? status,
    int? page,
    int? limit,
  }) async {
    try {
      return await _orderRepository.getOrders(
        status: status,
        page: page,
        limit: limit,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<Order> getOrderById(String id) async {
    if (id.isEmpty) {
      throw Exception('Sipariş ID\'si gerekli');
    }

    try {
      return await _orderRepository.getOrder(id);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Order>> getOrdersByCompany({
    required String companyId,
    OrderStatus? status,
    int? page,
    int? limit,
  }) async {
    if (companyId.isEmpty) {
      throw Exception('Şirket ID\'si gerekli');
    }

    try {
      return await _orderRepository.getOrdersByCompany(
        companyId: companyId,
        status: status,
        page: page,
        limit: limit,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<Order> updateStatus({
    required String id,
    required OrderStatus status,
  }) async {
    if (id.isEmpty) {
      throw Exception('Sipariş ID\'si gerekli');
    }

    try {
      return await _orderRepository.updateOrderStatus(
        id: id,
        status: status,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<Order> cancelOrder(String id) async {
    if (id.isEmpty) {
      throw Exception('Sipariş ID\'si gerekli');
    }

    try {
      return await _orderRepository.cancelOrder(id);
    } catch (e) {
      rethrow;
    }
  }

  // Helper methods
  List<Order> filterByStatus(List<Order> orders, OrderStatus status) {
    return orders.where((order) => order.status == status).toList();
  }

  List<Order> getPendingOrders(List<Order> orders) {
    return filterByStatus(orders, OrderStatus.pending);
  }

  List<Order> getCompletedOrders(List<Order> orders) {
    return filterByStatus(orders, OrderStatus.completed);
  }

  double getTotalRevenue(List<Order> orders) {
    return orders
        .where((order) => order.paymentStatus == PaymentStatus.paid)
        .fold(0.0, (sum, order) => sum + order.totalAmount);
  }
}
