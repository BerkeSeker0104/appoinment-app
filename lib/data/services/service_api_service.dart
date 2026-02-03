import 'dart:convert';
import '../../core/services/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../models/service_model.dart';

class ServiceApiService {
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

  // Get all services
  Future<List<ServiceModel>> getServices({String? typeId}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (typeId != null) {
        queryParams['serviceId'] = typeId;
      }

      final response = await _apiClient.get(
        ApiConstants.services,
        queryParameters: queryParams,
      );
      final data = _asMap(response.data);

      List<dynamic> servicesList = [];
      if (data['data'] is List) {
        servicesList = data['data'] as List<dynamic>;
      } else if (data['services'] is List) {
        servicesList = data['services'] as List<dynamic>;
      } else if (data['items'] is List) {
        servicesList = data['items'] as List<dynamic>;
      } else if (data is List) {
        servicesList = data as List<dynamic>;
      }


      // ServiceModel.fromJson'u kullanabilmek için her item'i Map olarak parse et
      return servicesList.map((json) {
        if (json is Map<String, dynamic>) {
          return _parseServiceModel(json);
        }
        return _parseServiceModel(<String, dynamic>{});
      }).toList();
    } catch (e) {
      // If endpoint doesn't exist yet (404), return empty list
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('404') || errorString.contains('bulunamadı')) {
        return [];
      }
      throw Exception('Hizmetler yüklenirken hata oluştu: $e');
    }
  }

  // Parse service model - backend formatına göre uyarla
  ServiceModel _parseServiceModel(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id']?.toString() ?? '',
      name: _parseServiceName(json['name']),
      description: _parseServiceName(json['description']),
      price: _parsePrice(
        json['price'] ?? json['minPrice'] ?? json['min_price'],
      ),
      durationMinutes: _parseDuration(
        json['duration'] ?? json['duration_minutes'],
      ),
      iconName:
          json['icon_name']?.toString() ??
          json['iconName']?.toString() ??
          json['icon']?.toString() ??
          'content_cut',
      isActive:
          json['is_active'] == true ||
          json['isActive'] == true ||
          json['status'] == 'active',
      barberId:
          json['barber_id']?.toString() ??
          json['barberId']?.toString() ??
          json['company_id']?.toString() ??
          '',
    );
  }

  double _parsePrice(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  int _parseDuration(dynamic value) {
    if (value == null) return 30; // Default 30 dakika
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value) ?? 30;
    }
    if (value is double) return value.toInt();
    return 30;
  }

  String _parseServiceName(dynamic nameValue) {
    if (nameValue == null) return '';

    if (nameValue is String) {
      // Check if the string is a JSON object
      try {
        final decodedName = jsonDecode(nameValue);
        if (decodedName is Map<String, dynamic>) {
          // Önce Türkçe, sonra İngilizce, son olarak orijinal string
          return decodedName['tr'] as String? ??
              decodedName['en'] as String? ??
              nameValue;
        } else {
          return nameValue;
        }
      } catch (_) {
        // Not a JSON string, use as is
        return nameValue;
      }
    } else if (nameValue is Map<String, dynamic>) {
      // Already a Map
      return nameValue['tr'] as String? ??
          nameValue['en'] as String? ??
          nameValue.toString();
    }

    return nameValue.toString();
  }

  // Get a specific service by ID
  Future<ServiceModel> getService(String serviceId) async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.services}/$serviceId',
      );
      final data = _asMap(response.data);

      Map<String, dynamic> serviceData;
      if (data['data'] is Map<String, dynamic>) {
        serviceData = data['data'];
      } else if (data['service'] is Map<String, dynamic>) {
        serviceData = data['service'];
      } else {
        serviceData = data;
      }

      return _parseServiceModel(serviceData);
    } catch (e) {
      throw Exception('Hizmet bilgileri yüklenirken hata oluştu: $e');
    }
  }

  // Search services
  Future<List<ServiceModel>> searchServices(String query) async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.services}/search',
        queryParameters: {'q': query},
      );
      final data = _asMap(response.data);

      List<dynamic> servicesList = [];
      if (data['data'] is List) {
        servicesList = data['data'] as List<dynamic>;
      } else if (data['services'] is List) {
        servicesList = data['services'] as List<dynamic>;
      } else if (data['items'] is List) {
        servicesList = data['items'] as List<dynamic>;
      } else if (data is List) {
        servicesList = data as List<dynamic>;
      }

      return servicesList.map((json) {
        if (json is Map<String, dynamic>) {
          return _parseServiceModel(json);
        }
        return _parseServiceModel(<String, dynamic>{});
      }).toList();
    } catch (e) {
      throw Exception('Hizmet arama yapılırken hata oluştu: $e');
    }
  }
}
