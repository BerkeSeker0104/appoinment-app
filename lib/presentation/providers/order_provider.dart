import 'package:flutter/foundation.dart';
import '../../domain/entities/order.dart';
import '../../domain/usecases/order_usecases.dart';
import '../../data/repositories/order_repository_impl.dart';
import '../../core/services/app_lifecycle_service.dart';

class OrderProvider with ChangeNotifier implements LoadingStateResettable {
  final OrderUseCases _orderUseCases = OrderUseCases(OrderRepositoryImpl());

  List<Order> _orders = [];
  Order? _selectedOrder;
  OrderStatus? _filterStatus;
  bool _isLoading = false;
  String? _error;

  List<Order> get orders => _orders;
  Order? get selectedOrder => _selectedOrder;
  OrderStatus? get filterStatus => _filterStatus;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load orders
  Future<void> loadOrders({OrderStatus? status}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _orders = await _orderUseCases.getOrders(status: status);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load order by ID
  Future<void> loadOrder(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedOrder = await _orderUseCases.getOrderById(id);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load orders by company
  Future<void> loadOrdersByCompany({
    required String companyId,
    OrderStatus? status,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _orders = await _orderUseCases.getOrdersByCompany(
        companyId: companyId,
        status: status,
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create order
  Future<Order?> createOrder({
    required List<Map<String, dynamic>> items,
    required String deliveryType,
    String? pickupBranchId,
    String? deliveryAddress,
    String? notes,
    required String paymentMethod,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final order = await _orderUseCases.createOrder(
        items: items,
        deliveryType: deliveryType,
        pickupBranchId: pickupBranchId,
        deliveryAddress: deliveryAddress,
        notes: notes,
        paymentMethod: paymentMethod,
      );
      _error = null;
      _isLoading = false;
      notifyListeners();
      return order;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Update order status
  Future<bool> updateOrderStatus({
    required String id,
    required OrderStatus status,
  }) async {
    try {
      final updatedOrder = await _orderUseCases.updateStatus(
        id: id,
        status: status,
      );

      // Update in list
      final index = _orders.indexWhere((order) => order.id == id);
      if (index != -1) {
        _orders[index] = updatedOrder;
      }

      // Update selected order if it's the same
      if (_selectedOrder?.id == id) {
        _selectedOrder = updatedOrder;
      }

      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Cancel order
  Future<bool> cancelOrder(String id) async {
    try {
      final cancelledOrder = await _orderUseCases.cancelOrder(id);

      // Update in list
      final index = _orders.indexWhere((order) => order.id == id);
      if (index != -1) {
        _orders[index] = cancelledOrder;
      }

      // Update selected order if it's the same
      if (_selectedOrder?.id == id) {
        _selectedOrder = cancelledOrder;
      }

      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Filter by status
  void filterByStatus(OrderStatus? status) {
    _filterStatus = status;
    loadOrders(status: status);
  }

  // Get filtered orders (client-side filtering)
  List<Order> getFilteredOrders() {
    if (_filterStatus == null) return _orders;
    return _orders.where((order) => order.status == _filterStatus).toList();
  }

  // Get statistics
  int get totalOrders => _orders.length;
  int get pendingOrdersCount =>
      _orders.where((o) => o.status == OrderStatus.pending).length;
  int get completedOrdersCount =>
      _orders.where((o) => o.status == OrderStatus.completed).length;
  double get totalRevenue => _orderUseCases.getTotalRevenue(_orders);

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Clear selected order
  void clearSelectedOrder() {
    _selectedOrder = null;
    notifyListeners();
  }

  /// Reset loading states - called when app resumes from background
  @override
  void resetLoadingState() {
    if (_isLoading) {
      _isLoading = false;
      notifyListeners();
    }
  }
}
