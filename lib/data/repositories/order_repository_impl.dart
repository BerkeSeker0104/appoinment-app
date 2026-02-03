import '../../domain/entities/order.dart';
import '../../domain/repositories/order_repository.dart';
import '../../domain/usecases/auth_usecases.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../services/order_api_service.dart';
import '../services/mock_order_service.dart';
import '../models/order_model.dart';
import '../models/order_item_model.dart';

class OrderRepositoryImpl implements OrderRepository {
  final OrderApiService _orderApiService = OrderApiService();
  final MockOrderService _mockOrderService = MockOrderService();
  final AuthUseCases _authUseCases = AuthUseCases(AuthRepositoryImpl());

  // Convert Model to Entity
  Order _modelToEntity(OrderModel model) {
    return Order(
      id: model.id,
      userId: model.userId,
      orderNumber: model.orderNumber,
      items: model.items.map(_itemModelToEntity).toList(),
      totalAmount: model.totalAmount,
      status: model.status,
      paymentStatus: model.paymentStatus,
      deliveryType: model.deliveryType,
      pickupBranchId: model.pickupBranchId,
      pickupBranchName: model.pickupBranchName,
      deliveryAddress: model.deliveryAddress,
      notes: model.notes,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
    );
  }

  OrderItem _itemModelToEntity(OrderItemModel model) {
    return OrderItem(
      id: model.id,
      productId: model.productId,
      productName: model.productName,
      quantity: model.quantity,
      price: model.price,
      subtotal: model.subtotal,
      productImage: model.productImage,
    );
  }

  @override
  Future<Order> createOrder({
    required List<Map<String, dynamic>> items,
    required String deliveryType,
    String? pickupBranchId,
    String? deliveryAddress,
    String? notes,
    required String paymentMethod,
  }) async {
    try {
      final model = await _orderApiService.createOrder(
        items: items,
        deliveryType: deliveryType,
        pickupBranchId: pickupBranchId,
        deliveryAddress: deliveryAddress,
        notes: notes,
        paymentMethod: paymentMethod,
      );
      return _modelToEntity(model);
    } catch (e) {
      // Fallback to mock service if backend is not ready
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('404') ||
          errorString.contains('bulunamadı') ||
          errorString.contains('henüz aktif değil')) {
        // Use mock service
        final user = await _authUseCases.getCurrentUser();
        if (user == null) {
          throw Exception('Kullanıcı bilgileri alınamadı');
        }

        final paymentStatus = paymentMethod == 'cash'
            ? PaymentStatus.pending
            : PaymentStatus.paid;

        final mockModel = await _mockOrderService.createOrder(
          userId: user.id,
          items: items,
          deliveryType: deliveryType,
          pickupBranchId: pickupBranchId,
          pickupBranchName: null, // Will be set if needed
          deliveryAddress: deliveryAddress,
          notes: notes,
          paymentMethod: paymentMethod,
          paymentStatus: paymentStatus,
        );

        return _modelToEntity(mockModel);
      }
      rethrow;
    }
  }

  @override
  Future<List<Order>> getOrders({
    OrderStatus? status,
    int? page,
    int? limit,
  }) async {
    try {
      final models = await _orderApiService.getOrders(
        status: status,
        page: page,
        limit: limit,
      );
      return models.map(_modelToEntity).toList();
    } catch (e) {
      // Fallback to mock service if backend is not ready
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('404') ||
          errorString.contains('bulunamadı')) {
        final user = await _authUseCases.getCurrentUser();
        if (user == null) {
          return [];
        }
        final mockModels = await _mockOrderService.getOrders(
          userId: user.id,
          status: status,
        );
        return mockModels.map(_modelToEntity).toList();
      }
      rethrow;
    }
  }

  @override
  Future<Order> getOrder(String id) async {
    try {
      final model = await _orderApiService.getOrder(id);
      return _modelToEntity(model);
    } catch (e) {
      // Fallback to mock service if backend is not ready
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('404') ||
          errorString.contains('bulunamadı')) {
        final mockModel = await _mockOrderService.getOrderById(id);
        return _modelToEntity(mockModel);
      }
      rethrow;
    }
  }

  @override
  Future<List<Order>> getOrdersByCompany({
    required String companyId,
    OrderStatus? status,
    int? page,
    int? limit,
  }) async {
    try {
      final models = await _orderApiService.getOrdersByCompany(
        companyId: companyId,
        status: status,
        page: page,
        limit: limit,
      );
      return models.map(_modelToEntity).toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Order> updateOrderStatus({
    required String id,
    required OrderStatus status,
  }) async {
    try {
      final model = await _orderApiService.updateOrderStatus(
        id: id,
        status: status,
      );
      return _modelToEntity(model);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Order> cancelOrder(String id) async {
    try {
      final model = await _orderApiService.cancelOrder(id);
      return _modelToEntity(model);
    } catch (e) {
      rethrow;
    }
  }
}
