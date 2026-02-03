import 'dart:convert';
import '../../core/services/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../models/order_model.dart';
import '../../domain/entities/order.dart' show OrderStatus;

class OrderApiService {
  final ApiClient _apiClient = ApiClient();

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is String) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map<String, dynamic>) return decoded;
      } catch (_) {}
    }
    return <String, dynamic>{};
  }

  // Create order
  Future<OrderModel> createOrder({
    required List<Map<String, dynamic>> items, // [{productId, quantity}]
    required String deliveryType, // pickup or delivery
    String? pickupBranchId,
    String? deliveryAddress,
    String? notes,
    required String paymentMethod,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.orders,
        data: {
          'items': items,
          'deliveryType': deliveryType,
          if (pickupBranchId != null) 'pickupBranchId': pickupBranchId,
          if (deliveryAddress != null) 'deliveryAddress': deliveryAddress,
          if (notes != null) 'notes': notes,
          'paymentMethod': paymentMethod,
        },
      );

      final data = _asMap(response.data);

      Map<String, dynamic> orderData;
      if (data['data'] is Map<String, dynamic>) {
        orderData = data['data'];
      } else if (data['order'] is Map<String, dynamic>) {
        orderData = data['order'];
      } else {
        orderData = data;
      }

      return OrderModel.fromJson(orderData);
    } catch (e) {
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('404') || errorString.contains('bulunamadı')) {
        throw Exception(
          'Sipariş oluşturma özelliği henüz aktif değil. Backend ekibi bu endpoint\'i ekleyecek.',
        );
      }
      throw Exception('Sipariş oluşturulurken hata oluştu: $e');
    }
  }

  // Get user's orders
  Future<List<OrderModel>> getOrders({
    OrderStatus? status,
    String? orderNumber,
    int? page,
    int? limit,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null) {
        queryParams['status'] = status.name;
      }
      if (orderNumber != null && orderNumber.isNotEmpty) {
        queryParams['orderNumber'] = orderNumber;
      }
      if (page != null) queryParams['page'] = page;
      if (limit != null) queryParams['limit'] = limit;

      final response = await _apiClient.get(
        ApiConstants.productOrders,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      final data = _asMap(response.data);

      List<dynamic> ordersList = [];
      if (data['data'] is List) {
        ordersList = data['data'] as List<dynamic>;
      } else if (data['orders'] is List) {
        ordersList = data['orders'] as List<dynamic>;
      } else if (data is List) {
        ordersList = data as List<dynamic>;
      }

      return ordersList
          .map((json) {
            try {
              if (json is Map<String, dynamic>) {
                return OrderModel.fromJson(json);
              }
              return null;
            } catch (e) {
              print('OrderApiService: Error parsing order: $e, json: $json');
              return null;
            }
          })
          .whereType<OrderModel>()
          .toList();
    } catch (e) {
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('404') || errorString.contains('bulunamadı')) {
        return [];
      }
      throw Exception('Siparişler yüklenirken hata oluştu: $e');
    }
  }

  // Get order by ID
  Future<OrderModel> getOrder(String id) async {
    try {
      final response =
          await _apiClient.get('${ApiConstants.productOrders}/$id');
      final data = _asMap(response.data);

      Map<String, dynamic> orderData;
      if (data['data'] is Map<String, dynamic>) {
        orderData = data['data'];
      } else if (data['order'] is Map<String, dynamic>) {
        orderData = data['order'];
      } else {
        orderData = data;
      }

      return OrderModel.fromJson(orderData);
    } catch (e) {
      throw Exception('Sipariş bilgileri yüklenirken hata oluştu: $e');
    }
  }

  // Get orders by company (for company panel)
  Future<List<OrderModel>> getOrdersByCompany({
    required String companyId,
    OrderStatus? status,
    int? page,
    int? limit,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null) {
        // Backend numeric status bekliyor
        final statusInt = status == OrderStatus.pending
            ? 0
            : status == OrderStatus.confirmed
                ? 1
                : status == OrderStatus.completed
                    ? 2
                    : null;
        if (statusInt != null) {
          queryParams['status'] = statusInt;
        }
      }
      if (page != null) queryParams['page'] = page;
      if (limit != null) queryParams['limit'] = limit;

      // Company tarafında da /api/product/order kullanılıyor (backend JWT'den company ID alıyor)
      final response = await _apiClient.get(
        ApiConstants.productOrders,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      final data = _asMap(response.data);

      List<dynamic> ordersList = [];
      if (data['data'] is List) {
        ordersList = data['data'] as List<dynamic>;
      } else if (data['orders'] is List) {
        ordersList = data['orders'] as List<dynamic>;
      } else if (data is List) {
        ordersList = data as List<dynamic>;
      }

      return ordersList
          .map((json) {
            try {
              if (json is Map<String, dynamic>) {
                return OrderModel.fromJson(json);
              }
              return null;
            } catch (e) {
              print(
                  'OrderApiService: Error parsing company order: $e, json: $json');
              return null;
            }
          })
          .whereType<OrderModel>()
          .toList();
    } catch (e) {
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('404') || errorString.contains('bulunamadı')) {
        return [];
      }
      throw Exception('Şirket siparişleri yüklenirken hata oluştu: $e');
    }
  }

  // Update order status (Company/Admin)
  Future<OrderModel> updateOrderStatus({
    required String id,
    required OrderStatus status,
  }) async {
    try {
      final response = await _apiClient.put(
        '${ApiConstants.orders}/$id/status',
        data: {
          'status': status.name,
        },
      );

      final data = _asMap(response.data);

      Map<String, dynamic> orderData;
      if (data['data'] is Map<String, dynamic>) {
        orderData = data['data'];
      } else if (data['order'] is Map<String, dynamic>) {
        orderData = data['order'];
      } else {
        orderData = data;
      }

      return OrderModel.fromJson(orderData);
    } catch (e) {
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('404') || errorString.contains('bulunamadı')) {
        throw Exception(
          'Sipariş durumu güncelleme özelliği henüz aktif değil.',
        );
      }
      throw Exception('Sipariş durumu güncellenirken hata oluştu: $e');
    }
  }

  // Cancel order
  Future<OrderModel> cancelOrder(String id) async {
    try {
      return await updateOrderStatus(
        id: id,
        status: OrderStatus.cancelled,
      );
    } catch (e) {
      throw Exception('Sipariş iptal edilirken hata oluştu: $e');
    }
  }
}
