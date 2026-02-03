import 'dart:convert';
import '../../core/services/api_client.dart';
import '../models/extra_feature_model.dart';

class ExtraFeatureApiService {
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

  // Get all extra features
  Future<List<ExtraFeatureModel>> getExtraFeatures() async {
    try {
      final response = await _apiClient.get('/api/extra-feature');
      final data = _asMap(response.data);

      List<dynamic> featuresList = [];
      if (data['data'] is List) {
        featuresList = data['data'] as List<dynamic>;
      } else if (data is List) {
        featuresList = data as List<dynamic>;
      }


      final models =
          featuresList.map((json) {
            final model = ExtraFeatureModel.fromJson(json);
            return model;
          }).toList();

      return models;
    } catch (e) {
      return [];
    }
  }

  // Get extra feature by ID
  Future<ExtraFeatureModel?> getExtraFeature(int id) async {
    try {
      final response = await _apiClient.get('/api/extra-feature/$id');
      final data = _asMap(response.data);

      if (data['data'] is Map<String, dynamic>) {
        return ExtraFeatureModel.fromJson(data['data']);
      }
      return ExtraFeatureModel.fromJson(data);
    } catch (e) {
      return null;
    }
  }
}
