import 'dart:convert';
import '../../core/services/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../models/feature_model.dart';

class FeatureApiService {
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

  // Get all available features
  Future<List<FeatureModel>> getFeatures() async {
    try {
      final response = await _apiClient.get(ApiConstants.features);
      final data = _asMap(response.data);

      List<dynamic> featuresList = [];
      if (data['data'] is List) {
        featuresList = data['data'] as List<dynamic>;
      } else if (data['features'] is List) {
        featuresList = data['features'] as List<dynamic>;
      } else if (data['items'] is List) {
        featuresList = data['items'] as List<dynamic>;
      } else if (data is List) {
        featuresList = data as List<dynamic>;
      }

      return featuresList.map((json) => FeatureModel.fromJson(json)).toList();
    } catch (e) {
      // If endpoint doesn't exist yet (404), return default features
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('404') || errorString.contains('bulunamadı')) {
        return _getDefaultFeatures();
      }
      throw Exception('Özellikler yüklenirken hata oluştu: $e');
    }
  }

  // Get features for a specific branch
  Future<List<FeatureModel>> getBranchFeatures(String branchId) async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.branchFeatures}/$branchId',
      );
      final data = _asMap(response.data);

      List<dynamic> featuresList = [];
      if (data['data'] is List) {
        featuresList = data['data'] as List<dynamic>;
      } else if (data['features'] is List) {
        featuresList = data['features'] as List<dynamic>;
      } else if (data['items'] is List) {
        featuresList = data['items'] as List<dynamic>;
      } else if (data is List) {
        featuresList = data as List<dynamic>;
      }

      return featuresList.map((json) => FeatureModel.fromJson(json)).toList();
    } catch (e) {
      // If endpoint doesn't exist yet (404), return empty list
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('404') || errorString.contains('bulunamadı')) {
        return [];
      }
      throw Exception('Şube özellikleri yüklenirken hata oluştu: $e');
    }
  }

  // Update branch features
  Future<List<FeatureModel>> updateBranchFeatures(
    String branchId,
    List<String> featureIds,
  ) async {
    try {

      final response = await _apiClient.post(
        '${ApiConstants.branchFeatures}/$branchId',
        data: {'features': featureIds},
      );
      final data = _asMap(response.data);

      List<dynamic> featuresList = [];
      if (data['data'] is List) {
        featuresList = data['data'] as List<dynamic>;
      } else if (data['features'] is List) {
        featuresList = data['features'] as List<dynamic>;
      } else if (data['items'] is List) {
        featuresList = data['items'] as List<dynamic>;
      } else if (data is List) {
        featuresList = data as List<dynamic>;
      }

      return featuresList.map((json) => FeatureModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Şube özellikleri güncellenirken hata oluştu: $e');
    }
  }

  // Default features fallback
  List<FeatureModel> _getDefaultFeatures() {
    return [
      const FeatureModel(id: '1', name: 'WiFi'),
      const FeatureModel(id: '2', name: 'Klima'),
      const FeatureModel(id: '3', name: 'Otopark'),
      const FeatureModel(id: '4', name: 'Engelli Erişimi'),
      const FeatureModel(id: '5', name: 'Kartla Ödeme'),
      const FeatureModel(id: '6', name: 'Vale Hizmeti'),
      const FeatureModel(id: '7', name: 'Çocuk Oyun Alanı'),
      const FeatureModel(id: '8', name: 'Kahve/Çay İkramı'),
      const FeatureModel(id: '9', name: 'Masaj'),
      const FeatureModel(id: '10', name: 'Sakal Tasarımı'),
      const FeatureModel(id: '11', name: 'Boya/Röfle'),
      const FeatureModel(id: '12', name: 'Cilt Bakımı'),
    ];
  }
}
